/// Three visual states for the settlement card on the dashboard.
///
/// Derived from [PendingSettlement.cardState] — the card widget only
/// needs to switch on this enum, no string comparisons in UI code.
enum SettlementCardState {
  /// Outstanding amount > 0, no payments completed yet.
  pending,

  /// Some payments settled, some still outstanding.
  inProgress,

  /// All payments completed — nothing left to action.
  settled,
}

/// Dashboard summary data model — plain Dart, no codegen required
class DashboardSummary {
  final double totalExpense;
  final double myBalance;
  final double pendingSettlement;
  final int totalTrips;
  final DateTime? lastTripDate;

  const DashboardSummary({
    required this.totalExpense,
    required this.myBalance,
    required this.pendingSettlement,
    required this.totalTrips,
    this.lastTripDate,
  });

  DashboardSummary copyWith({
    double? totalExpense,
    double? myBalance,
    double? pendingSettlement,
    int? totalTrips,
    DateTime? lastTripDate,
  }) {
    return DashboardSummary(
      totalExpense: totalExpense ?? this.totalExpense,
      myBalance: myBalance ?? this.myBalance,
      pendingSettlement: pendingSettlement ?? this.pendingSettlement,
      totalTrips: totalTrips ?? this.totalTrips,
      lastTripDate: lastTripDate ?? this.lastTripDate,
    );
  }
}

/// Upcoming drive data model
class UpcomingDrive {
  final String id;
  final DateTime tripDate;
  final String driverName;
  final bool isYouDriving;
  final int passengerCount;
  final double estimatedExpense;
  final String? driverStatus;

  const UpcomingDrive({
    required this.id,
    required this.tripDate,
    required this.driverName,
    required this.isYouDriving,
    required this.passengerCount,
    required this.estimatedExpense,
    this.driverStatus,
  });

  bool get isToday => _isSameDay(tripDate, DateTime.now());
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _isSameDay(tripDate, tomorrow);
  }

  String get daysFromNow {
    final difference = tripDate.difference(DateTime.now()).inDays;
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return 'In $difference days';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  UpcomingDrive copyWith({
    String? id,
    DateTime? tripDate,
    String? driverName,
    bool? isYouDriving,
    int? passengerCount,
    double? estimatedExpense,
    String? driverStatus,
  }) {
    return UpcomingDrive(
      id: id ?? this.id,
      tripDate: tripDate ?? this.tripDate,
      driverName: driverName ?? this.driverName,
      isYouDriving: isYouDriving ?? this.isYouDriving,
      passengerCount: passengerCount ?? this.passengerCount,
      estimatedExpense: estimatedExpense ?? this.estimatedExpense,
      driverStatus: driverStatus ?? this.driverStatus,
    );
  }
}

/// Recent trip data model
class RecentTrip {
  final String id;
  final DateTime tripDate;
  final String driverName;
  final int passengerCount;
  final double totalExpense;
  final double yourShare;
  final String status;

  const RecentTrip({
    required this.id,
    required this.tripDate,
    required this.driverName,
    required this.passengerCount,
    required this.totalExpense,
    required this.yourShare,
    required this.status,
  });

  bool get isPast => tripDate.isBefore(DateTime.now());
  String get formattedDate => _formatDate(tripDate);

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';

    final months = difference ~/ 30;
    if (months == 1) return 'Last month';
    return '${date.day}/${date.month}';
  }

  RecentTrip copyWith({
    String? id,
    DateTime? tripDate,
    String? driverName,
    int? passengerCount,
    double? totalExpense,
    double? yourShare,
    String? status,
  }) {
    return RecentTrip(
      id: id ?? this.id,
      tripDate: tripDate ?? this.tripDate,
      driverName: driverName ?? this.driverName,
      passengerCount: passengerCount ?? this.passengerCount,
      totalExpense: totalExpense ?? this.totalExpense,
      yourShare: yourShare ?? this.yourShare,
      status: status ?? this.status,
    );
  }
}

/// Pending settlement data model
class PendingSettlement {
  final String id;
  final int month;
  final int year;

  /// Sum of outstanding (pending + confirmed) payment amounts.
  /// Zero when fully settled.
  final double totalAmount;

  /// Number of payments still requiring action (pending or payer-confirmed).
  final int transactionCount;

  /// Number of fully completed payments this month.
  final int completedCount;

  /// Overall settlement status string — matches [SettlementStatusConst].
  final String status;

  const PendingSettlement({
    required this.id,
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.transactionCount,
    required this.completedCount,
    required this.status,
  });

  /// Derived display state for the dashboard card.
  SettlementCardState get cardState {
    if (status == 'completed') return SettlementCardState.settled;
    if (completedCount > 0) return SettlementCardState.inProgress;
    return SettlementCardState.pending;
  }

  PendingSettlement copyWith({
    String? id,
    int? month,
    int? year,
    double? totalAmount,
    int? transactionCount,
    int? completedCount,
    String? status,
  }) {
    return PendingSettlement(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionCount: transactionCount ?? this.transactionCount,
      completedCount: completedCount ?? this.completedCount,
      status: status ?? this.status,
    );
  }
}
