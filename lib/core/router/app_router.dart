import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/data/auth_repository.dart';

part 'app_router.g.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    routes: $appRoutes,
    redirect: (context, state) {
      final isLoading = authStateAsync.isLoading;
      final isAuthenticated = authStateAsync.value?.session != null;
      
      final isGoingToLogin = state.uri.toString() == '/login';
      final isGoingToWelcome = state.uri.toString() == '/welcome';

      if (isLoading) return null;

      if (!isAuthenticated && !isGoingToLogin && !isGoingToWelcome) {
        return '/welcome';
      }

      if (isAuthenticated && (isGoingToLogin || isGoingToWelcome)) {
        return '/';
      }

      return null;
    },
  );
});

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

@TypedGoRoute<WelcomeRoute>(path: '/welcome')
class WelcomeRoute extends GoRouteData with $WelcomeRoute {
  const WelcomeRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) => const WelcomeScreen();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    final extra = state.extra as Map<String, dynamic>?;
    final isMagicCode = extra?['magic_code'] as bool? ?? false;
    return LoginScreen(initialMagicCodeMode: isMagicCode);
  }
}
