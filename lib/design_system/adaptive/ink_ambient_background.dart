import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/hanguk_ink.dart';

/// Calm, breathing ink-painting backdrop from the `Hanguk App.dc.html`
/// prototype: drifting sumi clouds, a softly breathing moon-jar, and a few
/// cherry-blossom petals falling on a slow loop.
///
/// Purely decorative and non-interactive (`IgnorePointer`); it tints itself
/// per [tabIndex] so each screen feels distinct yet harmonious. Drop it as the
/// bottom layer of a [Stack] behind screen content.
class InkAmbientBackground extends StatefulWidget {
  /// Which main tab is active (0..3) — drives the subtle background tint.
  final int tabIndex;

  const InkAmbientBackground({super.key, this.tabIndex = 0});

  @override
  State<InkAmbientBackground> createState() => _InkAmbientBackgroundState();
}

class _InkAmbientBackgroundState extends State<InkAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // Petal seeds: (startXFraction, sizePx, duration, phaseSeed, drift, color)
  static const _petals = <_Petal>[
    _Petal(0.22, 26, 9, 0.0, 40, Color(0x99E86A8C)),
    _Petal(0.48, 20, 11, 0.4, 30, Color(0x94D4A24E)),
    _Petal(0.68, 28, 8, 0.7, 46, Color(0x8C9B7CE0)),
    _Petal(0.12, 22, 12, 0.2, 34, Color(0x80D4A24E)),
    _Petal(0.85, 24, 10, 0.85, 38, Color(0x80E86A8C)),
  ];

  @override
  void initState() {
    super.initState();
    // One long, gently looping clock; the painter derives all motion from it.
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: HangukInk.screenGradient(widget.tabIndex),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _InkPainter(t: _c.value * 60),
            ),
          ),
        ),
      ),
    );
  }
}

class _Petal {
  final double x;
  final double size;
  final double dur;
  final double seed;
  final double drift;
  final Color color;
  const _Petal(this.x, this.size, this.dur, this.seed, this.drift, this.color);
}

class _InkPainter extends CustomPainter {
  /// Elapsed seconds.
  final double t;
  const _InkPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ---- Drifting ink clouds ----
    _cloud(canvas, w * -0.1 + math.sin(t * 0.12) * 40,
        h * 0.12 + math.cos(t * 0.1) * 12, 170, 0x100F2225);
    _cloud(canvas, w * 0.6 + math.sin(t * 0.12 + 2) * 40,
        h * 0.46 + math.cos(t * 0.1 + 1) * 12, 150, 0x0D2B3A42);

    // ---- Breathing moon-jar ----
    final breathe = 0.55 + 0.35 * (0.5 + 0.5 * math.sin(t * 0.7));
    final moonCenter = Offset(w + 10, 120);
    canvas.drawCircle(
      moonCenter,
      100,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.6 * breathe),
            HangukInk.hanji.withValues(alpha: 0.1 * breathe),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 0.78],
        ).createShader(Rect.fromCircle(center: moonCenter, radius: 100)),
    );

    // ---- Falling petals ----
    for (final p in _InkAmbientBackgroundState._petals) {
      final prog = ((t / p.dur) + p.seed) % 1.0;
      final px = w * p.x + math.sin(prog * math.pi * 2 * 2 + p.seed * 6) * p.drift;
      final py = (prog * 1.18 - 0.08) * h;
      final opacity = prog < 0.08
          ? prog * 9
          : prog > 0.92
              ? (1 - prog) * 9
              : 0.72;
      final rot = (t * 50 / 57.3) + p.seed * 6.28;
      _petal(canvas, Offset(px, py), p.size, rot,
          p.color.withValues(alpha: p.color.a * opacity.clamp(0.0, 1.0)));
    }
  }

  void _cloud(Canvas canvas, double cx, double cy, double r, int argb) {
    canvas.drawCircle(
      Offset(cx + r, cy + r * 0.55),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Color(argb), Colors.transparent],
        ).createShader(
            Rect.fromCircle(center: Offset(cx + r, cy + r * 0.55), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _petal(Canvas canvas, Offset c, double s, double rot, Color color) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final k = s / 20.0;
    // Petal path mirrors the prototype's "M10 2 C13 5 13 9 10 12 ..." teardrop.
    final path = Path()
      ..moveTo(0, -8 * k)
      ..cubicTo(3 * k, -5 * k, 3 * k, -1 * k, 0, 2 * k)
      ..cubicTo(-3 * k, -1 * k, -3 * k, -5 * k, 0, -8 * k)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InkPainter old) => old.t != t;
}
