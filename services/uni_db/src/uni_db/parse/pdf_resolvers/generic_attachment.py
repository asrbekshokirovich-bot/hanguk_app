"""Generic attachment resolver for direct-download notice boards.

Many Korean admission boards render the post detail page with the guideline
PDF as an ordinary download anchor — a direct ``.pdf`` href, or a
``download.php`` / ``fileDown.do`` / ``download.File.asp`` style endpoint.
This resolver fetches the detail page (the announcement's ``url_ko``), finds
the best such attachment, and returns it. It is registered for hosts whose
detail pages follow that pattern (CAU, Kookmin, …); boards that hide the file
behind a JS ``onclick`` handler need a site-specific resolver instead.

Mirror of the KAIST resolver's generic core; kept separate so the per-host
registry can point unrelated universities at one shared implementation.
"""

from __future__ import annotations

import logging
from typing import Final
from urllib.parse import urljoin, urlsplit

import httpx
from bs4 import BeautifulSoup

from . import ResolvedPdf

log = logging.getLogger(__name__)

_HTTP_TIMEOUT_SEC: Final[float] = 30.0
_DOWNLOAD_HINTS: Final[tuple[str, ...]] = (
    "download", "filedown", "file_down", "file/down", "filedownload",
    "attach", "fileid", "/file", "down.asp", "down.do",
)
_GUIDE_HINTS: Final[tuple[str, ...]] = (
    "guide", "admission", "모집요강", "요강", "전형", "모집", "안내",
)


def _is_pdf_href(href: str) -> bool:
    return urlsplit(href).path.lower().endswith(".pdf")


def _looks_like_download(href: str) -> bool:
    low = href.lower()
    return any(hint in low for hint in _DOWNLOAD_HINTS)


def _score(text: str, href: str) -> int:
    blob = f"{text} {href}".lower()
    return sum(1 for hint in _GUIDE_HINTS if hint in blob)


def _extract_pdf_link(html: str, base_url: str) -> tuple[str, str] | None:
    soup = BeautifulSoup(html, "lxml")
    candidates: list[tuple[int, str, str]] = []
    for anchor in soup.find_all("a"):
        href = (anchor.get("href") or "").strip()
        if not href or href.startswith("#") or href.lower().startswith("javascript:"):
            continue
        text = anchor.get_text(strip=True)
        names_pdf = ".pdf" in text.lower()
        if not (_is_pdf_href(href) or (_looks_like_download(href) and names_pdf)):
            continue
        absolute = urljoin(base_url, href)
        filename = text if names_pdf else (urlsplit(absolute).path.rsplit("/", 1)[-1] or text)
        candidates.append((_score(filename, absolute), absolute, filename or "attachment.pdf"))
    if not candidates:
        return None
    candidates.sort(key=lambda c: c[0], reverse=True)
    _, absolute, filename = candidates[0]
    return absolute, filename


async def resolve(
    attachment_url: str,
    http_client: httpx.AsyncClient,
    referer: str | None = None,
) -> ResolvedPdf | None:
    """Resolve a detail-page URL to its best attached PDF/download link."""
    del referer
    log.info("generic_attachment: resolving %s", attachment_url[:140])
    try:
        resp = await http_client.get(attachment_url, timeout=_HTTP_TIMEOUT_SEC)
    except httpx.HTTPError as exc:
        log.warning("generic_attachment: detail fetch failed: %s", exc)
        return None
    if resp.status_code != 200:
        log.warning("generic_attachment: HTTP %s for %s", resp.status_code, attachment_url[:120])
        return None
    found = _extract_pdf_link(resp.text, attachment_url)
    if found is None:
        log.info("generic_attachment: no attachment link on detail page")
        return None
    download_url, filename = found
    return ResolvedPdf(url=download_url, filename=filename, headers={"Referer": attachment_url})
