/// Base error class hierarchy for app-wide error handling
sealed class AppError implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError: $message (code: $code)';
}

/// Network-related errors
class NetworkError extends AppError {
  NetworkError({
    String message = 'Network connection failed',
    String? code,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'NETWORK_ERROR',
    stackTrace: stackTrace,
  );
}

/// Validation errors for user input
class ValidationError extends AppError {
  ValidationError({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'VALIDATION_ERROR',
    stackTrace: stackTrace,
  );
}

/// Unauthorized access errors
class UnauthorizedError extends AppError {
  UnauthorizedError({
    String message = 'Unauthorized access',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: 'UNAUTHORIZED',
    stackTrace: stackTrace,
  );
}

/// Resource not found errors
class NotFoundError extends AppError {
  NotFoundError({
    String message = 'Resource not found',
    String? code,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'NOT_FOUND',
    stackTrace: stackTrace,
  );
}

/// Server-side errors
class ServerError extends AppError {
  final int? statusCode;

  ServerError({
    String message = 'Server error occurred',
    this.statusCode,
    String? code,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'SERVER_ERROR',
    stackTrace: stackTrace,
  );
}

/// Cache operation errors
class CacheError extends AppError {
  CacheError({
    String message = 'Cache operation failed',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: 'CACHE_ERROR',
    stackTrace: stackTrace,
  );
}

/// Synchronization errors
class SyncError extends AppError {
  SyncError({
    String message = 'Sync failed',
    String? code,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'SYNC_ERROR',
    stackTrace: stackTrace,
  );
}

/// Database operation errors
class DatabaseError extends AppError {
  DatabaseError({
    String message = 'Database operation failed',
    String? code,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'DATABASE_ERROR',
    stackTrace: stackTrace,
  );
}

/// Firebase-specific errors
class FirebaseError extends AppError {
  FirebaseError({
    String message = 'Firebase operation failed',
    String? code,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'FIREBASE_ERROR',
    stackTrace: stackTrace,
  );
}

/// Generic unknown errors
class UnknownError extends AppError {
  UnknownError({
    String message = 'An unexpected error occurred',
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: 'UNKNOWN_ERROR',
    stackTrace: stackTrace,
  );
}
