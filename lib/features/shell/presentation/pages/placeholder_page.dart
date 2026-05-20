import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

/// Generic placeholder screen used for tabs that are not yet implemented.
///
/// Displays a centred [icon], the [title] of the section and a
/// "Coming Soon" subtitle — matching the overall Material 3 theme.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    Key? key,
    required this.title,
    required this.icon,
  }) : super(key: key);

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon badge
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: AppSpacing.iconXl,
                    color: colorScheme.primary.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Section title
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Coming soon label
                Text(
                  'Coming Soon',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.45),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Decorative pill chip
                Chip(
                  label: const Text('In development'),
                  avatar: Icon(
                    Icons.construction_rounded,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  backgroundColor: colorScheme.secondaryContainer.withOpacity(0.6),
                  labelStyle: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
