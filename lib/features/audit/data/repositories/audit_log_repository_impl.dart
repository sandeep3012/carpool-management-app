import 'package:uuid/uuid.dart';
import '../../../../core/database/exceptions.dart';
import '../../../../core/database/models/audit_log_model.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../../../core/database/isar_service.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final IsarService _isar;

  AuditLogRepositoryImpl({required IsarService isar}) : _isar = isar;

  @override
  Future<void> logAction({
    required String entityType,
    required String entityId,
    required String action,
    required String changedField,
    required String? oldValue,
    required String? newValue,
    required String performedBy,
    String? reason,
  }) async {
    try {
      final auditId = const Uuid().v4();
      final log = AuditLogModel.create(
        auditId: auditId,
        entityType: entityType,
        entityId: entityId,
        action: action,
        changedField: changedField,
        oldValue: oldValue,
        newValue: newValue,
        performedBy: performedBy,
        reason: reason,
      );

      await _isar.txn(() async {
        await _isar.auditLogs.put(log);
      });
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to log action',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AuditLogModel>> getHistoryForEntity(
    String entityId,
    String entityType,
  ) async {
    try {
      final results = await _isar.auditLogs.filter(
        (a) => a.entityId == entityId && a.entityType == entityType,
      );
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get entity history',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AuditLogModel>> getHistoryByType(String entityType) async {
    try {
      final results =
          await _isar.auditLogs.filter((a) => a.entityType == entityType);
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get history by type',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AuditLogModel>> getHistoryByAction(String action) async {
    try {
      final results =
          await _isar.auditLogs.filter((a) => a.action == action);
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get history by action',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AuditLogModel>> getRecentHistory(Duration duration) async {
    try {
      final since = DateTime.now().subtract(duration);
      final results = await _isar.auditLogs.filter(
        (a) => a.createdAt.isAfter(since),
      );
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get recent history',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteOldLogs(DateTime beforeDate) async {
    try {
      final logs = await _isar.auditLogs.filter(
        (a) => a.createdAt.isBefore(beforeDate),
      );

      await _isar.txn(() async {
        for (final log in logs) {
          await _isar.auditLogs.delete(log.id);
        }
      });
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to delete old logs',
        originalError: e,
      );
    }
  }

  @override
  Future<int> getLogCount() async {
    try {
      return _isar.auditLogs.count();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get log count',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AuditLogModel>> exportHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final results = await _isar.auditLogs.filter(
        (a) =>
            !a.createdAt.isBefore(startDate) && !a.createdAt.isAfter(endDate),
      );
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to export history',
        originalError: e,
      );
    }
  }
}
