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
const Color _settledColor = Color(0xFF546E7A); // grey  — even

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

/// Tappable card that shows one member's net balance with a colour-coded
/// amount and a subtle background tint.  Used in the balance grid on the
/// settlement summary screen.
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
    final isCredit = balance.status == BalanceStatus.credit;
    final isDebit = balance.status == BalanceStatus.debit;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withAlpha(14),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      _avatarColor(balance.colorIndex).withAlpha(40),
                  child: Text(
                    balance.memberInitials,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _avatarColor(balance.colorIndex),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (balance.isCurrentUser)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.person,
                        size: 8, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // First name
            Text(
              balance.memberName.split(' ').first,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Balance chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(22),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

            const SizedBox(height: AppSpacing.xs),

            // Credit / Debit label
            Text(
              isCredit
                  ? 'gets back'
                  : isDebit
                      ? 'needs to pay'
                      : 'all clear',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withAlpha(180),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal balance row (my balance banner) ────────────────────────────────

/// Prominent banner at the top of the screen showing the current user's
/// net position.  Uses a gradient background to make it feel premium.
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
        children: [
          // Icon
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

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCredit
                      ? 'You are owed'
                      : isDebit
                          ? 'You owe'
                          : 'You\'re all settled!',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                if (!balance.status.contains('settled'))
                  Text(
                    '₹${balance.absBalance.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),

          // Trips driven badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
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
