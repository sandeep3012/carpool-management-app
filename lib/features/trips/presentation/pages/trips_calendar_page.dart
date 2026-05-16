import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/trip_entry_model.dart';
import '../providers/trips_provider.dart';
import '../widgets/trip_entry_sheet.dart';
import 'trip_detail_page.dart';

// ── Avatar colour palette (shared across the feature) ────────────────────────
const List<Color> _kAvatarColors = [
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
  Color(0xFF2E7D32),
  Color(0xFFBF360C),
  Color(0xFF00695C),
];
Color _avatarColor(int idx) => _kAvatarColors[idx % _kAvatarColors.length];

// ── Page ──────────────────────────────────────────────────────────────────────

class TripsCalendarPage extends ConsumerWidget {
  const TripsCalendarPage({super.key});

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calMonth = ref.watch(calendarMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final tripDays = ref.watch(tripDaysSetProvider);
    final selectedTrip = ref.watch(tripForSelectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Month navigation header
          _MonthHeader(
            label: '${_monthNames[calMonth.month]} ${calMonth.year}',
            onPrev: () => ref
                .read(calendarMonthProvider.notifier)
                .state = calMonth.prev(),
            onNext: () => ref
                .read(calendarMonthProvider.notifier)
                .state = calMonth.next(),
          ),

          // Weekday label row
          const _WeekdayRow(),

          // Calendar grid
          _CalendarGrid(
            month: calMonth.month,
            year: calMonth.year,
            tripDays: tripDays,
            selectedDay: selectedDate?.day,
            selectedMonth: selectedDate?.month,
            selectedYear: selectedDate?.year,
            onDayTap: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),

          const Divider(height: 1),

          // Bottom panel: trip card or empty state
          Expanded(
            child: selectedDate == null
                ? _NoDateSelected(
                    onPickToday: () {
                      final now = DateTime.now();
                      ref.read(selectedDateProvider.notifier).state =
                          DateTime(now.year, now.month, now.day);
                    },
                  )
                : selectedTrip != null
                    ? _TripSummaryPanel(
                        trip: selectedTrip,
                        onViewDetail: () => _openDetail(context, selectedTrip),
                        onEdit: () => _openEdit(context, ref, selectedTrip),
                      )
                    : _EmptyDayPanel(
                        date: selectedDate,
                        onAddTrip: () =>
                            _openNewTrip(context, ref, selectedDate),
                      ),
          ),
        ],
      ),

      // FAB — only when a date is selected and has no trip yet
      floatingActionButton: selectedDate != null && selectedTrip == null
          ? FloatingActionButton.extended(
              onPressed: () => _openNewTrip(context, ref, selectedDate),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log Trip'),
            )
          : null,
    );
  }

  Future<void> _openNewTrip(
      BuildContext context, WidgetRef ref, DateTime date) async {
    final trip = await showTripEntrySheet(context, date: date);
    if (trip != null) {
      ref.read(tripsNotifierProvider.notifier).addTrip(trip);
      // Re-watch the selected date so the card appears immediately
      ref.read(selectedDateProvider.notifier).state = date;
    }
  }

  void _openDetail(BuildContext context, TripEntry trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailPage(tripId: trip.id),
      ),
    );
  }

  Future<void> _openEdit(
      BuildContext context, WidgetRef ref, TripEntry trip) async {
    final result = await showTripEntrySheet(context, date: trip.date);
    if (result != null) {
      ref.read(tripsNotifierProvider.notifier).refresh();
    }
  }
}

// ── Month header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

// ── Weekday label row ─────────────────────────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  static const List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: _days
            .map(
              (d) => Expanded(
                child: Center(child: Text(d, style: textStyle)),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.year,
    required this.tripDays,
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onDayTap,
  });

  final int month;
  final int year;
  final Set<int> tripDays;
  final int? selectedDay;
  final int? selectedMonth;
  final int? selectedYear;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    // Monday-based: weekday 1=Mon … 7=Sun; offset 0-based
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - startOffset + 1;

              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 46));
              }

              final date = DateTime(year, month, day);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = selectedDay == day &&
                  selectedMonth == month &&
                  selectedYear == year;
              final hasTrip = tripDays.contains(day);

              return Expanded(
                child: _DayCell(
                  day: day,
                  isToday: isToday,
                  isSelected: isSelected,
                  hasTrip: hasTrip,
                  onTap: () => onDayTap(date),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasTrip,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasTrip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor = Colors.transparent;
    Color textColor = colorScheme.onSurface;
    FontWeight fontWeight = FontWeight.w400;

    if (isSelected) {
      bgColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      fontWeight = FontWeight.w700;
    } else if (isToday) {
      bgColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      fontWeight = FontWeight.w700;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: fontWeight,
                  ),
            ),
            if (hasTrip)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colorScheme.onPrimary.withAlpha(200)
                      : colorScheme.primary,
                ),
              )
            else
              const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}

// ── Bottom panels ─────────────────────────────────────────────────────────────

class _NoDateSelected extends StatelessWidget {
  const _NoDateSelected({required this.onPickToday});
  final VoidCallback onPickToday;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withAlpha(120),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Select a date to see trip details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(140),
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onPickToday,
            child: const Text('Go to Today'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayPanel extends StatelessWidget {
  const _EmptyDayPanel({required this.date, required this.onAddTrip});
  final DateTime date;
  final VoidCallback onAddTrip;

  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha(80)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No trip on ${date.day} ${_months[date.month]}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(140),
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: onAddTrip,
            child: const Text('Log a Trip'),
          ),
        ],
      ),
    );
  }
}

// ── Trip summary panel ────────────────────────────────────────────────────────

class _TripSummaryPanel extends StatelessWidget {
  const _TripSummaryPanel({
    required this.trip,
    required this.onViewDetail,
    required this.onEdit,
  });
  final TripEntry trip;
  final VoidCallback onViewDetail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver row + actions
          Row(
            children: [
              _MiniAvatar(member: trip.driver),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.driver.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('Driver',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: colorScheme.primary)),
                  ],
                ),
              ),
              TextButton(
                  onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: AppSpacing.xs),
              FilledButton(
                  onPressed: onViewDetail,
                  child: const Text('Details')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Attendee mini-avatars
          Row(
            children: [
              ...trip.attendees.take(5).map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _MiniAvatar(member: m, radius: 14),
                    ),
                  ),
              if (trip.attendees.length > 5)
                Text('+${trip.attendees.length - 5}',
                    style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Expense summary chips
          Row(
            children: [
              _SummaryChip(
                icon: Icons.payments_rounded,
                label: 'Total',
                value: '₹${trip.expenses.totalExpense.toStringAsFixed(0)}',
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              _SummaryChip(
                icon: Icons.person_rounded,
                label: 'Each',
                value: '₹${trip.perPersonShare.toStringAsFixed(0)}',
                color: colorScheme.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              _SummaryChip(
                icon: Icons.people_rounded,
                label: 'Pax',
                value: '${trip.passengerCount}',
                color: colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.member, this.radius = 18});
  final MemberModel member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(member.colorIndex);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withAlpha(40),
      child: Text(
        member.initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.65,
            ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: color.withAlpha(180))),
              Text(value,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
        ],
      ),
    );
  }
}
