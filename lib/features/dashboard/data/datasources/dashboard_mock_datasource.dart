import '../models/dashboard_models.dart';

class DashboardMockDatasource {
  static final _mockMembers = [
    'You',
    'John',
    'Sarah',
    'Mike',
    'Jane',
  ];

  static DashboardSummary getMonthlySummary() {
    return const DashboardSummary(
      totalExpense: 4200.0,
      myBalance: 150.0,
      pendingSettlement: 1200.0,
      totalTrips: 12,
      lastTripDate: null,
    );
  }

  static List<UpcomingDrive> getUpcomingDrives() {
    final today = DateTime.now();
    return [
      UpcomingDrive(
        id: 'trip_001',
        tripDate: today,
        driverName: 'You',
        isYouDriving: true,
        passengerCount: 4,
        estimatedExpense: 840.0,
        driverStatus: 'Confirmed',
      ),
      UpcomingDrive(
        id: 'trip_002',
        tripDate: today.add(const Duration(days: 1)),
        driverName: 'John',
        isYouDriving: false,
        passengerCount: 5,
        estimatedExpense: 950.0,
        driverStatus: 'Pending',
      ),
      UpcomingDrive(
        id: 'trip_003',
        tripDate: today.add(const Duration(days: 2)),
        driverName: 'Sarah',
        isYouDriving: false,
        passengerCount: 3,
        estimatedExpense: 720.0,
        driverStatus: null,
      ),
    ];
  }

  static List<RecentTrip> getRecentTrips() {
    final today = DateTime.now();
    return [
      RecentTrip(
        id: 'trip_101',
        tripDate: today,
        driverName: 'You',
        passengerCount: 5,
        totalExpense: 1050.0,
        yourShare: 210.0,
        status: 'active',
      ),
      RecentTrip(
        id: 'trip_100',
        tripDate: today.subtract(const Duration(days: 1)),
        driverName: 'John',
        passengerCount: 4,
        totalExpense: 840.0,
        yourShare: 210.0,
        status: 'completed',
      ),
      RecentTrip(
        id: 'trip_099',
        tripDate: today.subtract(const Duration(days: 2)),
        driverName: 'Sarah',
        passengerCount: 5,
        totalExpense: 950.0,
        yourShare: 190.0,
        status: 'completed',
      ),
      RecentTrip(
        id: 'trip_098',
        tripDate: today.subtract(const Duration(days: 3)),
        driverName: 'Mike',
        passengerCount: 4,
        totalExpense: 800.0,
        yourShare: 200.0,
        status: 'completed',
      ),
      RecentTrip(
        id: 'trip_097',
        tripDate: today.subtract(const Duration(days: 5)),
        driverName: 'You',
        passengerCount: 3,
        totalExpense: 720.0,
        yourShare: 240.0,
        status: 'completed',
      ),
    ];
  }

  static PendingSettlement? getPendingSettlement() {
    return const PendingSettlement(
      id: 'settlement_001',
      month: 5,
      year: 2026,
      totalAmount: 4200.0,
      transactionCount: 4,
      completedCount: 0,
      status: 'draft',
    );
  }

  static String getFormattedCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }
}
