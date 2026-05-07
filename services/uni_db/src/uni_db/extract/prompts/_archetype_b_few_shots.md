# Archetype B — Top Seoul private brochure-style calibration

Audit §5.2: 50–80 pages, glossy first 5–8 pages, recruitment units
organised by 단과대학, calendar in a single tabular page near the front,
embedded tuition tables (faculty-grouped, sometimes with 1학기 vs 2학기
split), bilingual side-by-side but English often abridged.

## Calibration notes

- Skip the first 5–8 marketing pages. They contain "왜 본교를 선택했나"
  prose that should NOT be extracted as a requirement or a recruitment
  unit. The calendar / tuition / unit-list section starts after the
  marketing block.
- Faculty-group classification is straightforward (인문 / 사회 / 자연 /
  공학 / 예체능). Map per audit §4.4.
- 단과대학 → 학부 → 학과 hierarchy is fully populated. Always emit the
  parent 단과대학 in `faculty_ko`.
- 1학기 = `is_first_semester=true` and includes 입학금. The 2학기 row
  excludes it (the brochure usually says "(입학금 별도)" — check the
  footnote).
