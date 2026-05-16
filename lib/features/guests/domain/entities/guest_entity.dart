/// Guest domain entity (pure Dart, no dependencies)
class GuestEntity {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final List<String> tripIds;
  final int totalRides;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuestEntity({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    required this.tripIds,
    required this.totalRides,
    required this.createdAt,
    required this.updatedAt,
  });

  GuestEntity copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    List<String>? tripIds,
    int? totalRides,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuestEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      tripIds: tripIds ?? this.tripIds,
      totalRides: totalRides ?? this.totalRides,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
