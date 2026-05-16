import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/auth_state_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({Key? key}) : super(key: key);

  void _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    final isActive = user.isActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: user.role == 'admin'
                          ? AppColors.primary
                          : AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.role == 'admin' ? '👨‍💼' : '👤',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            // User Details Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildInfoRow(
                    context,
                    'Email',
                    user.email,
                    Icons.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow(
                    context,
                    'Role',
                    (user.role ?? 'member').toUpperCase(),
                    user.role == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    roleColor: user.role == 'admin'
                        ? AppColors.primary
                        : AppColors.secondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow(
                    context,
                    'Status',
                    isActive ? 'Active' : 'Inactive',
                    Icons.check_circle,
                    statusColor:
                        isActive ? AppColors.success : AppColors.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Role-Based Features Card
            if (user.role == 'admin')
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Admin Features',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeatureItem('Approve Settlements'),
                    _buildFeatureItem('View Audit Logs'),
                    _buildFeatureItem('Manage Members'),
                    _buildFeatureItem('Generate Reports'),
                  ],
                ),
              ),
            if (user.role == 'member')
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Member Features',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeatureItem('View Trips'),
                    _buildFeatureItem('Add Expenses'),
                    _buildFeatureItem('View Settlements'),
                    _buildFeatureItem('Manage Profile'),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Logout',
              variant: ButtonVariant.danger,
              size: ButtonSize.medium,
              onPressed: () => _logout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? roleColor,
    Color? statusColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: roleColor ?? statusColor ?? Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: roleColor ?? statusColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: AppSpacing.md),
          Text(feature),
        ],
      ),
    );
  }
}
