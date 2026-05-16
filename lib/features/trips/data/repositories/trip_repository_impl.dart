import 'package:uuid/uuid.dart';
import '../../../../core/database/exceptions.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_local_datasource.dart';
import '../datasources/trip_remote_datasource.dart';
import '../models/trip_model.dart';
import '../../../../core/database/models/trip_model.dart' as db;

class TripRepositoryImpl implements TripRepository {
  final TripLocalDatasource _localDatasource;
  final TripRemoteDatasource _remoteDatasource;

  TripRepositoryImpl({
    required TripLocalDatasource localDatasource,
    required TripRemoteDatasource remoteDatasource,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource;

  @override
  Future<TripEntity> createTrip({
    required DateTime tripDate,
    required String driverId,
    required String driverName,
    required double distanceInKm,
  }) async {
    try {
      // Validate: no existing trip on this date
      final existing = await _localDatasource.getTripOnDate(tripDate);
      if (existing != null) {
        throw TripAlreadyExistsError(tripDate: tripDate);
      }

      // Validate: driver not already assigned on this date
      final driverTrips = await _localDatasource.getTripsByDriver(driverId);
      for (final trip in driverTrips) {
        if (_isSameDay(trip.tripDate, tripDate)) {
          throw DriverAlreadyAssignedError(
            driverId: driverId,
            tripDate: tripDate,
          );
        }
      }

      final tripId = const Uuid().v4();
      final dbTrip = db.TripModel.create(
        tripId: tripId,
        tripDate: tripDate,
        driverId: driverId,
        distanceInKm: distanceInKm,
        attendeeIds: [driverId],
        totalPassengers: 1,
      );

      final created = await _localDatasource.createTrip(dbTrip);
      return TripModel.fromDbModel(created).toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TripEntity?> getTripById(String tripId) async {
    try {
      final dbTrip = await _localDatasource.getTripById(tripId);
      return dbTrip != null ? TripModel.fromDbModel(dbTrip).toEntity() : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get trip',
        originalError: e,
      );
    }
  }

  @override
  Future<List<TripEntity>> getTripsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final dbTrips =
          await _localDatasource.getTripsByDateRange(startDate, endDate);
      return dbTrips
          .map((trip) => TripModel.fromDbModel(trip).toEntity())
          .toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get trips by date range',
        originalError: e,
      );
    }
  }

  @override
  Future<List<TripEntity>> getTripsByDriver(String driverId) async {
    try {
      final dbTrips = await _localDatasource.getTripsByDriver(driverId);
      return dbTrips
          .map((trip) => TripModel.fromDbModel(trip).toEntity())
          .toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get trips by driver',
        originalError: e,
      );
    }
  }

  @override
  Future<List<TripEntity>> getTripsByMonth(int month, int year) async {
    try {
      final dbTrips = await _localDatasource.getTripsByMonth(month, year);
      return dbTrips
          .map((trip) => TripModel.fromDbModel(trip).toEntity())
          .toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get trips by month',
        originalError: e,
      );
    }
  }

  @override
  Future<TripEntity?> getTripOnDate(DateTime tripDate) async {
    try {
      final dbTrip = await _localDatasource.getTripOnDate(tripDate);
      return dbTrip != null ? TripModel.fromDbModel(dbTrip).toEntity() : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get trip on date',
        originalError: e,
      );
    }
  }

  @override
  Future<TripEntity> updateTrip(TripEntity trip) async {
    try {
      final existing = await _localDatasource.getTripById(trip.id);
      if (existing == null) {
        throw EntityNotFoundError(entityType: 'Trip', entityId: trip.id);
      }

      final model = TripModel(
        id: trip.id,
        tripDate: trip.tripDate,
        driverId: trip.driverId,
        driverName: trip.driverName,
        distanceInKm: trip.distanceInKm,
        attendeeIds: trip.attendeeIds,
        totalPassengers: trip.totalPassengers,
        totalExpense: trip.totalExpense,
        expensePerPerson: trip.expensePerPerson,
        status: trip.status,
        isExpenseLocked: trip.isExpenseLocked,
        createdAt: trip.createdAt,
        updatedAt: DateTime.now(),
      );

      final dbTrip = model.toDbModel();
      final updated = await _localDatasource.updateTrip(dbTrip);
      return TripModel.fromDbModel(updated).toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      final existing = await _localDatasource.getTripById(tripId);
      if (existing == null) {
        throw EntityNotFoundError(entityType: 'Trip', entityId: tripId);
      }
      await _localDatasource.deleteTrip(tripId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TripEntity> addAttendee(String tripId, String userId) async {
    try {
      final dbTrip = await _localDatasource.getTripById(tripId);
      if (dbTrip == null) {
        throw EntityNotFoundError(entityType: 'Trip', entityId: tripId);
      }

      if (!dbTrip.attendeeIds.contains(userId)) {
        dbTrip.attendeeIds = [...dbTrip.attendeeIds, userId];
        dbTrip.totalPassengers = dbTrip.attendeeIds.length;
        dbTrip.updatedAt = DateTime.now();
        final updated = await _localDatasource.updateTrip(dbTrip);
        return TripModel.fromDbModel(updated).toEntity();
      }

      return TripModel.fromDbModel(dbTrip).toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TripEntity> removeAttendee(String tripId, String userId) async {
    try {
      final dbTrip = await _localDatasource.getTripById(tripId);
      if (dbTrip == null) {
        throw EntityNotFoundError(entityType: 'Trip', entityId: tripId);
      }

      if (dbTrip.attendeeIds.contains(userId)) {
        dbTrip.attendeeIds =
            dbTrip.attendeeIds.where((id) => id != userId).toList();
        dbTrip.totalPassengers = dbTrip.attendeeIds.length;
        dbTrip.updatedAt = DateTime.now();
        final updated = await _localDatasource.updateTrip(dbTrip);
        return TripModel.fromDbModel(updated).toEntity();
      }

      return TripModel.fromDbModel(dbTrip).toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TripEntity> lockTrip(String tripId) async {
    try {
      final dbTrip = await _localDatasource.getTripById(tripId);
      if (dbTrip == null) {
        throw EntityNotFoundError(entityType: 'Trip', entityId: tripId);
      }

      dbTrip.isExpenseLocked = true;
      dbTrip.status = 'completed';
      dbTrip.updatedAt = DateTime.now();
      final updated = await _localDatasource.updateTrip(dbTrip);
      return TripModel.fromDbModel(updated).toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TripEntity> unlockTrip(String tripId) async {
    try {
      final dbTrip = await _localDatasource.getTripById(tripId);
      if (dbTrip == null) {
        throw EntityNotFoundError(entityType: 'Trip', entityId: tripId);
      }

      dbTrip.isExpenseLocked = false;
      dbTrip.updatedAt = DateTime.now();
      final updated = await _localDatasource.updateTrip(dbTrip);
      return TripModel.fromDbModel(updated).toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<TripEntity>> getUnsyncedTrips() async {
    try {
      final dbTrips = await _localDatasource.getUnsyncedTrips();
      return dbTrips
          .map((trip) => TripModel.fromDbModel(trip).toEntity())
          .toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get unsynced trips',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markTripAsSynced(String tripId) async {
    try {
      await _localDatasource.markTripAsSynced(tripId);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to mark trip as synced',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getTripStatistics(int month, int year) async {
    try {
      final trips = await getTripsByMonth(month, year);

      double totalDistance = 0;
      double totalExpense = 0;
      int totalTrips = trips.length;
      int totalPassengers = 0;

      for (final trip in trips) {
        totalDistance += trip.distanceInKm;
        totalExpense += trip.totalExpense;
        totalPassengers += trip.totalPassengers;
      }

      return {
        'totalTrips': totalTrips,
        'totalDistance': totalDistance,
        'totalExpense': totalExpense,
        'totalPassengers': totalPassengers,
        'averageExpense':
            totalTrips > 0 ? totalExpense / totalTrips : 0.0,
        'averagePassengers':
            totalTrips > 0 ? totalPassengers / totalTrips : 0.0,
      };
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get trip statistics',
        originalError: e,
      );
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
