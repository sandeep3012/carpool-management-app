import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/settlement_models.dart';
import '../providers/settlements_provider.dart';
import '../widgets/member_balance_card.dart';
import '../widgets/payment_suggestion_card.dart';

/// Full-detail settlement screen for a single month.
///
/// Sections:
///   1. Header  — month label, total expense, trips count
///   2. Progress bar
///   3. Member balances grid
///   4. All payments (pending first, then completed)
///
/// Each payment card has an action button that advances its status.
/// Completed payments can be long-pressed to reset (demo convenience).
class SettlementDetailPage extends ConsumerWidget {
  const SettlementDetailPage({super.key, required this.settlementId});

  final String settlementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettlement = ref.watch(settlementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement Detail'),
        centerTitle: false,
        elevation: 0,
      ),
      body: asyncSettlement.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (settlement) => _DetailBody(settlement: settlement),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.settlement});
  final MonthlySettlement settlement;

  static const List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settlementProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pendingPayments = settlement.payments
        .where((p) => p.isPending || p.isConfirmed)
        .toList();
    final donePayments =
        settlement.payments.where((p) => p.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Header card
        _HeaderCard(settlement: settlement, months: _months),
        const SizedBox(height: AppSpacing.lg),

        // Progress bar
        SettlementProgressBar(
          completed: settlement.completedPayments,
          total: settlement.payments.length,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Member balances grid
        Text(
          'Member Balances',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        _BalancesGrid(balances: settlement.memberBalances),
        const SizedBox(height: AppSpacing.xl),

        // Payments — action needed
        if (pendingPayments.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Action Needed',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.error.withAlpha(20),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${pendingPayments.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...pendingPayments.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PaymentSuggestionCard(
                payment: p,
                onConfirm: () => _confirm(context, ref, notifier, p),
                onReset: () => notifier.resetPayment(p.id),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Payments — completed
        if (donePayments.isNotEmpty) ...[
          Text(
            'Settled',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ...donePayments.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PaymentSuggestionCard(
                payment: p,
                onConfirm: () {},
                onReset: () => notifier.resetPayment(p.id),
              ),
            ),
          ),
        ],

        // All settled empty state
        if (settlement.isFullySettled)
          _AllSettledCard(),

        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    SettlementNotifier notifier,
    PaymentSuggestion payment,
  ) async {
    final confirmed = await _showConfirmSheet(context, payment);
    if (confirmed == true) {
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
      builder: (_) => _PaymentConfirmSheet(payment: payment),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.settlement,
    required this.months,
  });
  final MonthlySettlement settlement;
  final List<String> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${months[settlement.month]} ${settlement.year}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${settlement.totalTrips} trips',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total Expense',
                    style: theme.textTheme.labelSmall),
                Text(
                  '₹${settlement.totalExpense.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Balances grid ─────────────────────────────────────────────────────────────
//
// Responsive design decisions:
//   • Uses Wrap so cards self-size to their content — no hardcoded heights.
//   • Card width is derived from BalanceCardMetrics so it tracks text scale.
//   • Wrap automatically flows cards to the next row on narrow screens.
//   • No GridView / mainAxisExtent needed — eliminating fragile pixel math.

class _BalancesGrid extends StatelessWidget {
  const _BalancesGrid({required this.balances});
  final List<MemberBalance> balances;

  @override
  Widget build(BuildContext context) {
    final cardWidth = BalanceCardMetrics.preferredWidth(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: balances
          .map((b) => SizedBox(width: cardWidth, child: MemberBalanceCard(balance: b)))
          .toList(),
    );
  }
}

// ── All settled card ──────────────────────────────────────────────────────────

class _AllSettledCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: const Color(0xFF2E7D32).withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration_rounded,
              size: 40, color: Color(0xFF2E7D32)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'All settled!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            'Everyone is even for this month.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF2E7D32).withAlpha(180),
                ),
          ),
        ],
      ),
    );
  }
}

// ── Payment confirmation bottom sheet ─────────────────────────────────────────

class _PaymentConfirmSheet extends StatelessWidget {
  const _PaymentConfirmSheet({required this.payment});
  final PaymentSuggestion payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfirming = payment.isPending;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child: Icon(
                isConfirming
                    ? Icons.send_rounded
                    : Icons.verified_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              isConfirming
                  ? 'Confirm Payment Sent'
                  : 'Confirm Payment Received',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isConfirming
                  ? '${payment.fromName} will confirm they sent ₹${payment.amount.toStringAsFixed(0)} to ${payment.toName}.'
                  : '${payment.toName} confirms they received ₹${payment.amount.toStringAsFixed(0)} from ${payment.fromName}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(160),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  isConfirming ? 'Yes, I sent ₹${payment.amount.toStringAsFixed(0)}' : 'Yes, I received it',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text('Unable to load settlement',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
