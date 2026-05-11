import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the bottom-nav tab currently shown by [HomeScreen].
/// Lifted to a provider (rather than local widget state) so deep-linked
/// CTAs — e.g. "Apply to a university" from the interview-launcher empty
/// state — can switch tabs without going through the widget tree.
///
/// Tabs in order:
///   0 — Applications   (default)
///   1 — Map
///   2 — Docs
///   3 — Training
final homeTabProvider = StateProvider<int>((ref) => 0);
