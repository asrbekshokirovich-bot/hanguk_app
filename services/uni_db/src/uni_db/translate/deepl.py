"""DeepL adapter.

Plan §P.3: excellent ko↔en, ko↔ru. Cheap per-character.

Phase 0: live call disabled; mock returns deterministic output.
"""

from __future__ import annotations

from ..config import settings
from .models import TargetLang, TranslationOutput

DEEPL_SUPPORTED_FROM_KO: frozenset[TargetLang] = frozenset({"en", "ru", "id"})


def translate(*, source_text_ko: str, target_lang: TargetLang) -> TranslationOutput:
    if target_lang not in DEEPL_SUPPORTED_FROM_KO:
        raise ValueError(f"DeepL does not support ko→{target_lang}.")
    if not settings.live_apis:
        return TranslationOutput(
            text_value=f"[deepl-mock {target_lang}] {source_text_ko}".strip(),
            provider="deepl",
            confidence=0.88,
        )
    if not settings.deepl_api_key:  # pragma: no cover
        raise RuntimeError("DEEPL_API_KEY missing.")
    raise NotImplementedError(
        "Live DeepL translation deferred to Phase 2 per plan §I."
    )
