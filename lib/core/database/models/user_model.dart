/// User model representing carpool members
/// Plain Dart class — no Isar codegen required
class UserModel {
  /// Local primary key
  int? id;

  /// Firebase reference (cloudId)
  late String userId;

  /// Synchronization status
  late String syncStatus; // "pending" | "synced" | "failed"

  /// Timestamps for sync tracking
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Core user data
  late String email;
  late String name;
  late String? phoneNumber;

  /// Role and status
  late String role; // "admin" | "member"
  late bool isActive;

  /// Metadata
  late bool isCurrentUser;
  late DateTime? lastLoginAt;
  late String? profileImageUrl;

  /// Getters for convenience
  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';

  UserModel();

  /// Create from parameters
  UserModel.create({
    required this.userId,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.role,
    this.isActive = true,
    this.isCurrentUser = false,
    this.syncStatus = 'pending',
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  /// Copy with modifications
  UserModel copyWith({
    String? userId,
    String? email,
    String? name,
    String? phoneNumber,
    String? role,
    bool? isActive,
    bool? isCurrentUser,
    DateTime? lastLoginAt,
    String? profileImageUrl,
    String? syncStatus,
  }) {
    return UserModel()
      ..id = id
      ..userId = userId ?? this.userId
      ..email = email ?? this.email
      ..name = name ?? this.name
      ..phoneNumber = phoneNumber ?? this.phoneNumber
      ..role = role ?? this.role
      ..isActive = isActive ?? this.isActive
      ..isCurrentUser = isCurrentUser ?? this.isCurrentUser
      ..lastLoginAt = lastLoginAt ?? this.lastLoginAt
      ..profileImageUrl = profileImageUrl ?? this.profileImageUrl
      ..syncStatus = syncStatus ?? this.syncStatus
      ..createdAt = createdAt
      ..updatedAt = DateTime.now();
  }

  @override
  String toString() => 'UserModel(id: $id, userId: $userId, name: $name, '
      'email: $email, role: $role, isActive: $isActive)';
}
