import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../updater/data/updater_repository.dart';
import '../../updater/presentation/update_dialog.dart';

/// "Seoul Night" welcome screen — dark navy→black gradient, glass, and a lime
/// action colour, with a guest-mode entry that needs no Magic Code.
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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -1),
            end: Alignment(0.8, 1),
            colors: [
              Color(0xFF1A3A6C),
              Color(0xFF132A4D),
              Color(0xFF0F213D),
              Color(0xFF0A0A1A),
            ],
            stops: [0.0, 0.38, 0.66, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow blobs (pure decoration).
            Positioned(
              top: -120,
              left: -120,
              child: _glow(380, const Color(0xFF406EBE), 0.5),
            ),
            Positioned(
              bottom: -100,
              right: -110,
              child: _glow(360, const Color(0xFFD4E94C), 0.14),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  // ── Hero ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        // 한 tile
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2A4E8C), Color(0xFF16305A)],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 48,
                                offset: const Offset(0, 24),
                              ),
                              BoxShadow(
                                color: const Color(0xFFD4E94C)
                                    .withValues(alpha: 0.12),
                                blurRadius: 0,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '한',
                            style: TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'HANGUK CONSULTING',
                          style: TextStyle(
                            color: Color(0xFFD4E94C),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Xush kelibsiz',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Janubiy Koreya universitetiga yo'lingiz shu yerdan boshlanadi.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '한국으로 가는 길',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  // ── Actions ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                    child: Column(
                      children: [
                        _LimeButton(
                          label: 'Menda sehrli kod bor',
                          onTap: () => context.push(
                            '/login',
                            extra: {'magic_code': true},
                          ),
                        ),
                        const SizedBox(height: 12),
                        _GuestButton(onTap: () => context.push('/guest')),
                        const SizedBox(height: 14),
                        Text(
                          "Kod shart emas — bemalol ko'ring, filtrlang va solishtiring.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size, Color color, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), Colors.transparent],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }
}

class _LimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE2F26A), Color(0xFFC7E04A)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4E94C).withValues(alpha: 0.28),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0A1A34),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: Color(0xFF0A1A34)),
          ],
        ),
      ),
    );
  }
}

class _GuestButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GuestButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Universitetlarni ko'rish",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD4E94C).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFD4E94C).withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                '탐색',
                style: TextStyle(
                  color: Color(0xFFD4E94C),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
