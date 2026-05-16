import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, tertiary, danger }
enum AppButtonSize { small, medium, large }

// Aliases for backward compatibility
typedef ButtonVariant = AppButtonVariant;
typedef ButtonSize = AppButtonSize;

/// Reusable button component with variants and sizes
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final double? height;

  const AppButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leading,
    this.trailing,
    this.width,
    this.height,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && !isLoading && onPressed != null;
    final (bgColor, fgColor, borderColor) = _getColors();

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? _getHeight(),
      child: variant == AppButtonVariant.primary
          ? _buildElevatedButton(bgColor, fgColor, effectiveEnabled)
          : variant == AppButtonVariant.secondary
              ? _buildOutlinedButton(fgColor, borderColor, effectiveEnabled)
              : _buildTextButton(fgColor, effectiveEnabled),
    );
  }

  Widget _buildElevatedButton(Color bgColor, Color fgColor, bool effectiveEnabled) {
    return ElevatedButton(
      onPressed: effectiveEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledBackgroundColor: AppColors.gray200,
        disabledForegroundColor: AppColors.gray500,
      ),
      child: _buildContent(fgColor),
    );
  }

  Widget _buildOutlinedButton(
    Color fgColor,
    Color borderColor,
    bool effectiveEnabled,
  ) {
    return OutlinedButton(
      onPressed: effectiveEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: effectiveEnabled ? borderColor : AppColors.gray300,
          width: 1.5,
        ),
        foregroundColor: fgColor,
      ),
      child: _buildContent(fgColor),
    );
  }

  Widget _buildTextButton(Color fgColor, bool effectiveEnabled) {
    return TextButton(
      onPressed: effectiveEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: fgColor,
        disabledForegroundColor: AppColors.gray400,
      ),
      child: _buildContent(fgColor),
    );
  }

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    final widgets = <Widget>[];
    if (leading != null) {
      widgets.add(leading!);
      widgets.add(const SizedBox(width: AppSpacing.sm));
    }
    widgets.add(Text(label));
    if (trailing != null) {
      widgets.add(const SizedBox(width: AppSpacing.sm));
      widgets.add(trailing!);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  (Color, Color, Color) _getColors() {
    return switch (variant) {
      AppButtonVariant.primary => (
        AppColors.primary,
        AppColors.white,
        AppColors.primary,
      ),
      AppButtonVariant.secondary => (
        AppColors.gray100,
        AppColors.gray900,
        AppColors.gray300,
      ),
      AppButtonVariant.tertiary => (
        Colors.transparent,
        AppColors.primary,
        Colors.transparent,
      ),
      AppButtonVariant.danger => (
        AppColors.error,
        AppColors.white,
        AppColors.error,
      ),
    };
  }

  double _getHeight() {
    return switch (size) {
      AppButtonSize.small => AppSpacing.buttonHeightSm,
      AppButtonSize.medium => AppSpacing.buttonHeightMd,
      AppButtonSize.large => AppSpacing.buttonHeightLg,
    };
  }
}
