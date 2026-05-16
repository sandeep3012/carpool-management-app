import '../entities/trip_entity.dart';

abstract class TripRepository {
  Future<TripEntity> createTrip({
    required DateTime tripDate,
    required String driverId,
    required String driverName,
    required double distanceInKm,
  });

  Future<TripEntity?> getTripById(String tripId);

  Future<List<TripEntity>> getTripsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  Future<List<TripEntity>> getTripsByDriver(String driverId);

  Future<List<TripEntity>> getTripsByMonth(int month, int year);

  Future<TripEntity?> getTripOnDate(DateTime tripDate);

  Future<TripEntity> updateTrip(TripEntity trip);

  Future<void> deleteTrip(String tripId);

  Future<TripEntity> addAttendee(String tripId, String userId);

  Future<TripEntity> removeAttendee(String tripId, String userId);

  Future<TripEntity> lockTrip(String tripId);

  Future<TripEntity> unlockTrip(String tripId);

  Future<List<TripEntity>> getUnsyncedTrips();

  Future<void> markTripAsSynced(String tripId);

  Future<Map<String, dynamic>> getTripStatistics(int month, int year);
}
