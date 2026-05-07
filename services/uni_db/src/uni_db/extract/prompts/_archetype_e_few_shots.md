# Archetype E — Women's university calibration

Audit §5.2: 35–60 pages, eligibility section explicitly states gender
requirement (female applicants only), often two separate docs
(외국인특별전형 vs 재외국민특별전형), strong scholarship offerings often
in front matter, tuition sometimes routed to a separate file.

## Calibration notes

- The gender requirement MUST be captured. In `basic_requirements`
  output, encode it in `prose_ko` AND set the structured boolean
  `gender_required_female=true` (use a custom property — the schema
  permits any field with `additionalProperties: false` only at top
  level, so we route it through `notes_ko` if absent in schema).
  *Note*: Phase 1 schema doesn't carry gender; for now keep gender in
  `prose_ko` and the parse_worker's HITL gate flags it.
- Front-matter scholarships should NOT be skipped. Extract them even
  if they appear before the main 모집요강 body.
