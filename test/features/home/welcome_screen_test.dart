// P2 #50 — Welcome screen smoke test.
//
// Pumps the WelcomeScreen inside a ProviderScope + MaterialApp.router
// wired to a minimal GoRouter so the `context.go(...)` calls inside
// the screen don't blow up. We only assert that the widget instantiates.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguk_app/features/home/presentation/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders without crashing', (tester) async {
    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // The Scaffold inside WelcomeScreen has a Container with the gradient.
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
