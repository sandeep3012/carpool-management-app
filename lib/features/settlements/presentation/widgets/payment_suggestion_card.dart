import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/settlement_models.dart';

// ── Avatar colour palette ─────────────────────────────────────────────────────
const List<Color> _kAvatarColors = [
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
  Color(0xFF2E7D32),
  Color(0xFFBF360C),
  Color(0xFF00695C),
];
Color _avatarColor(int idx) => _kAvatarColors[idx % _kAvatarColors.length];

// ── Status colours ────────────────────────────────────────────────────────────
Color _statusColor(String status) {
  switch (status) {
    case PaymentStatus.completed:
      return const Color(0xFF2E7D32);
    case PaymentStatus.confirmed:
      return const Color(0xFF1565C0);
    default:
      return const Color(0xFFE65100);
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case PaymentStatus.completed:
      return Icons.check_circle_rounded;
    case PaymentStatus.confirmed:
      return Icons.schedule_rounded;
    default:
      return Icons.pending_rounded;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case PaymentStatus.completed:
      return 'Paid';
    case PaymentStatus.confirmed:
      return 'Confirmed';
    default:
      return 'Pending';
  }
}

// ── Payment suggestion card ───────────────────────────────────────────────────

/// Card that visualises a single optimised payment:
///   [Payer avatar] ──── ₹amount ────→ [Payee avatar]
///
/// Tapping the action button advances the payment status.
/// A long press resets it (demo convenience).
class PaymentSuggestionCard extends StatelessWidget {
  const PaymentSuggestionCard({
    super.key,
    required this.payment,
    required this.onConfirm,
    this.onReset,
    this.isCompact = false,
  });

  final PaymentSuggestion payment;
  final VoidCallback onConfirm;
  final VoidCallback? onReset;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(payment.status);
    final isDone = !payment.isPending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDone
            ? statusColor.withAlpha(10)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDone
              ? statusColor.withAlpha(60)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          children: [
            // Payment flow row
            Row(
              children: [
                // Payer
                _PayerChip(
                  name: payment.fromName,
                  initials: payment.fromInitials,
                  colorIndex: payment.fromColorIndex,
                ),

                // Arrow + amount
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '₹${payment.amount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDone
                              ? statusColor
                              : theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    isDone
                                        ? statusColor.withAlpha(160)
                                        : theme.colorScheme.primary
                                            .withAlpha(120),
                                    isDone
                                        ? statusColor
                                        : theme.colorScheme.primary,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isDone
                                ? statusColor
                                : theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Payee
                _PayerChip(
                  name: payment.toName,
                  initials: payment.toInitials,
                  colorIndex: payment.toColorIndex,
                  isPayee: true,
                ),
              ],
            ),

            if (!isCompact) ...[
              const SizedBox(height: AppSpacing.md),

              // Status row + action button
              Row(
                children: [
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(20),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(payment.status),
                            size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(payment.status),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Action button
                  if (payment.isPending)
                    FilledButton.tonal(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Mark Paid'),
                    )
                  else if (payment.isConfirmed)
                    FilledButton(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Confirm Receipt'),
                    )
                  else
                    GestureDetector(
                      onLongPress: onReset,
                      child: Icon(Icons.check_circle_rounded,
                          color: statusColor, size: 28),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Payer / payee chip ────────────────────────────────────────────────────────

class _PayerChip extends StatelessWidget {
  const _PayerChip({
    required this.name,
    required this.initials,
    required this.colorIndex,
    this.isPayee = false,
  });

  final String name;
  final String initials;
  final int colorIndex;
  final bool isPayee;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(colorIndex);
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withAlpha(40),
            child: Text(
              initials,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name.split(' ').first,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: isPayee ? FontWeight.w600 : FontWeight.w400,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Settlement progress bar ───────────────────────────────────────────────────

/// Horizontal progress indicator showing how many payments are done.
class SettlementProgressBar extends StatelessWidget {
  const SettlementProgressBar({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : completed / total;
    final color = progress >= 1.0
        ? const Color(0xFF2E7D32)
        : theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Settlement Progress',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '$completed of $total paid',
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
