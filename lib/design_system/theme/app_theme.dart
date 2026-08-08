import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// Dark theme is the app's original look; [materialTheme] is kept as an
  /// alias so existing references (e.g. the splash screen) keep working.
  static ThemeData get darkTheme => materialTheme;

  /// Light (day) theme — Royal Blue brand on soft blue-grey surfaces, with
  /// the lime accent kept for CTAs. Navy ink for text so it stays legible.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightGradient.first,
      colorScheme: const ColorScheme.light(
        primary: AppColors.royalBlue,
        onPrimary: Colors.white,
        secondary: AppColors.vibrantLime,
        onSecondary: AppColors.inkNavy,
        surface: AppColors.lightSurface,
        onSurface: AppColors.inkNavy,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.inkNavy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.royalBlue),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vibrantLime,
          foregroundColor: AppColors.inkNavy,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.royalBlue,
          side: BorderSide(color: AppColors.royalBlue.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.royalBlue.withValues(alpha: 0.18),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.royalBlue.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.royalBlue),
        ),
        hintStyle: const TextStyle(color: AppColors.inkNavy60),
        prefixIconColor: AppColors.inkNavy60,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        indicatorColor: AppColors.royalBlue.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.royalBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: AppColors.inkNavy60, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.royalBlue);
          }
          return const IconThemeData(color: AppColors.inkNavy60);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.inkNavy60,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.royalBlue,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.royalBlue.withValues(alpha: 0.10),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  // Material 3 Theme for Android
  static ThemeData get materialTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.pureBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.vibrantLime,
        onPrimary: AppColors.pureBlack,
        secondary: AppColors.royalBlue,
        onSecondary: Colors.white,
        surface: Color(0xFF0F172A), // darkSlate
        onSurface: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.vibrantLime),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vibrantLime,
          foregroundColor: AppColors.pureBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.borderGlass),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceGlass.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderGlass),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderGlass),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.vibrantLime),
        ),
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIconColor: Colors.white70,
      ),
      // Retained for any incidental M2 BottomNavigationBar usage in
      // dialogs / pickers; the home shell now uses M3 NavigationBar via
      // AdaptiveBottomNavigation (UI/UX audit P0 #5, 2026-05-12).
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F213D),
        selectedItemColor: AppColors.vibrantLime,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      // Material 3 NavigationBar styling — colour-matched to the legacy
      // bottomNavigationBarTheme above so the swap is visually
      // continuous. NavigationBar defaults are otherwise tinted from
      // ColorScheme.surfaceContainer / .secondaryContainer which would
      // not match the brand palette.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F213D),
        indicatorColor: AppColors.vibrantLime.withValues(alpha: 0.18),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.vibrantLime,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Colors.white70, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.vibrantLime);
          }
          return const IconThemeData(color: Colors.white70);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.pureBlack,
        unselectedLabelColor: Colors.white54,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.vibrantLime,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceGlass.withValues(alpha: 0.12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderGlass, width: 0.5),
        ),
      ),
    );
  }

  // Cupertino Theme for iOS
  static CupertinoThemeData get cupertinoTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.vibrantLime,
      scaffoldBackgroundColor: AppColors.pureBlack,
      barBackgroundColor: AppColors.pureBlack,
    );
  }
}
