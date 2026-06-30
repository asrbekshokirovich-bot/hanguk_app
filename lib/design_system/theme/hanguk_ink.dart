import 'package:flutter/material.dart';

/// Hanguk "ink-painting" (수묵화 / hanji) design tokens.
///
/// Source of truth: the `Hanguk App.dc.html` Claude Design prototype.
/// A calm, premium Korean-education palette built on warm hanji paper,
/// sumi (먹) ink, and dancheong (단청) accents — used by the new app shell
/// chrome (ambient background + bottom dock). Kept separate from the legacy
/// [AppColors] navy/lime tokens so existing screens are untouched.
class HangukInk {
  HangukInk._();

  // ---- Hanji paper surfaces ----
  static const Color hanji = Color(0xFFF4EEE2); // warm ivory base
  static const Color paper = Color(0xFFFDFBF6); // raised card surface
  static const Color paperShade = Color(0xFFEFE9DA);

  // Per-screen background tints (Apply / Map / Docs / Train) — subtle, so no
  // two screens read identically, matching the prototype's `tints` array.
  static const List<List<Color>> screenTints = [
    [Color(0xFFF7F2E7), Color(0xFFF1EADB)], // applications — gold-warm
    [Color(0xFFEFF4EF), Color(0xFFE7F0E9)], // map — jade-cool
    [Color(0xFFF8F1ED), Color(0xFFF2E8E4)], // docs — plum-warm
    [Color(0xFFEFF5F1), Color(0xFFE8F1EC)], // training — celadon
  ];

  // ---- Sumi ink (text) ----
  static const Color ink = Color(0xFF2B3A42); // primary text
  static const Color ink2 = Color(0xFF8A8676); // secondary / muted
  static const Color ink3 = Color(0xFF9A9484); // tertiary / faint

  // ---- Dancheong accents ----
  static const Color gold = Color(0xFFD4A24E); // 단청 gold leaf
  static const Color goldDeep = Color(0xFFB5832F);
  static const Color jade = Color(0xFF3FA796); // jade green
  static const Color jadeDeep = Color(0xFF2E8073);
  static const Color plum = Color(0xFFE86A8C); // plum blossom
  static const Color plumDeep = Color(0xFFC4537A);
  static const Color persimmon = Color(0xFFE5734A);
  static const Color violet = Color(0xFF9B7CE0); // AI accent
  static const Color violetDeep = Color(0xFF523A92);

  /// Per-tab accent used by the dock seal-stamp and active dot.
  static const List<Color> tabAccents = [gold, jade, plum, jade];

  /// Soft vertical hanji gradient for a given tab index.
  static LinearGradient screenGradient(int tabIndex) {
    final pair = screenTints[tabIndex.clamp(0, screenTints.length - 1)];
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: pair,
    );
  }

  /// Display heading style (stands in for Noto Serif KR — bold, tight).
  static const TextStyle display = TextStyle(
    color: ink,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.1,
  );

  static const TextStyle overline = TextStyle(
    color: ink3,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
  );
}
