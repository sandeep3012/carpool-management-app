/// Audit log model for tracking all changes in the system
/// Plain Dart class — no Isar codegen required
class AuditLogModel {
  /// Local primary key
  int? id;

  /// Firebase reference (cloudId)
  late String auditId;

  /// Synchronization status
  late String syncStatus; // "pending" | "synced" | "failed"

  /// Timestamps for sync tracking
  late DateTime createdAt;
  late DateTime updatedAt;

  /// What was changed
  late String entityType;
  late String entityId;
  late int entityLocalId;

  /// The change details
  late String action;
  late String? changedField;
  late String? oldValue;
  late String? newValue;

  /// Who made the change
  late String performedBy;
  late String? reason;
  late String? ipAddress;
  late String? notes;

  AuditLogModel();

  /// Create from parameters
  AuditLogModel.create({
    required this.auditId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.performedBy,
    this.entityLocalId = 0,
    this.changedField,
    this.oldValue,
    this.newValue,
    this.reason,
    this.ipAddress,
    this.notes,
    this.syncStatus = 'pending',
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  /// Get action display name
  String get actionDisplayName => switch (action) {
        'create' => 'Created',
        'update' => 'Updated',
        'delete' => 'Deleted',
        'lock' => 'Locked',
        'unlock' => 'Unlocked',
        'sync' => 'Synced',
        _ => action,
      };

  /// Get entity type display name
  String get entityTypeDisplayName => switch (entityType) {
        'trip' => 'Trip',
        'expense' => 'Expense',
        'user' => 'User',
        'settlement' => 'Settlement',
        'guest' => 'Guest',
        _ => entityType,
      };

  /// Get summary of change
  String get changeSummary {
    switch (action) {
      case 'create':
        return 'Created new $entityTypeDisplayName';
      case 'update':
        if (changedField != null) {
          return 'Updated $changedField on $entityTypeDisplayName';
        }
        return 'Updated $entityTypeDisplayName';
      case 'delete':
        return 'Deleted $entityTypeDisplayName';
      case 'lock':
        return 'Locked $entityTypeDisplayName';
      case 'unlock':
        return 'Unlocked $entityTypeDisplayName';
      case 'sync':
        return 'Synced $entityTypeDisplayName';
      default:
        return '$action on $entityTypeDisplayName';
    }
  }

  /// Check if this is a destructive action
  bool get isDestructive => action == 'delete';

  /// Check if this is an edit action
  bool get isEditAction => action == 'update';

  /// Copy with modifications
  AuditLogModel copyWith({
    String? auditId,
    String? entityType,
    String? entityId,
    int? entityLocalId,
    String? action,
    String? changedField,
    String? oldValue,
    String? newValue,
    String? performedBy,
    String? reason,
    String? ipAddress,
    String? notes,
    String? syncStatus,
  }) {
    return AuditLogModel()
      ..id = id
      ..auditId = auditId ?? this.auditId
      ..entityType = entityType ?? this.entityType
      ..entityId = entityId ?? this.entityId
      ..entityLocalId = entityLocalId ?? this.entityLocalId
      ..action = action ?? this.action
      ..changedField = changedField ?? this.changedField
      ..oldValue = oldValue ?? this.oldValue
      ..newValue = newValue ?? this.newValue
      ..performedBy = performedBy ?? this.performedBy
      ..reason = reason ?? this.reason
      ..ipAddress = ipAddress ?? this.ipAddress
      ..notes = notes ?? this.notes
      ..syncStatus = syncStatus ?? this.syncStatus
      ..createdAt = createdAt
      ..updatedAt = DateTime.now();
  }

  @override
  String toString() =>
      'AuditLogModel(id: $id, auditId: $auditId, '
      'entityType: $entityType, entityId: $entityId, '
      'action: $action, performedBy: $performedBy)';
}
