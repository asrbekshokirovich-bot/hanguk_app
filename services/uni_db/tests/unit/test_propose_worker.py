"""propose_worker orchestrates the Naver keyword sweep → proposed_sources.

The live HTTP (NaverSearchAdapter) and DB write (propose_batch) are injected,
so these tests cover the worker's own logic: cross-keyword url dedup, the
Announcement→Candidate mapping, per-keyword error isolation, and count
aggregation from ProposeOutcome.inserted.
"""

from __future__ import annotations

from datetime import datetime, timezone

from uni_db.discovery.models import Announcement
from uni_db.discovery.propose_source import Candidate, ProposeOutcome
from uni_db.workers import propose_worker

_SINCE = datetime(2026, 1, 1, tzinfo=timezone.utc)


def _ann(url: str, title: str = "외국인전형 모집요강") -> Announcement:
    return Announcement(
        external_post_id="x" + url[-4:], title_ko=title, url_ko=url, posted_at=None
    )


class _RecordingPropose:
    """Stand-in for propose_batch: records candidates, marks any url with
    'live' as skipped (already in announcement_sources)."""

    def __init__(self) -> None:
        self.seen: list[Candidate] = []

    async def __call__(self, conn: object, candidates) -> list[ProposeOutcome]:
        cands = list(candidates)
        self.seen.extend(cands)
        return [
            ProposeOutcome(inserted="live" not in c.url_ko, reason="t")
            for c in cands
        ]


async def test_dedups_same_url_across_keywords() -> None:
    async def search(keyword: str) -> list[Announcement]:
        # The same notice surfaces under both keywords searched.
        return [_ann("https://admission.a.ac.kr/n/1")]

    propose = _RecordingPropose()
    run = await propose_worker.discover_sources(
        _conn(), since=_SINCE, keywords=("외국인전형", "모집요강"),
        search=search, propose=propose,
    )
    assert run.keywords_searched == 2
    assert run.candidates_seen == 1            # deduped to one url
    assert len(propose.seen) == 1
    assert run.proposed == 1


async def test_maps_announcement_to_naver_candidate() -> None:
    async def search(keyword: str) -> list[Announcement]:
        return [_ann("https://admission.b.ac.kr/n/2", title="정정공고 일정변경")]

    propose = _RecordingPropose()
    await propose_worker.discover_sources(
        _conn(), since=_SINCE, keywords=("정정공고",),
        search=search, propose=propose,
    )
    c = propose.seen[0]
    assert c.url_ko == "https://admission.b.ac.kr/n/2"
    assert c.proposed_by == "naver_search"
    assert c.candidate_title == "정정공고 일정변경"


async def test_one_keyword_error_does_not_abort_sweep() -> None:
    async def search(keyword: str) -> list[Announcement]:
        if keyword == "boom":
            raise RuntimeError("naver 429 rate limited")
        return [_ann(f"https://admission.c.ac.kr/{keyword}")]

    propose = _RecordingPropose()
    run = await propose_worker.discover_sources(
        _conn(), since=_SINCE, keywords=("boom", "외국인전형"),
        search=search, propose=propose,
    )
    assert run.search_errors == 1
    assert run.candidates_seen == 1            # the surviving keyword still ran
    assert run.proposed == 1


async def test_skipped_count_tracks_uninserted_outcomes() -> None:
    async def search(keyword: str) -> list[Announcement]:
        return [
            _ann("https://admission.d.ac.kr/new"),
            _ann("https://admission.d.ac.kr/live-already"),  # propose marks skipped
        ]

    run = await propose_worker.discover_sources(
        _conn(), since=_SINCE, keywords=("외국인전형",),
        search=search, propose=_RecordingPropose(),
    )
    assert run.candidates_seen == 2
    assert run.proposed == 1
    assert run.skipped == 1


async def test_default_search_requires_http_client() -> None:
    import pytest

    with pytest.raises(RuntimeError, match="http_client"):
        await propose_worker.discover_sources(_conn(), since=_SINCE, keywords=("외국인전형",))


def _conn() -> object:
    """The injected propose fn ignores the connection, so a sentinel is fine."""
    return object()
