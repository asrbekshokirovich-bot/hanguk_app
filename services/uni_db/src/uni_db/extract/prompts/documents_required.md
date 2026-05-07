# documents_required field-group extraction prompt

Audit §5.3 row `documents_required[]` (difficulty 4). Strict JSON schema
= `DOCUMENTS_REQUIRED_SCHEMA`.

## Rules

- One row per `(applicant_category, document_type)`.
- `document_type` uses the canonical 15-item registry — see
  `lib/features/documents/domain/document_type.dart` (Flutter side, kept
  in sync). Examples: `transcript`, `diploma`, `passport`, `sop`, `lor`,
  `financial_proof`, `health_check`, `apostille_certificate`, etc.
- `is_apostille_required`: true for foreign-issued docs in 95% of cases.
- `country_specific` is a JSON map keyed by ISO-3166 alpha-2:
  `{"CN":{"notarization":true},"UZ":{"consular":true}}`.
- Preserve all footnotes verbatim in `notes_ko`.
