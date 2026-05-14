"""Kangwon National University — international admissions notice board.

Source: https://admission.kangwon.ac.kr/
Status: JS-rendered SPA.  Placeholder selectors.
"""

from ..html_list_adapter import HtmlListSelectors

KANGWON_SELECTORS = HtmlListSelectors(
    row="table.board tbody tr",
    title="td.subject a",
    link="td.subject a",
    posted_at="td.date",
    posted_at_format="%Y.%m.%d",
    attachments_in_detail=True,
    external_id_regex=r"(?:nttId|articleNo|seq|no)=([0-9]+)",
)
