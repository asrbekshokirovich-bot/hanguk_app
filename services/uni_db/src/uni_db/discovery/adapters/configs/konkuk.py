"""Konkuk University — international admissions notice board.

Source: https://enter.konkuk.ac.kr/
Status: JS-rendered SPA — static HTML returns no notice rows.
Placeholder selectors. Needs Playwright adapter (Phase 4).
"""

from ..html_list_adapter import HtmlListSelectors

KONKUK_SELECTORS = HtmlListSelectors(
    row="table.board tbody tr",
    title="td.subject a",
    link="td.subject a",
    posted_at="td.date",
    posted_at_format="%Y.%m.%d",
    attachments_in_detail=True,
    external_id_regex=r"(?:nttId|articleNo|seq|bbsSeq|idx|no)=([0-9]+)",
)
