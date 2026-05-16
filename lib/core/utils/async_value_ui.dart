import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_error.dart';

/// Extension methods for AsyncValue to handle UI state in widgets
extension AsyncValueUI<T> on AsyncValue<T> {
  /// Show snackbar on error
  void showSnackbarOnError(BuildContext context) {
    if (this is AsyncError<T>) {
      final err = (this as AsyncError<T>).error;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(err)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Get human-readable error message
  String _getErrorMessage(Object error) {
    if (error is AppError) {
      return error.message;
    }
    if (error is String) {
      return error;
    }
    return 'An unexpected error occurred';
  }
}
