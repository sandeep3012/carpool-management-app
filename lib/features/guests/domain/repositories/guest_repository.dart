import '../entities/guest_entity.dart';

abstract class GuestRepository {
  Future<GuestEntity> createGuest({
    required String name,
    required String phoneNumber,
    String? email,
  });

  Future<GuestEntity?> getGuestById(String guestId);

  Future<List<GuestEntity>> getAllGuests();

  Future<List<GuestEntity>> getFrequentGuests({int minRides = 3});

  Future<GuestEntity> updateGuest(GuestEntity guest);

  Future<void> deleteGuest(String guestId);

  Future<GuestEntity> addTrip(String guestId, String tripId);

  Future<List<GuestEntity>> getUnsyncedGuests();

  Future<void> markGuestAsSynced(String guestId);
}
