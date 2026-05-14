"""Glossary-aware lookup that bypasses MT.

Plan §P.3: institution names and 외국인전형-class official terms must
never be machine-translated naively. They live in `term_glossary` with
authoritative=true and we look them up before any LLM/Papago/DeepL call.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Mapping

from .models import TargetLang


@dataclass(frozen=True, slots=True)
class GlossaryHit:
    term_ko: str
    term_value: str
    category: str


# In-process cache populated from the term_glossary table at worker startup.
# Tests pass a dict directly so they don't need a DB.
GlossaryCache = Mapping[tuple[str, TargetLang], GlossaryHit]


def lookup(
    cache: GlossaryCache,
    *,
    term_ko: str,
    target_lang: TargetLang,
) -> GlossaryHit | None:
    return cache.get((term_ko, target_lang))


def apply_glossary_pre_translate(
    text: str,
    *,
    cache: GlossaryCache,
    target_lang: TargetLang,
) -> tuple[str, list[GlossaryHit]]:
    """Return (text_with_terms_pinned, hits).

    Strategy: longest-match first to avoid '서울대' eclipsing '서울대학교'.
    For each pinned term we substitute a placeholder `⟪G:N⟫` so the
    downstream MT call doesn't touch it; the placeholder map is returned
    so callers can re-substitute the authoritative target after MT.
    """
    candidates = sorted(
        ((k, v) for (k, lang), v in cache.items() if lang == target_lang),
        key=lambda kv: len(kv[0]),
        reverse=True,
    )
    hits: list[GlossaryHit] = []
    out = text
    for term_ko, hit in candidates:
        if term_ko in out:
            # Use the post-translate index (== len(hits) at point of match)
            # so apply_glossary_post_translate's enumerate(hits) lines up.
            out = out.replace(term_ko, f"⟪G:{len(hits)}⟫")
            hits.append(hit)
    return out, hits


def apply_glossary_post_translate(
    text: str,
    hits: list[GlossaryHit],
) -> str:
    out = text
    for index, hit in enumerate(hits):
        out = out.replace(f"⟪G:{index}⟫", hit.term_value)
    return out
