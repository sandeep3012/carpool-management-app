import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user_model.dart';
import 'models/trip_model.dart';
import 'models/expense_model.dart';
import 'models/guest_model.dart';
import 'models/settlement_model.dart';
import 'models/audit_log_model.dart';

/// In-memory collection that mimics an Isar collection interface
class InMemoryCollection<T> {
  final List<T> _items = [];
  int _nextId = 1;

  List<T> get all => List.unmodifiable(_items);

  int get length => _items.length;

  Future<int> count() async => _items.length;

  Future<List<T>> findAll() async => List.from(_items);

  Future<T?> findFirst() async => _items.isEmpty ? null : _items.first;

  /// Put (insert or update) an item. Returns the assigned id.
  Future<int> put(T item) async {
    // Use reflection-free approach via the _getId/_setId helpers
    final id = _getItemId(item);
    if (id == null || id == 0) {
      _setItemId(item, _nextId++);
      _items.add(item);
    } else {
      final index = _items.indexWhere((e) => _getItemId(e) == id);
      if (index >= 0) {
        _items[index] = item;
      } else {
        _items.add(item);
      }
    }
    return _getItemId(item) ?? 0;
  }

  /// Delete item by id
  Future<bool> delete(int? id) async {
    if (id == null) return false;
    final index = _items.indexWhere((e) => _getItemId(e) == id);
    if (index >= 0) {
      _items.removeAt(index);
      return true;
    }
    return false;
  }

  /// Clear all items
  Future<void> clear() async => _items.clear();

  int? _getItemId(T item) {
    if (item is UserModel) return item.id;
    if (item is TripModel) return item.id;
    if (item is ExpenseModel) return item.id;
    if (item is GuestModel) return item.id;
    if (item is SettlementModel) return item.id;
    if (item is AuditLogModel) return item.id;
    return null;
  }

  void _setItemId(T item, int id) {
    if (item is UserModel) item.id = id;
    if (item is TripModel) item.id = id;
    if (item is ExpenseModel) item.id = id;
    if (item is GuestModel) item.id = id;
    if (item is SettlementModel) item.id = id;
    if (item is AuditLogModel) item.id = id;
  }

  /// Filter items using a predicate
  Future<List<T>> filter(bool Function(T) predicate) async {
    return _items.where(predicate).toList();
  }

  /// Find first matching item
  Future<T?> filterFirst(bool Function(T) predicate) async {
    try {
      return _items.firstWhere(predicate);
    } catch (_) {
      return null;
    }
  }
}

/// In-memory database service replacing Isar
/// This provides the same interface so all repositories work unchanged.
/// Can be replaced with real Isar once codegen is run.
class IsarService {
  // Collections
  final InMemoryCollection<UserModel> users = InMemoryCollection<UserModel>();
  final InMemoryCollection<TripModel> trips = InMemoryCollection<TripModel>();
  final InMemoryCollection<ExpenseModel> expenses =
      InMemoryCollection<ExpenseModel>();
  final InMemoryCollection<GuestModel> guests =
      InMemoryCollection<GuestModel>();
  final InMemoryCollection<SettlementModel> settlements =
      InMemoryCollection<SettlementModel>();
  final InMemoryCollection<AuditLogModel> auditLogs =
      InMemoryCollection<AuditLogModel>();

  IsarService();

  /// Atomic transaction (no-op in memory — all ops are synchronous)
  Future<T> txn<T>(Future<T> Function() callback) => callback();

  /// Clear all data
  Future<void> clear() async {
    await users.clear();
    await trips.clear();
    await expenses.clear();
    await guests.clear();
    await settlements.clear();
    await auditLogs.clear();
  }

  /// Close (no-op for in-memory)
  Future<void> close() async {}

  /// Get all unsynced data
  Future<Map<String, dynamic>> getUnsyncedData() async {
    return {
      'users': await users.filter((u) => u.syncStatus == 'pending'),
      'trips': await trips.filter((t) => t.syncStatus == 'pending'),
      'expenses': await expenses.filter((e) => e.syncStatus == 'pending'),
      'guests': await guests.filter((g) => g.syncStatus == 'pending'),
      'settlements':
          await settlements.filter((s) => s.syncStatus == 'pending'),
      'auditLogs': await auditLogs.filter((a) => a.syncStatus == 'pending'),
    };
  }

  /// Mark entities as synced
  Future<void> markAsSynced<T extends Object>(List<T> models) async {
    await txn(() async {
      for (final model in models) {
        if (model is UserModel) {
          model.syncStatus = 'synced';
          model.updatedAt = DateTime.now();
          await users.put(model);
        } else if (model is TripModel) {
          model.syncStatus = 'synced';
          model.updatedAt = DateTime.now();
          await trips.put(model);
        } else if (model is ExpenseModel) {
          model.syncStatus = 'synced';
          model.updatedAt = DateTime.now();
          await expenses.put(model);
        } else if (model is GuestModel) {
          model.syncStatus = 'synced';
          model.updatedAt = DateTime.now();
          await guests.put(model);
        } else if (model is SettlementModel) {
          model.syncStatus = 'synced';
          model.updatedAt = DateTime.now();
          await settlements.put(model);
        } else if (model is AuditLogModel) {
          model.syncStatus = 'synced';
          model.updatedAt = DateTime.now();
          await auditLogs.put(model);
        }
      }
    });
  }

  /// Get database statistics
  Future<Map<String, int>> getStatistics() async {
    return {
      'users': await users.count(),
      'trips': await trips.count(),
      'expenses': await expenses.count(),
      'guests': await guests.count(),
      'settlements': await settlements.count(),
      'auditLogs': await auditLogs.count(),
    };
  }
}

/// Singleton instance — shared across the app
final _isarServiceInstance = IsarService();

/// Provider for IsarService
final isarServiceProvider = Provider<IsarService>((ref) {
  return _isarServiceInstance;
});
