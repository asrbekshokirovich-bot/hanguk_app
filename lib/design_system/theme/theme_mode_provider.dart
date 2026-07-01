import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// App-wide light/dark theme selection, persisted across launches.
///
/// Defaults to [ThemeMode.dark] (the app's original look) and loads any saved
/// choice asynchronously on startup. Persistence uses [FlutterSecureStorage],
/// already a project dependency, to avoid adding a new package.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'app_theme_mode';
  static const _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    // Kick off the async load; state updates once the stored value arrives.
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _key);
      final restored = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => null,
      };
      if (restored != null) state = restored;
    } catch (_) {
      // Storage unavailable (e.g. locked keystore) — keep the default.
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {
      // Best-effort persistence; the in-memory choice still applies.
    }
  }

  /// Flip between explicit light and dark (used by the header toggle).
  void toggle() =>
      set(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
}
