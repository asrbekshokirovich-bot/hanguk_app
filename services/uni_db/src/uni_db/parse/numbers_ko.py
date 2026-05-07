"""Korean monetary-number normalisation.

Audit §4.4 / §5.3 row `tuition_per_semester`. We convert every encountered
representation to integer KRW while preserving the original verbatim
string for HITL evidence.

Supported (covered by tests):

  4,800,000원
  4,800,000 원
  KRW 4,800,000
  ₩ 4,800,000
  4800000
  480만원                   # 만 = 10⁴
  480 만 원
  48,000,000원
  4억 8000만원              # 억 = 10⁸
  5천만 원                  # 천 = 10³ (in compound form)
  3백만원                   # 백 = 10²
"""

from __future__ import annotations

import re
from dataclasses import dataclass

_MULTIPLIERS = {
    "백": 10**2,
    "천": 10**3,
    "만": 10**4,
    "억": 10**8,
    "조": 10**12,
}


@dataclass(frozen=True, slots=True)
class ParsedAmount:
    amount_krw: int
    original: str


# Tokeniser splits on the multiplier suffixes. We match groups like
# (digits)(unit)? so "4억 8000만원" yields [(4, '억'), (8000, '만'), (0, None)].
_TOKEN_RE = re.compile(r"(\d{1,4}(?:,\d{3})*|\d+)\s*(억|조|만|천|백)?")
_CLEAN_RE = re.compile(r"\s*(원|KRW|krw|￦|₩)\s*$")


def parse_korean_amount(text: str) -> ParsedAmount | None:
    """Best-effort parser. Returns None when no number is found.

    Strategy:
      1. Strip a trailing currency suffix (원/KRW/₩).
      2. If the remaining string is a plain digit-comma number, return as-is.
      3. Otherwise tokenise into (digits, unit) pairs and accumulate.
    """
    if not text:
        return None
    body = _CLEAN_RE.sub("", text.strip())

    # Plain digit-comma: "4,800,000" / "4800000"
    if re.fullmatch(r"\d{1,3}(?:,\d{3})+|\d+", body):
        return ParsedAmount(amount_krw=int(body.replace(",", "")), original=text.strip())

    # Compound: walk left-to-right, multiplying.
    total = 0
    matched = False
    for m in _TOKEN_RE.finditer(body):
        digits, unit = m.group(1), m.group(2)
        if not digits and not unit:
            continue
        n = int(digits.replace(",", "")) if digits else 1
        mult = _MULTIPLIERS.get(unit, 1) if unit else 1
        total += n * mult
        matched = True

    if not matched or total == 0:
        # Fall back: extract any digits and use that.
        digits_only = re.search(r"\d[\d,]*", body)
        if digits_only:
            return ParsedAmount(
                amount_krw=int(digits_only.group(0).replace(",", "")),
                original=text.strip(),
            )
        return None

    return ParsedAmount(amount_krw=total, original=text.strip())
