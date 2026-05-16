import '../../../../core/database/models/trip_model.dart' as db;
import '../../domain/entities/trip_entity.dart';

/// Trip data model — plain Dart class, no codegen required
class TripModel {
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

  const TripModel({
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

  factory TripModel.fromDbModel(db.TripModel dbTrip) {
    return TripModel(
      id: dbTrip.tripId,
      tripDate: dbTrip.tripDate,
      driverId: dbTrip.driverId ?? '',
      driverName: '',
      distanceInKm: dbTrip.distanceInKm,
      attendeeIds: dbTrip.attendeeIds,
      totalPassengers: dbTrip.totalPassengers,
      totalExpense: dbTrip.totalExpense,
      expensePerPerson: dbTrip.expensePerPerson,
      status: dbTrip.status,
      isExpenseLocked: dbTrip.isExpenseLocked,
      createdAt: dbTrip.createdAt,
      updatedAt: dbTrip.updatedAt,
    );
  }

  TripEntity toEntity() {
    return TripEntity(
      id: id,
      tripDate: tripDate,
      driverId: driverId,
      driverName: driverName,
      distanceInKm: distanceInKm,
      attendeeIds: attendeeIds,
      totalPassengers: totalPassengers,
      totalExpense: totalExpense,
      expensePerPerson: expensePerPerson,
      status: status,
      isExpenseLocked: isExpenseLocked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  db.TripModel toDbModel() {
    return db.TripModel.create(
      tripId: id,
      tripDate: tripDate,
      driverId: driverId,
      distanceInKm: distanceInKm,
      attendeeIds: attendeeIds,
    )
      ..totalPassengers = totalPassengers
      ..totalExpense = totalExpense
      ..expensePerPerson = expensePerPerson
      ..status = status
      ..isExpenseLocked = isExpenseLocked;
  }

  TripModel copyWith({
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
    return TripModel(
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
