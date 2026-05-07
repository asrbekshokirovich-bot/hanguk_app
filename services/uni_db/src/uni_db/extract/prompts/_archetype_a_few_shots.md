# Archetype A — SNU flagship calibration

Audit §5.2: 80–120 pages, deep applicant-category sections, cross-
referenced tuition booklet, bilingual side-by-side columns, 부록 (appendix)
tables, voluminous 모집단위별 quotas with 정원외 / 정원내 split.

## Calibration notes

- The bilingual layout means the same calendar row often appears twice —
  once Korean, once English. **Trust the Korean row** (§P.1) and ignore
  the English copy. Set `source_text_ko` to the Korean version only.
- Tuition is published in a separate booklet. When the section says
  "별도 책자 참조", emit `{"rows": []}` and DO NOT hallucinate from the
  brochure summary lines.
- `applicant_category` granularity is high: 외국인전형 신입학,
  외국인전형 편입학, 글로벌인재특별전형, 재외국민특별전형. Match
  exactly.
- `quota` values are usually integers; SNU uses 정원외 markers heavily
  for arts/PE — preserve as `is_in_quota=false`.
