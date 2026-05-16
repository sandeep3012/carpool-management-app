import 'package:uuid/uuid.dart';
import '../../../../core/database/exceptions.dart';
import '../../domain/entities/guest_entity.dart';
import '../../domain/repositories/guest_repository.dart';
import '../../../../core/database/models/guest_model.dart' as db;
import '../../../../core/database/isar_service.dart';

class GuestRepositoryImpl implements GuestRepository {
  final IsarService _isar;

  GuestRepositoryImpl({required IsarService isar}) : _isar = isar;

  @override
  Future<GuestEntity> createGuest({
    required String name,
    required String phoneNumber,
    String? email,
  }) async {
    try {
      final guestId = const Uuid().v4();
      final dbGuest = db.GuestModel.create(
        guestId: guestId,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
      );

      await _isar.txn(() async {
        await _isar.guests.put(dbGuest);
      });

      return _mapDbToEntity(dbGuest);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to create guest',
        originalError: e,
      );
    }
  }

  @override
  Future<GuestEntity?> getGuestById(String guestId) async {
    try {
      final guest = await _isar.guests.filterFirst((g) => g.guestId == guestId);
      return guest != null ? _mapDbToEntity(guest) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get guest',
        originalError: e,
      );
    }
  }

  @override
  Future<List<GuestEntity>> getAllGuests() async {
    try {
      final guests = await _isar.guests.findAll();
      return guests.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get all guests',
        originalError: e,
      );
    }
  }

  @override
  Future<List<GuestEntity>> getFrequentGuests({int minRides = 3}) async {
    try {
      final guests =
          await _isar.guests.filter((g) => g.totalRides >= minRides);
      return guests.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get frequent guests',
        originalError: e,
      );
    }
  }

  @override
  Future<GuestEntity> updateGuest(GuestEntity guest) async {
    try {
      final existing =
          await _isar.guests.filterFirst((g) => g.guestId == guest.id);

      if (existing == null) {
        throw EntityNotFoundError(entityType: 'Guest', entityId: guest.id);
      }

      existing
        ..name = guest.name
        ..phoneNumber = guest.phoneNumber
        ..email = guest.email
        ..updatedAt = DateTime.now();

      await _isar.txn(() async {
        await _isar.guests.put(existing);
      });

      return _mapDbToEntity(existing);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteGuest(String guestId) async {
    try {
      final existing =
          await _isar.guests.filterFirst((g) => g.guestId == guestId);

      if (existing == null) {
        throw EntityNotFoundError(entityType: 'Guest', entityId: guestId);
      }

      await _isar.txn(() async {
        await _isar.guests.delete(existing.id);
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GuestEntity> addTrip(String guestId, String tripId) async {
    try {
      final guest =
          await _isar.guests.filterFirst((g) => g.guestId == guestId);

      if (guest == null) {
        throw EntityNotFoundError(entityType: 'Guest', entityId: guestId);
      }

      if (!guest.tripIds.contains(tripId)) {
        guest.addTrip(tripId);
        await _isar.txn(() async {
          await _isar.guests.put(guest);
        });
      }

      return _mapDbToEntity(guest);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<GuestEntity>> getUnsyncedGuests() async {
    try {
      final guests =
          await _isar.guests.filter((g) => g.syncStatus == 'pending');
      return guests.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get unsynced guests',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markGuestAsSynced(String guestId) async {
    try {
      final guest =
          await _isar.guests.filterFirst((g) => g.guestId == guestId);

      if (guest != null) {
        guest.syncStatus = 'synced';
        guest.updatedAt = DateTime.now();
        await _isar.txn(() async {
          await _isar.guests.put(guest);
        });
      }
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to mark guest as synced',
        originalError: e,
      );
    }
  }

  GuestEntity _mapDbToEntity(db.GuestModel guest) {
    return GuestEntity(
      id: guest.guestId,
      name: guest.name,
      phoneNumber: guest.phoneNumber,
      email: guest.email,
      tripIds: guest.tripIds,
      totalRides: guest.totalRides,
      createdAt: guest.createdAt,
      updatedAt: guest.updatedAt,
    );
  }
}
