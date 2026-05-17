#!/usr/bin/env python3
"""One-shot parse run: announcements -> PDF -> Supabase Storage -> Claude extract.

Walks recent announcements that carry a PDF attachment but do not yet have
a linked guideline_document. For each:

  1. Download the PDF (httpx with the source's User-Agent).
  2. SHA256-hash + upload to Supabase Storage (bucket=guideline-blobs).
  3. Insert a guideline_documents row (parse_status='pending').
  4. Link announcements.guideline_document_id.
  5. Run the parse pipeline (PyMuPDF -> Claude field-group extraction).
  6. Write extraction_jobs + review_queue entries via persist_outcome.

Usage:
    UNI_DB_LIVE_CRAWL=true UNI_DB_LIVE_APIS=true \
      .venv/bin/python scripts/run_parse_once.py --limit 1
"""

from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import logging
import sys
from datetime import datetime, timezone
from uuid import UUID, uuid4

import asyncpg
import httpx

from uni_db.config import settings
from uni_db.parse.extract_orchestrator import extract as extract_pdf
from uni_db.parse.pdf_resolvers import (
    ResolvedPdf,
    get_resolver_for_url,
    resolve_pdf,
)
from uni_db.storage import supabase_storage
from uni_db.workers.parse_worker import parse_one_document, persist_outcome

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s %(name)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
log = logging.getLogger("run_parse_once")

# Cap each PDF download — Korean admissions PDFs run 200kb–4MB.
MAX_PDF_BYTES = 20 * 1024 * 1024   # 20 MiB hard cap


def _pick_pdf_attachment(attachments: list[dict]) -> dict | None:
    for a in attachments:
        url = (a.get("url") or "").lower()
        name = (a.get("filename") or "").lower()
        if url.endswith(".pdf") or name.endswith(".pdf"):
            return a
    # Fall back to the first attachment — some boards serve PDFs via
    # opaque /download/{idx} routes that don't carry the extension.
    return attachments[0] if attachments else None


async def _fetch_candidates(
    conn: asyncpg.Connection, limit: int
) -> list[asyncpg.Record]:
    """Return unlinked announcements that have a usable PDF chain.

    A row is "usable" if either:
      * its ``attachments`` array has at least one entry (the legacy
        direct-fetch path), OR
      * its ``url_ko`` points at a host with a registered per-source
        resolver (Yonsei, KU). In that case the resolver follows the
        detail page to find the real PDF, even though discovery never
        populated the attachment URL.

    The host-allow-list is enforced in SQL (cheaper than fetching all
    unlinked rows and post-filtering in Python).
    """
    # Hosts whose attachments are JS-mediated or hidden behind a detail
    # page handler. ``get_resolver_for_url`` knows the full registry —
    # mirror its keys here so the DB filter stays in lockstep.
    resolver_hosts = ["oku.korea.ac.kr", "admission.yonsei.ac.kr"]
    host_pattern = "|".join(h.replace(".", r"\.") for h in resolver_hosts)
    # Postgres regex: match either the bare host or a subdomain prefix.
    url_regex = rf"^https?://(?:[^/]+\.)?(?:{host_pattern})/"
    return await conn.fetch(
        """
        select a.id            as announcement_id,
               a.title_ko,
               a.url_ko,
               a.attachments::text as attachments_json,
               s.id            as source_id,
               s.institution_id,
               s.url_ko        as source_url_ko
          from public.announcements a
          join public.announcement_sources s on s.id = a.source_id
         where a.guideline_document_id is null
           and (
                 (a.attachments is not null
                  and jsonb_array_length(a.attachments) > 0)
                 or a.url_ko ~* $2
               )
         order by a.posted_at desc
         limit $1
        """,
        limit,
        url_regex,
    )


async def _insert_guideline_document(
    conn: asyncpg.Connection,
    *,
    institution_id: UUID | None,
    source_url_ko: str,
    storage_path: str,
    sha256: str,
    size_bytes: int,
    mime: str,
) -> UUID:
    new_id = uuid4()
    await conn.execute(
        """
        insert into public.guideline_documents (
          id, institution_id, source_url_ko,
          storage_path, file_hash_sha256, file_size_bytes, mime_type,
          fetched_at, parse_status, parsed_version, language
        ) values (
          $1, $2, $3,
          $4, $5, $6, $7,
          $8, 'pending', 0, 'ko'
        )
        on conflict (file_hash_sha256) do update
           set fetched_at = excluded.fetched_at
        returning id
        """,
        new_id,
        institution_id,
        source_url_ko,
        storage_path,
        sha256,
        size_bytes,
        mime,
        datetime.now(tz=timezone.utc),
    )
    row = await conn.fetchrow(
        "select id from public.guideline_documents where file_hash_sha256 = $1",
        sha256,
    )
    return row["id"]


async def _link_announcement(
    conn: asyncpg.Connection,
    announcement_id: UUID,
    guideline_document_id: UUID,
) -> None:
    await conn.execute(
        "update public.announcements set guideline_document_id = $2 where id = $1",
        announcement_id,
        guideline_document_id,
    )


async def _process_one(
    conn: asyncpg.Connection,
    http: httpx.AsyncClient,
    row: asyncpg.Record,
) -> tuple[bool, str]:
    attachments = json.loads(row["attachments_json"] or "[]")
    pick = _pick_pdf_attachment(attachments)
    url = pick.get("url") if pick else None

    # Yonsei (and any future Playwright-discovered source) lands
    # announcements with empty attachments arrays because the list-page
    # rows don't expose the attachment anchors. Fall back to the
    # announcement's URL — if the URL's host has a per-source resolver,
    # the resolver will follow it to find the real PDF.
    if not url and get_resolver_for_url(row["url_ko"] or "") is not None:
        url = row["url_ko"]
        log.info(
            "-> no attachment in row; using announcement URL "
            "(resolver registered for host)"
        )

    if not url:
        return False, "no usable attachment"

    # Per-source resolver: KU / Yonsei attachments are HTML detail pages
    # that hide the real PDF behind a JS click handler or a download.asp
    # query-string. The resolver returns the resolved direct URL plus any
    # headers (typically a Referer) the download GET needs. Hosts without
    # a registered resolver fall through to the legacy direct-fetch path.
    resolved: ResolvedPdf | None = await resolve_pdf(
        url, http_client=http, referer=row["source_url_ko"],
    )
    if resolved is not None:
        download_url = resolved.url
        download_headers = {
            "User-Agent": settings.http_user_agent,
            "Referer": row["source_url_ko"],
            **dict(resolved.headers),
        }
        log.info(
            "-> resolved attachment via %s resolver: %s (filename=%s)",
            url.split("/")[2] if "/" in url else url,
            download_url[:100],
            resolved.filename[:60],
        )
    else:
        download_url = url
        download_headers = {
            "User-Agent": settings.http_user_agent,
            "Referer": row["source_url_ko"],
        }

    log.info("-> fetching %s", download_url[:100])
    resp = await http.get(
        download_url,
        timeout=settings.http_request_timeout_sec,
        headers=download_headers,
        follow_redirects=True,
    )
    resp.raise_for_status()
    data = resp.content

    if len(data) > MAX_PDF_BYTES:
        return False, f"pdf too large ({len(data)} bytes)"

    raw_mime = (resp.headers.get("content-type") or "").split(";", 1)[0].strip()
    looks_like_pdf = data[:4] == b"%PDF"
    if looks_like_pdf:
        # Many Korean CMS endpoints emit ``application/download``,
        # ``application/octet-stream``, or even ``text/html`` (sic) for
        # PDFs. Trust the magic-bytes sniff and normalise the stored
        # mime so downstream consumers can rely on it.
        mime = "application/pdf"
    else:
        mime = raw_mime or "application/octet-stream"
        if "html" in mime.lower() or not raw_mime:
            return False, (
                f"attachment served non-PDF (mime={raw_mime!r}, "
                f"first4={data[:4]!r})"
            )

    sha256 = hashlib.sha256(data).hexdigest()
    log.info("   sha256=%s bytes=%d mime=%s", sha256[:12], len(data), mime)

    stored = supabase_storage.store_blob(data, sha256=sha256, mime=mime)
    log.info("   stored at %s", stored.storage_path)

    gd_id = await _insert_guideline_document(
        conn,
        institution_id=row["institution_id"],
        source_url_ko=row["source_url_ko"],
        storage_path=stored.storage_path,
        sha256=sha256,
        size_bytes=len(data),
        mime=mime,
    )
    await _link_announcement(conn, row["announcement_id"], gd_id)
    log.info("   guideline_document=%s linked to announcement=%s",
             str(gd_id)[:8], str(row["announcement_id"])[:8])

    extracted, decision = extract_pdf(data)
    log.info("   pdf: %d pages, tier=%s, chars/page=%.0f",
             extracted.page_count, decision.tier, decision.chars_per_page_avg)

    if not extracted.text.strip():
        await conn.execute(
            "update public.guideline_documents set parse_status='failed' where id=$1",
            gd_id,
        )
        return False, "no text extracted from PDF"

    # First ~6 pages drive archetype classification; full text drives section slicing.
    pages_text = extracted.text.split("\n")
    head = "\n".join(pages_text[: min(len(pages_text), 600)])  # ~first chunks

    outcome = parse_one_document(
        guideline_document_id=gd_id,
        pdf_text_first_pages=head,
        pdf_text_full=extracted.text,
    )
    log.info("   archetype=%s extraction_groups=%d review_entries=%d",
             outcome.archetype.label,
             len(outcome.extraction_results),
             len(outcome.review_queue_entries))

    await persist_outcome(conn, outcome)
    return True, f"parsed ({outcome.archetype.label})"


async def main(args: argparse.Namespace) -> int:
    log.info("live_crawl=%s live_apis=%s", settings.live_crawl, settings.live_apis)

    conn = await asyncpg.connect(settings.supabase_db_url)
    try:
        candidates = await _fetch_candidates(conn, args.limit)
        log.info("Candidates: %d", len(candidates))
        if not candidates:
            log.info("Nothing to parse (no announcements with unlinked attachments).")
            return 0

        ok = 0
        fail = 0
        async with httpx.AsyncClient(
            headers={"User-Agent": settings.http_user_agent},
            follow_redirects=True,
            timeout=settings.http_request_timeout_sec,
        ) as http:
            for row in candidates:
                title = (row["title_ko"] or "")[:50]
                log.info("Processing: %s", title)
                try:
                    success, note = await _process_one(conn, http, row)
                except Exception as e:  # noqa: BLE001
                    success = False
                    note = f"exception: {type(e).__name__}: {e}"
                    log.exception("   error processing announcement")
                if success:
                    ok += 1
                    log.info("   [OK] %s", note)
                else:
                    fail += 1
                    log.warning("   [SKIP] %s", note)
    finally:
        await conn.close()

    log.info("Done. ok=%d failed=%d", ok, fail)
    return 0 if ok > 0 else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--limit", type=int, default=1, help="Max announcements to parse this run")
    args = parser.parse_args()
    sys.exit(asyncio.run(main(args)))
