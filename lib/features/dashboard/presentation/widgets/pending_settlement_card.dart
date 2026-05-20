import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/dashboard_models.dart';

/// Settlement status card on the dashboard.
///
/// Renders one of three distinct states derived from [PendingSettlement.cardState]:
///
///   [SettlementCardState.pending]    — outstanding amount, action required.
///                                      Warm amber tones, schedule icon.
///   [SettlementCardState.inProgress] — partial progress.
///                                      Neutral blue, timelapse icon.
///   [SettlementCardState.settled]    — everything cleared.
///                                      Calm green, check-circle icon.
///
/// No state is hardcoded — all colors, icons, and labels are derived from
/// the model so the card automatically updates when payments are confirmed.
class PendingSettlementCard extends StatelessWidget {
  final PendingSettlement settlement;
  final VoidCallback? onTap;

  const PendingSettlementCard({
    super.key,
    required this.settlement,
    this.onTap,
  });

  // Month name lookup — index 0 unused so month integers map directly.
  static const List<String> _months = [
    '',
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = settlement.cardState;
    final style = _StateStyle.of(context, state);
    final monthLabel =
        '${_months[settlement.month]} ${settlement.year}';

    return AppCard(
      onTap: onTap,
      backgroundColor: style.cardBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: icon + label + subtitle ────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge + title
                Row(
                  children: [
                    _IconBadge(
                      icon: style.icon,
                      iconColor: style.accentColor,
                      backgroundColor: style.badgeBackground,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        style.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Subtitle
                Text(
                  _buildSubtitle(settlement),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          // ── Right: amount (or "All Clear") + month ────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (state == SettlementCardState.settled) ...[
                // Calm "All Clear" label — no rupee amount
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: style.accentColor.withAlpha(22),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'All Clear',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: style.accentColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ] else ...[
                // Outstanding amount
                Text(
                  '₹${settlement.totalAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: style.accentColor,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                monthLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(PendingSettlement s) {
    switch (s.cardState) {
      case SettlementCardState.settled:
        return 'Everything is clear for this month';
      case SettlementCardState.inProgress:
        final total = s.transactionCount + s.completedCount;
        return '${s.completedCount} of $total payments settled';
      case SettlementCardState.pending:
        final n = s.transactionCount;
        return '$n ${n == 1 ? 'transaction' : 'transactions'} need attention';
    }
  }
}

// ── Icon badge ────────────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}

// ── State style data ──────────────────────────────────────────────────────────

/// Immutable bundle of visual properties for one [SettlementCardState].
///
/// Computed once per [build] call via [_StateStyle.of] — no widget state
/// needed.  All alpha values are chosen for WCAG-legible contrast.
class _StateStyle {
  const _StateStyle._({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.badgeBackground,
    required this.cardBackground,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Color badgeBackground;
  final Color? cardBackground; // null → AppCard default (white)

  factory _StateStyle.of(BuildContext context, SettlementCardState state) {
    switch (state) {
      // ── Pending ── warm amber, action-required feel ─────────────────
      case SettlementCardState.pending:
        return const _StateStyle._(
          title: 'Settlement Pending',
          icon: Icons.pending_actions_rounded,
          // Amber-800 — legible on white, warmer than raw yellow
          accentColor: Color(0xFFB45309),
          // Very light amber wash for the icon container
          badgeBackground: Color(0x35FFC107),
          // Hairline amber tint on the card itself
          cardBackground: Color(0xFFFFFBF2),
        );

      // ── In-progress ── neutral blue, progress feel ──────────────────
      case SettlementCardState.inProgress:
        return _StateStyle._(
          title: 'In Progress',
          icon: Icons.timelapse_rounded,
          accentColor: Theme.of(context).colorScheme.primary,
          badgeBackground:
              Theme.of(context).colorScheme.primary.withAlpha(28),
          cardBackground: null, // default white — no colour push
        );

      // ── Settled ── calm green, closure feel ─────────────────────────
      case SettlementCardState.settled:
        return const _StateStyle._(
          title: 'All Settled',
          icon: Icons.check_circle_outline_rounded,
          // Green-800 — muted, trustworthy, not flashy
          accentColor: Color(0xFF2E7D32),
          badgeBackground: Color(0x302E7D32),
          // Very subtle green wash — calm, not celebratory
          cardBackground: Color(0xFFF4FBF4),
        );
    }
  }
}
