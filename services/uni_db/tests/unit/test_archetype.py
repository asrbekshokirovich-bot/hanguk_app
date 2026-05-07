"""Plan §F.1 / Audit §5.2 archetype dispatcher."""

from uni_db.extract.archetype import (
    classify_archetype,
    find_section_offsets,
)


class TestClassifyArchetype:
    def test_snu_text_classifies_as_a(self) -> None:
        out = classify_archetype("서울대학교 2026학년도 외국인전형 신입학")
        assert out.label == "A"
        assert out.confidence >= 0.55

    def test_yonsei_text_classifies_as_b(self) -> None:
        out = classify_archetype("연세대학교 2026 단과대학 외국인전형 안내")
        assert out.label == "B"

    def test_pnu_text_classifies_as_c(self) -> None:
        out = classify_archetype("부산대학교 거점국립대 외국인전형")
        assert out.label == "C"

    def test_ewha_text_classifies_as_e(self) -> None:
        out = classify_archetype("이화여자대학교 외국인특별전형 — 여학생만")
        assert out.label == "E"

    def test_default_when_no_signals(self) -> None:
        out = classify_archetype("Plain text with no archetype hints.")
        assert out.label == "B"
        assert out.confidence < 0.5


class TestFindSectionOffsets:
    def test_korean_guideline_text_finds_all_sections(
        self, korean_guideline_text: str
    ) -> None:
        offsets = find_section_offsets(korean_guideline_text)
        assert "calendar" in offsets
        assert "tuition" in offsets
        assert "scholarships" in offsets
        assert "requirements" in offsets
        assert "documents_required" in offsets

    def test_returns_empty_dict_for_unrelated_text(self) -> None:
        assert find_section_offsets("hello world") == {}
