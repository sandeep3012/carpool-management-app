import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/trip_entry_model.dart';

// ── Avatar colour palette (maps colorIndex → seed hue) ───────────────────────

const List<Color> _kAvatarColors = [
  Color(0xFF1565C0), // blue  – index 0 (Rajesh / current user)
  Color(0xFF6A1B9A), // purple – index 1 (Priya)
  Color(0xFF2E7D32), // green  – index 2 (Suresh)
  Color(0xFFBF360C), // deep-orange – index 3 (Kavitha)
  Color(0xFF00695C), // teal   – index 4 (Arun)
];

Color _avatarColor(int index) => _kAvatarColors[index % _kAvatarColors.length];

// ── Public API ────────────────────────────────────────────────────────────────

/// Horizontal scrolling avatar row for selecting trip attendees.
///
/// Each avatar is a filled circle with the member's initials.
/// Tapping toggles attendance; a checkmark overlay confirms selection.
/// The driver is always pre-selected and cannot be deselected.
class AttendanceSelector extends StatelessWidget {
  const AttendanceSelector({
    super.key,
    required this.members,
    required this.selectedIds,
    required this.driverId,
    required this.onToggle,
  });

  final List<MemberModel> members;
  final Set<String> selectedIds;
  final String? driverId;
  final ValueChanged<MemberModel> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Text(
              'Attendees',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${selectedIds.length} of ${members.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Scrollable avatar row
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final member = members[index];
              return _MemberAvatar(
                member: member,
                isSelected: selectedIds.contains(member.id),
                isDriver: member.id == driverId,
                onTap: () => onToggle(member),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Avatar tile ───────────────────────────────────────────────────────────────

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.member,
    required this.isSelected,
    required this.isDriver,
    required this.onTap,
  });

  final MemberModel member;
  final bool isSelected;
  final bool isDriver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(member.colorIndex);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : color.withAlpha(50),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      member.initials,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Driver crown badge
                if (isDriver)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.tertiary,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  )
                // Checkmark badge
                else if (isSelected)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              member.name.split(' ').first,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withAlpha(120),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Driver selector ───────────────────────────────────────────────────────────

/// Horizontal chip row for selecting the single driver.
class DriverSelector extends StatelessWidget {
  const DriverSelector({
    super.key,
    required this.members,
    required this.selectedDriverId,
    required this.onSelect,
  });

  final List<MemberModel> members;
  final String? selectedDriverId;
  final ValueChanged<MemberModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final m = members[index];
              final isSelected = m.id == selectedDriverId;
              final color = _avatarColor(m.colorIndex);
              return ChoiceChip(
                label: Text(m.name.split(' ').first),
                selected: isSelected,
                onSelected: (_) => onSelect(m),
                selectedColor: color.withAlpha(30),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? color : null,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected ? color : Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm),
              );
            },
          ),
        ),
      ],
    );
  }
}
