import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/models/user_model.dart' as db;
import '../../../../core/database/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth repository implementation using in-memory local database
class AuthRepositoryImpl implements AuthRepository {
  final IsarService _isar;

  const AuthRepositoryImpl({required IsarService isar}) : _isar = isar;

  /// Get currently logged-in user from local database
  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final user = await _isar.users.filterFirst(
        (u) => u.isCurrentUser == true,
      );
      if (user != null) {
        return _mapDbUserToEntity(user);
      }
      return null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get current user',
        originalError: e,
      );
    }
  }

  /// Mock login with hardcoded credentials
  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      // Mock credentials for development
      if (email == 'admin@carpool.com' && password == 'admin123') {
        return await _createOrUpdateMockUser(
          email: email,
          name: 'Admin User',
          role: 'admin',
        );
      }

      if (email == 'member@carpool.com' && password == 'member123') {
        return await _createOrUpdateMockUser(
          email: email,
          name: 'Regular Member',
          role: 'member',
        );
      }

      throw ValidationError(message: 'Invalid email or password');
    } on ValidationError {
      rethrow;
    } catch (e) {
      throw DatabaseException(
        message: 'Login failed',
        originalError: e,
      );
    }
  }

  /// Logout - clear current user flag
  @override
  Future<void> logout() async {
    try {
      final currentUser = await _isar.users.filterFirst(
        (u) => u.isCurrentUser == true,
      );

      if (currentUser != null) {
        await _isar.txn(() async {
          currentUser.isCurrentUser = false;
          currentUser.updatedAt = DateTime.now();
          await _isar.users.put(currentUser);
        });
      }
    } catch (e) {
      throw DatabaseException(
        message: 'Logout failed',
        originalError: e,
      );
    }
  }

  /// Check if user is currently logged in
  @override
  Future<bool> isLoggedIn() async {
    try {
      final user = await _isar.users.filterFirst(
        (u) => u.isCurrentUser == true,
      );
      return user != null && user.isActive;
    } catch (e) {
      return false;
    }
  }

  /// Get user by ID
  Future<UserEntity?> getUserById(String userId) async {
    try {
      final user = await _isar.users.filterFirst(
        (u) => u.userId == userId,
      );
      if (user != null) {
        return _mapDbUserToEntity(user);
      }
      return null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get user by ID',
        originalError: e,
      );
    }
  }

  /// Get all active users
  Future<List<UserEntity>> getActiveUsers() async {
    try {
      final users = await _isar.users.filter((u) => u.isActive == true);
      return users.map(_mapDbUserToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get active users',
        originalError: e,
      );
    }
  }

  /// Create a new user
  Future<UserEntity> createUser({
    required String email,
    required String name,
    String? phoneNumber,
    required String role,
  }) async {
    try {
      // Check if user already exists
      final existing = await _isar.users.filterFirst(
        (u) => u.email == email,
      );

      if (existing != null) {
        throw UniqueConstraintError(field: 'email', value: email);
      }

      final userId = const Uuid().v4();
      final dbUser = db.UserModel.create(
        userId: userId,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        role: role,
      );

      await _isar.txn(() async {
        await _isar.users.put(dbUser);
      });

      return _mapDbUserToEntity(dbUser);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to create user',
        originalError: e,
      );
    }
  }

  /// Update user
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      final dbUser = await _isar.users.filterFirst(
        (u) => u.userId == user.id,
      );

      if (dbUser == null) {
        throw EntityNotFoundError(entityType: 'User', entityId: user.id);
      }

      dbUser
        ..name = user.name
        ..updatedAt = DateTime.now();

      await _isar.txn(() async {
        await _isar.users.put(dbUser);
      });

      return _mapDbUserToEntity(dbUser);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to update user',
        originalError: e,
      );
    }
  }

  /// Deactivate user
  Future<void> deactivateUser(String userId) async {
    try {
      final dbUser = await _isar.users.filterFirst(
        (u) => u.userId == userId,
      );

      if (dbUser == null) {
        throw EntityNotFoundError(entityType: 'User', entityId: userId);
      }

      dbUser
        ..isActive = false
        ..updatedAt = DateTime.now();

      await _isar.txn(() async {
        await _isar.users.put(dbUser);
      });
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to deactivate user',
        originalError: e,
      );
    }
  }

  /// Helper: Map database model to entity
  UserEntity _mapDbUserToEntity(db.UserModel dbUser) {
    return UserEntity(
      id: dbUser.userId,
      email: dbUser.email,
      name: dbUser.name,
      role: dbUser.role,
      isActive: dbUser.isActive,
      createdAt: dbUser.createdAt,
      lastLoginAt: dbUser.lastLoginAt,
    );
  }

  /// Helper: Create or update mock user for development
  Future<UserEntity> _createOrUpdateMockUser({
    required String email,
    required String name,
    required String role,
  }) async {
    var dbUser = await _isar.users.filterFirst((u) => u.email == email);

    if (dbUser == null) {
      dbUser = db.UserModel.create(
        userId: const Uuid().v4(),
        email: email,
        name: name,
        role: role,
      );
    }

    // Clear other current users first
    final otherCurrentUsers = await _isar.users.filter(
      (u) => u.isCurrentUser == true && u.email != email,
    );

    await _isar.txn(() async {
      for (final user in otherCurrentUsers) {
        user.isCurrentUser = false;
        await _isar.users.put(user);
      }

      dbUser!.isCurrentUser = true;
      dbUser.lastLoginAt = DateTime.now();
      dbUser.updatedAt = DateTime.now();
      await _isar.users.put(dbUser);
    });

    return _mapDbUserToEntity(dbUser);
  }
}
