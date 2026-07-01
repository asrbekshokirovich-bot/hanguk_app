import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/theme_mode_provider.dart';
import 'liquid_glass.dart';

/// Frosted "liquid glass" toggle that flips between light (day) and dark modes
/// and persists the choice via [themeModeProvider]. Shows a sun in dark mode
/// (tap → go light) and a moon in light mode (tap → go dark).
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return Semantics(
      button: true,
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: LiquidGlass(
          radius: 12,
          onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 19,
              color: isDark ? AppColors.vibrantLime : AppColors.royalBlue,
            ),
          ),
        ),
      ),
    );
  }
}
