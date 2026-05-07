"""Translation pipeline routing tests (mocked).

Plan §P.3 provider strategy:
    en  → Claude (prose) / DeepL (labels)
    uz  → pivot via en (Claude both hops); confidence -= 0.15
    vi  → Papago primary
    ru  → DeepL

Phase 2 (ADR-004): only `en` is enabled by default. Tests that exercise
non-en targets opt in by widening `settings.translation_languages_enabled`
via monkeypatch so the routing logic stays exercised even with the
ADR-004 default-off gate in place.
"""

import pytest

from uni_db.translate import pipeline
from uni_db.translate.glossary import GlossaryHit
from uni_db.translate.pipeline import LanguageNotEnabledError, translate


def _glossary() -> dict:
    return {
        ("서울대학교", "en"): GlossaryHit(
            term_ko="서울대학교",
            term_value="Seoul National University",
            category="institution_name",
        ),
        ("서울대학교", "uz"): GlossaryHit(
            term_ko="서울대학교",
            term_value="Seul Milliy Universiteti",
            category="institution_name",
        ),
        ("외국인전형", "en"): GlossaryHit(
            term_ko="외국인전형",
            term_value="Foreign Applicant Track",
            category="official_term",
        ),
    }


class TestPipelineRouting:
    def test_label_to_english_uses_deepl_mock(self) -> None:
        out = translate(
            source_text_ko="서울대학교",
            target_lang="en",
            glossary=_glossary(),
            is_label=True,
        )
        # Glossary hit replaces the whole token before MT runs.
        assert "Seoul National University" in out.text_value
        assert out.provider == "deepl"

    def test_prose_to_english_uses_claude_mock(self) -> None:
        out = translate(
            source_text_ko="서울대학교의 외국인전형 안내입니다.",
            target_lang="en",
            glossary=_glossary(),
            is_label=False,
        )
        assert "Seoul National University" in out.text_value
        assert "Foreign Applicant Track" in out.text_value
        assert out.provider == "claude"

    def test_uzbek_pivots_via_english(self, monkeypatch) -> None:
        # ADR-004: uz is default-off in Phase 2; widen to test routing.
        monkeypatch.setattr(
            pipeline.settings, "translation_languages_enabled", "en,uz",
            raising=False,
        )
        out = translate(
            source_text_ko="외국인전형 모집요강",
            target_lang="uz",
            glossary=_glossary(),
        )
        assert out.via_pivot is True
        assert out.confidence < 0.85       # pivot tax applied
        assert out.provider == "claude"

    def test_vietnamese_uses_papago(self, monkeypatch) -> None:
        monkeypatch.setattr(
            pipeline.settings, "translation_languages_enabled", "en,vi",
            raising=False,
        )
        out = translate(
            source_text_ko="모집요강",
            target_lang="vi",
            glossary={},
        )
        assert out.provider == "papago"

    def test_russian_uses_deepl(self, monkeypatch) -> None:
        monkeypatch.setattr(
            pipeline.settings, "translation_languages_enabled", "en,ru",
            raising=False,
        )
        out = translate(
            source_text_ko="모집요강",
            target_lang="ru",
            glossary={},
        )
        assert out.provider == "deepl"


class TestPhase2DefaultLanguageGate:
    """ADR-004: Phase 2 default-on is `en` only. Other languages raise."""

    def test_uz_raises_with_adr_pointer(self) -> None:
        with pytest.raises(LanguageNotEnabledError, match="ADR-004"):
            translate(
                source_text_ko="외국인전형",
                target_lang="uz",
                glossary={},
            )

    def test_vi_raises_by_default(self) -> None:
        with pytest.raises(LanguageNotEnabledError):
            translate(
                source_text_ko="외국인전형",
                target_lang="vi",
                glossary={},
            )

    def test_en_works_by_default(self) -> None:
        out = translate(
            source_text_ko="외국인전형",
            target_lang="en",
            glossary={},
        )
        assert out.provider == "claude"


class TestBackTranslationHook:
    def test_back_translate_callback_is_invoked_when_supplied(self) -> None:
        called: list[tuple[str, str]] = []

        def fake_back(text: str, lang: str) -> str:
            called.append((text, lang))
            return "외국인전형 모집요강"      # identical → distance ≈ 0

        out = translate(
            source_text_ko="외국인전형 모집요강",
            target_lang="en",
            glossary={},
            back_translate_fn=fake_back,
        )
        assert called, "back-translate fn should be invoked"
        assert out.back_trans_distance is not None
        assert out.back_trans_distance < 1.0
