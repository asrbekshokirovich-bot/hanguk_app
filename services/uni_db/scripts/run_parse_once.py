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
           and a.attachments is not null
           and jsonb_array_length(a.attachments) > 0
         order by a.posted_at desc
         limit $1
        """,
        limit,
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
    if not pick:
        return False, "no usable attachment"

    url = pick.get("url")
    if not url:
        return False, "attachment has no url"

    log.info("-> fetching %s", url[:100])
    resp = await http.get(
        url,
        timeout=settings.http_request_timeout_sec,
        headers={
            "User-Agent": settings.http_user_agent,
            "Referer": row["source_url_ko"],
        },
        follow_redirects=True,
    )
    resp.raise_for_status()
    data = resp.content

    if len(data) > MAX_PDF_BYTES:
        return False, f"pdf too large ({len(data)} bytes)"

    mime = (resp.headers.get("content-type") or "").split(";", 1)[0].strip() or "application/pdf"
    if "html" in mime.lower():
        return False, f"attachment served HTML, not PDF (mime={mime})"

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
