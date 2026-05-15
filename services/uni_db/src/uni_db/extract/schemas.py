"""JSON schemas matching the §C tables.

Used by the LLM extraction layer in strict-JSON mode. Audit §5.3 /
plan §F.3. Each schema covers ONE field group (calendar, tuition,
requirements, scholarships, documents_required) so the LLM call is
narrow and the validator can pinpoint the failing field.
"""

from __future__ import annotations

from typing import Any

CALENDAR_SCHEMA: dict[str, Any] = {
    "type": "object",
    # Allow Claude to attach top-level meta fields like `is_correction_notice`,
    # `correction_text_ko` without invalidating the whole extraction. Per-row
    # strictness is preserved below.
    "additionalProperties": True,
    "properties": {
        "events": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["event_type", "starts_at", "source_text_ko"],
                "properties": {
                    "event_type": {
                        "type": "string",
                        "enum": [
                            "apply_open", "apply_close",
                            "document_submission_deadline",
                            # Aliases Claude emits for the deadline above.
                            "documents_deadline", "document_submission_close",
                            "first_stage_results", "interview", "practical_exam",
                            "final_results", "additional_admit",
                            "offer_confirmation",
                            "registration_open", "registration_close",
                            "registration_withdrawal_open",
                            "registration_withdrawal_close",
                            "orientation", "semester_start",
                            "scholarship_application_close",
                            "language_test_deadline",
                        ],
                    },
                    "starts_at":     {"type": "string", "format": "date-time"},
                    "ends_at":       {"type": ["string", "null"], "format": "date-time"},
                    "is_tentative":  {"type": "boolean"},
                    "notes_ko":      {"type": ["string", "null"]},
                    "source_text_ko":{"type": "string"},
                    "extractor_confidence": {"type": "number", "minimum": 0, "maximum": 1},
                },
            },
        },
    },
    "required": ["events"],
}

TUITION_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": True,  # root-level meta fields allowed
    "properties": {
        "rows": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["faculty_group", "academic_year",
                             "semester_number", "amount_krw", "source_text_ko"],
                "properties": {
                    "faculty_group":      {"type": "string"},
                    "academic_year":      {"type": "integer"},
                    "semester_number":    {"type": "integer", "minimum": 1, "maximum": 12},
                    "amount_krw":         {"type": "integer", "minimum": 0},
                    "admission_fee_krw":  {"type": ["integer", "null"], "minimum": 0},
                    "is_first_semester":  {"type": "boolean"},
                    "source_text_ko":     {"type": "string"},
                    "extractor_confidence":{"type": "number", "minimum": 0, "maximum": 1},
                },
            },
        },
    },
    "required": ["rows"],
}

REQUIREMENTS_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": True,  # root-level meta fields allowed
    "properties": {
        "applicant_category":      {"type": "string"},
        "topik_min_level":         {"type": ["integer", "null"], "minimum": 1, "maximum": 6},
        "topik_deferred":          {"type": "boolean"},
        "english_test":            {"type": ["object", "null"]},
        "gpa_floor_pct":           {"type": ["number", "null"], "minimum": 0, "maximum": 100},
        "interview_required":      {"type": "boolean"},
        "practical_exam_required": {"type": "boolean"},
        "prose_ko":                {"type": ["string", "null"]},
        "source_text_ko":          {"type": "string"},
        "extractor_confidence":    {"type": "number", "minimum": 0, "maximum": 1},
    },
    "required": ["applicant_category", "source_text_ko"],
}

SCHOLARSHIPS_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": True,  # root-level meta fields allowed
    "properties": {
        "rows": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["scope", "name_ko", "award_type", "source_text_ko"],
                "properties": {
                    "scope":      {"type": "string",
                                   "enum": ["national", "university", "department",
                                            "foundation", "regional"]},
                    "name_ko":    {"type": "string"},
                    "name_en":    {"type": ["string", "null"]},
                    "award_type": {"type": "string",
                                   "enum": ["tuition_waiver_pct", "tuition_waiver_krw",
                                            "stipend_monthly", "airfare", "other"]},
                    "award_value":{"type": ["number", "null"]},
                    "applicant_categories":  {"type": ["array", "null"], "items": {"type": "string"}},
                    "topik_tier_table":      {"type": ["object", "null"]},
                    "eligibility_predicate": {"type": ["object", "null"]},
                    "prose_ko":              {"type": ["string", "null"]},
                    # Claude frequently adds a short note alongside prose; allow it.
                    "notes_ko":              {"type": ["string", "null"]},
                    "correction_text_ko":    {"type": ["string", "null"]},
                    "is_correction_notice":  {"type": "boolean"},
                    "source_text_ko":        {"type": "string"},
                    "extractor_confidence":  {"type": "number", "minimum": 0, "maximum": 1},
                },
            },
        },
    },
    "required": ["rows"],
}

DOCUMENTS_REQUIRED_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": True,  # root-level meta fields allowed
    "properties": {
        "rows": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["applicant_category", "document_type", "source_text_ko"],
                "properties": {
                    "applicant_category":     {"type": "string"},
                    "document_type":          {"type": "string"},
                    "is_required":            {"type": "boolean"},
                    "is_apostille_required":  {"type": "boolean"},
                    "country_specific":       {"type": ["object", "null"]},
                    "notes_ko":               {"type": ["string", "null"]},
                    # Claude emits these in some shots — accept rather than reject.
                    "extractor_confidence":   {"type": "number", "minimum": 0, "maximum": 1},
                    "is_correction_notice":   {"type": "boolean"},
                    "source_text_ko":         {"type": "string"},
                },
            },
        },
    },
    "required": ["rows"],
}

RECRUITMENT_UNITS_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "rows": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["faculty_ko", "department_ko", "source_text_ko"],
                "properties": {
                    "external_code":  {"type": ["string", "null"]},
                    "faculty_ko":     {"type": "string"},
                    "division_ko":    {"type": ["string", "null"]},
                    "department_ko":  {"type": "string"},
                    "major_track_ko": {"type": ["string", "null"]},
                    "faculty_group":  {
                        "type": ["string", "null"],
                        "enum": [
                            None,
                            "humanities", "social", "natural_science", "engineering",
                            "arts_pe", "medicine", "dentistry", "veterinary",
                            "pharmacy", "theology", "interdisciplinary",
                        ],
                    },
                    "campus":               {"type": ["string", "null"]},
                    "quota":                {"type": ["integer", "string", "null"]},
                    "is_in_quota":          {"type": ["boolean", "null"]},
                    "applicant_category":   {"type": ["string", "null"]},
                    "is_correction_notice": {"type": "boolean"},
                    "correction_text_ko":   {"type": ["string", "null"]},
                    "notes_ko":             {"type": ["string", "null"]},
                    "source_text_ko":       {"type": "string"},
                    "extractor_confidence": {"type": "number", "minimum": 0, "maximum": 1},
                },
            },
        },
    },
    "required": ["rows"],
}

FIELD_GROUP_SCHEMAS: dict[str, dict[str, Any]] = {
    "calendar":           CALENDAR_SCHEMA,
    "tuition":            TUITION_SCHEMA,
    "requirements":       REQUIREMENTS_SCHEMA,
    "scholarships":       SCHOLARSHIPS_SCHEMA,
    "documents_required": DOCUMENTS_REQUIRED_SCHEMA,
    "recruitment_units":  RECRUITMENT_UNITS_SCHEMA,
    # Phase 1 alias: 'basic_requirements' is the user-facing label,
    # 'requirements' is the table name. Same shape.
    "basic_requirements": REQUIREMENTS_SCHEMA,
    "document_checklist": DOCUMENTS_REQUIRED_SCHEMA,
}
