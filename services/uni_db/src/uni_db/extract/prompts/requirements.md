# requirements field-group extraction prompt

Audit §5.3 difficulty 3–4 fields. Strict JSON schema = `REQUIREMENTS_SCHEMA`.

## Rules

- `applicant_category` MUST be the Korean string verbatim — do not
  translate. Examples: 외국인전형, 외국인특별전형, 재외국민특별전형.
- `topik_min_level`: integer 1..6 or null. If the document says "graduate
  acquisition acceptable", set `topik_deferred=true`.
- `english_test`: object such as `{"toefl_ibt":80,"ielts":5.5,"teps":297}`.
  null if no English test required.
- `gpa_floor_pct`: percentile 0..100 if specified ("top 20%" → 80.0).
  Plain GPA (e.g. "3.0/4.0") is converted to a percentile via the standard
  audit §5.3 mapping; if unsure, leave null and flag low confidence.
- Always preserve `prose_ko` for the original narrative — counselors rely on it.
