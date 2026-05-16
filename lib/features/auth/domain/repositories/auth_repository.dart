import '../entities/user_entity.dart';

/// Abstract auth repository interface
abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
}
