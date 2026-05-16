/// Trip domain entity (pure Dart, no dependencies)
class TripEntity {
  final String id;
  final DateTime tripDate;
  final String driverId;
  final String driverName;
  final double distanceInKm;
  final List<String> attendeeIds;
  final int totalPassengers;
  final double totalExpense;
  final double expensePerPerson;
  final String status;
  final bool isExpenseLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripEntity({
    required this.id,
    required this.tripDate,
    required this.driverId,
    required this.driverName,
    required this.distanceInKm,
    required this.attendeeIds,
    required this.totalPassengers,
    required this.totalExpense,
    required this.expensePerPerson,
    required this.status,
    required this.isExpenseLocked,
    required this.createdAt,
    required this.updatedAt,
  });

  TripEntity copyWith({
    String? id,
    DateTime? tripDate,
    String? driverId,
    String? driverName,
    double? distanceInKm,
    List<String>? attendeeIds,
    int? totalPassengers,
    double? totalExpense,
    double? expensePerPerson,
    String? status,
    bool? isExpenseLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripEntity(
      id: id ?? this.id,
      tripDate: tripDate ?? this.tripDate,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      totalPassengers: totalPassengers ?? this.totalPassengers,
      totalExpense: totalExpense ?? this.totalExpense,
      expensePerPerson: expensePerPerson ?? this.expensePerPerson,
      status: status ?? this.status,
      isExpenseLocked: isExpenseLocked ?? this.isExpenseLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
