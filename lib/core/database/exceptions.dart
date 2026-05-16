/// Database-specific exceptions
class DatabaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  DatabaseException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'DatabaseException: $message${code != null ? ' (code: $code)' : ''}';
}

class EntityNotFoundError extends DatabaseException {
  EntityNotFoundError({
    required String entityType,
    required String entityId,
  }) : super(
    message: 'Entity not found: $entityType with id $entityId',
    code: 'ENTITY_NOT_FOUND',
  );
}

class UniqueConstraintError extends DatabaseException {
  UniqueConstraintError({
    required String field,
    required String value,
  }) : super(
    message: 'Unique constraint failed: $field = $value',
    code: 'UNIQUE_CONSTRAINT',
  );
}

class InvalidOperationError extends DatabaseException {
  InvalidOperationError({
    required String message,
  }) : super(
    message: message,
    code: 'INVALID_OPERATION',
  );
}

class SyncError extends DatabaseException {
  SyncError({
    required String message,
    dynamic originalError,
  }) : super(
    message: message,
    code: 'SYNC_ERROR',
    originalError: originalError,
  );
}

class ValidationError extends DatabaseException {
  ValidationError({
    required String message,
  }) : super(
    message: message,
    code: 'VALIDATION_ERROR',
  );
}

class BusinessRuleError extends DatabaseException {
  BusinessRuleError({
    required String message,
  }) : super(
    message: message,
    code: 'BUSINESS_RULE_VIOLATED',
  );
}

/// Business rule violations
class DriverAlreadyAssignedError extends BusinessRuleError {
  DriverAlreadyAssignedError({
    required String driverId,
    required DateTime tripDate,
  }) : super(
    message: 'Driver is already assigned to a trip on ${tripDate.toLocal()}',
  );
}

class TripAlreadyExistsError extends BusinessRuleError {
  TripAlreadyExistsError({
    required DateTime tripDate,
  }) : super(
    message: 'A trip already exists for ${tripDate.toLocal()}. Only one trip per day allowed.',
  );
}

class ExpenseLockedError extends BusinessRuleError {
  ExpenseLockedError() : super(
    message: 'Cannot modify expenses. This trip is locked for settlement.',
  );
}

class SettlementAlreadyExistsError extends BusinessRuleError {
  SettlementAlreadyExistsError({
    required int month,
    required int year,
  }) : super(
    message: 'Settlement already exists for $month/$year.',
  );
}

class InvalidSettlementError extends BusinessRuleError {
  InvalidSettlementError({
    required String reason,
  }) : super(
    message: 'Settlement validation failed: $reason',
  );
}
