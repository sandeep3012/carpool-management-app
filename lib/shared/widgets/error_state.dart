import 'package:flutter/material.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Error state widget
class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String title;
  final String? subtitle;

  const ErrorState({
    required this.error,
    this.onRetry,
    this.title = 'Something went wrong',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = _getErrorMessage();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle ?? errorMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Try Again',
                onPressed: onRetry!,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorMessage() {
    if (error is AppError) {
      return (error as AppError).message;
    }
    if (error is String) {
      return error as String;
    }
    return 'An unexpected error occurred';
  }
}
