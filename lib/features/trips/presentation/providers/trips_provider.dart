import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/trip_local_store.dart';
import '../../data/models/trip_entry_model.dart';

// ── Selected month ────────────────────────────────────────────────────────────

/// The month/year the calendar is currently showing.
class CalendarMonth {
  final int month;
  final int year;

  const CalendarMonth({required this.month, required this.year});

  CalendarMonth prev() {
    if (month == 1) return CalendarMonth(month: 12, year: year - 1);
    return CalendarMonth(month: month - 1, year: year);
  }

  CalendarMonth next() {
    if (month == 12) return CalendarMonth(month: 1, year: year + 1);
    return CalendarMonth(month: month + 1, year: year);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth && other.month == month && other.year == year;

  @override
  int get hashCode => Object.hash(month, year);

  @override
  String toString() => '$month/$year';
}

/// Defaults to the current month so the calendar opens on today.
final calendarMonthProvider = StateProvider<CalendarMonth>((ref) {
  final now = DateTime.now();
  return CalendarMonth(month: now.month, year: now.year);
});

// ── Selected date ─────────────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

// ── Members ───────────────────────────────────────────────────────────────────

/// Canonical carpool group — sourced from [TripLocalStore].
final membersProvider = Provider<List<MemberModel>>((ref) {
  return kCanonicalMembers;
});

/// The current user within the canonical member list.
final currentUserProvider = Provider<MemberModel>((ref) {
  return kCanonicalMembers.firstWhere((m) => m.isCurrentUser);
});

// ── Main trips notifier ───────────────────────────────────────────────────────

/// Holds **all trips** across all months as live reactive state.
///
/// Starts with `[]` while the local store loads from disk; updates state as
/// soon as the file read completes.  All mutations immediately write to disk
/// via [TripLocalStore] and then refresh the in-memory list.
class TripsNotifier extends StateNotifier<List<TripEntry>> {
  TripsNotifier(this._ref) : super([]) {
    _init();
  }

  final Ref _ref;

  // Load from the persistent store into state.
  Future<void> _init() async {
    try {
      final store = await _ref.read(tripLocalStoreProvider.future);
      if (mounted) state = store.getAll();
    } catch (_) {
      // Leave state as [] on error; the UI will show an empty calendar.
    }
  }

  /// Reload from disk (e.g. after an external write or on pull-to-refresh).
  Future<void> refresh() => _init();

  /// Save (upsert) a trip and update reactive state.
  Future<void> addOrUpdate(TripEntry trip) async {
    final store = await _ref.read(tripLocalStoreProvider.future);
    await store.save(trip);
    if (mounted) state = store.getAll();
  }

  /// Delete a trip by id and update reactive state.
  Future<void> deleteTrip(String id) async {
    final store = await _ref.read(tripLocalStoreProvider.future);
    await store.remove(id);
    if (mounted) state = store.getAll();
  }
}

final tripsNotifierProvider =
    StateNotifierProvider<TripsNotifier, List<TripEntry>>(
  (ref) => TripsNotifier(ref),
);

// ── Derived: trips for the current calendar month ─────────────────────────────

/// Recomputes whenever the trip list OR the displayed month changes.
final tripsForMonthProvider = Provider<List<TripEntry>>((ref) {
  final all = ref.watch(tripsNotifierProvider);
  final cm = ref.watch(calendarMonthProvider);
  return all
      .where((t) => t.date.month == cm.month && t.date.year == cm.year)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

/// Set of day-of-month integers that have a trip in the current month.
final tripDaysSetProvider = Provider<Set<int>>((ref) {
  return {for (final t in ref.watch(tripsForMonthProvider)) t.date.day};
});

// ── Derived: trip for the selected calendar date ──────────────────────────────

final tripForSelectedDateProvider = Provider<TripEntry?>((ref) {
  final date = ref.watch(selectedDateProvider);
  if (date == null) return null;
  final all = ref.watch(tripsNotifierProvider);
  try {
    return all.firstWhere(
      (t) =>
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day,
    );
  } catch (_) {
    return null;
  }
});

// ── Trip form state notifier ──────────────────────────────────────────────────

/// Manages the state of the trip entry sheet for both **create** and **edit**.
///
/// The family key is `(DateTime date, String? existingTripId)`:
///   - `existingTripId == null` → create mode; a new ID is generated on save.
///   - `existingTripId != null` → edit mode; the store is queried synchronously
///     to hydrate all fields, and the same ID is reused on save so the
///     existing record is replaced (upserted) rather than duplicated.
///
/// [save] is async — it writes to [TripLocalStore] and notifies
/// [tripsNotifierProvider] so the calendar and settlement both update
/// immediately without any extra `ref.invalidate`.
class TripFormNotifier extends StateNotifier<TripFormState> {
  TripFormNotifier(DateTime initialDate, String? existingTripId, this._ref)
      : super(_buildInitialState(initialDate, existingTripId));

  final Ref _ref;

  /// Build the correct initial state.
  ///
  /// In edit mode the singleton [TripLocalStore] is queried synchronously —
  /// this is safe because the store is always initialised before any trip
  /// detail page (and therefore any edit sheet) can be opened.
  static TripFormState _buildInitialState(
      DateTime date, String? existingTripId) {
    if (existingTripId != null) {
      final trip = TripLocalStore().byId(existingTripId);
      if (trip != null) {
        return TripFormState(
          date: trip.date,
          originalId: trip.id,
          driver: trip.driver,
          attendees: List<MemberModel>.from(trip.attendees),
          distanceKm: trip.expenses.distanceKm,
          fuelRatePerLitre: trip.expenses.fuelRatePerLitre,
          mileageKmpl: trip.expenses.mileageKmpl,
          tollExpense: trip.expenses.tollExpense,
          parkingExpense: trip.expenses.parkingExpense,
          otherExpense: trip.expenses.otherExpense,
          notes: trip.notes,
        );
      }
    }
    // Create mode defaults.
    return TripFormState(
      date: date,
      driver: kCanonicalMembers.first,
      attendees: List<MemberModel>.from(kCanonicalMembers),
    );
  }

  void setDriver(MemberModel driver) => state = state.copyWith(driver: driver);

  void toggleAttendee(MemberModel member) {
    final current = List<MemberModel>.from(state.attendees);
    if (current.contains(member)) {
      if (member == state.driver) return; // driver must always attend
      current.remove(member);
    } else {
      current.add(member);
    }
    state = state.copyWith(attendees: current);
  }

  void setDistance(double v) => state = state.copyWith(distanceKm: v);
  void setFuelRate(double v) => state = state.copyWith(fuelRatePerLitre: v);
  void setMileage(double v) => state = state.copyWith(mileageKmpl: v);
  void setToll(double v) => state = state.copyWith(tollExpense: v);
  void setParking(double v) => state = state.copyWith(parkingExpense: v);
  void setOther(double v) => state = state.copyWith(otherExpense: v);
  void setNotes(String v) => state = state.copyWith(notes: v);

  /// Persist the form as a [TripEntry] and return it.
  ///
  /// Create mode → new timestamp-based ID.
  /// Edit mode   → original ID reused → [TripLocalStore.save] upserts the
  ///               existing record, eliminating the duplicate.
  Future<TripEntry> save() async {
    final entry = TripEntry(
      id: state.originalId ?? TripLocalStore.newId(state.date),
      date: state.date,
      driver: state.driver!,
      attendees: List<MemberModel>.from(state.attendees),
      expenses: state.breakdown,
      status: state.date.isAfter(DateTime.now())
          ? TripStatus.active
          : TripStatus.completed,
      createdAt: DateTime.now(),
    );
    await _ref.read(tripsNotifierProvider.notifier).addOrUpdate(entry);
    return entry;
  }
}

/// Family key: `(date, existingTripId)`.
///   - `existingTripId == null` → create a new trip.
///   - `existingTripId != null` → edit the trip with that ID.
final tripFormProvider = StateNotifierProvider.family<TripFormNotifier,
    TripFormState, (DateTime, String?)>(
  (ref, key) => TripFormNotifier(key.$1, key.$2, ref),
);
