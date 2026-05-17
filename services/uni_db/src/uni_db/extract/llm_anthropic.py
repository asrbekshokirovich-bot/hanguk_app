"""Claude extraction.

Plan §F.3. One call per field group with strict JSON schema mode.

Status (2026-05-08): the Anthropic SDK call site is implemented and
gated behind `settings.live_apis`. With `live_apis=False` the function
returns a deterministic mock that satisfies the schema for the calendar
group so the rest of the pipeline can be exercised end-to-end without
spending tokens. Other groups return empty-collection stubs.

When `live_apis=True` and `ANTHROPIC_API_KEY` is set, the live call
goes through. The system message (glossary + field-group prompt +
archetype few-shots + addenda) is marked `cache_control=ephemeral`
so subsequent extractions for the same archetype/field-group hit the
prompt cache (10x cheaper input tokens).

Cost (per plan §F.3): ~$1.30 per guideline at full Sonnet pricing,
materially lower with cache hits.
"""

from __future__ import annotations

import json
import logging
import re
import time
from dataclasses import dataclass
from typing import Any

import jsonschema
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from ..config import settings
from .prompt_assembler import GlossaryEntry, assemble_prompt
from .schemas import FIELD_GROUP_SCHEMAS

log = logging.getLogger(__name__)


# Sonnet pricing (USD per 1M tokens) per ADR-001 / plan §F.3.
# Cache write = 1.25x input rate; cache read = 0.10x input rate.
_SONNET_INPUT_USD_PER_M = 3.00
_SONNET_OUTPUT_USD_PER_M = 15.00
_SONNET_CACHE_WRITE_USD_PER_M = _SONNET_INPUT_USD_PER_M * 1.25
_SONNET_CACHE_READ_USD_PER_M = _SONNET_INPUT_USD_PER_M * 0.10

# Strip ```json ... ``` and ``` ... ``` fences — Sonnet sometimes wraps
# JSON output despite the prompt instruction not to. The closing fence is
# OPTIONAL because long extractions occasionally hit max_tokens before the
# closing ``` is emitted; we still want to recover the body in that case.
_FENCE_RE = re.compile(
    r"^\s*```(?:json|JSON)?\s*(.*?)(?:\s*```\s*)?$",
    re.DOTALL,
)


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


@dataclass(frozen=True, slots=True)
class _AnthropicCallResult:
    parsed: dict[str, Any]
    raw: str
    model: str
    input_tokens: int
    output_tokens: int
    cached_input_tokens: int
    cache_write_tokens: int
    cost_usd: float


class AnthropicResponseError(ValueError):
    """Raised when the model returns text we can't parse as JSON."""


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
        "rows": [
            {
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
        ],
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
        jsonschema.validate(instance=parsed, schema=FIELD_GROUP_SCHEMAS[field_group])
        latency_ms = int((time.monotonic() - started) * 1000)
        return ExtractionResult(
            field_group=field_group,
            parsed_output=parsed,
            raw_output=raw,
            llm_provider="mock",
            llm_model="mock",
            input_tokens=0,
            output_tokens=0,
            cost_usd=0.0,
            latency_ms=latency_ms,
            accuracy_self_score=_self_score(parsed),
        )

    call = _call_anthropic(
        field_group=field_group,
        archetype=archetype,
        source_text_ko=source_text_ko,
    )
    jsonschema.validate(instance=call.parsed, schema=FIELD_GROUP_SCHEMAS[field_group])

    latency_ms = int((time.monotonic() - started) * 1000)
    return ExtractionResult(
        field_group=field_group,
        parsed_output=call.parsed,
        raw_output=call.raw,
        llm_provider="anthropic",
        llm_model=call.model,
        input_tokens=call.input_tokens,
        output_tokens=call.output_tokens,
        cost_usd=call.cost_usd,
        latency_ms=latency_ms,
        accuracy_self_score=_self_score(call.parsed),
    )


def _self_score(parsed: object) -> float:
    if isinstance(parsed, dict) and "extractor_confidence" in parsed:
        try:
            return float(parsed["extractor_confidence"])  # type: ignore[arg-type]
        except (TypeError, ValueError):
            return 0.85
    return 0.85


# Anthropic completions can legitimately take 60-90s for long structured
# extractions. The 30s httpx timeout used for HTML fetches is far too tight
# for LLM calls — it was the root cause of the `requirements` field group
# timing out on every parse run. 120s gives Sonnet headroom while still
# bounding cron worker latency.
_ANTHROPIC_TIMEOUT_SEC = 120.0


def _get_client():  # pragma: no cover — exercised via monkeypatch in tests
    """Lazy-instantiate the Anthropic client.

    Factored as a function so tests can monkeypatch without importing the
    SDK. Production code path imports `anthropic` here, after the
    `settings.live_apis` gate has already passed in `extract_field_group`.
    """
    from anthropic import Anthropic

    return Anthropic(
        api_key=settings.anthropic_api_key,
        timeout=_ANTHROPIC_TIMEOUT_SEC,
    )


def _retriable_exception_types() -> tuple[type[BaseException], ...]:  # pragma: no cover
    """Return the set of Anthropic SDK exceptions worth retrying.

    Imported lazily so test environments without the SDK don't choke on
    module import. Returns a fallback if `anthropic` isn't installed.
    """
    try:
        from anthropic import (  # type: ignore[import-not-found]
            APIConnectionError,
            APITimeoutError,
            InternalServerError,
            RateLimitError,
        )

        return (APIConnectionError, APITimeoutError, InternalServerError, RateLimitError)
    except ImportError:
        return (ConnectionError, TimeoutError)


def _strip_fences(text: str) -> str:
    """Remove ```json``` / ``` markdown fences if the model wrapped output."""
    match = _FENCE_RE.match(text)
    if match:
        return match.group(1).strip()
    return text.strip()


def _compute_cost_usd(
    *,
    input_tokens: int,
    output_tokens: int,
    cached_input_tokens: int,
    cache_write_tokens: int,
) -> float:
    """Compute Sonnet billing for one call.

    Anthropic's `usage.input_tokens` reports tokens that were billed at
    the standard input rate (i.e. NOT cache-read). `cache_read_input_tokens`
    is billed separately at 10% of input rate; `cache_creation_input_tokens`
    is billed at 1.25x input rate (a one-time write cost). Output tokens
    bill at the full output rate regardless of cache state.
    """
    cost_input = input_tokens * _SONNET_INPUT_USD_PER_M / 1_000_000
    cost_output = output_tokens * _SONNET_OUTPUT_USD_PER_M / 1_000_000
    cost_cache_read = cached_input_tokens * _SONNET_CACHE_READ_USD_PER_M / 1_000_000
    cost_cache_write = cache_write_tokens * _SONNET_CACHE_WRITE_USD_PER_M / 1_000_000
    return round(cost_input + cost_output + cost_cache_read + cost_cache_write, 6)


# 2 attempts (1 retry) at 120s timeout each = max ~240s per field group
# instead of 4 attempts at 30s = 120s wasted on a hard-failing extraction.
# Real Anthropic glitches are rare; budget-bound the worst case rather
# than retrying optimistically into a timeout cliff.
@retry(
    reraise=True,
    stop=stop_after_attempt(2),
    wait=wait_exponential(multiplier=2, min=2, max=30),
    retry=retry_if_exception_type(_retriable_exception_types()),
)
def _call_anthropic(
    *,
    field_group: str,
    archetype: str,
    source_text_ko: str,
) -> _AnthropicCallResult:
    """Live Anthropic call.

    Gated by `settings.live_apis` upstream — this function itself does
    NOT re-check the flag, but it raises if the API key isn't present
    so accidental invocation in a misconfigured env fails loudly.
    """
    if not settings.anthropic_api_key:
        raise RuntimeError(
            "ANTHROPIC_API_KEY is not set; cannot call Claude. Set the "
            "key in services/uni_db/.env or unset UNI_DB_LIVE_APIS to "
            "use the deterministic mock path. See docs/credentials.md §4."
        )

    prompt = assemble_prompt(
        field_group=field_group,  # type: ignore[arg-type]
        archetype=archetype,
        source_text_ko=source_text_ko,
        glossary=_default_glossary(),
    )

    client = _get_client()

    log.info(
        "extract: calling anthropic %s for %s/%s (~%d input tokens estimated)",
        settings.anthropic_model_extract,
        archetype,
        field_group,
        prompt.estimated_input_tokens,
    )

    response = client.messages.create(
        model=settings.anthropic_model_extract,
        max_tokens=4096,
        # Mark the system block as cacheable. The system prompt is the
        # glossary + field-group + archetype few-shots — large and stable
        # per archetype, so cache hits are common across a crawl batch.
        system=[
            {
                "type": "text",
                "text": prompt.system,
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[{"role": "user", "content": prompt.user}],
    )

    raw = _extract_text(response)
    stripped = _strip_fences(raw)
    try:
        parsed = json.loads(stripped)
    except json.JSONDecodeError as exc:
        raise AnthropicResponseError(
            f"Anthropic response was not valid JSON: {exc}; raw={raw[:200]!r}"
        ) from exc
    if not isinstance(parsed, dict):
        raise AnthropicResponseError(
            f"Anthropic response parsed to {type(parsed).__name__}, expected dict"
        )

    usage = response.usage
    input_tokens = int(getattr(usage, "input_tokens", 0) or 0)
    output_tokens = int(getattr(usage, "output_tokens", 0) or 0)
    cached_input_tokens = int(getattr(usage, "cache_read_input_tokens", 0) or 0)
    cache_write_tokens = int(getattr(usage, "cache_creation_input_tokens", 0) or 0)
    cost = _compute_cost_usd(
        input_tokens=input_tokens,
        output_tokens=output_tokens,
        cached_input_tokens=cached_input_tokens,
        cache_write_tokens=cache_write_tokens,
    )

    log.info(
        "extract: anthropic %s/%s done — in=%d cached=%d cache_write=%d out=%d cost=$%.5f",
        archetype,
        field_group,
        input_tokens,
        cached_input_tokens,
        cache_write_tokens,
        output_tokens,
        cost,
    )

    return _AnthropicCallResult(
        parsed=parsed,
        raw=raw,
        model=getattr(response, "model", settings.anthropic_model_extract),
        input_tokens=input_tokens,
        output_tokens=output_tokens,
        cached_input_tokens=cached_input_tokens,
        cache_write_tokens=cache_write_tokens,
        cost_usd=cost,
    )


def _extract_text(response: Any) -> str:
    """Pull the first text block from a Messages response.

    Anthropic Messages responses come back as `content: list[ContentBlock]`,
    where each block has a `type` and (for text blocks) `.text`. We expect
    a single text block; if multiple, concatenate.
    """
    content = getattr(response, "content", None)
    if not content:
        raise AnthropicResponseError("Anthropic response had no content blocks")
    parts: list[str] = []
    for block in content:
        text = getattr(block, "text", None)
        if isinstance(text, str):
            parts.append(text)
    if not parts:
        raise AnthropicResponseError(
            "Anthropic response had no text blocks (only tool/image?)"
        )
    return "".join(parts)


def _default_glossary() -> tuple[GlossaryEntry, ...]:
    """Minimal glossary used by the extractor.

    The richer glossary table (see services/uni_db/TRANSLATION_GLOSSARY.md)
    is consumed by the translation worker. The extractor only needs the
    handful of terms that show up structurally in the prompts.
    """
    return (
        GlossaryEntry(term_ko="외국인전형", term_value="외국인전형", category="applicant_category"),
        GlossaryEntry(term_ko="재외국민전형", term_value="재외국민전형", category="applicant_category"),
        GlossaryEntry(term_ko="정정공고", term_value="정정공고", category="document_type"),
        GlossaryEntry(term_ko="모집요강", term_value="모집요강", category="document_type"),
    )
