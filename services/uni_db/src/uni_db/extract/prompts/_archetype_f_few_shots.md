# Archetype F — Specialized art/music/PE calibration

Audit §5.2: 40–80 pages, heavy 실기고사 (audition / practical exam)
emphasis with discipline-by-discipline pages (required pieces, recording
specs, evaluation rubrics), per-discipline quotas, per-discipline
tuition (vocal vs instrumental vs composition), calendar with multiple
discipline-specific exam dates.

## Calibration notes

- Audition specs are unstructured prose with technical terms (key
  signatures, etudes, etc.). Treat as free text → keep `prose_ko` and
  preserve `source_text_ko` verbatim. Do NOT try to schematise into
  structured rules.
- `practical_exam_required=true` for every recruitment unit in this
  archetype. The calendar emits multiple `practical_exam` events — one
  per discipline.
- Tuition is per-discipline (예: 성악 vs 작곡). The schema's
  `faculty_group=arts_pe` is fine for all, but preserve discipline in
  `recruitment_unit.major_track_ko` so counselors can drill in.
