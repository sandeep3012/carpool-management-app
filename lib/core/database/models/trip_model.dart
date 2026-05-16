/// Trip model representing daily carpool rides
/// Plain Dart class — no Isar codegen required
class TripModel {
  /// Local primary key
  int? id;

  /// Firebase reference (cloudId)
  late String tripId;

  /// Synchronization status
  late String syncStatus; // "pending" | "synced" | "failed"

  /// Timestamps for sync tracking
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Core trip data
  late DateTime tripDate;

  /// Driver information
  late String? driverId;

  /// Route information
  late double distanceInKm;

  /// Attendance tracking
  late List<String> attendeeIds;
  late int totalPassengers;

  /// Expense tracking
  late double totalExpense;
  late double expensePerPerson;

  /// State management
  late String status; // "draft" | "active" | "completed"
  late bool isExpenseLocked;
  late String? notes;

  TripModel();

  /// Create from parameters
  TripModel.create({
    required this.tripId,
    required this.tripDate,
    this.driverId,
    required this.distanceInKm,
    this.attendeeIds = const [],
    this.totalPassengers = 1,
    this.status = 'draft',
    this.syncStatus = 'pending',
    this.notes,
  })  : totalExpense = 0.0,
        expensePerPerson = 0.0,
        isExpenseLocked = false,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  /// Get month-year string for settlement queries
  String get monthYearString =>
      '${tripDate.year}-${tripDate.month.toString().padLeft(2, '0')}';

  /// Check if trip is in past
  bool get isPast => tripDate.isBefore(DateTime.now());

  /// Check if trip is today
  bool get isToday {
    final now = DateTime.now();
    return tripDate.year == now.year &&
        tripDate.month == now.month &&
        tripDate.day == now.day;
  }

  /// Can be locked (completed and all expenses finalized)
  bool get canBeLocked => status == 'completed' && !isExpenseLocked;

  /// Update expense totals
  void updateExpenseTotals(double newTotal) {
    totalExpense = newTotal;
    expensePerPerson =
        totalPassengers > 0 ? totalExpense / totalPassengers : 0.0;
    updatedAt = DateTime.now();
  }

  /// Copy with modifications
  TripModel copyWith({
    String? tripId,
    DateTime? tripDate,
    String? driverId,
    double? distanceInKm,
    List<String>? attendeeIds,
    int? totalPassengers,
    double? totalExpense,
    double? expensePerPerson,
    String? status,
    bool? isExpenseLocked,
    String? syncStatus,
    String? notes,
  }) {
    return TripModel()
      ..id = id
      ..tripId = tripId ?? this.tripId
      ..tripDate = tripDate ?? this.tripDate
      ..driverId = driverId ?? this.driverId
      ..distanceInKm = distanceInKm ?? this.distanceInKm
      ..attendeeIds = attendeeIds ?? this.attendeeIds
      ..totalPassengers = totalPassengers ?? this.totalPassengers
      ..totalExpense = totalExpense ?? this.totalExpense
      ..expensePerPerson = expensePerPerson ?? this.expensePerPerson
      ..status = status ?? this.status
      ..isExpenseLocked = isExpenseLocked ?? this.isExpenseLocked
      ..syncStatus = syncStatus ?? this.syncStatus
      ..notes = notes ?? this.notes
      ..createdAt = createdAt
      ..updatedAt = DateTime.now();
  }

  @override
  String toString() =>
      'TripModel(id: $id, tripId: $tripId, tripDate: $tripDate, '
      'driverId: $driverId, totalPassengers: $totalPassengers, '
      'status: $status, totalExpense: $totalExpense)';
}
