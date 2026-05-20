import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/trip_entry_model.dart';
import '../providers/trips_provider.dart';
import 'attendance_selector.dart';
import 'expense_entry_section.dart';

/// Quick-entry bottom sheet for creating **or editing** a trip.
///
/// Pass [existingTrip] to open in edit mode:
///   - All fields are pre-populated from the existing trip.
///   - Saving reuses the original ID so no duplicate is created.
///
/// Omit [existingTrip] (or pass null) for create mode.
///
/// Usage:
/// ```dart
/// // Create
/// showTripEntrySheet(context, date: selectedDate);
///
/// // Edit
/// showTripEntrySheet(context, date: trip.date, existingTrip: trip);
/// ```
Future<TripEntry?> showTripEntrySheet(
  BuildContext context, {
  required DateTime date,
  TripEntry? existingTrip,
}) {
  return showModalBottomSheet<TripEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TripEntrySheet(date: date, existingTrip: existingTrip),
  );
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class _TripEntrySheet extends ConsumerWidget {
  const _TripEntrySheet({required this.date, this.existingTrip});

  final DateTime date;
  final TripEntry? existingTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollController) {
        return _TripEntryContent(
          date: date,
          existingTrip: existingTrip,
          scrollController: scrollController,
        );
      },
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _TripEntryContent extends ConsumerStatefulWidget {
  const _TripEntryContent({
    required this.date,
    this.existingTrip,
    required this.scrollController,
  });

  final DateTime date;
  final TripEntry? existingTrip;
  final ScrollController scrollController;

  @override
  ConsumerState<_TripEntryContent> createState() => _TripEntryContentState();
}

class _TripEntryContentState extends ConsumerState<_TripEntryContent> {
  bool _saving = false;

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _fmtDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month]} ${d.year}';

  bool get _isEditMode => widget.existingTrip != null;

  /// The Riverpod family key: (date, existingTripId).
  /// Records implement == / hashCode by comparing fields, so Riverpod
  /// caches one notifier per unique (date, id) pair.
  (DateTime, String?) get _formKey => (widget.date, widget.existingTrip?.id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final members = ref.watch(membersProvider);
    final formState = ref.watch(tripFormProvider(_formKey));
    final notifier = ref.read(tripFormProvider(_formKey).notifier);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditMode ? 'Edit Trip' : 'New Trip',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _fmtDate(widget.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: AppSpacing.xl),

          // Scrollable form
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              children: [
                // Driver selector
                DriverSelector(
                  members: members,
                  selectedDriverId: formState.driver?.id,
                  onSelect: notifier.setDriver,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Attendance selector
                AttendanceSelector(
                  members: members,
                  selectedIds: {for (final m in formState.attendees) m.id},
                  driverId: formState.driver?.id,
                  onToggle: notifier.toggleAttendee,
                ),
                const SizedBox(height: AppSpacing.xl),

                const Divider(),
                const SizedBox(height: AppSpacing.lg),

                // Expense section
                ExpenseEntrySection(
                  formState: formState,
                  onDistanceChanged: notifier.setDistance,
                  onFuelRateChanged: notifier.setFuelRate,
                  onMileageChanged: notifier.setMileage,
                  onTollChanged: notifier.setToll,
                  onParkingChanged: notifier.setParking,
                  onOtherChanged: notifier.setOther,
                ),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),

          // Save button (sticky at bottom)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeightXl,
                child: FilledButton.icon(
                  onPressed: formState.isValid && !_saving
                      ? () => _save(formState, notifier)
                      : null,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving
                        ? 'Saving…'
                        : _isEditMode
                            ? 'Save Changes'
                            : 'Save Trip',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
      TripFormState formState, TripFormNotifier notifier) async {
    setState(() => _saving = true);
    try {
      final trip = await notifier.save();
      // For new trips: jump the calendar to the trip's month.
      // For edits: the calendar stays on its current month (no navigation).
      if (!_isEditMode) {
        ref.invalidate(calendarMonthProvider);
      }
      if (mounted) Navigator.of(context).pop(trip);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Convenience re-export of AppSpacing constants used above ──────────────────
// (AppSpacing.buttonHeightXl is already defined in app_spacing.dart)
