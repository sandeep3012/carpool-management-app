import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_models.dart';
import '../../../trips/data/datasources/trip_local_store.dart';
import '../../../trips/data/models/trip_entry_model.dart';
import '../../../trips/presentation/providers/trips_provider.dart';
import '../../../settlements/presentation/providers/settlements_provider.dart';
import '../../../settlements/data/models/settlement_models.dart';

// ── Dashboard state provider ──────────────────────────────────────────────────

/// Reactive dashboard state — recomputes whenever the trip list or
/// settlement changes.
///
/// Wraps the result in [AsyncValue] so the UI can show a skeleton while the
/// local store is loading from disk on the first app launch.
final dashboardStateProvider =
    Provider<AsyncValue<DashboardState>>((ref) {
  // Gate on the store being ready (loading state only on first launch).
  final storeAsync = ref.watch(tripLocalStoreProvider);
  if (storeAsync.isLoading) return const AsyncValue.loading();
  if (storeAsync.hasError) {
    return AsyncValue.error(
      storeAsync.error!,
      storeAsync.stackTrace ?? StackTrace.empty,
    );
  }

  // Store is ready — compute from reactive trip state.
  final allTrips = ref.watch(tripsNotifierProvider);
  final cm = ref.watch(calendarMonthProvider);
  final members = ref.watch(membersProvider);
  final settlementAsync = ref.watch(settlementProvider);

  final monthTrips = allTrips
      .where((t) => t.date.month == cm.month && t.date.year == cm.year)
      .toList();

  final now = DateTime.now();

  // ── Summary card ────────────────────────────────────────────────────────

  final totalExpense = monthTrips.fold<double>(
    0,
    (sum, t) => sum + t.expenses.totalExpense,
  );

  final currentUser = members.firstWhere(
    (m) => m.isCurrentUser,
    orElse: () => members.first,
  );

  // My net balance from the settlement computation.
  final myBalance = settlementAsync.maybeWhen(
    data: (s) {
      try {
        return s.memberBalances.firstWhere((b) => b.isCurrentUser).netBalance;
      } catch (_) {
        return 0.0;
      }
    },
    orElse: () => 0.0,
  );

  // Total pending payment amount (what still needs to move hands).
  final pendingAmount = settlementAsync.maybeWhen(
    data: (s) => s.payments
        .where((p) => p.isPending || p.isConfirmed)
        .fold<double>(0, (sum, p) => sum + p.amount),
    orElse: () => 0.0,
  );

  final lastPastTrip = monthTrips
      .where((t) => !t.date.isAfter(now))
      .fold<TripEntry?>(null, (latest, t) {
    if (latest == null) return t;
    return t.date.isAfter(latest.date) ? t : latest;
  });

  final summary = DashboardSummary(
    totalExpense: totalExpense,
    myBalance: myBalance,
    pendingSettlement: pendingAmount,
    totalTrips: monthTrips.length,
    lastTripDate: lastPastTrip?.date,
  );

  // ── Upcoming drives (today and future) ──────────────────────────────────

  final upcoming = allTrips
      .where((t) => !t.date.isBefore(DateTime(now.year, now.month, now.day)))
      .take(5)
      .map((t) => UpcomingDrive(
            id: t.id,
            tripDate: t.date,
            driverName: t.driver.name,
            isYouDriving: t.driver.id == currentUser.id,
            passengerCount: t.attendees.length,
            estimatedExpense: t.expenses.totalExpense,
            driverStatus: 'Confirmed',
          ))
      .toList();

  // ── Recent trips (past, newest first) ───────────────────────────────────

  final pastTrips = allTrips
      .where((t) => t.date.isBefore(now))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final myId = currentUser.id;

  final recentTrips = pastTrips.take(5).map((t) {
    final share = t.attendees.isNotEmpty
        ? t.expenses.totalExpense / t.attendees.length
        : 0.0;

    return RecentTrip(
      id: t.id,
      tripDate: t.date,
      driverName: t.driver.name,
      passengerCount: t.attendees.length,
      totalExpense: t.expenses.totalExpense,
      yourShare: t.attendees.any((a) => a.id == myId) ? share : 0.0,
      status: t.status,
    );
  }).toList();

  // ── Pending settlement card ──────────────────────────────────────────────

  final pendingSettlement = settlementAsync.maybeWhen(
    data: (s) => s.payments.isEmpty
        ? null
        : PendingSettlement(
            id: s.id,
            month: s.month,
            year: s.year,
            totalAmount: s.totalExpense,
            transactionCount: s.payments
                .where((p) => p.isPending || p.isConfirmed)
                .length,
            status: s.isFullySettled
                ? SettlementStatusConst.completed
                : SettlementStatusConst.inProgress,
          ),
    orElse: () => null,
  );

  return AsyncValue.data(DashboardState(
    summary: summary,
    upcomingDrives: upcoming,
    recentTrips: recentTrips,
    pendingSettlement: pendingSettlement,
  ));
});

// ── DashboardState ────────────────────────────────────────────────────────────

class DashboardState {
  final DashboardSummary summary;
  final List<UpcomingDrive> upcomingDrives;
  final List<RecentTrip> recentTrips;
  final PendingSettlement? pendingSettlement;

  const DashboardState({
    required this.summary,
    required this.upcomingDrives,
    required this.recentTrips,
    required this.pendingSettlement,
  });
}
