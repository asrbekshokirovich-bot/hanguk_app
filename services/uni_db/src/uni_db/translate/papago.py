"""Naver Papago adapter.

Plan §P.3: best ko↔vi and ko↔id. No first-party ko↔uz path (audit §P-6 risk).

Phase 0: live call disabled; mock returns deterministic output.
"""

from __future__ import annotations

import logging

from ..config import settings
from .models import TargetLang, TranslationOutput

log = logging.getLogger(__name__)

# Papago supports these directly from Korean.
PAPAGO_SUPPORTED_FROM_KO: frozenset[TargetLang] = frozenset(
    {"en", "vi", "id", "ru"}     # ru via N2MT; uz / mn unsupported
)


def translate(*, source_text_ko: str, target_lang: TargetLang) -> TranslationOutput:
    if target_lang not in PAPAGO_SUPPORTED_FROM_KO:
        raise ValueError(
            f"Papago does not support ko→{target_lang}; pivot via Claude required."
        )
    if not settings.live_apis:
        return TranslationOutput(
            text_value=f"[papago-mock {target_lang}] {source_text_ko}".strip(),
            provider="papago",
            confidence=0.82,
        )
    if not (settings.naver_papago_client_id and settings.naver_papago_client_secret):
        raise RuntimeError("Papago credentials missing.")  # pragma: no cover
    raise NotImplementedError(
        "Live Papago translation deferred to Phase 2 per plan §I."
    )
