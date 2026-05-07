"""Plan §C.16 / §P.3 — glossary lookup must bypass MT for institution
names and official terms."""

from uni_db.translate.glossary import (
    GlossaryHit,
    apply_glossary_post_translate,
    apply_glossary_pre_translate,
    lookup,
)


def _cache() -> dict:
    return {
        ("서울대학교", "en"): GlossaryHit(
            term_ko="서울대학교",
            term_value="Seoul National University",
            category="institution_name",
        ),
        ("서울대", "en"): GlossaryHit(
            term_ko="서울대",
            term_value="Seoul National University",
            category="institution_name",
        ),
        ("외국인전형", "en"): GlossaryHit(
            term_ko="외국인전형",
            term_value="Foreign Applicant Track",
            category="official_term",
        ),
    }


class TestLookup:
    def test_returns_hit_when_term_present(self) -> None:
        hit = lookup(_cache(), term_ko="서울대학교", target_lang="en")
        assert hit is not None
        assert hit.term_value == "Seoul National University"

    def test_returns_none_when_missing(self) -> None:
        assert lookup(_cache(), term_ko="없는학교", target_lang="en") is None


class TestPrePostTranslateRoundtrip:
    def test_longer_term_takes_precedence_over_shorter(self) -> None:
        text = "서울대학교의 외국인전형 안내"
        primed, hits = apply_glossary_pre_translate(
            text, cache=_cache(), target_lang="en"
        )
        # Longer match wins: 서울대학교 not 서울대 by itself.
        assert "서울대학교" not in primed
        assert "서울대학교" in [h.term_ko for h in hits]
        assert "외국인전형" in [h.term_ko for h in hits]

    def test_post_translate_substitutes_authoritative_target(self) -> None:
        text = "서울대학교의 외국인전형"
        primed, hits = apply_glossary_pre_translate(
            text, cache=_cache(), target_lang="en"
        )
        # Pretend MT happened — for the test we just keep `primed`.
        out = apply_glossary_post_translate(primed, hits)
        assert "Seoul National University" in out
        assert "Foreign Applicant Track" in out
