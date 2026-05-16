# Navigation Architecture & Routing Strategy

## Route Organization

### Route Tree Structure

```
/
├── /splash                    [SplashPage]
├── /login                     [LoginPage]
└── /home                      [HomeShell]
    ├── /dashboard             [DashboardPage]
    ├── /trips                 [TripsCalendarPage]
    │   ├── /:tripId           [TripDetailPage]
    │   └── /edit/:tripId      [TripEditPage] (modal, admin)
    ├── /settlements           [SettlementsListPage]
    │   └── /:settlementId     [SettlementDetailPage]
    ├── /reports               [ReportsPage]
    │   ├── /monthly/:month    [MonthlyReportPage]
    │   └── /member/:memberId  [MemberReportPage]
    ├── /members               [MembersPage] (admin only)
    │   └── /edit/:memberId    [EditMemberPage] (modal)
    └── /settings              [SettingsPage]
        └── /profile           [ProfilePage] (modal)
```

---

## Navigation Implementation

### Route Names Constants

```dart
// lib/routes/route_names.dart

class RouteNames {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  
  // Main
  static const String home = '/home';
  static const String dashboard = 'dashboard';
  static const String trips = 'trips';
  static const String settlements = 'settlements';
  static const String reports = 'reports';
  static const String members = 'members';
  static const String settings = 'settings';
  
  // Trip routes
  static const String tripDetail = 'detail';
  static const String tripEdit = 'edit';
  
  // Settlement routes
  static const String settlementDetail = 'detail';
  
  // Report routes
  static const String monthlyReport = 'monthly';
  static const String memberReport = 'member';
  
  // Settings routes
  static const String profile = 'profile';
  
  // Member routes
  static const String memberEdit = 'edit';
}
```

---

## Go Router Configuration

### Main Router Setup

```dart
// lib/routes/app_router.dart

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: _redirectLogic,
    routes: _buildRoutes(authState),
    errorBuilder: _buildErrorPage,
  );
});
```

### Route Builder Pattern

```dart
List<RouteBase> _buildRoutes(AuthState authState) {
  return [
    // Auth routes
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
    
    // Main navigation (shell)
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationShell(
          child: child,
          onTabChange: (index) => _handleTabChange(context, index),
        );
      },
      routes: [
        // Dashboard route
        GoRoute(
          path: RouteNames.home,
          name: RouteNames.dashboard,
          builder: (context, state) => const DashboardPage(),
        ),
        
        // Trips route with nested navigation
        GoRoute(
          path: '/${RouteNames.trips}',
          name: RouteNames.trips,
          builder: (context, state) => const TripsCalendarPage(),
          routes: [
            GoRoute(
              path: ':tripId',
              name: RouteNames.tripDetail,
              builder: (context, state) {
                final tripId = state.pathParameters['tripId']!;
                return TripDetailPage(tripId: tripId);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  name: RouteNames.tripEdit,
                  pageBuilder: (context, state) {
                    final tripId = state.pathParameters['tripId']!;
                    return _modalPageBuilder(
                      TripEditPage(tripId: tripId),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        
        // Settlements route
        GoRoute(
          path: '/${RouteNames.settlements}',
          name: RouteNames.settlements,
          builder: (context, state) => const SettlementsListPage(),
          routes: [
            GoRoute(
              path: ':settlementId',
              name: RouteNames.settlementDetail,
              builder: (context, state) {
                final settlementId = state.pathParameters['settlementId']!;
                return SettlementDetailPage(settlementId: settlementId);
              },
            ),
          ],
        ),
        
        // Reports route (admin visible)
        if (authState.isAdmin)
          GoRoute(
            path: '/${RouteNames.reports}',
            name: RouteNames.reports,
            builder: (context, state) => const ReportsPage(),
            routes: [
              GoRoute(
                path: 'monthly/:month',
                name: RouteNames.monthlyReport,
                builder: (context, state) {
                  final month = state.pathParameters['month']!;
                  return MonthlyReportPage(month: month);
                },
              ),
              GoRoute(
                path: 'member/:memberId',
                name: RouteNames.memberReport,
                builder: (context, state) {
                  final memberId = state.pathParameters['memberId']!;
                  return MemberReportPage(memberId: memberId);
                },
              ),
            ],
          ),
        
        // Members route (admin only)
        if (authState.isAdmin)
          GoRoute(
            path: '/${RouteNames.members}',
            name: RouteNames.members,
            builder: (context, state) => const MembersPage(),
            routes: [
              GoRoute(
                path: ':memberId/edit',
                name: RouteNames.memberEdit,
                pageBuilder: (context, state) {
                  final memberId = state.pathParameters['memberId']!;
                  return _modalPageBuilder(
                    EditMemberPage(memberId: memberId),
                  );
                },
              ),
            ],
          ),
        
        // Settings route
        GoRoute(
          path: '/${RouteNames.settings}',
          name: RouteNames.settings,
          builder: (context, state) => const SettingsPage(),
          routes: [
            GoRoute(
              path: 'profile',
              name: RouteNames.profile,
              pageBuilder: (context, state) {
                return _modalPageBuilder(const ProfilePage());
              },
            ),
          ],
        ),
      ],
    ),
  ];
}
```

---

## Bottom Navigation Implementation

### Navigation Shell Widget

```dart
// lib/features/core/widgets/main_navigation_shell.dart

class MainNavigationShell extends StatefulWidget {
  final Widget child;
  final Function(int) onTabChange;

  const MainNavigationShell({
    required this.child,
    required this.onTabChange,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;
  
  // Tab structure based on role
  List<BottomNavigationBarItem> _buildNavItems(bool isAdmin) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today),
        label: 'Trips',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet_outlined),
        activeIcon: Icon(Icons.account_balance_wallet),
        label: 'Settle',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.assessment_outlined),
          activeIcon: Icon(Icons.assessment),
          label: 'Reports',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    widget.onTabChange(index);
    
    // Navigate to correct route
    _navigateToTab(index);
  }

  void _navigateToTab(int index) {
    final routes = [
      RouteNames.dashboard,
      RouteNames.trips,
      RouteNames.settlements,
      if (context.authState.isAdmin) RouteNames.reports,
      RouteNames.settings,
    ];
    
    context.goNamed(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: _buildNavItems(isAdmin),
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
    );
  }
}
```

---

## Navigation Patterns

### Pattern 1: Simple Navigation (Dashboard → Trips)

```dart
// User taps "Trips" in bottom nav
context.goNamed(RouteNames.trips);
// Routes to: /home/trips
```

### Pattern 2: Nested Navigation (Trips → Detail)

```dart
// User taps trip card
context.goNamed(
  RouteNames.tripDetail,
  pathParameters: {'tripId': trip.id},
);
// Routes to: /home/trips/abc123
```

### Pattern 3: Modal Navigation (Edit Trip)

```dart
// User taps [Edit] in trip detail
context.goNamed(
  RouteNames.tripEdit,
  pathParameters: {'tripId': trip.id},
);
// Routes to: /home/trips/abc123/edit
// Shown as modal over detail page
```

### Pattern 4: Tab Navigation (Settings Profile)

```dart
// User taps [Edit Profile] in settings
context.goNamed(RouteNames.profile);
// Routes to: /home/settings/profile
// Shown as modal
```

### Pattern 5: With Parameters (Member Report)

```dart
// User taps member in report
context.goNamed(
  RouteNames.memberReport,
  pathParameters: {'memberId': member.id},
);
// Routes to: /home/reports/member/def456
```

---

## Navigation Guards & Redirects

### Auth Redirect

```dart
String? _redirectLogic(BuildContext context, GoRouterState state) {
  final authState = ref.watch(authStateProvider);
  final isAuthRoute = state.matchedLocation == RouteNames.splash ||
                      state.matchedLocation == RouteNames.login;
  
  // Not authenticated
  if (!authState.isAuthenticated) {
    if (isAuthRoute) return null;
    return RouteNames.login;
  }
  
  // Authenticated, trying to access login
  if (isAuthRoute) {
    return RouteNames.home;
  }
  
  return null;
}
```

### Role-Based Route Access

```dart
String? _checkRoleAccess(GoRouterState state, AuthState authState) {
  final location = state.matchedLocation;
  
  // Admin-only routes
  if (location.contains('/reports') || 
      location.contains('/members')) {
    if (!authState.isAdmin) {
      return RouteNames.dashboard; // Redirect to dashboard
    }
  }
  
  return null;
}
```

---

## Page Transitions

### Standard Page Transition

```dart
// Slide in from right
GoRoute(
  path: '/trips/:tripId',
  pageBuilder: (context, state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: TripDetailPage(tripId: state.pathParameters['tripId']!),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  },
)
```

### Modal Transition

```dart
Page<T> _modalPageBuilder<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.9, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut)),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}
```

### Bottom Sheet Transition

```dart
// For quick entry sheet (explicit handling in widget)
showModalBottomSheet(
  context: context,
  builder: (context) => const QuickTripEntrySheet(),
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  transitionAnimationController: _animationController,
)
```

---

## Deep Linking Support

### Deep Link Examples

```
carpool://app/trips/abc123
carpool://app/settlements/xyz789
carpool://app/reports/monthly/2026-05
carpool://app/members/def456/edit
```

### Deep Link Configuration

```dart
// Android: AndroidManifest.xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
    android:scheme="carpool"
    android:host="app" />
</intent-filter>

// iOS: Info.plist
<dict>
  <key>CFBundleTypeRoles</key>
  <array>
    <dict>
      <key>CFBundleTypeSchemes</key>
      <array>
        <string>carpool</string>
      </array>
    </dict>
  </array>
</dict>
```

### Deep Link Router

```dart
GoRoute(
  path: 'trips/:tripId',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    return TripDetailPage(tripId: tripId);
  },
)
```

---

## State Management for Navigation

### Navigation Provider

```dart
// Track current tab
final currentTabProvider = StateProvider<int>((ref) => 0);

// Persist nav state
final navHistoryProvider = StateProvider<List<String>>((ref) => ['/home']);

// Handle tab transitions
ref.read(currentTabProvider.notifier).state = newIndex;
```

### Preserve Scroll Position

```dart
// Create AutomaticKeepAliveClientMixin for each tab
class DashboardPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DashboardView();
  }
}
```

---

## FAQs: Navigation Decisions

### Q: Why ShellRoute instead of TabBarView?
**A**: ShellRoute maintains separate widget trees for each tab, preserving scroll position and state. TabBarView rebuilds widgets on switch.

### Q: How to handle back button behavior?
**A**: Use `willPopScope` in each page:
```dart
WillPopScope(
  onWillPop: () async {
    context.pop(); // Use goRouter pop
    return false;
  },
  child: child,
)
```

### Q: How to share parameters between routes?
**A**: Use `GoRouter` state parameters:
```dart
context.goNamed(
  'routeName',
  pathParameters: {'id': '123'},
  queryParameters: {'month': '05'},
);
```

### Q: How to prevent accidental swipe-back on iOS?
**A**: Disable gesture nav for specific routes:
```dart
GoRoute(
  path: '/trip-edit/:id',
  pageBuilder: (context, state) => NoGestureBackPage(
    child: TripEditPage(),
  ),
)
```

---

## Summary: Navigation Strategy

✅ **Feature-based routes**: Organized by feature, not UI
✅ **Nested navigation**: Parent-child relationship maintained
✅ **Tab persistence**: Each tab maintains its own state
✅ **Modal support**: Edit screens as modals, not routes
✅ **Deep linking ready**: All routes are deep-linkable
✅ **Role-aware**: Admin routes hidden from members
✅ **Smooth transitions**: Custom animations for each pattern
✅ **Memory efficient**: Shell route preserves widget state
✅ **Scalable**: Easy to add new routes without refactoring
✅ **Maintainable**: Clear naming, organized structure
