import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/feature_flags/phone_auth_flag.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../updater/data/updater_repository.dart';
import '../../updater/presentation/update_dialog.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final repo = ref.read(updaterRepositoryProvider);
    final versionInfo = await repo.checkForUpdate();
    if (!mounted) return;
    if (versionInfo is UpdateAvailable) {
      showDialog(
        context: context,
        barrierDismissible: !versionInfo.effectivelyForced,
        builder: (context) => const UpdateDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.royalBlue,
              Color(0xFF132A4D), // primary/90
              Color(0xFF0F213D), // primary/80
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      color: Colors.white,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // Decorative — wordmark next to it carries the
                        // brand for assistive tech.
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Hanguk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Hero Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors
                            .white, // Added white background so the JPEG blends in
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.vibrantLime.withValues(alpha: 0.3),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        // Decorative — the "Hanguk Consulting" headline
                        // immediately below carries the brand identity.
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        'Hanguk Consulting',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.welcomeTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Actions — Magic Code is the single, confident primary
                    // path. Phone auth is hidden behind a feature flag (off)
                    // until it is real, so no "Coming Soon" button ships
                    // (audit A2/S2).
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.push('/login', extra: {'magic_code': true}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vibrantLime,
                          foregroundColor: AppColors.pureBlack,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.workspace_premium, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.welcomeMagicCodeButton,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (kPhoneAuthEnabled)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => context.push('/login'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            foregroundColor: Colors.white.withValues(alpha: 0.7),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Log In / Sign Up with Phone Number',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        l10n.getCodeFromConsultant,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
