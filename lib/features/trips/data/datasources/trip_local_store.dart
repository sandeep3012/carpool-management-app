import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/persistence_service.dart';
import '../models/trip_entry_model.dart';

// Storage key — bump suffix on breaking schema changes to auto-reseed.
const _kKey = 'trips_v1';

/// Canonical member list for the MVP carpool group.
///
/// Kept here so every layer that needs member metadata (providers, seed,
/// settlement calculator) imports from one authoritative source.
const List<MemberModel> kCanonicalMembers = [
  MemberModel(
    id: 'm001',
    name: 'Rajesh Kumar',
    initials: 'RK',
    colorIndex: 0,
    isCurrentUser: true,
  ),
  MemberModel(id: 'm002', name: 'Priya Sharma', initials: 'PS', colorIndex: 1),
  MemberModel(id: 'm003', name: 'Suresh Patel', initials: 'SP', colorIndex: 2),
  MemberModel(id: 'm004', name: 'Kavitha Nair', initials: 'KN', colorIndex: 3),
  MemberModel(id: 'm005', name: 'Arun Singh', initials: 'AS', colorIndex: 4),
];

/// File-backed, in-memory trip store — the single source of truth at runtime.
///
/// Lifecycle:
///   1. [initialize] loads `carpool_trips_v1.json` from the app documents dir.
///   2. On a fresh install the file is absent → [_seed] populates 10 realistic
///      carpool trips for the current month and writes them to disk.
///   3. [save] / [remove] mutate the in-memory list and immediately flush to
///      disk, so changes survive app restarts.
///
/// Thread safety: Dart is single-threaded; no locking is necessary.
class TripLocalStore {
  TripLocalStore._();

  static final TripLocalStore _instance = TripLocalStore._();

  /// Returns the singleton instance.  Call [initialize] before first use.
  factory TripLocalStore() => _instance;

  final List<TripEntry> _trips = [];
  bool _ready = false;
  Completer<void>? _initCompleter;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Loads trips from disk.  Safe to call multiple times — subsequent calls
  /// are no-ops that return immediately once the first completes.
  Future<void> initialize() async {
    if (_ready) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      final raw = await PersistenceService.loadJson(_kKey);

      if (raw is List && raw.isNotEmpty) {
        for (final item in raw) {
          try {
            _trips.add(TripEntry.fromJson(item as Map<String, dynamic>));
          } catch (_) {
            // Skip any malformed entry rather than crashing.
          }
        }
      } else {
        // First install — seed with representative demo data.
        _trips.addAll(_seed());
        await _flush();
      }

      _trips.sort((a, b) => a.date.compareTo(b.date));
    } finally {
      _ready = true;
      _initCompleter!.complete();
    }
  }

  // ── Query API ─────────────────────────────────────────────────────────────

  /// Snapshot of all trips across all months.
  List<TripEntry> getAll() => List.unmodifiable(_trips);

  /// All trips in [month]/[year], sorted by date ascending.
  List<TripEntry> forMonth(int month, int year) => _trips
      .where((t) => t.date.month == month && t.date.year == year)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  /// Trip on the given calendar date, or `null` if none.
  TripEntry? forDate(DateTime d) {
    for (final t in _trips) {
      if (t.date.year == d.year &&
          t.date.month == d.month &&
          t.date.day == d.day) return t;
    }
    return null;
  }

  /// Trip by unique id, or `null`.
  TripEntry? byId(String id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Upsert a trip and persist immediately.
  Future<void> save(TripEntry trip) async {
    final idx = _trips.indexWhere((t) => t.id == trip.id);
    if (idx >= 0) {
      _trips[idx] = trip;
    } else {
      _trips.add(trip);
      _trips.sort((a, b) => a.date.compareTo(b.date));
    }
    await _flush();
  }

  /// Delete a trip by id and persist immediately.
  Future<void> remove(String id) async {
    _trips.removeWhere((t) => t.id == id);
    await _flush();
  }

  // ── ID generation ─────────────────────────────────────────────────────────

  /// Deterministic-ish id for a new trip on [date].
  static String newId(DateTime date) =>
      'trip_${date.year}_${date.month.toString().padLeft(2, '0')}'
      '_${date.day.toString().padLeft(2, '0')}'
      '_${DateTime.now().millisecondsSinceEpoch}';

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _flush() => PersistenceService.saveJson(
        _kKey,
        _trips.map((t) => t.toJson()).toList(),
      );

  // ── Seed data (fresh install only) ────────────────────────────────────────

  /// Generates 10 realistic weekday carpool trips for the current month.
  ///
  /// Driver schedule rotates through all 5 members; expenses match the real
  /// route: 45 km, ₹102/L fuel, 15 kmpl mileage, ₹60 daily toll, and
  /// occasional parking / other charges.
  static List<TripEntry> _seed() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Find up to 10 weekdays in the current month.
    final weekdays = <int>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var d = 1; d <= daysInMonth && weekdays.length < 10; d++) {
      final wd = DateTime(year, month, d).weekday;
      if (wd >= DateTime.monday && wd <= DateTime.friday) weekdays.add(d);
    }

    // Expense extras per weekday slot index.
    const extras = [
      (toll: 60.0, parking: 0.0, other: 0.0),
      (toll: 60.0, parking: 20.0, other: 0.0),
      (toll: 60.0, parking: 0.0, other: 30.0),
      (toll: 60.0, parking: 0.0, other: 0.0),
      (toll: 60.0, parking: 20.0, other: 0.0),
      (toll: 60.0, parking: 0.0, other: 0.0),
      (toll: 60.0, parking: 0.0, other: 0.0),
      (toll: 60.0, parking: 20.0, other: 50.0),
      (toll: 60.0, parking: 0.0, other: 0.0),
      (toll: 60.0, parking: 0.0, other: 0.0),
    ];

    return List.generate(weekdays.length, (i) {
      final day = weekdays[i];
      final date = DateTime(year, month, day);
      final driver = kCanonicalMembers[i % kCanonicalMembers.length];
      final ex = extras[i % extras.length];

      return TripEntry(
        id: 'trip_${year}_${month.toString().padLeft(2, '0')}'
            '_${day.toString().padLeft(2, '0')}',
        date: date,
        driver: driver,
        attendees: List.from(kCanonicalMembers),
        expenses: ExpenseBreakdown(
          distanceKm: 45.0,
          fuelRatePerLitre: 102.0,
          mileageKmpl: 15.0,
          tollExpense: ex.toll,
          parkingExpense: ex.parking,
          otherExpense: ex.other,
        ),
        status: date.isAfter(now) ? TripStatus.active : TripStatus.completed,
        createdAt: date.subtract(const Duration(hours: 2)),
      );
    });
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

/// Initialises and exposes the [TripLocalStore] singleton.
/// Consumers that need the loaded store should `await` this future.
final tripLocalStoreProvider = FutureProvider<TripLocalStore>((ref) async {
  final store = TripLocalStore();
  await store.initialize();
  return store;
});
