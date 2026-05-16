import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_error.dart';

/// Centralized error handling service
class ErrorHandler {
  final Ref _ref;

  ErrorHandler(this._ref);

  /// Wrap async operations with error handling
  Future<T> handle<T>(
    Future<T> Function() operation, {
    String? customMessage,
    bool rethrowError = true,
  }) async {
    try {
      return await operation();
    } on AppError {
      rethrow;
    } catch (e, stack) {
      final error = UnknownError(
        message: customMessage ?? 'An unexpected error occurred',
        stackTrace: stack,
      );
      if (rethrowError) rethrow;
      throw error;
    }
  }
}
