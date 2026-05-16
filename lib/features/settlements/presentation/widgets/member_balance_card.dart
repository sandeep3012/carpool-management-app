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

// ── Balance colour helpers ────────────────────────────────────────────────────
const Color _creditColor = Color(0xFF2E7D32); // green — owed money
const Color _debitColor = Color(0xFFC62828); // red   — owes money
const Color _settledColor = Color(0xFF546E7A); // grey  — settled

Color _balanceColor(MemberBalance b) {
  switch (b.status) {
    case BalanceStatus.credit:
      return _creditColor;
    case BalanceStatus.debit:
      return _debitColor;
    default:
      return _settledColor;
  }
}

// ── Full member balance card ──────────────────────────────────────────────────
//
// Responsive contract:
//   • Avatar is fixed-size (radius 18 = 36 px diameter) — it never scales.
//   • Every text widget is wrapped in FittedBox(fit: BoxFit.scaleDown) so it
//     shrinks to fit the available width instead of wrapping or overflowing.
//   • Padding uses tight symmetric values so the card fits in cells as narrow
//     as ~68 px without overflowing vertically.
//   • Labels are intentionally short:  "owed" / "owes" / "even"  (≤ 4 chars).
//
// Callers are responsible for providing enough HEIGHT (≥ 118 px at scale 1.0).
// Use BalanceCardMetrics.minHeight(context) for the canonical value.

class MemberBalanceCard extends StatelessWidget {
  const MemberBalanceCard({
    super.key,
    required this.balance,
    this.onTap,
  });

  final MemberBalance balance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _balanceColor(balance);
    final avatarColor = _avatarColor(balance.colorIndex);
    final isCredit = balance.status == BalanceStatus.credit;
    final isDebit = balance.status == BalanceStatus.debit;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Tight horizontal padding keeps card usable in narrow grid cells.
        // Vertical padding is explicit so intrinsic height stays predictable.
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(14),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar (fixed 36 × 36 px) ──────────────────────────────────
            Stack(
              alignment: Alignment.bottomRight,
              // clipBehavior: none so the badge renders outside the avatar
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor.withAlpha(40),
                  // FittedBox keeps initials inside even at large system fonts
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        balance.memberInitials,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: avatarColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                if (balance.isCurrentUser)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 7,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // ── First name ─────────────────────────────────────────────────
            // FittedBox scales the text DOWN if it is wider than the cell,
            // preventing wrapping and height overflow.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                balance.memberName.split(' ').first,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
            ),

            const SizedBox(height: 4),

            // ── Balance chip ───────────────────────────────────────────────
            // FittedBox ensures "+₹145" or "Settled" never overflows the cell.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  balance.status == BalanceStatus.settled
                      ? 'Settled'
                      : '${isCredit ? '+' : '−'}₹${balance.absBalance.toStringAsFixed(0)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Short status label ─────────────────────────────────────────
            // "owed" / "owes" / "even" — max 4 chars, safe even in 60 px cells.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isCredit
                    ? 'owed'
                    : isDebit
                        ? 'owes'
                        : 'even',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withAlpha(180),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sizing helper ──────────────────────────────────────────────────────

/// Canonical sizing constants for callers that must allocate space for a
/// [MemberBalanceCard] (e.g. scrollable rows and grid delegates).
///
/// Always read these values from the widget tree so they respect the current
/// [MediaQuery.textScalerOf] setting.
class BalanceCardMetrics {
  BalanceCardMetrics._();

  /// Minimum card height at the current text scale.
  /// Base is 118 px at scale 1.0; grows linearly, capped at 200 px.
  static double minHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return (118.0 * scale).clamp(118.0, 200.0);
  }

  /// Recommended card width at the current text scale.
  /// Base is 84 px at scale 1.0; grows proportionally.
  static double preferredWidth(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return (84.0 * scale).clamp(80.0, 130.0);
  }
}

// ── My Balance Banner ─────────────────────────────────────────────────────────

/// Prominent gradient banner showing the current user's net position.
///
/// Uses [Flexible] for the text column and [FittedBox] on the amount so it
/// never overflows on narrow screens or with large system fonts.
class MyBalanceBanner extends StatelessWidget {
  const MyBalanceBanner({super.key, required this.balance});

  final MemberBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = balance.status == BalanceStatus.credit;
    final isDebit = balance.status == BalanceStatus.debit;

    final bgColor = isCredit
        ? const Color(0xFF2E7D32)
        : isDebit
            ? const Color(0xFFC62828)
            : const Color(0xFF546E7A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge — fixed 48×48
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(30),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : isDebit
                      ? Icons.arrow_upward_rounded
                      : Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Text column — Expanded pushes the trips-driven badge to the right edge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCredit
                      ? 'You are owed'
                      : isDebit
                          ? 'You owe'
                          : "You're all settled!",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!balance.status.contains('settled'))
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${balance.absBalance.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Trips driven badge — fixed, right-aligned
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${balance.tripsDriven}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'trips driven',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
