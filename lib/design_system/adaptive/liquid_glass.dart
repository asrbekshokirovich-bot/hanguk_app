import 'package:flutter/material.dart';
import '../theme/theme_x.dart';

/// "Liquid glass" surface from the final Hanguk design: a frosted tile with a
/// glossy top highlight and soft inset/drop shadows, adapting to light/dark.
///
/// Wrap a small interactive element (icon tile, pill, CTA) to give it the
/// iOS-style liquid-glass sheen. The [child] is painted above the gloss.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color? tint;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 14,
    this.tint,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final br = BorderRadius.circular(radius);
    final base = tint ?? context.onS(dark ? 0.08 : 0.05);

    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: base,
        borderRadius: br,
        border: Border.all(color: context.onS(dark ? 0.16 : 0.12)),
        boxShadow: [
          // Glossy inner top edge + soft outer drop.
          BoxShadow(
            color: Colors.white.withValues(alpha: dark ? 0.10 : 0.55),
            blurRadius: 1,
            offset: const Offset(0, 1.4),
            spreadRadius: -0.5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.14),
            blurRadius: dark ? 14 : 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top highlight sheen (the "liquid" glare).
          Positioned(
            top: 1,
            left: 3,
            right: 3,
            height: radius * 2.4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius),
                  bottom: Radius.circular(radius * 3),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: dark ? 0.18 : 0.42),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    if (onTap == null) return surface;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: surface,
    );
  }
}
