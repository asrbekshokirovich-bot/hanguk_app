/// Centralized app configuration constants.
/// All credentials and environment-specific values should live here,
/// not scattered inline throughout the codebase.
class AppConfig {
  AppConfig._(); // Prevent instantiation

  // ── Supabase ─────────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://lysjdtyanhdfphqyijsr.supabase.co';

  /// The Supabase anonymous key. This is intentionally a public key — it is
  /// safe to ship in the client, but should never be a service_role key.
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4NTUxMDYsImV4cCI6MjA4ODQzMTEwNn0.p-WlK-r4xqRk63N6zc_8JCIV53FVmjwAcqK7Lx25GJs';

  // ── Vapi (WebRTC voice AI) ────────────────────────────────────────────────
  /// Public key for the Vapi WebRTC service. Safe to include in client builds.
  static const String vapiPublicKey = '5eb3a0e0-0b4a-4b75-bd3e-18cc95b90b46';

  // ── ElevenLabs voice IDs ─────────────────────────────────────────────────
  // Korean-native voices from the ElevenLabs shared voice library (verified
  // against the public Korean voice catalog). Override at build time with
  // --dart-define=VOICE_ID_KO_<PERSONA>=<id> if you want to swap. If a default
  // ID 404s on your ElevenLabs project (free-tier limits, voice removed),
  // Vapi returns silent dead air rather than a clean error — swap and rebuild.
  //
  // - friendly  → JiYoung   (warm, clear, friendly female)
  // - strict    → Hyun Bin  (cool, professional corporate male)
  // - impatient → KKC       (bright, stable male — clipped delivery)
  static const String voiceIdKoFriendly = String.fromEnvironment(
    'VOICE_ID_KO_FRIENDLY',
    defaultValue: 'AW5wrnG1jVizOYY7R1Oo',
  );
  static const String voiceIdKoStrict = String.fromEnvironment(
    'VOICE_ID_KO_STRICT',
    defaultValue: 's07IwTCOrCDCaETjUVjx',
  );
  static const String voiceIdKoImpatient = String.fromEnvironment(
    'VOICE_ID_KO_IMPATIENT',
    defaultValue: '1W00IGEmNmwmsDeYy7ag',
  );
  // English voices — kept as-is, they work correctly.
  static const String voiceIdEnFriendly = 'nPczCjzI2devNBz1zQrb';
  static const String voiceIdEnStrict = 'pNInz6obbfdqIjc9VDzA';
  static const String voiceIdEnImpatient = 'MF3mGyEYCl7XYWbV9V6O';
}
