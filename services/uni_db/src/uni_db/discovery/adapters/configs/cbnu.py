"""Chungbuk National University (CBNU) — international admissions notice board.

Source: https://ipsi.chungbuk.ac.kr/
Board:  /kor/bbs/BBSMSTR_000000000001/lst.do (standard eGov BBS)

The site uses the standard Korean eGov BBS framework.  The list page
appears to be AJAX-rendered (0 tables on the main page).
Placeholder selectors for the eGov BBS shape once a static URL is confirmed.
"""

from ..html_list_adapter import HtmlListSelectors

CBNU_SELECTORS = HtmlListSelectors(
    row="table.board-list tbody tr",
    title="td.td-subject a",
    link="td.td-subject a",
    posted_at="td.td-date",
    posted_at_format="%Y.%m.%d",
    attachments_in_detail=True,
    external_id_regex=r"(?:nttId|articleNo|bbsArticleNo)=([0-9]+)",
)
