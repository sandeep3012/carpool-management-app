import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/settlement_models.dart';
import '../providers/settlements_provider.dart';
import '../widgets/member_balance_card.dart';
import '../widgets/payment_suggestion_card.dart';
import 'settlement_detail_page.dart';

/// Main settlements tab — single-screen overview designed to answer:
///   "Who should pay, how much, to whom, and what's already done?"
///
/// Layout:
///   ① My Balance Banner  — big, coloured, emotionally clear
///   ② Settlement progress bar
///   ③ Pending payment cards (action needed)
///   ④ All members balance row (scrollable chips)
///   ⑤ "View full detail" link → SettlementDetailPage
class SettlementsPage extends ConsumerWidget {
  const SettlementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettlement = ref.watch(settlementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(settlementProvider.notifier).refresh(),
          ),
        ],
      ),
      body: asyncSettlement.when(
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.read(settlementProvider.notifier).refresh(),
        ),
        data: (settlement) => _SettlementBody(settlement: settlement),
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _SettlementBody extends ConsumerWidget {
  const _SettlementBody({required this.settlement});
  final MonthlySettlement settlement;

  static const List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myBalance = ref.watch(myBalanceProvider);
    final notifier = ref.read(settlementProvider.notifier);
    final theme = Theme.of(context);

    final pendingPayments = settlement.payments
        .where((p) => p.isPending || p.isConfirmed)
        .toList();

    return RefreshIndicator(
      onRefresh: () async => notifier.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Month label
          Text(
            '${_months[settlement.month]} ${settlement.year}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ① My balance banner
          if (myBalance != null) ...[
            MyBalanceBanner(balance: myBalance),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ② Settlement progress
          SettlementProgressBar(
            completed: settlement.completedPayments,
            total: settlement.payments.length,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ③ Pending payments
          if (pendingPayments.isEmpty && settlement.isFullySettled) ...[
            _AllSettledBanner(),
            const SizedBox(height: AppSpacing.xl),
          ] else if (pendingPayments.isNotEmpty) ...[
            _SectionHeader(
              title: 'Payments Needed',
              badge: pendingPayments.length.toString(),
              badgeColor: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            ...pendingPayments.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: PaymentSuggestionCard(
                  payment: p,
                  onConfirm: () => _onConfirm(context, ref, notifier, p),
                  onReset: () => notifier.resetPayment(p.id),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // ④ Member balance grid
          _SectionHeader(title: 'All Balances'),
          const SizedBox(height: AppSpacing.md),
          _HorizontalBalanceRow(balances: settlement.memberBalances),
          const SizedBox(height: AppSpacing.xl),

          // ⑤ Summary stats row
          _StatsRow(settlement: settlement),
          const SizedBox(height: AppSpacing.xl),

          // ⑥ View full detail link
          OutlinedButton.icon(
            onPressed: () => _openDetail(context, settlement.id),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('View Full Settlement Detail'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Future<void> _onConfirm(
    BuildContext context,
    WidgetRef ref,
    SettlementNotifier notifier,
    PaymentSuggestion payment,
  ) async {
    final result = await _showConfirmSheet(context, payment);
    if (result == true) {
      notifier.confirmPayment(payment.id);
    }
  }

  Future<bool?> _showConfirmSheet(
      BuildContext context, PaymentSuggestion payment) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickConfirmSheet(payment: payment),
    );
  }

  void _openDetail(BuildContext context, String settlementId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettlementDetailPage(settlementId: settlementId),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.badge, this.badgeColor});
  final String title;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (badge != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeColor ?? Theme.of(context).colorScheme.primary)
                  .withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              badge!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: badgeColor ??
                        Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Horizontal balance row ────────────────────────────────────────────────────
//
// Uses SingleChildScrollView + IntrinsicHeight + Row so the row height is
// driven entirely by card content — no hardcoded height, no clipping.
// IntrinsicHeight forces all cards in the Row to match the tallest card,
// which is itself sized by the card's Column(mainAxisSize: MainAxisSize.min).

class _HorizontalBalanceRow extends StatelessWidget {
  const _HorizontalBalanceRow({required this.balances});
  final List<MemberBalance> balances;

  @override
  Widget build(BuildContext context) {
    final cardWidth = BalanceCardMetrics.preferredWidth(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < balances.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: cardWidth,
                child: MemberBalanceCard(balance: balances[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.settlement});
  final MonthlySettlement settlement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.directions_car_rounded,
            label: 'Trips',
            value: '${settlement.totalTrips}',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: Icons.currency_rupee_rounded,
            label: 'Total Spent',
            value: '₹${settlement.totalExpense.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: Icons.swap_horiz_rounded,
            label: 'Payments',
            value: '${settlement.completedPayments}/${settlement.payments.length}',
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      // IntrinsicHeight lets the chip grow naturally without a fixed height.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          // FittedBox prevents wide values (e.g. "₹3,820") from overflowing
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── All settled banner ────────────────────────────────────────────────────────

class _AllSettledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: const Color(0xFF2E7D32).withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded,
              color: Color(0xFF2E7D32), size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Settled!',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Everyone is even for this month.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            const Color(0xFF2E7D32).withAlpha(180),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick confirm sheet ───────────────────────────────────────────────────────

class _QuickConfirmSheet extends StatelessWidget {
  const _QuickConfirmSheet({required this.payment});
  final PaymentSuggestion payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = payment.isPending;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              isPending
                  ? '${payment.fromName} sent ₹${payment.amount.toStringAsFixed(0)}\nto ${payment.toName}?'
                  : '${payment.toName} received ₹${payment.amount.toStringAsFixed(0)}\nfrom ${payment.fromName}?',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Confirm',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not Yet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _SkeletonBox(height: 90,
              borderRadius: AppSpacing.radiusXl),
          const SizedBox(height: AppSpacing.lg),
          _SkeletonBox(height: 40),
          const SizedBox(height: AppSpacing.lg),
          _SkeletonBox(height: 100,
              borderRadius: AppSpacing.radiusXl),
          const SizedBox(height: AppSpacing.md),
          _SkeletonBox(height: 100,
              borderRadius: AppSpacing.radiusXl),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.borderRadius = 8});
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(80)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load settlement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check your connection and try again.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(140),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
