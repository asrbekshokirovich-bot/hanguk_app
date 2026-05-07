"""Korean keyword vocabulary for admission-relevant content classification.

Sources:
  - Audit §6.3 (Korean signal terms)
  - Plan §P.1 (Korean-first principle)
  - Audit §6.6 (classifier hard rules)

Used by:
  - discovery/classifier.py — title and attachment-filename matching
  - extraction/archetype/* — header detection
  - translate/glossary.py — term-glossary lookup primer
"""

from __future__ import annotations

# ---------------------------------------------------------------------------
# Primary admission vocabulary — the 16 anchor terms from audit §6.3.
# A post matching any of these is a strong admission signal.
# ---------------------------------------------------------------------------
PRIMARY_KEYWORDS_KO: tuple[str, ...] = (
    "모집요강",       # admission guidelines
    "수시모집",       # early admission cycle (susi)
    "정시모집",       # regular admission cycle (jeongsi)
    "외국인전형",     # foreign-applicant track
    "외국인특별전형", # foreign special admission (no-space)
    "외국인 특별전형",# foreign special admission (with space variant)
    "재외국민",       # overseas Korean
    "재외국민특별전형",
    "편입학",         # transfer
    "신·편입학",      # new + transfer
    "대학원 모집",    # graduate recruitment
    "정정공고",       # CORRECTION NOTICE — highest priority
    "변경공고",       # amendment notice
    "일정변경",       # schedule change
    "추가모집",       # additional recruitment
    "충원합격",       # waitlist replacement
    "합격자발표",     # results announcement
    "원서접수",       # application receipt
)

# ---------------------------------------------------------------------------
# Critical correction-notice tokens — detected separately because a title
# diff acquiring any of these forces priority=1 in review_queue
# (audit §6.5, plan §F.6).
# ---------------------------------------------------------------------------
CORRECTION_KEYWORDS_KO: tuple[str, ...] = (
    "정정공고",
    "정정",
    "변경공고",
    "변경",
    "일정변경",
    "수정",
)

# ---------------------------------------------------------------------------
# English equivalents on bilingual sites — kept for filename heuristics
# only. Per §P-1 we never crawl /eng/ pages, but English-named PDF files
# like `2026-Spring-Foreign-Applicants.pdf` show up on KO boards.
# ---------------------------------------------------------------------------
PRIMARY_KEYWORDS_EN: tuple[str, ...] = (
    "admission guide",
    "admission guidelines",
    "international student admission",
    "foreign applicant",
    "special admission",
    "overseas korean",
    "transfer admission",
    "application period",
    "online application",
    "recruitment",
    "notice of correction",
    "result announcement",
    "successful applicants",
)

# ---------------------------------------------------------------------------
# File-extension allowlist for "this is the actual guideline document".
# Audit §5.1: 95% PDF, some HWP/HWPX. Ignore everything else.
# ---------------------------------------------------------------------------
GUIDELINE_FILE_EXTENSIONS: frozenset[str] = frozenset(
    {".pdf", ".hwp", ".hwpx", ".docx"}
)

# ---------------------------------------------------------------------------
# Domain allowlist — discovery never ingests Naver Cafe / blog mirrors.
# ---------------------------------------------------------------------------
ALLOWED_DOMAIN_SUFFIXES: tuple[str, ...] = (".ac.kr", ".go.kr")

# ---------------------------------------------------------------------------
# URL path segments that mark a page as English-side and out-of-scope (§P-1).
# ---------------------------------------------------------------------------
ENGLISH_PATH_SEGMENTS: tuple[str, ...] = ("/eng/", "/en/", "/english/")


def matches_admission_signal(title: str, attachments_filenames: list[str]) -> bool:
    """Audit §6.6 hard rule:
        title contains any-of(PRIMARY_KEYWORDS_KO)
        AND
        at least one attachment filename ends with a guideline extension
            OR contains any-of(PRIMARY_KEYWORDS_KO).
    """
    title_l = title.lower()
    title_hit = any(kw in title for kw in PRIMARY_KEYWORDS_KO) or any(
        kw in title_l for kw in PRIMARY_KEYWORDS_EN
    )
    if not title_hit:
        return False
    for fname in attachments_filenames:
        fname_lower = fname.lower()
        if any(fname_lower.endswith(ext) for ext in GUIDELINE_FILE_EXTENSIONS):
            return True
        if any(kw in fname for kw in PRIMARY_KEYWORDS_KO):
            return True
    return False


def is_correction_notice(title: str) -> bool:
    """Critical: priority-1 routing per audit §6.5."""
    return any(kw in title for kw in CORRECTION_KEYWORDS_KO)


def is_disallowed_url(url: str) -> bool:
    """Reject Naver/Daum mirrors and English mirror paths (§P-1)."""
    url_l = url.lower()
    if any(seg in url_l for seg in ENGLISH_PATH_SEGMENTS):
        return True
    host = url_l.split("/")[2] if "//" in url_l else url_l
    return not any(host.endswith(suffix) for suffix in ALLOWED_DOMAIN_SUFFIXES)
