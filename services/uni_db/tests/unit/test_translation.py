"""Translation pipeline routing tests (mocked).

Plan §P.3 provider strategy:
    en  → Claude (prose) / DeepL (labels)
    uz  → pivot via en (Claude both hops); confidence -= 0.15
    vi  → Papago primary
    ru  → DeepL
"""

from uni_db.translate.glossary import GlossaryHit
from uni_db.translate.pipeline import translate


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

    def test_uzbek_pivots_via_english(self) -> None:
        out = translate(
            source_text_ko="외국인전형 모집요강",
            target_lang="uz",
            glossary=_glossary(),
        )
        assert out.via_pivot is True
        assert out.confidence < 0.85       # pivot tax applied
        assert out.provider == "claude"

    def test_vietnamese_uses_papago(self) -> None:
        out = translate(
            source_text_ko="모집요강",
            target_lang="vi",
            glossary={},
        )
        assert out.provider == "papago"

    def test_russian_uses_deepl(self) -> None:
        out = translate(
            source_text_ko="모집요강",
            target_lang="ru",
            glossary={},
        )
        assert out.provider == "deepl"


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
