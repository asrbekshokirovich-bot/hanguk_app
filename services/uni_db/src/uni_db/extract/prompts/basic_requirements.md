# basic_requirements field-group extraction prompt (production)

Audit §4.5 / §5.3. Strict JSON schema = [`REQUIREMENTS_SCHEMA`](../schemas.py).
This is the parsing-difficulty 3 group covering TOPIK level, English
test requirements, GPA floor, and interview/practical-exam flags.

## Strict rules

- `applicant_category` is preserved verbatim in Korean
  (e.g. `외국인전형`, `외국인특별전형`, `재외국민특별전형`). Do NOT
  translate.
- `topik_min_level` is integer 1..6 or null. If the document says
  "졸업 전 취득 가능" or "to be acquired before graduation", set
  `topik_deferred=true`.
- `english_test` is a small object such as
  `{"toefl_ibt":80,"ielts":5.5,"teps":297}`. Use null when no English
  test is required.
- `gpa_floor_pct`: the audit's normalised 0..100 percentile. "상위 20%"
  → 80. Plain GPA ("3.0/4.0") → null with a `prose_ko` note explaining
  the source phrasing; the parse_worker validators will route to HITL.
- `interview_required` and `practical_exam_required` are booleans —
  read the calendar fragments earlier in the document if the
  requirements section doesn't restate them.
- ALWAYS preserve the original narrative in `prose_ko`. Counselors rely
  on it to disambiguate when the structured fields disagree with the
  prose.

## Few-shot

**Input**:

```
[지원자격]
- 본인 및 부모 모두 외국 국적 소지자
- 한국어 능력: TOPIK 3급 이상 (입학 전 4급 취득 권장)
- 영어 능력 (해당 학과만): TOEFL iBT 80 이상 또는 IELTS 5.5 이상
- 고등학교 졸업(예정)자
- 면접 실시 (사범대학, 의예과 등)
```

**Output**:

```json
{
  "applicant_category": "외국인전형",
  "topik_min_level": 3,
  "topik_deferred": false,
  "english_test": {"toefl_ibt": 80, "ielts": 5.5},
  "gpa_floor_pct": null,
  "interview_required": true,
  "practical_exam_required": false,
  "prose_ko": "본인 및 부모 모두 외국 국적 소지자. TOPIK 3급 이상(입학 전 4급 취득 권장). 면접은 사범대학, 의예과 등에서 실시.",
  "source_text_ko": "본인 및 부모 모두 외국 국적 소지자\\n한국어 능력: TOPIK 3급 이상 (입학 전 4급 취득 권장)\\n영어 능력 (해당 학과만): TOEFL iBT 80 이상 또는 IELTS 5.5 이상\\n고등학교 졸업(예정)자\\n면접 실시 (사범대학, 의예과 등)",
  "extractor_confidence": 0.86
}
```
