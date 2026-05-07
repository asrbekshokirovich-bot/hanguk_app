# Archetype C — Regional national plain table calibration

Audit §5.2: 30–50 pages, function-over-form B&W layout, very long
recruitment-unit lists (80–150 units typical), calendar table with many
footnote layers (특정 전공 면접일, 도서관학과 추가 시험 등), embedded
per-faculty tuition table, KO-only common.

## Calibration notes

- Recruitment-unit tables can run for 5+ pages. The parse_worker runs
  `parse.tables.stitch_spans()` to merge them; you receive the stitched
  table as one block. Trust column 0 to be the 단과대학 / 학부 label.
- 정원외 / 정원내 split is critical for these schools — they often have
  large 정원외 outside-quota allocations for foreign applicants. Always
  set `is_in_quota` correctly.
- Footnotes use `※` glyphs heavily. Preserve every footnote's verbatim
  Korean in `notes_ko`.
- KO-only documents — do not attempt translation. `name_en` stays null;
  the translation worker handles it later.
