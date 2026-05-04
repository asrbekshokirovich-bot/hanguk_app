import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/adaptive/hanguk_scaffold.dart';
import '../../../../design_system/adaptive/hanguk_card.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../data/auth_repository.dart';
import '../../updater/data/updater_repository.dart';
import '../../updater/presentation/update_dialog.dart';

// ─── Login Screen ──────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialMagicCodeMode;

  const LoginScreen({
    super.key,
    this.initialMagicCodeMode = false,
  });

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

  // Sign Up
  final _signUpNameCtrl = TextEditingController();
  final _signUpPhoneCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();
  final _signUpConfirmCtrl = TextEditingController();


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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final repo = ref.read(updaterRepositoryProvider);
    final versionInfo = await repo.checkForUpdate();
    if (versionInfo != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: !versionInfo.forceUpdate,
        builder: (context) => UpdateDialog(updateInfo: versionInfo),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    _signUpNameCtrl.dispose();
    _signUpPhoneCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    _signUpConfirmCtrl.dispose();
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
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (phone.isEmpty || phone.length < 5) {
      _setError('Please enter a valid phone number (e.g. +12345678).');
      return;
    }
    if (password.length < 6) {
      _setError('Password must be at least 6 characters.');
      return;
    }

    _setError(null);
    _setLoading(true);
    final result =
        await ref.read(authRepositoryProvider).signInWithPhone(phone, password);
    _setLoading(false);

    if (result.error != null) {
      _setError('Invalid phone number or password.');
    }
  }

  // ─── Inner Student Log In ────────────────────────────────────────────────────

  Future<void> _handleStudentLogin() async {
    final code = _codeCtrl.text.trim().toUpperCase();

    if (code.length < 6) {
      _setError('Please enter a valid access code (min 6 characters).');
      return;
    }

    _setError(null);
    _setLoading(true);
    final result =
        await ref.read(authRepositoryProvider).signInWithMagicCode(code);
    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
    }
  }

  // ─── Public Student Sign Up (Phone) ─────────────────────────────────────────

  Future<void> _handleSignUp() async {
    final name = _signUpNameCtrl.text.trim();
    final phone = _signUpPhoneCtrl.text.trim();
    final password = _signUpPasswordCtrl.text.trim();
    final confirm = _signUpConfirmCtrl.text.trim();

    if (name.isEmpty) {
      _setError('Full Name is required.');
      return;
    }
    if (phone.isEmpty || phone.length < 5) {
      _setError('A valid phone number is required (e.g. +12345678).');
      return;
    }
    if (password.length < 6) {
      _setError('Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _setError('Passwords do not match.');
      return;
    }

    _setError(null);
    _setLoading(true);
    final result = await ref
        .read(authRepositoryProvider)
        .signUpStudent(phone, password, name);
    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      if (result.isCrmAccount) {
        // Automatically switch to Magic Code Mode
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _isMagicCodeMode = true;
            });
          }
        });
      } else if (result.alreadyRegistered) {
        // Pre-fill phone number in Sign In screen
        _phoneCtrl.text = phone;
        // Automatically switch to Sign In Tab
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _tabController.animateTo(0);
          }
        });
      }
    } else {
      _setSuccess('Account created successfully! Please log in.');
      _signUpPasswordCtrl.clear();
      _signUpConfirmCtrl.clear();
      _tabController.animateTo(0);
    }
  }



  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                  const Text(
                    'Hanguk',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.vibrantLime,
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
                    const Text(
                      'Hanguk',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.vibrantLime,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student Portal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 28),

                  // ── Messages ───────────────────────────────────────────────────
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _success!,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Forms ──────────────────────────────────────────────────────
                  if (_isMagicCodeMode)
                    _buildMagicCodePortal(scheme)
                  else
                    _buildPublicAuthPortal(scheme),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Enter the 8-digit access code provided by your consultant or university representative.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        _HangukTextField(
          controller: _codeCtrl,
          hint: 'XXXXXXXX',
          icon: Icons.key,
          textCapitalization: TextCapitalization.characters,
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
          label: 'Login manually with Access Code',
          loading: _loading,
          onPressed: _handleStudentLogin,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // Optional fallback if user navigated wrong from Welcome Page
            setState(() => _isMagicCodeMode = false);
          },
          child: const Text(
            '← I actually want to Log in via Phone Number',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicAuthPortal(ColorScheme scheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const Icon(Icons.build_circle, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Public sign up and phone login are currently under maintenance as we upgrade our systems.\n\nStudents: Please use your Magic Access Code to log in for now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isMagicCodeMode = true;
                  });
                },
                icon: const Icon(Icons.vpn_key, color: Colors.white, size: 18),
                label: const Text(
                  'Switch to Magic Code Login',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: scheme.primary.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logo({required double size, required double radius}) {
    return ClipRRect(
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
          CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
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

  const _HangukTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: style ?? const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
