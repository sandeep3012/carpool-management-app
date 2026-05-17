import '../models/trip_entry_model.dart';

/// In-memory mock store for the Trips feature.
///
/// Generates a realistic month of carpool trips for May 2026
/// (Mon–Fri only, shared among 5 members on a rotating driver schedule).
/// Serves as the data source until a real backend is wired up.
class TripMockDatasource {
  TripMockDatasource._();

  // ── Members ─────────────────────────────────────────────────────────────────

  static const List<MemberModel> members = [
    MemberModel(
        id: 'm001',
        name: 'Piyush Kashyap',
        initials: 'PK',
        colorIndex: 0,
        isCurrentUser: true),
    MemberModel(
        id: 'm002', name: 'Sunil Kumawat', initials: 'SK', colorIndex: 1),
    MemberModel(
        id: 'm003', name: 'Yogesh Chaturvedi', initials: 'YC', colorIndex: 2),
    MemberModel(
        id: 'm004', name: 'Kshitiz Khandelwal', initials: 'KK', colorIndex: 3),
    MemberModel(
        id: 'm005', name: 'Sandeep Choudhary', initials: 'SC', colorIndex: 4),
  ];

  static MemberModel get currentUser => members[0];

  // ── In-memory trip store ──────────────────────────────────────────────────

  static final List<TripEntry> _trips = _generateMockTrips();

  static List<TripEntry> _generateMockTrips() {
    const int year = 2026;
    const int month = 5;
    final List<TripEntry> trips = [];

    // Rotating driver schedule: index cycles through members
    int driverIndex = 0;

    // Standard carpool values
    const double distanceKm = 45.0;
    const double fuelRate = 102.0;
    const double mileage = 15.0;

    // Weekdays in May 2026 with realistic expense variations
    final weekdayExpras = <int, ({double toll, double parking, double other})>{
      2: (toll: 60, parking: 0, other: 0),
      5: (toll: 60, parking: 20, other: 0),
      7: (toll: 60, parking: 0, other: 30),
      9: (toll: 60, parking: 0, other: 0),
      12: (toll: 60, parking: 20, other: 0),
      14: (toll: 60, parking: 0, other: 0),
      16: (toll: 60, parking: 0, other: 0),
      19: (toll: 60, parking: 20, other: 50),
      21: (toll: 60, parking: 0, other: 0),
      23: (toll: 60, parking: 0, other: 0),
    };

    for (final day in weekdayExpras.keys.toList()..sort()) {
      final date = DateTime(year, month, day);
      if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
        final driver = members[driverIndex % members.length];
        final extras = weekdayExpras[day]!;

        // All members attend every recorded trip
        final allAttendees = List<MemberModel>.from(members);

        trips.add(TripEntry(
          id: 'trip_${year}_${month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}',
          date: date,
          driver: driver,
          attendees: allAttendees,
          expenses: ExpenseBreakdown(
            distanceKm: distanceKm,
            fuelRatePerLitre: fuelRate,
            mileageKmpl: mileage,
            tollExpense: extras.toll,
            parkingExpense: extras.parking,
            otherExpense: extras.other,
          ),
          status: date.isAfter(DateTime.now())
              ? TripStatus.active
              : TripStatus.completed,
          createdAt: date.subtract(const Duration(hours: 2)),
        ));
        driverIndex++;
      }
    }
    return trips;
  }

  // ── Query API ────────────────────────────────────────────────────────────────

  /// All trips for [month]/[year], sorted by date ascending.
  static List<TripEntry> getTripsForMonth(int month, int year) {
    return _trips
        .where((t) => t.date.month == month && t.date.year == year)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Trip on a specific calendar date (null if none).
  static TripEntry? getTripForDate(DateTime date) {
    for (final t in _trips) {
      if (t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day) {
        return t;
      }
    }
    return null;
  }

  /// All trips (across months) for a driver.
  static List<TripEntry> getTripsForDriver(String driverId) {
    return _trips.where((t) => t.driver.id == driverId).toList();
  }

  /// Retrieve by id.
  static TripEntry? getTripById(String id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add or replace a trip (upsert).
  static void saveTrip(TripEntry trip) {
    final idx = _trips.indexWhere((t) => t.id == trip.id);
    if (idx >= 0) {
      _trips[idx] = trip;
    } else {
      _trips.add(trip);
      _trips.sort((a, b) => a.date.compareTo(b.date));
    }
  }

  /// Remove a trip by id.
  static void deleteTrip(String id) {
    _trips.removeWhere((t) => t.id == id);
  }

  /// Build a unique id for a new trip on [date].
  static String generateId(DateTime date) {
    return 'trip_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
