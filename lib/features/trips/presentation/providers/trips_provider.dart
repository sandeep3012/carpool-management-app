import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/trip_mock_datasource.dart';
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
  String toString() => '$month/$year';
}

final calendarMonthProvider =
    StateProvider<CalendarMonth>((ref) {
  final now = DateTime.now();
  return CalendarMonth(month: now.month, year: now.year);
});

// ── Selected date ─────────────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

// ── Members ───────────────────────────────────────────────────────────────────

final membersProvider = Provider<List<MemberModel>>((ref) {
  return TripMockDatasource.members;
});

// ── Trips for current month ────────────────────────────────────────────────────

final tripsForMonthProvider = Provider<List<TripEntry>>((ref) {
  final month = ref.watch(calendarMonthProvider);
  return TripMockDatasource.getTripsForMonth(month.month, month.year);
});

/// Set of days (day-of-month) that have a trip in the current month.
final tripDaysSetProvider = Provider<Set<int>>((ref) {
  final trips = ref.watch(tripsForMonthProvider);
  return {for (final t in trips) t.date.day};
});

// ── Trip for selected date ────────────────────────────────────────────────────

final tripForSelectedDateProvider = Provider<TripEntry?>((ref) {
  final date = ref.watch(selectedDateProvider);
  if (date == null) return null;
  return TripMockDatasource.getTripForDate(date);
});

// ── Trip form state notifier ──────────────────────────────────────────────────

class TripFormNotifier extends StateNotifier<TripFormState> {
  TripFormNotifier(DateTime initialDate)
      : super(TripFormState(
          date: initialDate,
          driver: TripMockDatasource.currentUser,
          attendees: List<MemberModel>.from(TripMockDatasource.members),
        ));

  void setDriver(MemberModel driver) {
    state = state.copyWith(driver: driver);
  }

  void toggleAttendee(MemberModel member) {
    final current = List<MemberModel>.from(state.attendees);
    if (current.contains(member)) {
      // Don't remove the driver from attendees
      if (member == state.driver) return;
      current.remove(member);
    } else {
      current.add(member);
    }
    state = state.copyWith(attendees: current);
  }

  void setDistance(double value) => state = state.copyWith(distanceKm: value);
  void setFuelRate(double value) =>
      state = state.copyWith(fuelRatePerLitre: value);
  void setMileage(double value) => state = state.copyWith(mileageKmpl: value);
  void setToll(double value) => state = state.copyWith(tollExpense: value);
  void setParking(double value) => state = state.copyWith(parkingExpense: value);
  void setOther(double value) => state = state.copyWith(otherExpense: value);
  void setNotes(String value) => state = state.copyWith(notes: value);

  /// Commit the form to the in-memory store and return the new [TripEntry].
  TripEntry save() {
    final entry = TripEntry(
      id: TripMockDatasource.generateId(state.date),
      date: state.date,
      driver: state.driver!,
      attendees: List<MemberModel>.from(state.attendees),
      expenses: state.breakdown,
      status: state.date.isAfter(DateTime.now())
          ? TripStatus.active
          : TripStatus.completed,
      createdAt: DateTime.now(),
    );
    TripMockDatasource.saveTrip(entry);
    return entry;
  }
}

/// Factory: creates a fresh form notifier bound to a specific date.
final tripFormProvider = StateNotifierProvider.family<TripFormNotifier,
    TripFormState, DateTime>((ref, date) {
  return TripFormNotifier(date);
});

// ── Trips list notifier (for add/delete refresh) ──────────────────────────────

class TripsNotifier extends StateNotifier<List<TripEntry>> {
  final Ref _ref;

  TripsNotifier(this._ref) : super([]) {
    _refresh();
  }

  void _refresh() {
    final month = _ref.read(calendarMonthProvider);
    state = TripMockDatasource.getTripsForMonth(month.month, month.year);
  }

  void refresh() => _refresh();

  void addTrip(TripEntry trip) {
    TripMockDatasource.saveTrip(trip);
    _refresh();
  }

  void deleteTrip(String id) {
    TripMockDatasource.deleteTrip(id);
    _refresh();
  }
}

final tripsNotifierProvider =
    StateNotifierProvider<TripsNotifier, List<TripEntry>>((ref) {
  return TripsNotifier(ref);
});
