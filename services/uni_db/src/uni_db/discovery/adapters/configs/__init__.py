"""Per-university adapter configuration registry.

``ADAPTER_REGISTRY`` maps a canonical ``announcement_sources.url_ko`` value
to a factory callable with signature::

    factory(source_id, institution_id, source_url_ko, http_client) -> SourceAdapter

Sources marked ``# JS-only`` need Playwright; their factories return an
``HtmlListAdapter`` with placeholder selectors that will yield 0 rows on a
live fetch (graceful no-op rather than a crash).

Sources marked ``# JSON API`` call a REST endpoint instead of scraping HTML.
"""

from __future__ import annotations

import httpx
from uuid import UUID

from ..html_list_adapter import HtmlListAdapter, HtmlListSelectors
from .snu import SNU_SELECTORS
from .yonsei import (
    YONSEI_SELECTORS,
    YONSEI_MIRAE_SELECTORS,
    make_yonsei_adapter,
    make_yonsei_mirae_adapter,
)
from .korea_univ import make_korea_univ_adapter
from .kaist import make_kaist_adapter
from .konkuk import KONKUK_SELECTORS
from .inha import INHA_SELECTORS
from .cbnu import CBNU_SELECTORS, make_cbnu_adapter
from .jbnu import JBNU_SELECTORS, make_jbnu_adapter
from .kangwon import KANGWON_SELECTORS
from .jeju import JEJU_SELECTORS
from .skku import SKKU_SELECTORS, make_skku_adapter


def _html(selectors: HtmlListSelectors):
    def factory(
        source_id: UUID,
        institution_id: UUID | None,
        source_url_ko: str,
        http_client: httpx.AsyncClient,
    ) -> SourceAdapter:
        return HtmlListAdapter(
            source_id=source_id,
            source_url_ko=source_url_ko,
            selectors=selectors,
            institution_id=institution_id,
            http_client=http_client,
        )
    return factory


# ── Static HTML ──────────────────────────────────────────────────────────────
# ── JSON API ─────────────────────────────────────────────────────────────────
# ── JS-only (placeholder selectors, yields 0 rows until Playwright adapter) ─

ADAPTER_REGISTRY: dict[str, object] = {
    # Static HTML — fully working
    "https://admission.snu.ac.kr/international/notice": _html(SNU_SELECTORS),

    # JSON API — fully working
    "https://oku.korea.ac.kr/oku/cms/FR_CON/index.do?MENU_ID=700": make_korea_univ_adapter,
    "https://admission.kaist.ac.kr/intl-undergraduate/notice":      make_kaist_adapter,

    # Playwright-rendered (JS-only sites)
    "https://admission.yonsei.ac.kr/seoul/admission/html/international/notice.asp": make_yonsei_adapter,
    "https://admission.yonsei.ac.kr/wonju/admission/html/international/notice.asp": make_yonsei_mirae_adapter,
    "https://admission.skku.edu/admission/html/abroad/notice.html":                 make_skku_adapter,
    "https://enter.jbnu.ac.kr/submenu.do?menuurl=rOjsbGuR5i0fqsax24xcPQ%3D%3D&":    make_jbnu_adapter,

    # Static HTML — egovframework boards
    "https://ipsi.chungbuk.ac.kr/kor/bbs/BBSMSTR_000000000017/lst.do":               make_cbnu_adapter,

    # JS-only — placeholder until Playwright config is written
    "https://admission.yonsei.ac.kr/":                   _html(YONSEI_SELECTORS),
    "https://admission.yonsei.ac.kr/mirae":               _html(YONSEI_MIRAE_SELECTORS),
    "https://enter.konkuk.ac.kr/":                        _html(KONKUK_SELECTORS),
    "https://admission.inha.ac.kr/cms/FR_CON/index.do?MENU_ID=160": _html(INHA_SELECTORS),
    "https://ipsi.chungbuk.ac.kr/":                       _html(CBNU_SELECTORS),
    "https://enter.jbnu.ac.kr/":                          _html(JBNU_SELECTORS),
    "https://admission.kangwon.ac.kr/":                   _html(KANGWON_SELECTORS),
    "https://ipsi.jejunu.ac.kr/":                         _html(JEJU_SELECTORS),
}
