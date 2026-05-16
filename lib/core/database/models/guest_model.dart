/// Guest model for temporary carpool riders
/// Plain Dart class — no Isar codegen required
class GuestModel {
  /// Local primary key
  int? id;

  /// Firebase reference (cloudId)
  late String guestId;

  /// Synchronization status
  late String syncStatus; // "pending" | "synced" | "failed"

  /// Timestamps for sync tracking
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Core guest data
  late String name;
  late String? phoneNumber;
  late String? email;

  /// Track guest usage
  late List<String> tripIds;
  late int totalRides;

  /// Metadata
  late String? notes;
  late String? addedBy;

  GuestModel();

  /// Create from parameters
  GuestModel.create({
    required this.guestId,
    required this.name,
    this.phoneNumber,
    this.email,
    this.notes,
    this.addedBy,
    this.syncStatus = 'pending',
  })  : tripIds = const [],
        totalRides = 0,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  /// Add trip to guest's history
  void addTrip(String tripId) {
    tripIds = [...tripIds, tripId];
    totalRides++;
    updatedAt = DateTime.now();
  }

  /// Get display name with contact
  String get displayName {
    if (phoneNumber != null) {
      return '$name ($phoneNumber)';
    }
    if (email != null) {
      return '$name ($email)';
    }
    return name;
  }

  /// Check if guest has been used multiple times
  bool get isFrequentGuest => totalRides > 2;

  /// Copy with modifications
  GuestModel copyWith({
    String? guestId,
    String? name,
    String? phoneNumber,
    String? email,
    List<String>? tripIds,
    int? totalRides,
    String? notes,
    String? addedBy,
    String? syncStatus,
  }) {
    return GuestModel()
      ..id = id
      ..guestId = guestId ?? this.guestId
      ..name = name ?? this.name
      ..phoneNumber = phoneNumber ?? this.phoneNumber
      ..email = email ?? this.email
      ..tripIds = tripIds ?? this.tripIds
      ..totalRides = totalRides ?? this.totalRides
      ..notes = notes ?? this.notes
      ..addedBy = addedBy ?? this.addedBy
      ..syncStatus = syncStatus ?? this.syncStatus
      ..createdAt = createdAt
      ..updatedAt = DateTime.now();
  }

  @override
  String toString() =>
      'GuestModel(id: $id, guestId: $guestId, name: $name, '
      'phoneNumber: $phoneNumber, totalRides: $totalRides)';
}
