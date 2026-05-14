"""Adiga (어디가) upstream adapter — KCUE admissions calendar.

Adiga (https://www.adiga.kr/) is the Ministry of Education's official
admissions information portal, operated by KCUE (한국대학교육협의회).
It publishes a unified admissions calendar and recruitment-unit registry
covering ~330 4-year universities and 130+ junior colleges.

Public touchpoints:
* Web UI: https://www.adiga.kr/PageLinkSiteView.do?menuId=PG-WEB-...
* KCUE OpenAPI: published on data.go.kr under "한국대학교육협의회_..."
  datasets. Requires DATA_GO_KR_APP_KEY (NOT a separate Adiga key).
* CSV/XLSX direct downloads: linked from the Adiga "자료실" page.

This module provides the CSV/XLSX direct-download path for the calendar
materialized view (BUILD_PLAN §N.1). For the OpenAPI integration, see
upstream/data_go_kr.py and configure with the KCUE dataset endpoint.

NB: ADIGA_APP_KEY in .env is presently unused. Keep it set for the
future when KCUE exposes a partner-only Adiga REST endpoint (per their
2026 roadmap).
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime

import httpx

from ..config import settings

log = logging.getLogger(__name__)


# Adiga publishes the admissions calendar CSV at a stable URL each year;
# the path includes the academic year. Update annually.
ADIGA_CALENDAR_CSV_URL = (
    "https://www.adiga.kr/files/admission_calendar_{academic_year}.csv"
)


@dataclass(frozen=True, slots=True)
class AdigaCalendarRow:
    institution_name_ko: str
    track: str            # "수시" / "정시" / "재외국민" / "외국인"
    event_name_ko: str    # "원서접수 시작" / "합격자 발표" 등
    event_at: datetime
    source_blob_hash: str


async def fetch_calendar_csv(
    academic_year: int,
    *,
    http_client: httpx.AsyncClient,
) -> str:
    """Download the raw Adiga calendar CSV for an academic year.

    Returns the decoded CSV text (EUC-KR or UTF-8 — both are handled).
    Caller is responsible for parsing into AdigaCalendarRow objects.
    """
    url = ADIGA_CALENDAR_CSV_URL.format(academic_year=academic_year)
    log.info("adiga: fetching calendar CSV for %d from %s", academic_year, url)
    resp = await http_client.get(url, timeout=settings.http_request_timeout_sec)
    resp.raise_for_status()

    # Try UTF-8 first, fall back to EUC-KR which KCUE legacy exports use.
    for enc in ("utf-8", "euc-kr"):
        try:
            return resp.content.decode(enc)
        except UnicodeDecodeError:
            continue
    raise RuntimeError(f"adiga calendar CSV: could not decode as utf-8 or euc-kr ({len(resp.content)} bytes)")
