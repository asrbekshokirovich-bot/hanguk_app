# Archetype D — Faith-affiliated / mid-private calibration

Audit §5.2: 20–50 pages, mission-statement page early, narrative prose
more frequent than competitors, scholarship tables emphasise religious-
merit awards alongside academic, quotas often less granular (sometimes
collapse to 단과대학 level only).

## Calibration notes

- The mission/chaplaincy page is NOT a recruitment-units source —
  ignore it.
- Scholarship rows often carry religious-eligibility predicates
  (예: 기독교인, 신학과 우대). Encode them in
  `eligibility_predicate.religion` when present, but ALWAYS keep the
  prose verbatim — counselors flag this for HITL.
- Some D-archetype docs (Sogang, Dongguk) split spring/fall in the same
  document. Emit ONLY the events for the cycle the parse_worker is
  targeting; the worker passes the cycle context in `source_text_ko`.
