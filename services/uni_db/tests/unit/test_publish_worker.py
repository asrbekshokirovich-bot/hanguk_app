"""publish_worker normalizes approved review items into the public tables.

The DB is faked (records in, inserts captured), so these cover the worker's
logic: payload selection (reviewer edit > raw), the per-field-group mapping,
cycle get-or-create for cycle-scoped tables, the document-name fallback,
skip/idempotency, and batch error isolation.
"""

from __future__ import annotations

from datetime import date
from uuid import uuid4

from uni_db.workers import publish_worker as pw


class _Conn:
    def __init__(self, records: list[dict]) -> None:
        self._records = records
        self.executes: list[tuple[str, tuple]] = []
        self.cycle_id = uuid4()
        self.fetchvals = 0

    async def fetch(self, sql: str, *args: object) -> list[dict]:
        return self._records

    async def fetchval(self, sql: str, *args: object):
        self.fetchvals += 1          # get_or_create_cycle
        return self.cycle_id

    async def execute(self, sql: str, *args: object) -> str:
        self.executes.append((" ".join(sql.split()), args))
        return "OK"

    def inserts_into(self, table: str) -> list[tuple]:
        key = f"insert into public.{table} "
        return [args for sql, args in self.executes if key in sql]

    @property
    def marked_published(self) -> int:
        return sum(1 for sql, _ in self.executes
                   if "update public.review_queue set published_at" in sql)


def _rec(field_group: str, parsed_output: dict, reviewer_decision=None) -> dict:
    return {
        "queue_id": uuid4(), "reviewer_decision": reviewer_decision,
        "field_group": field_group, "parsed_output": parsed_output,
        "accuracy_self_score": 0.9, "guideline_document_id": uuid4(),
        "institution_id": uuid4(),
    }


# --------------------------------------------------------------------------- #
# pure helpers


class TestHelpers:
    def test_infer_year_from_payload(self) -> None:
        assert pw.infer_year({"rows": [{"source_text_ko": "2027학년도 모집"}]},
                             default=2099) == 2027

    def test_infer_year_default_when_absent(self) -> None:
        assert pw.infer_year({"rows": [{"x": "no year"}]}, default=2027) == 2027

    def test_infer_term_fall_vs_spring(self) -> None:
        assert pw.infer_term({"rows": [{"source_text_ko": "2026 후기 9월 모집"}]}) == "fall"
        assert pw.infer_term({"rows": [{"source_text_ko": "전기 모집"}]}) == "spring"

    def test_first_doc_name_fallback(self) -> None:
        assert pw.first_doc_name({"document_name_ko": "졸업증명서"}) == "졸업증명서"
        assert pw.first_doc_name({"name_ko": "여권"}) == "여권"
        assert pw.first_doc_name({"nothing": 1}) == "서류"

    def test_as_date(self) -> None:
        assert pw._as_date("2026-09-01") == date(2026, 9, 1)
        assert pw._as_date("2026-09-01T09:00:00Z") == date(2026, 9, 1)
        assert pw._as_date(None) is None
        assert pw._as_date("nope") is None

    def test_payload_prefers_reviewer_edit(self) -> None:
        rec = {"reviewer_decision": {"rows": [{"e": 1}]}, "parsed_output": {"rows": [{"r": 1}]}}
        assert pw._payload(rec) == {"rows": [{"e": 1}]}
        rec2 = {"reviewer_decision": None, "parsed_output": {"rows": [{"r": 1}]}}
        assert pw._payload(rec2) == {"rows": [{"r": 1}]}


# --------------------------------------------------------------------------- #
# publish_pending


async def test_publishes_tuition_and_marks_done() -> None:
    rec = _rec("tuition", {"rows": [{"faculty_group": "인문", "academic_year": 2026,
                                     "semester_number": 1, "amount_krw": 4800000,
                                     "source_text_ko": "x"}]})
    conn = _Conn([rec])
    run = await pw.publish_pending(conn)
    assert run.published == 1 and run.rows_written == 1
    assert len(conn.inserts_into("tuition")) == 1
    assert conn.marked_published == 1


async def test_requirements_creates_cycle_then_inserts() -> None:
    rec = _rec("requirements", {"rows": [{"applicant_category": "외국인전형",
                                          "topik_min_level": 3, "source_text_ko": "x"}]})
    conn = _Conn([rec])
    run = await pw.publish_pending(conn)
    assert conn.fetchvals == 1                      # cycle get-or-create
    assert len(conn.inserts_into("requirements")) == 1
    assert run.rows_written == 1


async def test_documents_uses_doc_name_fallback() -> None:
    rec = _rec("documents_required",
               {"rows": [{"document_name_ko": "졸업증명서", "source_text_ko": "x"}]})
    conn = _Conn([rec])
    await pw.publish_pending(conn)
    args = conn.inserts_into("documents_required")[0]
    assert "졸업증명서" in args                      # document_type filled from fallback


async def test_calendar_periods_to_admission_periods() -> None:
    rec = _rec("calendar", {"events": [], "periods": [
        {"program_level": "undergraduate", "application_start": "2026-09-01",
         "application_end": "2026-09-30", "result_announcement": "2026-11-20"}]})
    conn = _Conn([rec])
    run = await pw.publish_pending(conn)
    assert len(conn.inserts_into("university_admission_periods")) == 1
    assert run.rows_written == 1


async def test_reviewer_edit_takes_precedence() -> None:
    rec = _rec("scholarships",
               {"rows": [{"scope": "university", "name_ko": "RAW",
                          "award_type": "tuition_waiver_pct", "source_text_ko": "x"}]},
               reviewer_decision={"rows": [{"scope": "university", "name_ko": "EDITED",
                                            "award_type": "tuition_waiver_pct",
                                            "source_text_ko": "x"}]})
    conn = _Conn([rec])
    await pw.publish_pending(conn)
    args = conn.inserts_into("scholarships")[0]
    assert "EDITED" in args and "RAW" not in args


async def test_skips_empty_payload_but_marks_published() -> None:
    rec = _rec("tuition", {"rows": []})
    conn = _Conn([rec])
    run = await pw.publish_pending(conn)
    assert run.skipped == 1 and run.published == 0
    assert conn.inserts_into("tuition") == []
    assert conn.marked_published == 1               # don't re-scan it next run


async def test_failed_extraction_skipped() -> None:
    rec = _rec("requirements", {"_extraction_failed": "boom"})
    conn = _Conn([rec])
    run = await pw.publish_pending(conn)
    assert run.skipped == 1
    assert conn.inserts_into("requirements") == []


async def test_one_bad_item_does_not_abort_batch() -> None:
    good = _rec("scholarships", {"rows": [{"scope": "university", "name_ko": "S",
                                           "award_type": "airfare", "source_text_ko": "x"}]})
    bad = _rec("tuition", {"rows": [{"amount_krw": 1}]})
    conn = _Conn([good, bad])

    real_execute = conn.execute

    async def execute(sql: str, *args: object):
        if "insert into public.tuition" in " ".join(sql.split()):
            raise RuntimeError("boom")
        return await real_execute(sql, *args)

    conn.execute = execute  # type: ignore[method-assign]
    run = await pw.publish_pending(conn)
    assert run.published == 1 and run.errors == 1
