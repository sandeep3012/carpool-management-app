import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/trip_entry_model.dart';
import '../providers/trips_provider.dart';
import '../widgets/trip_entry_sheet.dart';

// ── Avatar colour palette (mirrors attendance_selector.dart) ──────────────────
const List<Color> _kAvatarColors = [
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
  Color(0xFF2E7D32),
  Color(0xFFBF360C),
  Color(0xFF00695C),
];
Color _avatarColor(int idx) =>
    _kAvatarColors[idx % _kAvatarColors.length];

// ── Page ──────────────────────────────────────────────────────────────────────

/// Full trip detail screen — driven by a [TripEntry].
///
/// Shows: date/driver/status, attendee row, expense breakdown
/// (fuel formula + extras), per-person split, and an edit FAB.
class TripDetailPage extends ConsumerWidget {
  const TripDetailPage({super.key, required this.tripId});

  final String tripId;

  static const List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  String _fmtDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month]} ${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Look up the trip from the in-memory store
    final trips = ref.watch(tripsNotifierProvider);
    final TripEntry? trip =
        trips.cast<TripEntry?>().firstWhere(
              (t) => t?.id == tripId,
              orElse: () => null,
            );

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Detail')),
        body: const Center(child: Text('Trip not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Detail'),
        centerTitle: false,
        elevation: 0,
        actions: [
          _StatusChip(status: trip.status),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Date & driver card
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtDate(trip.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _Avatar(member: trip.driver),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driver.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Driver',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Attendees
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendees (${trip.passengerCount})',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: trip.attendees
                      .map((m) => _AttendeeChip(member: m,
                          isDriver: m.id == trip.driver.id))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Expense breakdown
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Breakdown',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.md),
                _ExpenseLine(
                  icon: Icons.local_gas_station_rounded,
                  label:
                      'Fuel (${trip.expenses.distanceKm.toStringAsFixed(0)} km'
                      ' ÷ ${trip.expenses.mileageKmpl.toStringAsFixed(0)} kmpl'
                      ' × ₹${trip.expenses.fuelRatePerLitre.toStringAsFixed(0)}/L)',
                  value: trip.expenses.fuelExpense,
                ),
                if (trip.expenses.tollExpense > 0)
                  _ExpenseLine(
                    icon: Icons.toll_rounded,
                    label: 'Toll',
                    value: trip.expenses.tollExpense,
                  ),
                if (trip.expenses.parkingExpense > 0)
                  _ExpenseLine(
                    icon: Icons.local_parking_rounded,
                    label: 'Parking',
                    value: trip.expenses.parkingExpense,
                  ),
                if (trip.expenses.otherExpense > 0)
                  _ExpenseLine(
                    icon: Icons.more_horiz_rounded,
                    label: 'Other',
                    value: trip.expenses.otherExpense,
                  ),
                const Divider(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _TotalBox(
                        label: 'Total',
                        value: trip.expenses.totalExpense,
                        primary: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _TotalBox(
                        label:
                            'Per person (${trip.passengerCount})',
                        value: trip.perPersonShare,
                        primary: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),

      // Edit FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onEdit(context, ref, trip),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Edit'),
      ),
    );
  }

  Future<void> _onEdit(
      BuildContext context, WidgetRef ref, TripEntry trip) async {
    // Pass the full existing trip so the sheet hydrates all fields and
    // reuses the original ID on save (no duplicate created).
    // No manual refresh needed — this page already watches tripsNotifierProvider
    // reactively, so it rebuilds automatically when the trip is upserted.
    await showTripEntrySheet(context, date: trip.date, existingTrip: trip);
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSpacing.elevationSm,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == TripStatus.completed;
    final color = isCompleted
        ? const Color(0xFF2E7D32)
        : Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(
        isCompleted ? 'Completed' : 'Active',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(60)),
      padding: EdgeInsets.zero,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});
  final MemberModel member;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(member.colorIndex);
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withAlpha(40),
      child: Text(
        member.initials,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AttendeeChip extends StatelessWidget {
  const _AttendeeChip({required this.member, required this.isDriver});
  final MemberModel member;
  final bool isDriver;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(member.colorIndex);
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withAlpha(40),
        child: Text(
          member.initials,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
      label: Text(
        member.name.split(' ').first +
            (isDriver ? ' 🚗' : ''),
      ),
      backgroundColor:
          isDriver ? color.withAlpha(15) : null,
      side: isDriver
          ? BorderSide(color: color.withAlpha(60))
          : const BorderSide(color: Colors.transparent),
      padding: EdgeInsets.zero,
    );
  }
}

class _ExpenseLine extends StatelessWidget {
  const _ExpenseLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha(150)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  const _TotalBox({
    required this.label,
    required this.value,
    required this.primary,
  });
  final String label;
  final double value;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = primary
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
