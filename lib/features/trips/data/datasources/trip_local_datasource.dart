import '../../../../core/database/isar_service.dart';
import '../../../../core/database/models/trip_model.dart' as db;

abstract class TripLocalDatasource {
  Future<db.TripModel> createTrip(db.TripModel trip);

  Future<db.TripModel?> getTripById(String tripId);

  Future<List<db.TripModel>> getTripsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  Future<List<db.TripModel>> getTripsByDriver(String driverId);

  Future<List<db.TripModel>> getTripsByMonth(int month, int year);

  Future<db.TripModel?> getTripOnDate(DateTime tripDate);

  Future<db.TripModel> updateTrip(db.TripModel trip);

  Future<void> deleteTrip(String tripId);

  Future<List<db.TripModel>> getUnsyncedTrips();

  Future<void> markTripAsSynced(String tripId);

  Future<void> clearSyncStatus(String tripId);
}

class TripLocalDatasourceImpl implements TripLocalDatasource {
  final IsarService _isar;

  TripLocalDatasourceImpl({required IsarService isar}) : _isar = isar;

  @override
  Future<db.TripModel> createTrip(db.TripModel trip) async {
    await _isar.txn(() async {
      await _isar.trips.put(trip);
    });
    return trip;
  }

  @override
  Future<db.TripModel?> getTripById(String tripId) async {
    return _isar.trips.filterFirst((t) => t.tripId == tripId);
  }

  @override
  Future<List<db.TripModel>> getTripsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _isar.trips.filter(
      (t) =>
          !t.tripDate.isBefore(startDate) && !t.tripDate.isAfter(endDate),
    );
  }

  @override
  Future<List<db.TripModel>> getTripsByDriver(String driverId) async {
    return _isar.trips.filter((t) => t.driverId == driverId);
  }

  @override
  Future<List<db.TripModel>> getTripsByMonth(int month, int year) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return getTripsByDateRange(startDate, endDate);
  }

  @override
  Future<db.TripModel?> getTripOnDate(DateTime tripDate) async {
    final startOfDay =
        DateTime(tripDate.year, tripDate.month, tripDate.day);
    final endOfDay =
        DateTime(tripDate.year, tripDate.month, tripDate.day, 23, 59, 59);
    final trips = await _isar.trips.filter(
      (t) =>
          !t.tripDate.isBefore(startOfDay) && !t.tripDate.isAfter(endOfDay),
    );
    return trips.isEmpty ? null : trips.first;
  }

  @override
  Future<db.TripModel> updateTrip(db.TripModel trip) async {
    await _isar.txn(() async {
      await _isar.trips.put(trip);
    });
    return trip;
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final trip = await getTripById(tripId);
    if (trip != null) {
      await _isar.txn(() async {
        await _isar.trips.delete(trip.id);
      });
    }
  }

  @override
  Future<List<db.TripModel>> getUnsyncedTrips() async {
    return _isar.trips.filter((t) => t.syncStatus == 'pending');
  }

  @override
  Future<void> markTripAsSynced(String tripId) async {
    final trip = await getTripById(tripId);
    if (trip != null) {
      trip.syncStatus = 'synced';
      trip.updatedAt = DateTime.now();
      await _isar.txn(() async {
        await _isar.trips.put(trip);
      });
    }
  }

  @override
  Future<void> clearSyncStatus(String tripId) async {
    final trip = await getTripById(tripId);
    if (trip != null) {
      trip.syncStatus = 'failed';
      trip.updatedAt = DateTime.now();
      await _isar.txn(() async {
        await _isar.trips.put(trip);
      });
    }
  }
}
