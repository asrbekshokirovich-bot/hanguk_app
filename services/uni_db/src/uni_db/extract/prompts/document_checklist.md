# document_checklist field-group extraction prompt (production)

Audit §4.7. Strict JSON schema = [`DOCUMENTS_REQUIRED_SCHEMA`](../schemas.py).
Difficulty-4: country-specific apostille routing is the trap.

## Strict rules

- One row per `(applicant_category, document_type)`.
- `document_type` uses the canonical enum (kept in sync with
  `lib/features/documents/domain/document_type.dart`):
  `application_form`, `personal_statement`, `study_plan`,
  `hs_diploma`, `hs_transcript`, `nationality_proof_self`,
  `nationality_proof_parents`, `family_relationship_cert`,
  `topik_certificate`, `english_test`, `recommendation_letter`,
  `bank_balance_cert`, `sponsor_bank_statement`, `photo`,
  `application_fee_receipt`.
- `is_apostille_required`: true for any foreign-issued document by
  default (audit §4.7).
- `country_specific`: ISO-3166 alpha-2 keyed object. Encode the
  country-specific gotchas the audit calls out:
  - `CN`: `{ "notarization": true, "chesicc_required": true }`
  - `VN`: `{ "consular_legalization": true, "apostille": false }` (Vietnam
    only joined the convention recently — older PDFs still ask for
    consular).
  - `UZ`: `{ "consular_legalization": true, "apostille": false }`.
  - `RU`/CIS: `{ "apostille": true, "translation_notarized": true }`.
  - `CA`: `{ "apostille": true }` (post-2024-01-11; pre-2024 docs may
    still reference consular).
- `notes_ko` carries the verbatim Korean footnote.

## Few-shot

**Input**:

```
[제출서류]
1. 입학원서 (온라인 출력본)
2. 자기소개서 및 학업계획서
3. 고등학교 졸업증명서 (아포스티유 또는 영사확인 필수)
4. 고등학교 성적증명서 (동일)
5. 본인 국적증명서 (여권 사본 가능)
6. 부모 국적증명서 (양친 모두)
7. 가족관계증명서 (아포스티유)
8. TOPIK 성적표 (해당 시)
9. 추천서 1부
10. 잔고증명서 (USD 20,000 이상)
※ 중국 학력 서류는 인증서가 추가로 필요합니다.
```

**Output**:

```json
{
  "rows": [
    {"applicant_category":"외국인전형","document_type":"application_form",
     "is_required":true,"is_apostille_required":false,
     "source_text_ko":"입학원서 (온라인 출력본)"},
    {"applicant_category":"외국인전형","document_type":"personal_statement",
     "is_required":true,"is_apostille_required":false,
     "source_text_ko":"자기소개서 및 학업계획서"},
    {"applicant_category":"외국인전형","document_type":"hs_diploma",
     "is_required":true,"is_apostille_required":true,
     "country_specific":{"CN":{"notarization":true,"chesicc_required":true}},
     "notes_ko":"중국 학력 서류는 인증서가 추가로 필요",
     "source_text_ko":"고등학교 졸업증명서 (아포스티유 또는 영사확인 필수)"},
    {"applicant_category":"외국인전형","document_type":"hs_transcript",
     "is_required":true,"is_apostille_required":true,
     "country_specific":{"CN":{"notarization":true,"chesicc_required":true}},
     "source_text_ko":"고등학교 성적증명서 (동일)"},
    {"applicant_category":"외국인전형","document_type":"nationality_proof_self",
     "is_required":true,"is_apostille_required":false,
     "source_text_ko":"본인 국적증명서 (여권 사본 가능)"},
    {"applicant_category":"외국인전형","document_type":"nationality_proof_parents",
     "is_required":true,"is_apostille_required":false,
     "source_text_ko":"부모 국적증명서 (양친 모두)"},
    {"applicant_category":"외국인전형","document_type":"family_relationship_cert",
     "is_required":true,"is_apostille_required":true,
     "source_text_ko":"가족관계증명서 (아포스티유)"},
    {"applicant_category":"외국인전형","document_type":"topik_certificate",
     "is_required":false,"is_apostille_required":false,
     "source_text_ko":"TOPIK 성적표 (해당 시)"},
    {"applicant_category":"외국인전형","document_type":"recommendation_letter",
     "is_required":true,"is_apostille_required":false,
     "source_text_ko":"추천서 1부"},
    {"applicant_category":"외국인전형","document_type":"bank_balance_cert",
     "is_required":true,"is_apostille_required":false,
     "source_text_ko":"잔고증명서 (USD 20,000 이상)"}
  ]
}
```
