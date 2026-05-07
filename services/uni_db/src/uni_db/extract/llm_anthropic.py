"""Claude Sonnet extraction.

Plan §F.3. One call per field group with strict JSON schema mode.

Phase 0 status: the Anthropic SDK call site is wired but kept BEHIND
`settings.live_apis`. With live_apis=False, the function returns a
deterministic mock that satisfies the schema for the calendar group so
the rest of the pipeline can be exercised end-to-end without spending
tokens. Other groups return empty-collection stubs.

Cost (per plan §F.3): ~$1.30 per guideline.
"""

from __future__ import annotations

import json
import logging
import time
from dataclasses import dataclass
from typing import Any

import jsonschema

from ..config import settings
from .schemas import FIELD_GROUP_SCHEMAS

log = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class ExtractionResult:
    field_group: str
    parsed_output: dict[str, Any]
    raw_output: str
    llm_provider: str
    llm_model: str
    input_tokens: int
    output_tokens: int
    cost_usd: float
    latency_ms: int
    accuracy_self_score: float


_MOCK_OUTPUTS: dict[str, dict[str, Any]] = {
    "calendar": {
        "events": [
            {
                "event_type": "apply_open",
                "starts_at": "2026-09-01T09:00:00+09:00",
                "ends_at": None,
                "is_tentative": False,
                "notes_ko": "<mock> 모집기간 시작",
                "source_text_ko": "2026.09.01(월) 09:00 원서접수 시작",
                "extractor_confidence": 0.91,
            },
            {
                "event_type": "apply_close",
                "starts_at": "2026-09-30T17:00:00+09:00",
                "ends_at": None,
                "is_tentative": False,
                "notes_ko": "<mock> 17:00 KST 마감",
                "source_text_ko": "2026.09.30(화) 17:00까지 접수",
                "extractor_confidence": 0.92,
            },
        ]
    },
    "tuition": {"rows": []},
    "requirements": {
        "applicant_category": "외국인전형",
        "topik_min_level": None,
        "topik_deferred": False,
        "english_test": None,
        "gpa_floor_pct": None,
        "interview_required": False,
        "practical_exam_required": False,
        "prose_ko": "<mock requirements>",
        "source_text_ko": "<mock>",
        "extractor_confidence": 0.5,
    },
    "scholarships": {"rows": []},
    "documents_required": {"rows": []},
}


def extract_field_group(
    *,
    field_group: str,
    archetype: str,
    source_text_ko: str,
) -> ExtractionResult:
    """Extract one field group from a guideline section.

    Args:
        field_group: one of `calendar | tuition | requirements |
                     scholarships | documents_required`.
        archetype: A..H (used to pick the right prompt template).
        source_text_ko: the raw text slice for this section, in Korean.

    Returns:
        ExtractionResult with `parsed_output` validated against
        FIELD_GROUP_SCHEMAS[field_group]. Raises jsonschema.ValidationError
        if the LLM output drifts.
    """
    if field_group not in FIELD_GROUP_SCHEMAS:
        raise ValueError(f"unknown field_group: {field_group}")

    started = time.monotonic()

    if not settings.live_apis:
        parsed = _MOCK_OUTPUTS[field_group]
        raw = json.dumps(parsed, ensure_ascii=False)
        log.info(
            "extract: returning mock for %s/%s (UNI_DB_LIVE_APIS=false)",
            archetype,
            field_group,
        )
    else:
        parsed, raw = _call_anthropic(
            field_group=field_group,
            archetype=archetype,
            source_text_ko=source_text_ko,
        )

    jsonschema.validate(instance=parsed, schema=FIELD_GROUP_SCHEMAS[field_group])

    latency_ms = int((time.monotonic() - started) * 1000)
    return ExtractionResult(
        field_group=field_group,
        parsed_output=parsed,
        raw_output=raw,
        llm_provider="anthropic" if settings.live_apis else "mock",
        llm_model=settings.anthropic_model_extract if settings.live_apis else "mock",
        input_tokens=0,
        output_tokens=0,
        cost_usd=0.0,
        latency_ms=latency_ms,
        accuracy_self_score=parsed.get("extractor_confidence", 0.85)  # type: ignore[arg-type]
        if isinstance(parsed, dict) and "extractor_confidence" in parsed
        else 0.85,
    )


def _call_anthropic(
    *,
    field_group: str,
    archetype: str,
    source_text_ko: str,
) -> tuple[dict[str, Any], str]:  # pragma: no cover — Phase 1+
    """Real Anthropic call.

    Disabled in Phase 0; raises if invoked.
    """
    if not settings.anthropic_api_key:
        raise RuntimeError(
            "ANTHROPIC_API_KEY missing; cannot call Claude. Phase 0 keeps this "
            "disabled — see services/uni_db/README.md."
        )
    raise NotImplementedError(
        "Live Anthropic call deferred to Phase 1 per plan §F.3. The prompt "
        "templates are in services/uni_db/src/uni_db/extract/prompts/, and the "
        "schemas already live in extract/schemas.py."
    )
