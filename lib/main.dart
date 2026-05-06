import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'design_system/theme/app_theme.dart';
import 'features/updater/presentation/update_gate.dart';
import 'package:device_preview/device_preview.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show a splash while Supabase initializes — prevents ANR on slow emulators
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const _SplashApp(),
    ),
  );

  try {
    await Supabase.initialize(
      url: 'https://lysjdtyanhdfphqyijsr.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4NTUxMDYsImV4cCI6MjA4ODQzMTEwNn0.p-WlK-r4xqRk63N6zc_8JCIV53FVmjwAcqK7Lx25GJs',
    );
  } catch (e) {
    debugPrint('Supabase init error (offline mode): $e');
  }

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const ProviderScope(
        child: HangukApp(),
      ),
    ),
  );
}

/// Lightweight splash shown while Supabase initialises (prevents ANR).
class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialTheme,
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),
      home: const Scaffold(
        backgroundColor: Color(0xFF0A0A1A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: Image(
                  image: AssetImage('assets/images/logo.jpg'),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ],
          ),
        ),
      ),
    );
  }
}

class HangukApp extends ConsumerWidget {
  const HangukApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Hanguk Student App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialTheme,
      routerConfig: goRouter,
      builder: (context, child) {
        // Auto-update gate runs on launch + every foreground transition,
        // so updates aren't gated behind the login screen anymore.
        final wrapped = UpdateGate(child: child ?? const SizedBox.shrink());
        return DevicePreview.appBuilder(context, wrapped);
      },
      locale: DevicePreview.locale(context),
    );
  }
}
