"""Unit tests for extraction output normalization (Layer 2)."""

from uni_db.extract.normalize import content_key_for, normalize_output


class TestContentKey:
    def test_calendar_uses_events(self) -> None:
        assert content_key_for("calendar") == "events"

    def test_others_use_rows(self) -> None:
        for g in ("tuition", "requirements", "scholarships", "documents_required"):
            assert content_key_for(g) == "rows"


class TestNormalizeOutput:
    def test_bare_list_is_wrapped(self) -> None:
        assert normalize_output("scholarships", [{"x": 1}]) == {"rows": [{"x": 1}]}

    def test_bare_list_calendar_uses_events(self) -> None:
        assert normalize_output("calendar", [{"event_type": "apply_open"}]) == {
            "events": [{"event_type": "apply_open"}]
        }

    def test_missing_key_single_array_is_adopted(self) -> None:
        out = normalize_output("scholarships", {"scholarships": [{"a": 1}]})
        assert out == {"rows": [{"a": 1}]}

    def test_missing_key_no_array_defaults_empty(self) -> None:
        assert normalize_output("tuition", {"note": "none found"}) == {
            "note": "none found",
            "rows": [],
        }

    def test_non_dict_non_list_defaults_empty(self) -> None:
        assert normalize_output("tuition", "garbage") == {"rows": []}

    def test_extraction_failed_is_untouched(self) -> None:
        payload = {"_extraction_failed": "boom"}
        assert normalize_output("tuition", payload) == payload

    def test_unknown_calendar_event_type_mapped_to_other(self) -> None:
        out = normalize_output("calendar", {"events": [
            {"event_type": "tuition_payment", "starts_at": "2026-01-01T00:00:00Z"},
            {"event_type": "apply_open", "starts_at": "2026-02-01T00:00:00Z"},
        ]})
        assert out["events"][0]["event_type"] == "other"
        assert out["events"][1]["event_type"] == "apply_open"

    def test_already_valid_rows_unchanged(self) -> None:
        payload = {"rows": [{"scope": "university", "name_ko": "x"}]}
        assert normalize_output("scholarships", payload) == payload
