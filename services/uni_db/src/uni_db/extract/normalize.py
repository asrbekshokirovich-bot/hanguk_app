"""Normalize LLM extraction output before schema validation.

The model occasionally drifts from the exact envelope: it returns a bare
array, omits the `rows`/`events` key, names the array differently, or emits a
calendar `event_type` outside our enum. Rather than failing the whole
extraction (which dumps a raw error on the reviewer), we repair these
structural quirks first. Genuine emptiness still normalizes to `{"rows": []}`
/ `{"events": []}`, which Layer 1 queue-hygiene then drops from the queue.

Pure / no IO.
"""

from __future__ import annotations

from typing import Any

# Field groups whose content array is "events"; everything else is "rows".
_CONTENT_KEY: dict[str, str] = {"calendar": "events"}

# Allowed calendar event types (mirror of CALENDAR_SCHEMA enum). Anything
# outside this set is mapped to "other".
CALENDAR_EVENT_TYPES: frozenset[str] = frozenset({
    "apply_open", "apply_close",
    "document_submission_deadline", "documents_deadline", "document_submission_close",
    "first_stage_results", "interview", "practical_exam",
    "final_results", "additional_admit", "offer_confirmation",
    "registration_open", "registration_close",
    "registration_withdrawal_open", "registration_withdrawal_close",
    "orientation", "semester_start",
    "scholarship_application_close", "language_test_deadline",
    "other",
})


def content_key_for(field_group: str) -> str:
    return _CONTENT_KEY.get(field_group, "rows")


def normalize_output(field_group: str, parsed: Any) -> Any:
    """Repair structural drift so valid-but-oddly-shaped output passes.

    Never touches a `_extraction_failed` marker. Returns a dict with the
    expected content key present.
    """
    key = content_key_for(field_group)

    # A bare array → wrap it in the envelope.
    if isinstance(parsed, list):
        parsed = {key: parsed}

    if not isinstance(parsed, dict):
        return {key: []}

    if "_extraction_failed" in parsed:
        return parsed

    # Ensure the content key exists. If the model used a single differently
    # named array key, adopt it; otherwise default to empty.
    if key not in parsed:
        array_keys = [k for k, v in parsed.items() if isinstance(v, list)]
        if len(array_keys) == 1:
            parsed[key] = parsed.pop(array_keys[0])
        else:
            parsed[key] = []

    # Calendar: map any unknown event_type to "other" so one odd label
    # doesn't fail the whole batch.
    if field_group == "calendar" and isinstance(parsed.get(key), list):
        for row in parsed[key]:
            if isinstance(row, dict):
                et = row.get("event_type")
                if isinstance(et, str) and et not in CALENDAR_EVENT_TYPES:
                    row["event_type"] = "other"

    return parsed
