# requirements field-group extraction prompt

Audit §4.5 / §5.3. Strict JSON schema = [`REQUIREMENTS_SCHEMA`](../schemas.py).
Difficulty 3–4 fields: TOPIK level, English test scores, GPA floor, interview /
practical-exam flags.

## Output shape

Return a top-level object with a single key `rows` — an **array** of
requirement rows. One row per **applicant_category** (e.g. one row for
외국인전형, a separate row for 재외국민전형 if both appear in the same
guideline).

**Critical: when the source span has no requirements information, return
`{"rows": []}` and stop.** Do not invent a row. Do not emit synthetic
fields. Do not include fields from other field groups (`document_type`,
`institution`, `program_level`, `admission_cycles` — these belong to
`documents_required` / `calendar` and will be rejected by the schema).

## Per-row rules

- `applicant_category` is preserved **verbatim in Korean** (e.g.
  `외국인전형`, `외국인특별전형`, `재외국민특별전형`, `정원외 외국인`).
  Do NOT translate. Use the glossary's canonical spelling when ambiguous.
- `topik_min_level` is integer `1..6` or `null`. If the document says
  "졸업 전 취득 가능" or "to be acquired before graduation", set
  `topik_deferred=true` and leave `topik_min_level` at the *target* level.
- `english_test` is `null` when no English test is required. Otherwise an
  object with ONLY these keys (omit any field not mentioned in source):
  `toefl_ibt`, `toefl_pbt`, `ielts`, `teps`, `duolingo`, `cambridge`,
  `other_ko` (free-text escape for tests outside the closed list, e.g.
  CEFR, DELE, JLPT), `deferred` (boolean).
- `gpa_floor_pct` is the **0..100 percentile**. "상위 20%" → `80`.
  Plain GPA ("3.0/4.0") → `null` with a `prose_ko` note explaining the
  source phrasing; HITL will normalize.
- `interview_required` and `practical_exam_required` are booleans. If the
  requirements section doesn't restate them, check the calendar fragment
  earlier in the document.
- `prose_ko`: preserve the original narrative. Counselors rely on it.
- `source_text_ko`: the verbatim Korean span you read for this row.

## Few-shot 1 — single category with structured fields

**Input** (archetype G, KAIST-style guideline):

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
  "rows": [
    {
      "applicant_category": "외국인전형",
      "topik_min_level": 3,
      "topik_deferred": false,
      "english_test": {"toefl_ibt": 80, "ielts": 5.5, "deferred": false},
      "gpa_floor_pct": null,
      "interview_required": true,
      "practical_exam_required": false,
      "prose_ko": "본인 및 부모 모두 외국 국적 소지자. TOPIK 3급 이상(입학 전 4급 취득 권장). 면접은 사범대학, 의예과 등에서 실시.",
      "source_text_ko": "본인 및 부모 모두 외국 국적 소지자\n한국어 능력: TOPIK 3급 이상 (입학 전 4급 취득 권장)\n영어 능력 (해당 학과만): TOEFL iBT 80 이상 또는 IELTS 5.5 이상\n고등학교 졸업(예정)자\n면접 실시 (사범대학, 의예과 등)",
      "extractor_confidence": 0.88
    }
  ]
}
```

## Few-shot 2 — multi-category guideline (two rows)

**Input** (one document with both 외국인 + 재외국민 tracks):

```
[외국인전형 자격]
- 본인 및 부모 모두 외국인
- TOPIK 4급 이상 필수
[재외국민전형 자격]
- 본인 한국 국적, 부모 중 1인 이상 해외 3년 거주
- TOPIK 면제, 단 한국어 면접 실시
```

**Output**:

```json
{
  "rows": [
    {
      "applicant_category": "외국인전형",
      "topik_min_level": 4,
      "topik_deferred": false,
      "english_test": null,
      "gpa_floor_pct": null,
      "interview_required": false,
      "practical_exam_required": false,
      "prose_ko": "본인 및 부모 모두 외국 국적. TOPIK 4급 이상 필수.",
      "source_text_ko": "본인 및 부모 모두 외국인\nTOPIK 4급 이상 필수",
      "extractor_confidence": 0.91
    },
    {
      "applicant_category": "재외국민전형",
      "topik_min_level": null,
      "topik_deferred": false,
      "english_test": null,
      "gpa_floor_pct": null,
      "interview_required": true,
      "practical_exam_required": false,
      "prose_ko": "한국 국적, 부모 1인 이상 해외 3년 거주. TOPIK 면제. 한국어 면접 실시.",
      "source_text_ko": "본인 한국 국적, 부모 중 1인 이상 해외 3년 거주\nTOPIK 면제, 단 한국어 면접 실시",
      "extractor_confidence": 0.86
    }
  ]
}
```

## Few-shot 3 — empty section (marketing PDF, archetype A)

**Input**:

```
2026학년도 외국인 학부 신입학 안내 — 글로벌 인재의 요람 KAIST에서 함께하세요.
원서접수: 2025.09.05 ~ 2025.09.20
```

(No 지원자격 / requirements section anywhere in the document.)

**Output**:

```json
{"rows": []}
```

## Final reminder

Return ONLY the JSON object. No prose, no markdown code fences (` ```json `),
no commentary. The schema rejects any per-row field outside the closed list
above — emitting `document_type`, `institution`, `program_level`,
`admission_cycles`, or other group-bleed fields will fail validation.

## Enrichment per row (per applicant_category / track)

For each requirements row, additionally include when present in the guideline:
- `majors`: string[] — majors / recruitment units open to this track (Korean names).
- `tuition`: { `amount_krw`, `admission_fee_krw`, `academic_year`, `semester_number` } —
  per-track tuition for one semester (integers; null if not stated).
- `english_test`: besides the per-test fields, set the normalised pair:
    - `test`: the PRIMARY required test ("ielts" | "toefl_ibt" | "toefl_pbt" | "teps" |
      "duolingo" | "topik" | "cambridge" | "other")
    - `min_score`: its numeric minimum (IELTS 6.0 -> 6.0; TOEFL iBT 80 -> 80)
    - `deferred`: true if it may be submitted after admission
  Always capture the numeric band when a score is stated — never emit just
  {"deferred": false} when the guideline gives a required score.
