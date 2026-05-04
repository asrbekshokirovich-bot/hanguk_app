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
}
