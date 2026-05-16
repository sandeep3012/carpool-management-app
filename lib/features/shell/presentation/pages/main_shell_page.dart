import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Tab descriptor ───────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Fixed 4-tab configuration: Dashboard · Trips · Settlements · Settings.
///
/// Branch indices match the [StatefulShellBranch] order defined in
/// [appRouterProvider] — keep them in sync.
const List<_NavItem> _kNavItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
  ),
  _NavItem(
    label: 'Trips',
    icon: Icons.route_outlined,
    activeIcon: Icons.route_rounded,
  ),
  _NavItem(
    label: 'Settlements',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
  ),
  _NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
  ),
];

// ── Shell page ───────────────────────────────────────────────────────────────

/// Root scaffold that provides the persistent [NavigationBar] for the app.
///
/// Built by [StatefulShellRoute.indexedStack] inside [appRouterProvider].
/// Each branch of the shell maintains its own widget tree via an
/// [IndexedStack], so tab state survives switching (no extra
/// [AutomaticKeepAliveClientMixin] needed at this level).
///
/// Tab switching calls [StatefulNavigationShell.goBranch], which:
/// - navigates to the branch's initial route when switching tabs, and
/// - pops to the branch root when the already-active tab is tapped again.
class MainShellPage extends ConsumerWidget {
  const MainShellPage({
    Key? key,
    required this.navigationShell,
  }) : super(key: key);

  /// Provided by [StatefulShellRoute.indexedStack] — drives tab index
  /// and exposes [goBranch] for programmatic tab switching.
  final StatefulNavigationShell navigationShell;

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab pops to the branch's root location.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // The shell's body IS the NavigationShell — it renders whichever
      // branch is currently selected via an IndexedStack internally.
      body: navigationShell,
      bottomNavigationBar: _AppNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

// ── Navigation bar ───────────────────────────────────────────────────────────

/// Material 3 [NavigationBar] with exactly 4 [NavigationDestination]s.
///
/// Uses [NavigationDestinationLabelBehavior.alwaysShow] for clarity and
/// a short [animationDuration] to keep transitions snappy.
class _AppNavigationBar extends StatelessWidget {
  const _AppNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      animationDuration: const Duration(milliseconds: 250),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: _kNavItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
              tooltip: item.label,
            ),
          )
          .toList(),
    );
  }
}
