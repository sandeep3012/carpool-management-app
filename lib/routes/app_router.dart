import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_names.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_state_provider.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/shell/presentation/pages/main_shell_page.dart';
import '../features/shell/presentation/pages/placeholder_page.dart';
import '../features/trips/presentation/pages/trips_calendar_page.dart';
import '../features/trips/presentation/pages/trip_detail_page.dart';
import '../features/settlements/presentation/pages/settlements_page.dart';

// ── Error page ────────────────────────────────────────────────────────────────

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Something went wrong')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error?.toString() ?? 'An unexpected error occurred.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ── Router provider ───────────────────────────────────────────────────────────

/// Top-level [GoRouter] instance.
///
/// ## Auth-aware redirect rules
/// | Location            | Auth?  | Action                     |
/// |---------------------|--------|----------------------------|
/// | /splash             | any    | Allow (initial load)        |
/// | any                 | no     | Redirect → /login           |
/// | /login or /home     | yes    | Redirect → /home/dashboard  |
/// | everything else     | yes    | Allow                       |
///
/// ## Shell structure
/// [StatefulShellRoute.indexedStack] mounts four branches under a single
/// [MainShellPage] scaffold so the [NavigationBar] persists across tabs.
/// Each branch owns its own navigation stack; switching tabs preserves
/// scroll position, loaded data, and any in-progress animations.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,

    // ── Global auth redirect ────────────────────────────
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;

      // Splash always runs uninterrupted
      if (location == RouteNames.splash) return null;

      // Unauthenticated: allow only the login screen
      if (!isAuthenticated) {
        return location == RouteNames.login ? null : RouteNames.login;
      }

      // Authenticated: redirect away from auth screens and bare /home
      if (location == RouteNames.login || location == RouteNames.home) {
        return RouteNames.dashboard;
      }

      return null;
    },

    routes: [
      // ── Auth routes ────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Main navigation shell ──────────────────────────
      //
      // StatefulShellRoute.indexedStack keeps each branch alive in an
      // IndexedStack, preserving scroll positions and provider state
      // without any manual KeepAlive wiring in the child pages.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          // ── Branch 0: Dashboard ───────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),

          // ── Branch 1: Trips ────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.trips,
                name: 'trips',
                builder: (context, state) => const TripsCalendarPage(),
                routes: [
                  GoRoute(
                    path: 'detail/:tripId',
                    name: 'trip-detail',
                    builder: (context, state) => TripDetailPage(
                      tripId: state.pathParameters['tripId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 2: Settlements ───────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settlements,
                name: 'settlements',
                builder: (context, state) => const SettlementsPage(),
              ),
            ],
          ),

          // ── Branch 3: Settings (placeholder) ───────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settings,
                name: 'settings',
                builder: (context, state) => const PlaceholderPage(
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
});
