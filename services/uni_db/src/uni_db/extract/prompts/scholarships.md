# scholarships field-group extraction prompt

Audit §5.3 difficulty 4 — heavy HITL routing. Strict JSON schema =
`SCHOLARSHIPS_SCHEMA`.

## Rules

- One row per scholarship.
- `scope`: where the scholarship comes from (national/government =
  national, university-administered = university, department-funded =
  department, external foundation = foundation, regional/city = regional).
- `award_type` enum: `tuition_waiver_pct | tuition_waiver_krw |
  stipend_monthly | airfare | other`.
- `topik_tier_table` is a JSON map of `{TOPIK_level: percentage_waived}`
  — common at TOPIK-tied scholarships.
- `eligibility_predicate` is structured rules (best-effort);
  ALWAYS keep `prose_ko` so counselors have the canonical narrative.
- Mark `extractor_confidence < 0.85` whenever an eligibility window is
  cited (these are difficulty-5 per audit and need HITL).
