"""Archetype classifier + dispatcher.

Audit §5.2 / Plan §F.1. Eight structural patterns:

  A — SNU flagship (80–120 pages, deep applicant-category sections)
  B — Top Seoul private brochure-style (Yonsei/Korea/SKKU/Hanyang)
  C — Regional national plain table (PNU/KNU/CNU…)
  D — Faith-affiliated / mid-private (Sogang/Dongguk/…)
  E — Women's university (Ewha/Sookmyung/…)
  F — Specialized art/music/PE (K-Arts/KNUSA/…)
  G — STEM specialized (KAIST/UNIST/POSTECH-grad)
  H — 전문대 minimal

Phase 0 ships a deterministic header-keyword classifier + a stub for the
LLM (Claude Haiku) tiebreaker. Real archetype-specific extractors are
Phase 1+.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from typing import Literal

log = logging.getLogger(__name__)

ArchetypeLabel = Literal["A", "B", "C", "D", "E", "F", "G", "H"]


@dataclass(frozen=True, slots=True)
class ArchetypeFingerprint:
    label: ArchetypeLabel
    confidence: float
    rationale: str


# Per-archetype heuristic anchors (audit §5.2 fingerprints). The matcher
# scans the first ~3 pages of extracted text.
_ARCHETYPE_HINTS: dict[ArchetypeLabel, tuple[str, ...]] = {
    "A": ("서울대학교", "KAIST", "POSTECH", "외국인전형 신입학"),
    "B": ("연세대학교", "고려대학교", "성균관대학교", "한양대학교", "단과대학"),
    "C": ("경북대학교", "부산대학교", "전남대학교", "충남대학교", "거점국립대"),
    "D": ("서강대학교", "동국대학교", "원광대학교", "선교", "사명"),
    "E": ("이화여자대학교", "숙명여자대학교", "여자대학교", "여학생만"),
    "F": ("실기고사", "audition", "음악", "미술", "체육"),
    "G": ("UNIST", "GIST", "DGIST", "약간명", "소수정원", "english-medium"),
    "H": ("전문대학", "전문대", "2년제", "3년제"),
}


def classify_archetype(first_pages_text: str) -> ArchetypeFingerprint:
    """Best-effort header-text classifier.

    Returns the highest-scoring archetype label plus the matched terms.
    Tied/empty inputs default to 'B' (top private brochure) since that is
    the most common shape in the priority list.
    """
    text = first_pages_text or ""
    scores: dict[ArchetypeLabel, int] = {}
    for label, hints in _ARCHETYPE_HINTS.items():
        scores[label] = sum(1 for h in hints if h in text)
    best_label, best_score = max(scores.items(), key=lambda kv: kv[1])
    if best_score == 0:
        return ArchetypeFingerprint(
            label="B",
            confidence=0.40,
            rationale="no archetype hints matched; defaulting to B",
        )
    confidence = min(0.95, 0.55 + 0.10 * best_score)
    return ArchetypeFingerprint(
        label=best_label,
        confidence=confidence,
        rationale=f"matched {best_score} hint(s) for archetype {best_label}",
    )


# Section-anchor regex shared across archetypes A–E; F–H override.
SECTION_ANCHORS: dict[str, re.Pattern[str]] = {
    "calendar":           re.compile(r"(전형\s*일정|모집\s*일정|주요\s*일정|입학\s*일정)"),
    "tuition":            re.compile(r"(등록금|학기별\s*등록금|입학금)"),
    "scholarships":       re.compile(r"(장학금|장학\s*제도|국가장학금)"),
    "requirements":       re.compile(r"(지원\s*자격|지원자격|TOPIK|한국어\s*능력)"),
    "documents_required": re.compile(r"(제출\s*서류|구비\s*서류|첨부\s*서류)"),
}


def find_section_offsets(text: str) -> dict[str, int]:
    """Return character offsets where each canonical section starts.

    Used by the per-archetype extractors as input slices to the LLM call.
    """
    out: dict[str, int] = {}
    for section, pattern in SECTION_ANCHORS.items():
        m = pattern.search(text)
        if m:
            out[section] = m.start()
    return out
