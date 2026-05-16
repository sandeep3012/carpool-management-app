/// User domain entity (pure Dart, no dependencies)
class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.id,
      required this.email,
    required this.name,
    this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });
}
