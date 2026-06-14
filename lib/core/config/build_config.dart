/// Compile-time flag for the distribution channel.
///
/// Set `STORE_BUILD=true` when building for Google Play or the Apple
/// App Store. On Android, pair it with the `store` product flavor so the
/// merged manifest drops `REQUEST_INSTALL_PACKAGES`:
///
///   flutter build appbundle --release --flavor store \
///       --dart-define=STORE_BUILD=true
///   flutter build ipa       --release --dart-define=STORE_BUILD=true
///
/// Default (`false`) + the `direct` flavor keeps the self-distribution
/// flow alive (the auto-updater downloads + installs APKs from Supabase
/// Storage, which is incompatible with both store policies):
///
///   flutter build apk --release --flavor direct
///
/// When [kIsStoreBuild] is true:
///   - The in-app auto-updater (`UpdateGate`) is bypassed at the
///     `MaterialApp.builder` level (see `main.dart`).
///   - `UpdaterRepository.downloadAndInstall` fails fast instead of
///     calling into the `install_plugin` install path (defense in depth;
///     the `store` flavor's manifest lacks the install permission anyway).
///
/// Two defenses, by design: the Android `store` flavor guarantees Play
/// compliance at the *manifest* level (the only thing Play statically
/// scans), while this *runtime* flag neutralizes the updater behavior.
const bool kIsStoreBuild = bool.fromEnvironment(
  'STORE_BUILD',
  defaultValue: false,
);
