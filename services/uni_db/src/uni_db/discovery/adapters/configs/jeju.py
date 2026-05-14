"""Jeju National University — international admissions notice board.

Source: https://ipsi.jejunu.ac.kr/
Status: DNS resolution failed during 2026-05-14 probe. May be temporarily
offline or domain changed.  Placeholder selectors (eGov BBS pattern).
"""

from ..html_list_adapter import HtmlListSelectors

JEJU_SELECTORS = HtmlListSelectors(
    row="table.board-list tbody tr",
    title="td.td-subject a",
    link="td.td-subject a",
    posted_at="td.td-date",
    posted_at_format="%Y.%m.%d",
    attachments_in_detail=True,
    external_id_regex=r"(?:nttId|articleNo|bbsArticleNo)=([0-9]+)",
)
