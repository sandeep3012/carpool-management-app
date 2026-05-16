import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'loading_indicator.dart';
import 'error_state.dart';
import 'empty_state.dart';

/// Universal widget builder for AsyncValue states
class AsyncValueBuilder<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) onData;
  final Widget Function()? onLoading;
  final Widget Function(Object error, StackTrace stack)? onError;
  final Widget Function()? onEmpty;

  const AsyncValueBuilder({
    required this.asyncValue,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) {
        if (data is List<dynamic> && (data).isEmpty) {
          return onEmpty?.call() ?? const EmptyState();
        }
        return onData(data);
      },
      loading: () => onLoading?.call() ?? const LoadingIndicator(),
      error: (error, stack) =>
          onError?.call(error, stack) ?? ErrorState(error: error),
    );
  }
}
