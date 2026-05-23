"""Unit tests for the per-source PDF resolvers.

The resolvers translate an announcement's stored attachment URL (which
for KU is the HTML detail page, not the PDF) into the real download URL
the parse orchestrator can `httpx.get`. These tests run against a real
detail-page HTML fixture captured from `oku.korea.ac.kr` on 2026-05-17.

Network calls are intercepted by ``respx`` — no live HTTP and no live
LLM. The fixtures are checked into the repo so re-runs are stable.
"""

from __future__ import annotations

from pathlib import Path

import httpx
import pytest
import respx

from uni_db.parse.pdf_resolvers import (
    ResolvedPdf,
    get_resolver_for_url,
    resolve_pdf,
)
from uni_db.parse.pdf_resolvers import korea_univ as ku_resolver
from uni_db.parse.pdf_resolvers import yonsei as yonsei_resolver

FIXTURES = Path(__file__).resolve().parent.parent / "fixtures"

KU_DETAIL_URL = (
    "https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do"
    "?MENU_ID=1700&BBS_SEQ=1791&SITE_NO=2&BOARD_SEQ=5"
)

YONSEI_DETAIL_URL = (
    "https://admission.yonsei.ac.kr/seoul/admission/html/international/"
    "noticeView.asp?BBS_NO=3417"
)


def _load_fixture_bytes(name: str) -> bytes:
    path = FIXTURES / name
    if not path.exists():
        pytest.skip(f"fixture missing: {path}")
    return path.read_bytes()


# ---------------------------------------------------------------------------
# Registry / dispatch
# ---------------------------------------------------------------------------


class TestRegistryDispatch:
    def test_get_resolver_picks_korea_univ_by_host(self) -> None:
        assert get_resolver_for_url(KU_DETAIL_URL) is ku_resolver.resolve

    def test_unknown_host_returns_none(self) -> None:
        assert get_resolver_for_url("https://example.com/some/page") is None

    def test_get_resolver_is_case_insensitive_on_host(self) -> None:
        upper_host = KU_DETAIL_URL.replace("oku.korea.ac.kr", "OKU.KOREA.AC.KR")
        assert get_resolver_for_url(upper_host) is ku_resolver.resolve

    def test_get_resolver_picks_yonsei_by_host(self) -> None:
        assert get_resolver_for_url(YONSEI_DETAIL_URL) is yonsei_resolver.resolve


# ---------------------------------------------------------------------------
# Korea University resolver
# ---------------------------------------------------------------------------


class TestKoreaUnivResolver:
    @pytest.fixture
    def detail_html(self) -> bytes:
        return _load_fixture_bytes("korea_univ_detail.html")

    @respx.mock
    async def test_happy_path_resolves_real_pdf_link(self, detail_html: bytes) -> None:
        respx.get(KU_DETAIL_URL).mock(
            return_value=httpx.Response(200, content=detail_html),
        )
        async with httpx.AsyncClient() as client:
            resolved = await ku_resolver.resolve(KU_DETAIL_URL, client, None)

        assert resolved is not None
        assert isinstance(resolved, ResolvedPdf)
        # The fixture's only fileDown anchor is BBS_SEQ=1791, FILE_SEQ=2
        # rendered as "2028학년도_고려대(서울)_입학전형시행계획(2026.04.).pdf".
        assert resolved.url == (
            "https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do"
            "?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1791&FILE_SEQ=2"
        )
        assert resolved.filename.endswith(".pdf")
        assert "입학전형" in resolved.filename
        # Referer header must point at the detail page so the OKU
        # anti-leech check passes.
        assert resolved.headers.get("Referer") == KU_DETAIL_URL

    @respx.mock
    async def test_returns_none_when_html_has_no_filedown_anchor(self) -> None:
        no_file_html = (
            b"<html><body><a href='#;'>no download here</a></body></html>"
        )
        respx.get(KU_DETAIL_URL).mock(
            return_value=httpx.Response(200, content=no_file_html),
        )
        async with httpx.AsyncClient() as client:
            resolved = await ku_resolver.resolve(KU_DETAIL_URL, client, None)
        assert resolved is None

    @respx.mock
    async def test_returns_none_on_http_error(self) -> None:
        respx.get(KU_DETAIL_URL).mock(return_value=httpx.Response(500))
        async with httpx.AsyncClient() as client:
            resolved = await ku_resolver.resolve(KU_DETAIL_URL, client, None)
        assert resolved is None

    @respx.mock
    async def test_top_level_dispatcher_routes_to_ku(self, detail_html: bytes) -> None:
        respx.get(KU_DETAIL_URL).mock(
            return_value=httpx.Response(200, content=detail_html),
        )
        async with httpx.AsyncClient() as client:
            resolved = await resolve_pdf(KU_DETAIL_URL, http_client=client)
        assert resolved is not None
        assert "FileDown.do" in resolved.url
        assert "GBN=X01" in resolved.url


# ---------------------------------------------------------------------------
# Yonsei resolver
# ---------------------------------------------------------------------------


class TestYonseiResolver:
    @pytest.fixture
    def detail_html(self) -> bytes:
        return _load_fixture_bytes("yonsei_detail.html")

    @respx.mock
    async def test_happy_path_resolves_download_asp_url(
        self, detail_html: bytes
    ) -> None:
        # Yonsei's detail pages declare ``text/html; Charset=euc-kr``.
        # Mirror that in the mocked response so the resolver decodes the
        # body exactly as it would live.
        respx.get(YONSEI_DETAIL_URL).mock(
            return_value=httpx.Response(
                200,
                content=detail_html,
                headers={"content-type": "text/html; charset=euc-kr"},
            ),
        )
        async with httpx.AsyncClient() as client:
            resolved = await yonsei_resolver.resolve(
                YONSEI_DETAIL_URL, client, None
            )

        assert resolved is not None
        assert isinstance(resolved, ResolvedPdf)
        # The per-notice attachment on the fixture is a /download.asp URL
        # carrying the EUC-KR url-encoded filename. The resolver must
        # prefer it over the boilerplate www2.yonsei.ac.kr year-plan PDF.
        assert "/seoul/download.asp" in resolved.url
        assert "furl=bbs/" in resolved.url
        # The Referer header must point at the detail page so the
        # anti-leech check passes on the actual download GET.
        assert resolved.headers.get("Referer") == YONSEI_DETAIL_URL

    @respx.mock
    async def test_falls_back_to_year_plan_when_no_per_notice_attachment(
        self,
    ) -> None:
        boilerplate_only = (
            b'<html><body>'
            b'<a href="https://www2.yonsei.ac.kr/entrance/plan/2028_plan.pdf">'
            b'2028 plan</a>'
            b'</body></html>'
        )
        respx.get(YONSEI_DETAIL_URL).mock(
            return_value=httpx.Response(200, content=boilerplate_only),
        )
        async with httpx.AsyncClient() as client:
            resolved = await yonsei_resolver.resolve(
                YONSEI_DETAIL_URL, client, None
            )
        assert resolved is not None
        assert resolved.url.endswith("/2028_plan.pdf")

    @respx.mock
    async def test_returns_none_when_no_pdf_anchor(self) -> None:
        no_pdf_html = b"<html><body><p>text-only notice</p></body></html>"
        respx.get(YONSEI_DETAIL_URL).mock(
            return_value=httpx.Response(200, content=no_pdf_html),
        )
        async with httpx.AsyncClient() as client:
            resolved = await yonsei_resolver.resolve(
                YONSEI_DETAIL_URL, client, None
            )
        assert resolved is None

    @respx.mock
    async def test_returns_none_on_http_error(self) -> None:
        respx.get(YONSEI_DETAIL_URL).mock(return_value=httpx.Response(500))
        async with httpx.AsyncClient() as client:
            resolved = await yonsei_resolver.resolve(
                YONSEI_DETAIL_URL, client, None
            )
        assert resolved is None

    async def test_rejects_non_detail_urls(self) -> None:
        # The list page itself must NOT be resolved — guards against
        # accidental loops if a future change passes a list URL through.
        list_url = (
            "https://admission.yonsei.ac.kr/seoul/admission/html/"
            "international/notice.asp"
        )
        async with httpx.AsyncClient() as client:
            resolved = await yonsei_resolver.resolve(list_url, client, None)
        assert resolved is None


# ---------------------------------------------------------------------------
# ResolvedPdf shape
# ---------------------------------------------------------------------------


class TestResolvedPdfShape:
    def test_resolved_pdf_is_frozen_dataclass(self) -> None:
        resolved = ResolvedPdf(url="https://x/y.pdf", filename="y.pdf")
        with pytest.raises((AttributeError, Exception)):
            resolved.url = "tampered"  # type: ignore[misc]

    def test_resolved_pdf_default_headers_is_empty(self) -> None:
        resolved = ResolvedPdf(url="https://x/y.pdf", filename="y.pdf")
        assert dict(resolved.headers) == {}

    async def test_resolve_pdf_unknown_host_returns_none(self) -> None:
        # An unregistered host must short-circuit to None *without*
        # touching the supplied client. We pass a real client (and close
        # it) so the test stays warning-free under pytest's
        # filterwarnings=error setting.
        async with httpx.AsyncClient() as client:
            resolved = await resolve_pdf(
                "https://no-such-host.example.com/page",
                http_client=client,
            )
        assert resolved is None
