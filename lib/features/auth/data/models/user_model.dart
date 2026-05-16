import '../../../../core/database/models/user_model.dart' as db;

/// User data model for auth feature
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
  });

  /// Convert to database model
  db.UserModel toDbModel({
    required String userId,
    String syncStatus = 'pending',
  }) {
    return db.UserModel.create(
      userId: userId,
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      role: role,
      isActive: isActive,
    )..syncStatus = syncStatus;
  }

  /// Create from database model
  static UserModel fromDbModel(db.UserModel dbModel) {
    return UserModel(
      id: dbModel.userId,
      email: dbModel.email,
      name: dbModel.name,
      phoneNumber: dbModel.phoneNumber,
      role: dbModel.role,
      isActive: dbModel.isActive,
      lastLoginAt: dbModel.lastLoginAt,
    );
  }

  /// Copy with modifications
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? role,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, name: $name, role: $role)';
}
