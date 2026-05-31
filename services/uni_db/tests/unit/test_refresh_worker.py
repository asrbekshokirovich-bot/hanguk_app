"""refresh_worker re-fetches already-ingested live sources to catch updates.

Heavy steps (HTTP, storage, parse, the resolver) are injected, so these cover
the worker's own logic: unchanged sha → stamp checked, changed sha → supersede
+ re-parse, fetch failure → still stamp checked (so a permanently-broken URL
doesn't block the rotation), and per-source error isolation.
"""

from __future__ import annotations

from uuid import UUID, uuid4

from uni_db.workers import refresh_worker as rw


class _Resp:
    def __init__(self, content: bytes, ctype: str = "application/pdf") -> None:
        self.content = content
        self.headers = {"content-type": ctype}

    def raise_for_status(self) -> None:
        pass


class _HTTP:
    def __init__(self, handler) -> None:
        self.handler = handler
        self.gets: list[str] = []

    async def get(self, url: str, **_kw: object) -> _Resp:
        self.gets.append(url)
        return self.handler(url)


class _Stored:
    storage_path = "guideline-blobs/new.pdf"


def _store(data: bytes, *, sha256: str, mime: str) -> _Stored:
    return _Stored()


async def _noop_parse(conn: object, gd_id: object, data: bytes) -> None:
    return None


def _gd_record(*, current_sha: str) -> dict:
    """A single due-for-check row (shape that _DUE_SQL would return)."""
    return {
        "source_id": uuid4(),
        "url_ko": "https://uni.ac.kr/admission/guide.pdf",
        "gd_id": uuid4(),
        "file_hash_sha256": current_sha,
        "institution_id": uuid4(),
    }


class _Conn:
    """Fake asyncpg.Connection for the refresh worker.

    `rows` feeds .fetch(_DUE_SQL); .fetchrow simulates
    `insert_guideline_document`'s post-conflict id lookup (returns a fresh id
    for any sha256 query — i.e. the new row "landed"). .execute records every
    SQL string for assertions.
    """

    def __init__(self, rows: list[dict]) -> None:
        self.rows = rows
        self.executed: list[str] = []
        self.new_gd_id = uuid4()

    async def fetch(self, sql: str, *args: object) -> list[dict]:
        return self.rows

    async def fetchrow(self, sql: str, *args: object):
        if "from public.guideline_documents where file_hash_sha256" in " ".join(sql.split()):
            return {"id": self.new_gd_id}
        return None

    async def execute(self, sql: str, *args: object) -> str:
        self.executed.append(" ".join(sql.split()))
        return "OK"

    def _count(self, fragment: str) -> int:
        return sum(1 for s in self.executed if fragment in s)

    @property
    def n_checked_stamped(self) -> int:
        return self._count("set last_checked_at = now()")

    @property
    def n_checked_with_fetched_bump(self) -> int:
        return self._count("set last_checked_at = now(), fetched_at = now()")

    @property
    def n_superseded(self) -> int:
        return self._count("set superseded_by_id = $2")

    @property
    def n_inserts(self) -> int:
        return self._count("insert into public.guideline_documents")


# --------------------------------------------------------------------------- #
# refresh_one — the three outcomes


async def test_unchanged_only_stamps_checked() -> None:
    sha = "a" * 64
    row = _gd_record(current_sha=sha)
    conn = _Conn([row])
    http = _HTTP(lambda url: _Resp(b"%PDF-1.4 same content"))

    # Make hashlib agree with the row's stored sha by patching the worker's
    # hashlib via the bytes coming back from http. Easiest: precompute the sha
    # of the response body and use it as the row's "current" sha.
    import hashlib
    body = b"%PDF-1.4 identical bytes"
    row["file_hash_sha256"] = hashlib.sha256(body).hexdigest()
    http = _HTTP(lambda url: _Resp(body))

    parse_calls: list[UUID] = []

    async def _parse(c, gd_id, d):
        parse_calls.append(gd_id)

    outcome, _note = await rw.refresh_one(
        conn, http, row,
        store_blob=_store, run_parse=_parse,
        generic_resolve=lambda *a, **k: None,
    )
    assert outcome == "unchanged"
    assert conn.n_checked_with_fetched_bump == 1   # bumps both fields
    assert conn.n_inserts == 0
    assert conn.n_superseded == 0
    assert parse_calls == []                       # never re-parses unchanged content


async def test_changed_inserts_supersedes_and_parses() -> None:
    row = _gd_record(current_sha="old" + "0" * 61)
    conn = _Conn([row])
    http = _HTTP(lambda url: _Resp(b"%PDF-1.4 new cycle content"))
    parse_calls: list[UUID] = []

    async def _parse(c, gd_id, d):
        parse_calls.append(gd_id)

    outcome, _note = await rw.refresh_one(
        conn, http, row,
        store_blob=_store, run_parse=_parse,
        generic_resolve=lambda *a, **k: None,
    )
    assert outcome == "updated"
    assert conn.n_inserts == 1
    assert conn.n_superseded == 1
    assert conn.n_checked_stamped >= 1
    assert parse_calls == [conn.new_gd_id]         # parsed the NEW row, not the old


async def test_resolve_failed_still_stamps_checked() -> None:
    # Server returned HTML and the resolver couldn't find a download link.
    # refresh_one must still mark the row checked so the rotation moves on.
    # (Genuine raises out of HTTP are covered by the batch-isolation test below.)
    row = _gd_record(current_sha="abc" + "0" * 61)
    conn = _Conn([row])
    http_html = _HTTP(lambda url: _Resp(b"<html>nope</html>", ctype="text/html"))

    async def _resolve_none(url, http, referer):
        return None

    outcome, _ = await rw.refresh_one(
        conn, http_html, row,
        store_blob=_store, run_parse=_noop_parse,
        generic_resolve=_resolve_none,
    )
    assert outcome == "fetch_failed"
    assert conn.n_checked_stamped == 1
    assert conn.n_inserts == 0
    assert conn.n_superseded == 0


# --------------------------------------------------------------------------- #
# refresh_pending — batch behaviour


async def test_batch_counts_and_isolation() -> None:
    import hashlib

    # Three rows: unchanged, changed, fetch-failed (raises mid-resolve).
    unchanged_body = b"%PDF-1.4 same"
    r_unchanged = _gd_record(current_sha=hashlib.sha256(unchanged_body).hexdigest())
    r_changed   = _gd_record(current_sha="old" + "0" * 61)
    r_failing   = _gd_record(current_sha="zzz" + "0" * 61)
    conn = _Conn([r_unchanged, r_changed, r_failing])

    def _handler(url: str) -> _Resp:
        # `url_ko` is the same for all rows in this fake, so route by request
        # count rather than URL.
        n = len(http.gets)
        if n == 1:
            return _Resp(unchanged_body)                       # row 1: unchanged
        if n == 2:
            return _Resp(b"%PDF-1.4 brand new content")        # row 2: changed
        raise RuntimeError("simulated fetch error on row 3")   # row 3: failing

    http = _HTTP(_handler)

    unchanged, updated, failed = await rw.refresh_pending(
        conn, http, limit=10, min_age_hours=0,
        store_blob=_store, run_parse=_noop_parse,
        generic_resolve=lambda *a, **k: None,
    )
    assert (unchanged, updated, failed) == (1, 1, 1)
    # Each row got stamped checked (the failing row through the except path).
    assert conn.n_checked_stamped + conn.n_checked_with_fetched_bump >= 3
    # Only one supersede + one insert (the changed row).
    assert conn.n_inserts == 1
    assert conn.n_superseded == 1


async def test_empty_due_list_is_a_clean_zero() -> None:
    conn = _Conn([])
    http = _HTTP(lambda url: _Resp(b""))
    result = await rw.refresh_pending(
        conn, http, limit=5,
        store_blob=_store, run_parse=_noop_parse,
        generic_resolve=lambda *a, **k: None,
    )
    assert result == (0, 0, 0)
    assert conn.executed == []
