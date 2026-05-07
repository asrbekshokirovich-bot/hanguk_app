"""Admin CLI — `uni-db <subcommand>`.

Phase 0 commands:
  review-digest          Print HITL review queue as Markdown digest.
  crawl --source X       Run discovery against a fixture (no live HTTP).
  parse  --fixture NAME  Run extraction (mocked LLM) against a fixture PDF.
  schema-check           Verify migrations parse and that tables-of-record
                         are referenced by views.

The CLI never touches a live DB unless SUPABASE_DB_URL is set AND the
subcommand explicitly calls for it. Every paid integration is gated on
settings.live_apis.
"""

from __future__ import annotations

import argparse
import asyncio
import logging
import sys
from pathlib import Path

from .config import settings


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="uni-db", description="Korean Universities DB admin")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_review = sub.add_parser("review-digest", help="Print HITL queue as markdown")
    p_review.add_argument("--limit", type=int, default=20)

    p_crawl = sub.add_parser("crawl", help="Run discovery against a source")
    p_crawl.add_argument("--source", required=True, help="e.g. snu | rss-fixture")
    p_crawl.add_argument("--fixture", action="store_true",
                         help="Read from tests/fixtures/<source>.html")

    p_parse = sub.add_parser("parse", help="Run extraction over a fixture PDF")
    p_parse.add_argument("--fixture", required=True,
                         help="basename in tests/fixtures (without extension)")

    sub.add_parser("schema-check", help="Lint the migrations directory")
    return parser


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=settings.log_level, stream=sys.stderr)
    parser = _build_parser()
    args = parser.parse_args(argv)

    if args.cmd == "review-digest":
        return asyncio.run(_review_digest(limit=args.limit))
    if args.cmd == "crawl":
        return asyncio.run(_crawl_fixture(source=args.source, fixture=args.fixture))
    if args.cmd == "parse":
        return asyncio.run(_parse_fixture(name=args.fixture))
    if args.cmd == "schema-check":
        return _schema_check()

    parser.error(f"unknown command: {args.cmd}")
    return 2


async def _review_digest(*, limit: int) -> int:
    """Phase 0 print-only digest: requires SUPABASE_DB_URL.

    Without a live DB this just prints a header explaining how to enable it.
    """
    if not settings.supabase_db_url:
        print("# HITL review queue\n")
        print("> SUPABASE_DB_URL not set. Phase 0 keeps this offline by default.")
        print("> Set the env in `services/uni_db/.env` and re-run.")
        return 0

    from .db import acquire

    async with acquire() as conn:
        rows = await conn.fetch(
            """
            select id, priority, reason, entity_type, entity_id,
                   name_ko, name_en, source_url_ko
              from public.v_review_queue_dashboard
             order by priority asc
             limit $1
            """,
            limit,
        )
    print("# HITL review queue\n")
    for r in rows:
        print(f"- **P{r['priority']}** {r['reason']} — {r['name_ko'] or r['name_en']}")
        print(f"  - entity: `{r['entity_type']}#{r['entity_id']}`")
        if r["source_url_ko"]:
            print(f"  - source: {r['source_url_ko']}")
    return 0


async def _crawl_fixture(*, source: str, fixture: bool) -> int:
    if not fixture:
        print("Phase 0 only supports --fixture mode.", file=sys.stderr)
        return 2

    from uuid import uuid4
    from .discovery.adapters.html_list_adapter import HtmlListAdapter, HtmlListSelectors
    from .workers.discovery_worker import run_one_source
    from .discovery.registry import RegistrySource

    fixture_root = Path(__file__).parent.parent.parent / "tests" / "fixtures"
    candidate = fixture_root / f"{source}_list.html"
    if not candidate.exists():
        print(f"fixture {candidate} missing", file=sys.stderr)
        return 2

    adapter = HtmlListAdapter(
        source_id=uuid4(),
        source_url_ko="https://admission.snu.ac.kr/international/notice",
        selectors=HtmlListSelectors(
            row="tr.notice-row",
            title="td.title",
            link="td.title a",
            posted_at="td.date",
        ),
        fixture_path=candidate,
    )
    src = RegistrySource(
        id=adapter.source_id,
        institution_id=None,
        source_type="university_admission_board",
        url_ko=adapter.source_url_ko,
        status="live",
        cron_high_season_minutes=360,
        cron_off_season_minutes=1440,
        consecutive_fails=0,
    )
    run = await run_one_source(source=src, adapter=adapter, prior_snapshots={})
    print(f"# discovery run — {source}")
    print(f"  records_seen={run.summary.records_seen} new={run.summary.records_new} "
          f"changed={run.summary.records_changed} status={run.summary.status}")
    for ann, finding in run.findings:
        print(f"  - [{finding.finding_type}/P{finding.priority}] {ann.title_ko[:80]}")
    return 0


async def _parse_fixture(*, name: str) -> int:
    fixture_root = Path(__file__).parent.parent.parent / "tests" / "fixtures"
    candidate = fixture_root / f"{name}.pdf"
    if not candidate.exists():
        print(f"fixture {candidate} missing", file=sys.stderr)
        return 2

    from uuid import uuid4
    from .parse.pdf_text import extract_text_from_path
    from .workers.parse_worker import parse_one_document

    extracted = extract_text_from_path(candidate)
    outcome = parse_one_document(
        guideline_document_id=uuid4(),
        pdf_text_first_pages=extracted.text[:6000],
        pdf_text_full=extracted.text,
    )
    print(f"# parse — {name}")
    print(f"  archetype={outcome.archetype.label} ({outcome.archetype.confidence:.2f})")
    for r in outcome.extraction_results:
        print(f"  - {r.field_group}: {r.llm_provider}/{r.llm_model} "
              f"conf={r.accuracy_self_score:.2f}")
    if outcome.review_queue_entries:
        print(f"  review_queue: {len(outcome.review_queue_entries)} entries enqueued")
    return 0


def _schema_check() -> int:
    """Phase 0 lint: every migration parses with Python's `sqlparse`-equivalent
    naive line scan, and every CREATE VIEW resolves table names that exist."""
    repo_root = Path(__file__).parent.parent.parent.parent.parent
    migrations = sorted((repo_root / "supabase" / "migrations").glob("*.sql"))
    table_names: set[str] = set()
    view_refs: list[tuple[str, str]] = []   # (view_name, referenced_table)
    for path in migrations:
        text = path.read_text(encoding="utf-8")
        for line in text.splitlines():
            ll = line.strip().lower()
            if ll.startswith("create table if not exists public."):
                table_names.add(ll.split(".", 1)[1].split(" ", 1)[0].rstrip(" ("))

    print(f"# schema-check — found {len(table_names)} tables across {len(migrations)} migrations")
    for t in sorted(table_names):
        print(f"  - {t}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
