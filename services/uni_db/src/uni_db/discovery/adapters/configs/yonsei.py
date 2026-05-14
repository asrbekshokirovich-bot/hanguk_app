"""Yonsei University — international admissions notice board.

Source (Seoul):  https://admission.yonsei.ac.kr/
Source (Mirae):  https://admission.yonsei.ac.kr/mirae

Both Yonsei sites render via client-side JavaScript (meta-refresh to
/seoul/admission/html/main/main.asp which then uses JS routing). A static
httpx request returns an empty body.  These sources require a Playwright-based
adapter to render the JS before scraping.

Status: PENDING Playwright adapter (Phase 4 infrastructure).
Until then, the selectors below are placeholders and the adapter factory
raises NotImplementedError so the orchestrator can skip gracefully.
"""

from __future__ import annotations

from ..html_list_adapter import HtmlListSelectors

# Placeholder — actual selectors cannot be determined without JS execution.
# Will be replaced once Playwright adapter is implemented.
YONSEI_SELECTORS = HtmlListSelectors(
    row="table.board-list tbody tr",
    title="td.title a",
    link="td.title a",
    posted_at="td.date",
    posted_at_format="%Y.%m.%d",
    attachments_in_detail=True,
    external_id_regex=r"(?:nttId|articleNo|seq|bbsSeq|idx)=([0-9]+)",
)

YONSEI_MIRAE_SELECTORS = YONSEI_SELECTORS
