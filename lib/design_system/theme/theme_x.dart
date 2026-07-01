import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware colour helpers so screens read correctly in both day (light)
/// and dark modes without hardcoding `Colors.white`.
///
/// Use `context.onS(0.7)` in place of `Colors.white70`, `context.ink` for
/// primary text, and `context.accentText` for the lime accent used as
/// text/icons (pure lime is illegible on white, so light mode swaps to the
/// darker olive [AppColors.limeInk]).
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Primary on-surface text colour (white in dark, navy in light).
  Color get ink => Theme.of(this).colorScheme.onSurface;

  /// On-surface colour at a given opacity — the theme-aware replacement for
  /// `Colors.white70` / `Colors.white54` / `Colors.white24`, etc.
  Color onS(double alpha) =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: alpha);

  /// The lime accent when used as *text or icon* (legible in both modes).
  Color get accentText => isDark ? AppColors.vibrantLime : AppColors.limeInk;

  /// A translucent card/surface fill that works on either background.
  Color get glassFill =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: isDark ? 0.06 : 0.04);

  /// Hairline border colour for cards/dividers in either mode.
  Color get hairline =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.10);
}
