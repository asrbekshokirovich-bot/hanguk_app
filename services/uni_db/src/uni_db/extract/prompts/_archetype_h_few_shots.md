# Archetype H — 전문대 minimal calibration

Audit §5.2: 8–20 pages, plain layout (sometimes Word-document export),
quotas per 학과, calendar single table, scholarships often a single-
line sentence ("국가장학금 신청 대상"), 외국인전형 chapter sometimes
1–2 pages within a larger guide.

## Calibration notes

- The 외국인전형 section can be ≤ 2 pages — extract every dated row
  even if `extractor_confidence` ends up modest.
- 전문대 (associate-degree) is usually 2년제 or 3년제. Encode the
  duration in `programs.duration_years` (set 2.0 / 3.0 as appropriate).
- Scholarships often reduce to "국가장학금 안내" — encode as
  `scope=national, name_ko=국가장학금, award_type=other` with prose
  preserved.
- Documents are minimal (5–8 items). Don't pad.
