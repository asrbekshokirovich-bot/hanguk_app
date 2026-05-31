/// Feature flag for the public phone-number auth path (sign up + phone
/// login).
///
/// Default `false`: phone auth is **not** finished, and shipping a visible
/// "Coming Soon / under construction" entry point trips App Store review
/// (Apple 2.1) and reads as a broken first impression (audit A2/S2). While
/// this is off, Magic Code is the single, finished primary login path and the
/// phone UI is hidden entirely — not stubbed.
///
/// Flip on (when the phone flow is actually wired up and tested) with:
///   --dart-define=PHONE_AUTH_ENABLED=true
const bool kPhoneAuthEnabled = bool.fromEnvironment(
  'PHONE_AUTH_ENABLED',
  defaultValue: false,
);
