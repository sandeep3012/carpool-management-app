import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/dashboard_mock_datasource.dart';
import '../../data/models/dashboard_models.dart';

// Mock summary provider
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  // Simulated network delay
  await Future.delayed(const Duration(milliseconds: 500));
  return DashboardMockDatasource.getMonthlySummary();
});

// Mock upcoming drives provider
final upcomingDrivesProvider = FutureProvider<List<UpcomingDrive>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return DashboardMockDatasource.getUpcomingDrives();
});

// Mock recent trips provider
final recentTripsProvider = FutureProvider<List<RecentTrip>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return DashboardMockDatasource.getRecentTrips();
});

// Mock pending settlement provider
final pendingSettlementProvider = FutureProvider<PendingSettlement?>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return DashboardMockDatasource.getPendingSettlement();
});

// Combined dashboard state
final dashboardStateProvider =
    FutureProvider<DashboardState>((ref) async {
  final summary = await ref.watch(dashboardSummaryProvider.future);
  final upcomingDrives = await ref.watch(upcomingDrivesProvider.future);
  final recentTrips = await ref.watch(recentTripsProvider.future);
  final pendingSettlement =
      await ref.watch(pendingSettlementProvider.future);

  return DashboardState(
    summary: summary,
    upcomingDrives: upcomingDrives,
    recentTrips: recentTrips,
    pendingSettlement: pendingSettlement,
  );
});

class DashboardState {
  final DashboardSummary summary;
  final List<UpcomingDrive> upcomingDrives;
  final List<RecentTrip> recentTrips;
  final PendingSettlement? pendingSettlement;

  DashboardState({
    required this.summary,
    required this.upcomingDrives,
    required this.recentTrips,
    required this.pendingSettlement,
  });
}
