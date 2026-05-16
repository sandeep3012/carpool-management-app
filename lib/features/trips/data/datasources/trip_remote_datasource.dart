import '../models/trip_model.dart';

abstract class TripRemoteDatasource {
  Future<TripModel> createTrip(TripModel trip);

  Future<TripModel?> getTripById(String tripId);

  Future<List<TripModel>> getTripsByMonth(int month, int year);

  Future<TripModel> updateTrip(TripModel trip);

  Future<void> deleteTrip(String tripId);

  Future<List<TripModel>> syncTrips(List<String> tripIds);
}

class TripRemoteDatasourceImpl implements TripRemoteDatasource {
  @override
  Future<TripModel> createTrip(TripModel trip) async {
    // TODO: Implement Firebase Firestore write
    throw UnimplementedError('Firebase sync not yet implemented');
  }

  @override
  Future<TripModel?> getTripById(String tripId) async {
    // TODO: Implement Firebase Firestore read
    throw UnimplementedError('Firebase sync not yet implemented');
  }

  @override
  Future<List<TripModel>> getTripsByMonth(int month, int year) async {
    // TODO: Implement Firebase Firestore query
    throw UnimplementedError('Firebase sync not yet implemented');
  }

  @override
  Future<TripModel> updateTrip(TripModel trip) async {
    // TODO: Implement Firebase Firestore update
    throw UnimplementedError('Firebase sync not yet implemented');
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    // TODO: Implement Firebase Firestore delete
    throw UnimplementedError('Firebase sync not yet implemented');
  }

  @override
  Future<List<TripModel>> syncTrips(List<String> tripIds) async {
    // TODO: Implement batch Firebase Firestore read
    throw UnimplementedError('Firebase sync not yet implemented');
  }
}
