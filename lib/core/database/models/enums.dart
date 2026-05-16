/// User roles
enum UserRole {
  admin,
  member,
}

/// Trip status tracking
enum TripStatus {
  draft,
  active,
  completed,
}

/// Types of expenses
enum ExpenseType {
  fuel,
  toll,
  parking,
  other,
}

/// Settlement status
enum SettlementStatus {
  draft,
  pending,
  settled,
}

/// Sync status for all entities
enum SyncStatus {
  pending,
  synced,
  failed,
}

/// Actions tracked in audit log
enum AuditAction {
  create,
  update,
  delete,
  lock,
  unlock,
  sync,
}

/// Entity types for audit tracking
enum AuditEntityType {
  trip,
  expense,
  user,
  settlement,
  guest,
}

/// String representations for database storage
extension UserRoleExt on UserRole {
  String get value => name;

  static UserRole fromString(String value) => UserRole.values.firstWhere(
    (e) => e.name == value,
    orElse: () => UserRole.member,
  );
}

extension TripStatusExt on TripStatus {
  String get value => name;

  static TripStatus fromString(String value) => TripStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TripStatus.draft,
  );
}

extension ExpenseTypeExt on ExpenseType {
  String get value => name;

  static ExpenseType fromString(String value) => ExpenseType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ExpenseType.other,
  );
}

extension SettlementStatusExt on SettlementStatus {
  String get value => name;

  static SettlementStatus fromString(String value) =>
      SettlementStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SettlementStatus.draft,
      );
}

extension SyncStatusExt on SyncStatus {
  String get value => name;

  static SyncStatus fromString(String value) => SyncStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => SyncStatus.pending,
  );
}
