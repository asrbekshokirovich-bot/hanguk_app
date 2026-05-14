"""Inha University — international admissions notice board.

Source: https://admission.inha.ac.kr/cms/FR_CON/index.do?MENU_ID=160
Board:  FR_BBS_CON/BoardView.do — AJAX-rendered list.

The board list is populated via AJAX from FR_BBS_CON/BoardView.do.
Placeholder selectors until a JsonApiAdapter config is written.
"""

from ..html_list_adapter import HtmlListSelectors

INHA_SELECTORS = HtmlListSelectors(
    row="table.board-list tbody tr",
    title="td.title a",
    link="td.title a",
    posted_at="td.date",
    posted_at_format="%Y.%m.%d",
    attachments_in_detail=True,
    external_id_regex=r"(?:nttId|articleNo|seq|bbsSeq|BBS_SEQ)=([0-9]+)",
)
