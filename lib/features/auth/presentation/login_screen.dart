import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/feature_flags/phone_auth_flag.dart';
import '../../../../design_system/adaptive/hanguk_scaffold.dart';
import '../../../../design_system/adaptive/hanguk_card.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

// ─── Login Screen ──────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialMagicCodeMode;

  const LoginScreen({super.key, this.initialMagicCodeMode = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Sign In
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  late bool _isMagicCodeMode;

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _isMagicCodeMode = widget.initialMagicCodeMode;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _setError(null);
        _setSuccess(null);
      }
    });
    // Update checks moved to `UpdateGate` (wraps MaterialApp.builder), so
    // they fire on every app launch + foreground transition, not just from
    // this screen.
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _setError(String? msg) => setState(() {
    _error = msg;
    if (msg != null) _success = null;
  });

  void _setSuccess(String? msg) => setState(() {
    _success = msg;
    if (msg != null) _error = null;
  });

  void _setLoading(bool v) => setState(() => _loading = v);

  // ─── Public Student Log In (Phone) ──────────────────────────────────────────

  Future<void> _handlePhoneLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (phone.isEmpty || phone.length < 5) {
      _setError(l10n.loginErrorInvalidPhone);
      return;
    }
    if (password.length < 6) {
      _setError(l10n.loginErrorPasswordTooShort);
      return;
    }

    _setError(null);
    _setLoading(true);
    final result = await ref
        .read(authRepositoryProvider)
        .signInWithPhone(phone, password);
    _setLoading(false);

    if (result.error != null) {
      _setError(l10n.loginErrorInvalidCredentials);
    }
  }

  // ─── Inner Student Log In ────────────────────────────────────────────────────

  Future<void> _handleStudentLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim().toUpperCase();

    if (code.length < 6) {
      _setError(l10n.loginErrorInvalidAccessCode);
      return;
    }

    _setError(null);
    _setLoading(true);
    final result = await ref
        .read(authRepositoryProvider)
        .signInWithMagicCode(code);
    _setLoading(false);

    if (result.error != null) {
      // Server-side error string passes through unchanged; the
      // auth_repository normalizes it for display.
      _setError(result.error);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return HangukScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────────
              Row(
                children: [
                  _logo(size: 40, radius: 10),
                  const SizedBox(width: 12),
                  // Brand name — intentionally not localized.
                  // A5 — wordmark is white on dark everywhere; lime is
                  // reserved for actions/active states.
                  const Text(
                    'Hanguk',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ── Card ─────────────────────────────────────────────────────────────
              HangukCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    _logo(size: 72, radius: 18),
                    const SizedBox(height: 16),
                    // Brand name — intentionally not localized.
                    const Text(
                      'Hanguk',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.loginStudentPortal,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Messages ───────────────────────────────────────────────────
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFFCA5A5), // light-red, AA on dark
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_success != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _success!,
                          style: const TextStyle(
                            color: Color(0xFF86EFAC), // light-green, AA on dark
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Forms ──────────────────────────────────────────────────────
                    // A2 — Magic Code is the finished primary path. Phone auth
                    // is hidden behind a feature flag (off) until it is real, so
                    // no "Coming Soon" UI is reachable in the normal flow.
                    if (_isMagicCodeMode || !kPhoneAuthEnabled)
                      _buildMagicCodePortal(scheme)
                    else
                      _buildPublicAuthPortal(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagicCodePortal(ColorScheme scheme) {
    final l10n = AppLocalizations.of(context)!;
    // AutofillGroup lets iOS surface the OTP autofill chip and Android
    // group the credential for save-prompt purposes (audit P0 #3).
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              l10n.loginAccessCodeHelp,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          _HangukTextField(
            controller: _codeCtrl,
            // Mask: code shape is enforced by the inputFormatters; not
            // localized.
            hint: 'XXXXXXXX',
            icon: Icons.key,
            textCapitalization: TextCapitalization.characters,
            // OTP autofill: surfaces SMS-code suggestions on iOS QuickType
            // and triggers the Android one-time-code retriever.
            autofillHints: const [AutofillHints.oneTimeCode],
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleStudentLogin(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(
              letterSpacing: 6,
              fontFamily: 'monospace',
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _HangukButton(
            label: l10n.loginAccessCodeButton,
            loading: _loading,
            onPressed: _handleStudentLogin,
          ),
          const SizedBox(height: 12),
          // When phone auth is enabled, offer the fallback to it. Otherwise
          // show a quiet helper telling students where to get their code
          // (replaces the removed "Coming Soon" UI).
          if (kPhoneAuthEnabled)
            TextButton(
              onPressed: () {
                // Optional fallback if user navigated wrong from Welcome Page
                setState(() => _isMagicCodeMode = false);
              },
              child: Text(
                l10n.loginSwitchToPhone,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          else
            Text(
              l10n.getCodeFromConsultant,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
        ],
      ),
    );
  }

  // Phone login form — only reachable when `kPhoneAuthEnabled` is true. The
  // previous "Coming Soon / under construction" card was removed (audit A2):
  // it tripped App Store review and read as a broken first impression.
  Widget _buildPublicAuthPortal() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HangukTextField(
          controller: _phoneCtrl,
          hint: '+998 90 123 45 67',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _HangukTextField(
          controller: _passwordCtrl,
          hint: '••••••',
          icon: Icons.lock,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handlePhoneLogin(),
        ),
        const SizedBox(height: 16),
        _HangukButton(
          label: l10n.loginAccessCodeButton,
          loading: _loading,
          onPressed: _handlePhoneLogin,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isMagicCodeMode = true;
            });
          },
          icon: const Icon(Icons.vpn_key, color: Colors.white, size: 18),
          label: Text(
            l10n.loginSwitchToMagicCode,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _logo({required double size, required double radius}) {
    // Brand logo is purely decorative — the "Hanguk" wordmark next to it
    // already conveys the brand to assistive tech, so we exclude the image
    // to prevent screen readers from announcing the file name.
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/logo.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: const Icon(Icons.school, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text('Loading...', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _HangukTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  // Accessibility / autofill plumbing — see WCAG 2.2 + audit P0 #3.
  // Passing these enables iOS QuickType, Android Autofill, and OTP
  // surface bar suggestions on the magic-code field.
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  const _HangukTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.style,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: style ?? const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _HangukButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _HangukButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.black, // Dark text on Lime background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
