/// Route constant names for type-safe navigation.
///
/// Auth routes use absolute paths.
/// Shell branch routes also use absolute paths so any widget
/// can call [context.go] without building paths from parts.
class RouteNames {
  RouteNames._();

  // ── Auth ──────────────────────────────────────────────
  static const String splash = '/splash';
  static const String login = '/login';

  // ── Shell entry (redirect → dashboard) ───────────────
  /// Navigating here triggers a redirect to [dashboard].
  /// Kept as a constant so SplashPage can continue using
  /// [context.go(RouteNames.home)] without change.
  static const String home = '/home';

  // ── Shell branches (absolute paths) ──────────────────
  static const String dashboard = '/home/dashboard';
  static const String trips = '/home/trips';
  static const String settlements = '/home/settlements';
  static const String settings = '/home/settings';

  // ── Trips sub-routes (helper, not a GoRoute path constant) ───────────────
  /// Build the absolute path for a trip detail screen.
  static String tripDetail(String tripId) => '/home/trips/detail/$tripId';
}
