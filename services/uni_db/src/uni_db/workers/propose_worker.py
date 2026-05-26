"""Propose-sources worker — auto-discover unknown ac.kr admission boards.

`run-pipeline` and `reparse` only ever touch sources we already track. To grow
coverage to universities we've never crawled, this runs the Naver web-search
adapter over the Korean keyword vocabulary, maps each surviving hit to a
`propose_source.Candidate`, and writes it to `proposed_sources` for the HITL
reviewer to approve (ADR-005). Approved rows are promoted into
`announcement_sources` by the `trg_proposed_source_promote` trigger — nothing
goes live without a human, so this worker is safe to schedule.

The Naver HTTP call lives in `NaverSearchAdapter`, which self-gates on
`settings.live_apis`; this module only orchestrates the keyword loop, the
cross-keyword url dedup, and the gate-and-insert via `propose_batch`. Both the
per-keyword search and the propose sink are injectable so the loop unit-tests
without live HTTP or a database.
"""

from __future__ import annotations

import logging
from collections.abc import Awaitable, Callable, Iterable, Sequence
from dataclasses import dataclass
from datetime import datetime
from typing import TYPE_CHECKING
from uuid import uuid4

import asyncpg

from ..discovery.adapters.naver_search_adapter import (
    DEFAULT_DISCOVERY_KEYWORDS,
    NaverSearchAdapter,
)
from ..discovery.models import Announcement
from ..discovery.propose_source import Candidate, ProposeOutcome, propose_batch

if TYPE_CHECKING:
    import httpx

log = logging.getLogger(__name__)

# Yields the announcements for one keyword. NaverSearchAdapter satisfies the
# default; tests pass a fake to avoid live HTTP.
SearchFn = Callable[[str], Awaitable[list[Announcement]]]
ProposeFn = Callable[
    [asyncpg.Connection, Iterable[Candidate]], Awaitable[list[ProposeOutcome]]
]


@dataclass(frozen=True, slots=True)
class ProposeRun:
    keywords_searched: int
    candidates_seen: int  # unique url_ko across every keyword
    proposed: int         # rows inserted/refreshed in proposed_sources
    skipped: int          # gated out, or url already live
    search_errors: int    # keywords whose search call raised


async def discover_sources(
    conn: asyncpg.Connection,
    *,
    since: datetime,
    keywords: Sequence[str] = DEFAULT_DISCOVERY_KEYWORDS,
    http_client: httpx.AsyncClient | None = None,
    search: SearchFn | None = None,
    propose: ProposeFn = propose_batch,
) -> ProposeRun:
    """Run Naver discovery across `keywords` and propose unseen ac.kr boards.

    `search(keyword)` returns the announcements for one keyword; the default
    builds a fresh NaverSearchAdapter per keyword over the shared http_client.
    A keyword that errors (rate limit, transient 5xx) is logged and skipped so
    one bad call never aborts the whole sweep.
    """
    search_fn = search or _default_search(http_client, since)

    seen: dict[str, Candidate] = {}
    search_errors = 0
    for kw in keywords:
        try:
            posts = await search_fn(kw)
        except Exception as exc:  # one keyword failing must not kill the sweep
            search_errors += 1
            log.warning(
                "propose_worker: search %r failed: %s: %s",
                kw, type(exc).__name__, str(exc)[:160],
            )
            continue
        for ann in posts:
            # The same notice surfaces under several keywords; keep the first.
            if ann.url_ko in seen:
                continue
            seen[ann.url_ko] = Candidate(
                url_ko=ann.url_ko,
                proposed_by="naver_search",
                candidate_title=ann.title_ko,
            )

    outcomes = await propose(conn, list(seen.values()))
    proposed = sum(1 for o in outcomes if o.inserted)
    skipped = len(outcomes) - proposed
    log.info(
        "propose_worker: keywords=%d unique_candidates=%d proposed=%d "
        "skipped=%d search_errors=%d",
        len(keywords), len(seen), proposed, skipped, search_errors,
    )
    return ProposeRun(
        keywords_searched=len(keywords),
        candidates_seen=len(seen),
        proposed=proposed,
        skipped=skipped,
        search_errors=search_errors,
    )


def _default_search(
    http_client: httpx.AsyncClient | None, since: datetime
) -> SearchFn:
    if http_client is None:
        raise RuntimeError(
            "discover_sources needs an http_client (or an injected search fn)"
        )

    async def search(keyword: str) -> list[Announcement]:
        adapter = NaverSearchAdapter(
            source_id=uuid4(), keyword=keyword, http_client=http_client
        )
        return await adapter.list_recent_posts(since=since)

    return search
