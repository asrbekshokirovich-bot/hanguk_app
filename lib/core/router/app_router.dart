import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../feature_flags/uni_db_flag.dart';
import '../../features/uni_db/presentation/application_tracker_screen.dart';
import '../../features/uni_db/presentation/institution_compare_screen.dart';
import '../../features/uni_db/presentation/institution_detail_screen.dart';
import '../../features/uni_db/presentation/notification_settings_screen.dart';

part 'app_router.g.dart';

// University DB routes (plan §H.3) — only registered when the
// `UNI_DB_ENABLED` compile-time flag is true. Kept as plain GoRoute
// entries so flipping the flag does not require running build_runner.
List<RouteBase> _uniDbRoutes() => [
      GoRoute(
        path: '/institutions/compare',
        builder: (context, state) {
          final raw = state.uri.queryParameters['ids'] ?? '';
          final ids = raw
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
          return InstitutionCompareScreen(ids: ids);
        },
      ),
      GoRoute(
        path: '/institutions/:id',
        builder: (context, state) => InstitutionDetailScreen(
          institutionId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/applications/tracker',
        builder: (context, state) => const ApplicationTrackerScreen(),
      ),
      GoRoute(
        path: '/notifications/settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
    ];

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      ...$appRoutes,
      if (kUniDbEnabled) ..._uniDbRoutes(),
    ],
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
