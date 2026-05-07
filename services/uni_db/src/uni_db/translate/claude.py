"""Claude Sonnet translation adapter.

Plan §P.3 — primary for prose, primary for ko↔en pivot legs to languages
that lack direct ko providers (uz, mn).

Phase 0: live call site disabled; returns deterministic mock output.
"""

from __future__ import annotations

import logging

from ..config import settings
from .models import TargetLang, TranslationOutput

log = logging.getLogger(__name__)


def translate(
    *,
    source_text_ko: str,
    target_lang: TargetLang,
    pivot: TargetLang | None = None,
) -> TranslationOutput:
    """Phase 0 stub: returns a [LANG] prefix + the original text so the
    pipeline can be exercised without paying for tokens."""
    if not settings.live_apis:
        prefix = f"[claude-mock {target_lang}]"
        if pivot:
            prefix = f"[claude-mock ko→{pivot}→{target_lang}]"
        return TranslationOutput(
            text_value=f"{prefix} {source_text_ko}".strip(),
            provider="claude",
            confidence=0.55 if pivot else 0.85,
            via_pivot=pivot is not None,
        )

    if not settings.anthropic_api_key:  # pragma: no cover
        raise RuntimeError("ANTHROPIC_API_KEY missing; cannot call Claude.")

    raise NotImplementedError(
        "Live Claude translation deferred to Phase 2 per plan §I."
    )
