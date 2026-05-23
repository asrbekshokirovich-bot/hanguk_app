"""Layer 1 queue-hygiene helpers: empty / failed extraction detection."""

from uni_db.workers.parse_worker import _is_empty_output, _is_failed_output


class TestIsFailedOutput:
    def test_failed_marker(self) -> None:
        assert _is_failed_output({"_extraction_failed": "AnthropicResponseError"}) is True

    def test_normal_output_not_failed(self) -> None:
        assert _is_failed_output({"rows": [{"a": 1}]}) is False

    def test_non_dict(self) -> None:
        assert _is_failed_output("nope") is False


class TestIsEmptyOutput:
    def test_empty_rows(self) -> None:
        assert _is_empty_output({"rows": []}) is True

    def test_empty_events(self) -> None:
        assert _is_empty_output({"events": []}) is True

    def test_empty_dict(self) -> None:
        assert _is_empty_output({}) is True

    def test_populated_rows(self) -> None:
        assert _is_empty_output({"rows": [{"name_ko": "x"}]}) is False

    def test_populated_events(self) -> None:
        assert _is_empty_output({"events": [{"event_type": "apply_open"}]}) is False

    def test_failed_is_not_empty(self) -> None:
        # A failed extraction is "failed", not "empty" — they're routed differently.
        assert _is_empty_output({"_extraction_failed": "boom"}) is False

    def test_only_empty_lists_and_blank_strings(self) -> None:
        assert _is_empty_output({"rows": [], "notes": "", "meta": {}}) is True

    def test_scalar_value_counts_as_content(self) -> None:
        assert _is_empty_output({"count": 3}) is False

    def test_bool_only_is_empty(self) -> None:
        # Booleans alone (e.g. flags) don't count as reviewable content.
        assert _is_empty_output({"is_required": False, "rows": []}) is True
