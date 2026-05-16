import '../../../../core/database/models/audit_log_model.dart';

abstract class AuditLogRepository {
  Future<void> logAction({
    required String entityType,
    required String entityId,
    required String action,
    required String changedField,
    required String? oldValue,
    required String? newValue,
    required String performedBy,
    String? reason,
  });

  Future<List<AuditLogModel>> getHistoryForEntity(
    String entityId,
    String entityType,
  );

  Future<List<AuditLogModel>> getHistoryByType(String entityType);

  Future<List<AuditLogModel>> getHistoryByAction(String action);

  Future<List<AuditLogModel>> getRecentHistory(Duration duration);

  Future<void> deleteOldLogs(DateTime beforeDate);

  Future<int> getLogCount();

  Future<List<AuditLogModel>> exportHistory({
    required DateTime startDate,
    required DateTime endDate,
  });
}
