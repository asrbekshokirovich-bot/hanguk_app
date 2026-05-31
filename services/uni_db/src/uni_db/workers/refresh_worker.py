"""Refresh worker — re-fetch already-ingested live sources to catch updates.

Phase 5 freshness. The fetch/ingest workers only run on sources WITHOUT a
guideline_document yet, so a school that updates the PDF *behind a perennial
URL* (e.g. `…/admission/외국인_특별전형_모집요강.pdf` replaced in place each cycle, or
a correction-notice posted over yesterday's file) is invisible to the rest of
the pipeline forever — we'd keep showing the 2017 version. The audit caught
exactly this with cdu.

This worker rotates through live, current (not-superseded) documents oldest-
checked-first, re-fetches each via the same resolver chain ingest uses, then:

  * sha-compares the new content with the stored hash;
  * **unchanged** → stamp `last_checked_at = now` so the rotation moves on;
  * **changed** → insert a new `guideline_documents` row, set the old row's
    `superseded_by_id` to the new one, and re-run parse — producing a fresh
    `review_queue` item that flows through the existing publish + translate
    pipeline (so the operator approves the new cycle, the staleness guard lets
    it publish as current, and translate fills EN/UZ — all without any one-off
    operator action).

Errors on a single source are isolated (and the source is still stamped
checked, so a permanently-broken URL doesn't block the rotation forever).
Heavy steps (resolve, store, parse) are injected with lazy-importing defaults
so the worker unit-tests without httpx / PyMuPDF / boto3.
"""

from __future__ import annotations

import contextlib
import hashlib
import logging
from typing import Final
from uuid import UUID

import asyncpg
import httpx

from .direct_ingest_worker import GenericResolve, resolve_to_pdf
from .fetch_worker import (
    RunParse,
    _default_run_parse,
    _default_store_blob,
    _StoreBlob,
    insert_guideline_document,
)

log = logging.getLogger(__name__)


# Live promoted sources whose CURRENT guideline_document is due for a re-check
# (oldest-checked first; nulls — never checked — first). The partial index on
# `last_checked_at where superseded_by_id is null` keeps this cheap as the
# document count grows.
_DUE_SQL: Final[str] = """
select s.id              as source_id,
       s.url_ko          as url_ko,
       gd.id             as gd_id,
       gd.file_hash_sha256,
       gd.institution_id
  from public.announcement_sources s
  join public.guideline_documents gd on gd.source_url_ko = s.url_ko
 where s.status = 'live'
   and gd.superseded_by_id is null
   and (gd.last_checked_at is null
        or gd.last_checked_at < now() - make_interval(hours => $2))
 order by gd.last_checked_at nulls first
 limit $1
"""


async def _mark_checked(
    conn: asyncpg.Connection, gd_id: UUID, *, also_bump_fetched: bool = False
) -> None:
    """Stamp `last_checked_at = now`. When the bytes were unchanged but we did
    re-download them, also bump `fetched_at` (the file is still in active use)."""
    if also_bump_fetched:
        await conn.execute(
            "update public.guideline_documents "
            "set last_checked_at = now(), fetched_at = now() where id = $1",
            gd_id,
        )
    else:
        await conn.execute(
            "update public.guideline_documents set last_checked_at = now() where id = $1",
            gd_id,
        )


async def _mark_superseded(
    conn: asyncpg.Connection, old_id: UUID, new_id: UUID
) -> None:
    await conn.execute(
        "update public.guideline_documents set superseded_by_id = $2 where id = $1",
        old_id, new_id,
    )


async def refresh_one(
    conn: asyncpg.Connection,
    http: httpx.AsyncClient,
    row: asyncpg.Record,
    *,
    store_blob: _StoreBlob | None = None,
    run_parse: RunParse | None = None,
    generic_resolve: GenericResolve | None = None,
) -> tuple[str, str]:
    """Re-check one source. Returns (outcome, note). outcome ∈
    {'unchanged', 'updated', 'fetch_failed'}.

    On fetch failure we still mark the row checked, so a permanently-broken
    source doesn't pin the head of the oldest-first queue.
    """
    store_blob = store_blob or _default_store_blob
    run_parse = run_parse or _default_run_parse
    if generic_resolve is None:
        from ..parse.pdf_resolvers.generic_attachment import resolve as generic_resolve

    url = row["url_ko"]
    data, mime = await resolve_to_pdf(http, url, generic_resolve=generic_resolve)
    if data is None:
        await _mark_checked(conn, row["gd_id"])
        return "fetch_failed", mime  # mime carries the skip reason here

    new_sha = hashlib.sha256(data).hexdigest()
    if new_sha == row["file_hash_sha256"]:
        await _mark_checked(conn, row["gd_id"], also_bump_fetched=True)
        return "unchanged", "sha unchanged"

    # Real update — store the new bytes, insert a fresh row (the sha256
    # unique-key ON CONFLICT in insert_guideline_document just returns the
    # existing id if some other path beat us to it), supersede the old, parse.
    stored = store_blob(data, sha256=new_sha, mime=mime)
    new_gd_id = await insert_guideline_document(
        conn,
        institution_id=row["institution_id"],
        source_url_ko=url,
        storage_path=stored.storage_path,
        sha256=new_sha,
        size_bytes=len(data),
        mime=mime,
    )
    await _mark_superseded(conn, row["gd_id"], new_gd_id)
    await _mark_checked(conn, row["gd_id"])
    await run_parse(conn, new_gd_id, data)
    return "updated", f"{row['file_hash_sha256'][:8]} → {new_sha[:8]}"


async def refresh_pending(
    conn: asyncpg.Connection,
    http: httpx.AsyncClient,
    *,
    limit: int,
    min_age_hours: int = 24,
    store_blob: _StoreBlob | None = None,
    run_parse: RunParse | None = None,
    generic_resolve: GenericResolve | None = None,
) -> tuple[int, int, int]:
    """Refresh up to `limit` live, current sources whose `last_checked_at` is
    older than `min_age_hours` (or null). Returns (unchanged, updated, failed)."""
    rows = await conn.fetch(_DUE_SQL, limit, min_age_hours)
    log.info("refresh_worker: %d source(s) due for re-check", len(rows))
    unchanged = updated = failed = 0
    for row in rows:
        try:
            outcome, note = await refresh_one(
                conn, http, row,
                store_blob=store_blob,
                run_parse=run_parse,
                generic_resolve=generic_resolve,
            )
        except Exception as exc:  # one bad source must not abort the batch
            outcome, note = "fetch_failed", f"{type(exc).__name__}: {exc}"
            log.warning("refresh_worker: error on %s: %s",
                        str(row["gd_id"])[:8], note)
            # Stamp anyway so a permanently-broken source doesn't pin the head
            # of the oldest-first queue. If even the stamp fails, the next pass
            # picks up the same row — preferable to crashing the whole batch.
            with contextlib.suppress(Exception):
                await _mark_checked(conn, row["gd_id"])
        if outcome == "unchanged":
            unchanged += 1
        elif outcome == "updated":
            updated += 1
            log.info("refresh_worker: %s UPDATED — %s",
                     str(row["gd_id"])[:8], note)
        else:
            failed += 1
            log.info("refresh_worker: %s skip — %s",
                     str(row["gd_id"])[:8], note)
    return unchanged, updated, failed
