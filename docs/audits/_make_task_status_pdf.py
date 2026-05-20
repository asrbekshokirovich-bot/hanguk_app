"""Generate UNI_DB_TASK_STATUS_2026-05-17.pdf — short, plain-language status of every uni-db phase."""

from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
)

OUT = Path(__file__).with_name("UNI_DB_TASK_STATUS_2026-05-17.pdf")

# ---------- styles ----------
styles = getSampleStyleSheet()
H1 = ParagraphStyle("H1", parent=styles["Heading1"], fontSize=18, spaceAfter=4, textColor=colors.HexColor("#111111"))
SUB = ParagraphStyle("SUB", parent=styles["Normal"], fontSize=10, textColor=colors.HexColor("#666666"), spaceAfter=14)
H2 = ParagraphStyle("H2", parent=styles["Heading2"], fontSize=12, spaceBefore=10, spaceAfter=4, textColor=colors.HexColor("#1f4e79"))
LEGEND = ParagraphStyle("LEGEND", parent=styles["Normal"], fontSize=9, textColor=colors.HexColor("#444444"), spaceAfter=10)
NOTE = ParagraphStyle("NOTE", parent=styles["Italic"], fontSize=9, textColor=colors.HexColor("#666666"), spaceBefore=6)

# Status tokens — plain ASCII so no Unicode-glyph-box problem
DONE = "DONE"
WIP  = "WIP "
TODO = "TODO"

STATUS_COLOR = {
    DONE: colors.HexColor("#0a7c2f"),   # green
    WIP:  colors.HexColor("#b8860b"),   # amber
    TODO: colors.HexColor("#a92020"),   # red
}

# ---------- content (short, simple language) ----------
PHASES = [
    ("Phase 0 — Foundation (May 7)", [
        (DONE, "Build Python service skeleton"),
        (DONE, "First test suite passes"),
        (DONE, "Static analyzer clean"),
    ]),
    ("Phase 1 — Flip-ready (May 8)", [
        (DONE, "Add flip-ready scaffolding"),
        (DONE, "Fix 6 bugs from first real test run"),
        (DONE, "Deploy to staging Supabase + smoke test"),
    ]),
    ("Phase 2 — Live Anthropic (May 8 to 10)", [
        (DONE, "Add Anthropic API gate (UNI_DB_LIVE_APIS flag)"),
        (DONE, "Wire live extraction call to Claude"),
        (DONE, "Use real prod schema, drop staging shim"),
    ]),
    ("Phase 3 — Infra + Cutover (May 10 to 11)", [
        (DONE, "Hetzner VPS runbook"),
        (DONE, "Phase 3 design doc + reviewer onboarding"),
        (DONE, "Cut app over to new 'institutions' table"),
        (DONE, "Drop legacy 'universities' table (697 test rows)"),
    ]),
    ("Phase P1-P3 — First 3 adapters (May 14)", [
        (DONE, "SNU adapter (10 announcements live)"),
        (DONE, "Korea Univ adapter (9 live)"),
        (DONE, "KAIST adapter (10 live)"),
        (DONE, "Discovery script + systemd timer"),
    ]),
    ("Phase P4 Track 1 — Parse pipeline (May 14)", [
        (DONE, "KAIST PDF -> Claude -> Supabase end-to-end"),
        (DONE, "Route failures to human-review queue"),
    ]),
    ("Phase P4 Track 2 — Playwright (May 14)", [
        (DONE, "Playwright adapter for JS-only sites"),
        (DONE, "Yonsei live (4 announcements)"),
    ]),
    ("Phase P4 Track 3 — Upstream skeletons (May 14)", [
        (DONE, "data.go.kr adapter — key in .env, KCUE BasicInformationService verified live"),
        (DONE, "Adiga adapter — scheduleAjax.do integration; 27 events backfilled to staging"),
    ]),
    ("Phase P5 — Adiga calendar integration (May 17)", [
        (DONE, "Adiga URL discovery (real endpoint: /uct/cas/scheduleAjax.do)"),
        (DONE, "adiga.py rewrite: CSRF-scrape + HTML-embedded JSON parsing"),
        (DONE, "adiga_calendar_events table migration applied to staging"),
        (DONE, "Worker CLI: --year, --ingest, --dry-run flags"),
        (DONE, "Backfill cal-year 2026: 27 events (14 수시 + 13 정시)"),
        (DONE, "Idempotency verified (27 → 27 on re-run)"),
        (WIP,  "Systemd timer install on Hetzner (files written, needs SSH)"),
    ]),
    ("Phase P4 Track 4 — Translations (May 14)", [
        (DONE, "Vietnamese translations live"),
        (DONE, "Mongolian translations live"),
        (DONE, "Glossary placeholder bug fixed"),
    ]),
    ("Phase P4 A+B — Schema + LLM fixes (May 15)", [
        (DONE, "Relax 5 JSON schemas (additionalProperties: True)"),
        (DONE, "Widen calendar event_type enum (13 -> 19)"),
        (DONE, "LLM timeout 30s -> 120s, retries 4 -> 2"),
        (DONE, "Fix .env pydantic crash (inline # comments)"),
        (DONE, "KAIST 'requirements' hallucination fix (rows-array schema + new prompt, live 3/3 on staging)"),
    ]),
    ("Phase P4 C+D — Translate at scale (May 15)", [
        (DONE, "3 KAIST PDFs fully parsed"),
        (DONE, "273 announcement-title translations"),
    ]),
    ("Phase P4 — 7 more universities (May 15)", [
        (DONE, "CBNU live (11)"),
        (DONE, "JBNU live (7)"),
        (DONE, "SKKU live (3)"),
        (DONE, "Inha live (15)"),
        (DONE, "Kangwon live (10)"),
        (DONE, "Jeju live (10)"),
        (DONE, "Hanyang live (2)"),
    ]),
    ("Phase P4 E — Konkuk (May 15)", [
        (DONE, "Konkuk live (6 announcements)"),
        (DONE, "12 live sources total, ~97 announcements"),
    ]),
    ("Phase P6 — KAIST requirements hallucination fix (May 17)", [
        (DONE, "Recon: identified 3 distinct failure modes from staging extraction_jobs"),
        (DONE, "Schema rewrite: REQUIREMENTS_SCHEMA -> {rows: [...]} with closed english_test"),
        (DONE, "Prompt rewrite: 3 few-shots (single-cat / multi-cat / empty); no-fence rule"),
        (DONE, "Prompt-file consolidation: requirements.md = basic_requirements.md (dead-code cleanup)"),
        (DONE, "Live re-parse 3 KAIST PDFs: 3/3 schema-clean, $0.093 Anthropic spend"),
        (DONE, "Unit tests still pass (191/191)"),
    ]),
]

OUTSTANDING = [
    # critical
    (TODO, "CRITICAL: rotate the leaked Gmail password (in transcript 3ae39a73)"),
    (TODO, "CRITICAL: push branch claude/store-readiness-p0-p1 (31 unpushed commits)"),
    (TODO, "HIGH: decide fate of uncommitted 'drop Papago' rework in jovial-wiles worktree"),
    (TODO, "HIGH: commit untracked migration 20260512124000_enable_rls_audit_v2.sql"),
    # medium
    (TODO, "Wire non-KAIST PDF download chain (10 of 12 sources have 0 parsed PDFs)"),
    (TODO, "Implement EasyOCR (ADR-002 chose it; no code yet)"),
    (TODO, "Apply for data.go.kr 모집요강 + 교육부_고등교육기관 datasets (if scope expands)"),
    (TODO, "Install Adiga systemd timer on Hetzner (one-time SSH session)"),
    (TODO, "Widen review_queue.reason CHECK constraint (debt from commit 616771d)"),
    (TODO, "Resolve youthful-shannon-0b1dc4 branch (21 ahead, deletes uni-db)"),
    # housekeeping
    (TODO, "Delete dead ADAPTER_REGISTRY placeholder entries"),
    (TODO, "Delete deprecated services/uni_db/src/uni_db/storage/r2.py"),
    (TODO, "Update stale services/uni_db/README.md"),
    (TODO, "Author project CLAUDE.md (none exists in Hanguk/)"),
    (TODO, "Delete 8 merge-dead claude/* branches"),
]


# ---------- table builder ----------
def status_table(rows):
    """rows = [(status, text), ...]"""
    data = []
    for status, text in rows:
        data.append([
            Paragraph(f'<font color="{STATUS_COLOR[status].hexval()}"><b>{status}</b></font>', styles["Normal"]),
            Paragraph(text, styles["Normal"]),
        ])
    tbl = Table(data, colWidths=[18*mm, 152*mm])
    tbl.setStyle(TableStyle([
        ("VALIGN",   (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING",  (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING",   (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 3),
        ("LINEBELOW",    (0, 0), (-1, -2), 0.25, colors.HexColor("#eeeeee")),
    ]))
    return tbl


def summary_table():
    total = sum(len(items) for _, items in PHASES) + len(OUTSTANDING)
    done = sum(1 for _, items in PHASES for s, _ in items if s == DONE)
    wip  = sum(1 for _, items in PHASES for s, _ in items if s == WIP) + sum(1 for s, _ in OUTSTANDING if s == WIP)
    todo = sum(1 for s, _ in OUTSTANDING if s == TODO)
    data = [
        ["Status", "Count"],
        [Paragraph(f'<font color="{STATUS_COLOR[DONE].hexval()}"><b>Completed</b></font>', styles["Normal"]), str(done)],
        [Paragraph(f'<font color="{STATUS_COLOR[WIP].hexval()}"><b>In progress / partial</b></font>', styles["Normal"]), str(wip)],
        [Paragraph(f'<font color="{STATUS_COLOR[TODO].hexval()}"><b>Not started</b></font>', styles["Normal"]), str(todo)],
        ["Total tasks tracked", str(total)],
    ]
    tbl = Table(data, colWidths=[80*mm, 25*mm])
    tbl.setStyle(TableStyle([
        ("BACKGROUND",  (0, 0), (-1, 0), colors.HexColor("#1f4e79")),
        ("TEXTCOLOR",   (0, 0), (-1, 0), colors.whitesmoke),
        ("FONTNAME",    (0, 0), (-1, 0), "Helvetica-Bold"),
        ("VALIGN",      (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN",       (1, 0), (1, -1), "RIGHT"),
        ("GRID",        (0, 0), (-1, -1), 0.25, colors.HexColor("#cccccc")),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING",(0, 0), (-1, -1), 6),
        ("TOPPADDING",  (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 5),
    ]))
    return tbl


# ---------- assemble ----------
def build():
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=18*mm, rightMargin=18*mm,
        topMargin=15*mm,  bottomMargin=15*mm,
        title="Hanguk Uni-DB — Task Status by Phase",
        author="Audit run 2026-05-17",
    )
    story = []

    story.append(Paragraph("Hanguk Uni-DB — Task Status by Phase", H1))
    story.append(Paragraph("Snapshot 2026-05-17 &nbsp;|&nbsp; Branch: claude/store-readiness-p0-p1", SUB))

    story.append(Paragraph("Legend", H2))
    story.append(Paragraph(
        f'<font color="{STATUS_COLOR[DONE].hexval()}"><b>DONE</b></font> = finished and committed &nbsp; '
        f'<font color="{STATUS_COLOR[WIP].hexval()}"><b>WIP</b></font> = started, not finished &nbsp; '
        f'<font color="{STATUS_COLOR[TODO].hexval()}"><b>TODO</b></font> = not started',
        LEGEND
    ))

    story.append(Paragraph("Summary", H2))
    story.append(summary_table())
    story.append(Spacer(1, 6))

    for title, items in PHASES:
        story.append(Paragraph(title, H2))
        story.append(status_table(items))

    story.append(Spacer(1, 4))
    story.append(Paragraph("Outstanding work (not started)", H2))
    story.append(status_table(OUTSTANDING))

    story.append(Paragraph(
        "Full detail in docs/audits/UNIVERSITY_DB_CHANGE_AUDIT_2026-05-17.md",
        NOTE
    ))

    doc.build(story)
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    build()
