# Archetype G — STEM specialized calibration

Audit §5.2: 30–60 pages, English-first or English-only, qualitative
quotas (`약간명`, `소수정원`), scholarships heavily embedded, recruitment
unit list short (often a single college), application via custom portal
(univapply.kaist.ac.kr / interapply / apply.unist.ac.kr).

## Calibration notes

- Despite the English-first format, plan §P.1 still mandates KO source
  preservation. Locate the Korean version of every key line and emit
  it in `source_text_ko`. If only English exists, emit the English
  string in `source_text_ko` and flag `extractor_confidence -= 0.1`.
- Qualitative quotas: the schema accepts integer or string. Emit
  `"약간명"` / `"소수정원"` verbatim — DO NOT guess a number.
- Scholarship rows in archetype G are usually 100% tuition + monthly
  stipend bundled. Encode as two rows:
    `award_type=tuition_waiver_pct, award_value=100`
    `award_type=stipend_monthly, award_value=<KRW/month>`
