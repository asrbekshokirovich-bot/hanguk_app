"""Validate the 2026-05 enrichment fields against the field-group schemas."""

import jsonschema
import pytest

from uni_db.extract.schemas import FIELD_GROUP_SCHEMAS


def _validate(group: str, payload: dict) -> None:
    jsonschema.validate(instance=payload, schema=FIELD_GROUP_SCHEMAS[group])


class TestCalendarPeriods:
    def test_full_period_validates(self) -> None:
        _validate("calendar", {
            "events": [],
            "periods": [{
                "language_track": "english",
                "program_level": "undergraduate",
                "online_application_start": "2026-09-01",
                "online_application_end": "2026-09-30",
                "offline_application_start": None,
                "offline_application_end": None,
                "interview_start": "2026-10-15",
                "interview_end": "2026-10-16",
                "application_start": "2026-09-01",
                "application_end": "2026-09-30",
                "document_deadline": "2026-10-05",
                "result_announcement": "2026-11-20",
                "application_fee_krw": 80000,
                "application_fee_usd": 60,
                "source_text_ko": "온라인 지원 2026.09.01~09.30",
            }],
        })

    def test_events_only_still_valid(self) -> None:
        _validate("calendar", {"events": []})

    def test_bad_language_track_rejected(self) -> None:
        with pytest.raises(jsonschema.ValidationError):
            _validate("calendar", {"events": [], "periods": [{"language_track": "spanish"}]})


class TestRequirementsEnrichment:
    def test_majors_tuition_english_test(self) -> None:
        _validate("requirements", {"rows": [{
            "applicant_category": "외국인전형",
            "source_text_ko": "지원자격",
            "majors": ["컴퓨터공학과", "전기전자공학부"],
            "tuition": {
                "amount_krw": 4500000,
                "admission_fee_krw": 1000000,
                "academic_year": 2026,
                "semester_number": 1,
            },
            "english_test": {"test": "ielts", "min_score": 6.0, "deferred": False},
        }]})

    def test_legacy_row_without_new_fields_valid(self) -> None:
        _validate("requirements", {"rows": [{
            "applicant_category": "외국인전형", "source_text_ko": "x",
        }]})


class TestScholarshipTiers:
    def test_topik_and_ielts_tiers(self) -> None:
        _validate("scholarships", {"rows": [{
            "scope": "university", "name_ko": "외국인 장학금",
            "award_type": "tuition_waiver_pct", "source_text_ko": "장학",
            "topik_tier_table": [
                {"topik_level": 6, "award_type": "tuition_waiver_pct", "award_value": 100, "duration": "all_years"},
                {"topik_level": 4, "award_type": "tuition_waiver_pct", "award_value": 50, "duration": "first_semester"},
            ],
            "ielts_tier_table": [
                {"ielts_min": 6.5, "award_type": "tuition_waiver_pct", "award_value": 100, "duration": "full_year"},
            ],
        }]})

    def test_topik_tier_object_backward_compat(self) -> None:
        _validate("scholarships", {"rows": [{
            "scope": "university", "name_ko": "x",
            "award_type": "other", "source_text_ko": "y",
            "topik_tier_table": {"3": 40, "4": 50},  # legacy object form still ok
        }]})

    def test_bad_duration_rejected(self) -> None:
        with pytest.raises(jsonschema.ValidationError):
            _validate("scholarships", {"rows": [{
                "scope": "university", "name_ko": "x",
                "award_type": "other", "source_text_ko": "y",
                "ielts_tier_table": [{"ielts_min": 6.0, "duration": "forever"}],
            }]})


class TestRequirementStatusSentinels:
    def test_all_statuses_validate(self) -> None:
        _validate("requirements", {"rows": [{
            "source_text_ko": "TOPIK 면제",
            "topik_min_level": None, "topik_status": "not_required",
            "english_test": None, "english_status": "not_stated",
            "gpa_floor_pct": None, "gpa_status": "not_stated",
        }]})

    def test_required_status(self) -> None:
        _validate("requirements", {"rows": [{
            "source_text_ko": "TOPIK 4급 이상",
            "topik_min_level": 4, "topik_status": "required",
        }]})

    def test_bad_status_rejected(self) -> None:
        with pytest.raises(jsonschema.ValidationError):
            _validate("requirements", {"rows": [{
                "source_text_ko": "x", "topik_status": "maybe",
            }]})

    def test_status_optional_backward_compat(self) -> None:
        # Rows without the new sentinels still validate.
        _validate("requirements", {"rows": [{
            "source_text_ko": "x", "topik_min_level": 3,
        }]})


class TestDocumentDeadlines:
    def test_per_document_deadline_validates(self) -> None:
        _validate("documents_required", {"rows": [{
            "document_type": "lor", "source_text_ko": "추천서",
            "is_required": False,
            "deadline": "2026-10-29", "applies_to_round": "early",
        }]})

    def test_deadline_nullable(self) -> None:
        _validate("documents_required", {"rows": [{
            "document_type": "passport", "source_text_ko": "여권",
            "deadline": None, "applies_to_round": None,
        }]})


class TestTrackCompleteness:
    def test_full_and_partial_validate(self) -> None:
        for c in ("full", "partial"):
            _validate("requirements", {"rows": [{
                "source_text_ko": "x", "applicant_category": "외국인전형",
                "completeness": c,
            }]})

    def test_bad_completeness_rejected(self) -> None:
        with pytest.raises(jsonschema.ValidationError):
            _validate("requirements", {"rows": [{
                "source_text_ko": "x", "completeness": "mostly",
            }]})


class TestAudienceTag:
    def test_audience_values_validate(self) -> None:
        for a in ("foreign", "overseas_korean", "defector", "naturalized", "domestic"):
            _validate("requirements", {"rows": [{"source_text_ko": "x", "audience": a}]})

    def test_bad_audience_rejected(self) -> None:
        with pytest.raises(jsonschema.ValidationError):
            _validate("requirements", {"rows": [{"source_text_ko": "x", "audience": "alien"}]})
