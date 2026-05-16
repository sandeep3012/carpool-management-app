import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'route_names.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_state_provider.dart';

// Placeholder pages (to be replaced with actual implementations)
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home Page')),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({this.error, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Error: ${error?.toString() ?? 'Unknown'}'),
      ),
    );
  }
}

/// GoRouter configuration with auth-aware redirects
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;

      // Allow splash screen to always load initially
      if (location == RouteNames.splash) {
        return null;
      }

      // If not authenticated, redirect to login
      if (!isAuthenticated) {
        if (location != RouteNames.login) {
          return RouteNames.login;
        }
        return null;
      }

      // If authenticated but trying to access login, redirect to home
      if (location == RouteNames.login) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
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
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'dashboard',
            name: 'dashboard',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Dashboard')),
            ),
          ),
          GoRoute(
            path: 'trips',
            name: 'trips',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Trips')),
            ),
          ),
          GoRoute(
            path: 'settlements',
            name: 'settlements',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Settlements')),
            ),
          ),
          GoRoute(
            path: 'members',
            name: 'members',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Members')),
            ),
          ),
          GoRoute(
            path: 'reports',
            name: 'reports',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Reports')),
            ),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Settings')),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
});
