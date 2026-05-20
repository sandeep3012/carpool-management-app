import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/upcoming_drive_card.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_trips_section.dart';
import '../widgets/pending_settlement_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _onNewTrip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New Trip — Coming soon')),
    );
  }

  void _onViewSettlement() {
    context.go('/home/settlements');
  }

  void _onViewReport() {
    // Reports tab not yet available — surface a friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports — Coming soon')),
    );
  }

  void _onUpcomingDriveTap(String tripId) {
    // Navigate to trip detail when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trip detail: $tripId — Coming soon')),
    );
  }

  void _onPendingSettlementTap() {
    context.go('/home/settlements');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dashboardState = ref.watch(dashboardStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        centerTitle: false,
      ),
      body: dashboardState.when(
        data: (data) {
          return _DashboardContent(
            data: data,
            onNewTrip: _onNewTrip,
            onViewSettlement: _onViewSettlement,
            onViewReport: _onViewReport,
            onUpcomingDriveTap: _onUpcomingDriveTap,
            onPendingSettlementTap: _onPendingSettlementTap,
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildSkeletonCard(height: 140),
          const SizedBox(height: AppSpacing.lg),
          _buildSkeletonCard(height: 200),
          const SizedBox(height: AppSpacing.lg),
          _buildSkeletonCard(height: 200),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return ErrorState(
      error: error,
      title: 'Unable to load dashboard',
      subtitle: 'Please check your connection and try again.',
      onRetry: () {
        ref.invalidate(dashboardStateProvider);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardState data;
  final VoidCallback onNewTrip;
  final VoidCallback onViewSettlement;
  final VoidCallback onViewReport;
  final Function(String) onUpcomingDriveTap;
  final VoidCallback onPendingSettlementTap;

  const _DashboardContent({
    required this.data,
    required this.onNewTrip,
    required this.onViewSettlement,
    required this.onViewReport,
    required this.onUpcomingDriveTap,
    required this.onPendingSettlementTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expense Summary Card
          _AnimatedCard(
            delay: 0,
            child: ExpenseSummaryCard(summary: data.summary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Actions
          _AnimatedCard(
            delay: 1,
            child: QuickActionsSection(
              onNewTrip: onNewTrip,
              onViewSettlement: onViewSettlement,
              onViewReport: onViewReport,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Pending Settlement (if any)
          if (data.pendingSettlement != null) ...[
            _AnimatedCard(
              delay: 2,
              child: PendingSettlementCard(
                settlement: data.pendingSettlement!,
                onTap: onPendingSettlementTap,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Upcoming Drives
          if (data.upcomingDrives.isNotEmpty) ...[
            _AnimatedCard(
              delay: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Drives',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.upcomingDrives.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final drive = data.upcomingDrives[index];
                      return UpcomingDriveCard(
                        drive: drive,
                        onTap: () => onUpcomingDriveTap(drive.id),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Recent Trips
          _AnimatedCard(
            delay: 4,
            child: RecentTripsSection(
              trips: data.recentTrips,
              onViewAll: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final int delay;
  final Widget child;

  const _AnimatedCard({
    required this.delay,
    required this.child,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
