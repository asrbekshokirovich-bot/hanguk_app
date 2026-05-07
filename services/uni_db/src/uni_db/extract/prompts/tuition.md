# tuition field-group extraction prompt

Audit §4.4. One row per (faculty_group, academic_year, semester_number).
Strict JSON schema = `TUITION_SCHEMA` in [schemas.py](../schemas.py).

## Rules

- Amounts are stored in KRW as `bigint`. Strip `원` and commas.
- `faculty_group` must come from the audit §4.4 buckets:
  humanities / social / natural_science / engineering / arts_pe /
  medicine / dentistry / veterinary / pharmacy / theology /
  interdisciplinary.
- `is_first_semester=true` only for the row that includes 입학금.
- `source_text_ko` is the exact row from the table.

If the document references a separate tuition booklet (typical for
archetype A — SNU/KAIST/POSTECH), return `{"rows": []}` and add a note
in the calling worker's HITL queue.
