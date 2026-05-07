"""Parse worker — pulls pending guideline_documents and runs extraction.

Plan §F. Phase 0 wiring:

  1. dequeue: read guideline_documents.parse_status='pending' (one row).
  2. classify archetype.
  3. for each field_group: call extract_field_group(...). With
     `UNI_DB_LIVE_APIS=false` this returns deterministic mocks so the
     end-to-end loop runs against fixtures.
  4. validate per-difficulty (plan §F.4).
  5. write extraction_jobs row + (auto-publish OR enqueue review_queue).

The DB write paths take an asyncpg.Connection; tests pass a fake.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Iterable
from uuid import UUID, uuid4

import asyncpg

from ..extract.archetype import (
    ArchetypeFingerprint,
    classify_archetype,
    find_section_offsets,
)
from ..extract.llm_anthropic import ExtractionResult, extract_field_group
from ..extract.validators import evaluate as validate_field

log = logging.getLogger(__name__)

FIELD_GROUPS = (
    "calendar",
    "tuition",
    "requirements",
    "scholarships",
    "documents_required",
)


@dataclass(frozen=True, slots=True)
class ParseOutcome:
    guideline_document_id: UUID
    archetype: ArchetypeFingerprint
    extraction_results: list[ExtractionResult]
    review_queue_entries: list[dict[str, object]]


def parse_one_document(
    *,
    guideline_document_id: UUID,
    pdf_text_first_pages: str,
    pdf_text_full: str,
) -> ParseOutcome:
    """Pure: returns the outcome without touching the DB.

    The DB-writing wrapper is `persist_outcome`. Tests exercise this
    function directly against fixture text.
    """
    archetype = classify_archetype(pdf_text_first_pages)
    offsets = find_section_offsets(pdf_text_full)

    results: list[ExtractionResult] = []
    review_entries: list[dict[str, object]] = []

    for group in FIELD_GROUPS:
        section_text = _slice_for(pdf_text_full, group, offsets)
        result = extract_field_group(
            field_group=group,
            archetype=archetype.label,
            source_text_ko=section_text,
        )
        results.append(result)

        verdict = validate_field(
            field_name=_canonical_field_for(group),
            confidence=result.accuracy_self_score,
        )
        if verdict.requires_hitl:
            review_entries.append(
                {
                    "entity_type": "extraction_jobs",
                    "entity_id": None,           # filled by persist_outcome
                    "reason": "low_confidence" if result.accuracy_self_score < 0.85
                              else "high_difficulty_field",
                    "priority": 3 if result.accuracy_self_score >= 0.7 else 2,
                    "field_group": group,
                    "rationale": verdict.rationale,
                }
            )

    return ParseOutcome(
        guideline_document_id=guideline_document_id,
        archetype=archetype,
        extraction_results=results,
        review_queue_entries=review_entries,
    )


async def persist_outcome(
    conn: asyncpg.Connection,
    outcome: ParseOutcome,
) -> None:
    for result in outcome.extraction_results:
        job_id = uuid4()
        await conn.execute(
            """
            insert into public.extraction_jobs (
              id, guideline_document_id, archetype, field_group,
              status, llm_provider, llm_model, input_tokens, output_tokens,
              cost_usd, latency_ms, accuracy_self_score,
              raw_output, parsed_output, started_at, ended_at
            ) values (
              $1,$2,$3,$4,
              'succeeded', $5,$6,$7,$8,
              $9,$10,$11,
              $12::jsonb, $13::jsonb, $14, $15
            )
            """,
            job_id,
            outcome.guideline_document_id,
            outcome.archetype.label,
            result.field_group,
            result.llm_provider,
            result.llm_model,
            result.input_tokens,
            result.output_tokens,
            result.cost_usd,
            result.latency_ms,
            result.accuracy_self_score,
            result.raw_output if isinstance(result.raw_output, str)
                else json.dumps(result.raw_output, ensure_ascii=False),
            json.dumps(result.parsed_output, ensure_ascii=False),
            datetime.now(tz=timezone.utc),
            datetime.now(tz=timezone.utc),
        )

        # If this group requires HITL, enqueue.
        for entry in outcome.review_queue_entries:
            if entry.get("field_group") == result.field_group:
                await conn.execute(
                    """
                    insert into public.review_queue (
                      entity_type, entity_id, reason, priority,
                      reviewer_notes
                    ) values ($1,$2,$3,$4,$5)
                    """,
                    "extraction_jobs",
                    job_id,
                    entry["reason"],
                    entry["priority"],
                    entry["rationale"],
                )

    await conn.execute(
        """
        update public.guideline_documents
           set parse_status   = 'succeeded',
               parsed_version = parsed_version + 1,
               archetype      = $2
         where id = $1
        """,
        outcome.guideline_document_id,
        outcome.archetype.label,
    )


def _slice_for(full_text: str, group: str, offsets: dict[str, int]) -> str:
    if group not in offsets:
        return full_text[:8000]                  # fallback: first 8k chars
    start = offsets[group]
    return full_text[start : start + 12000]


def _canonical_field_for(group: str) -> str:
    return {
        "calendar":           "application_open_at",     # representative D1 field
        "tuition":            "tuition_per_semester",    # D3
        "requirements":       "topik_required_level",    # D3
        "scholarships":       "scholarships",            # D4
        "documents_required": "documents_required",      # D4
    }.get(group, group)


def iter_field_groups() -> Iterable[str]:
    return iter(FIELD_GROUPS)
