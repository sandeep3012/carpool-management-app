import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/persistence_service.dart';
import '../models/trip_entry_model.dart';

// Storage key — bump suffix on breaking schema changes to auto-reseed.
// v2: reduced to 3 members, empty seed for cleaner debugging.
const _kKey = 'trips_v2';

/// Canonical member list for the MVP carpool group.
///
/// Kept here so every layer that needs member metadata (providers, seed,
/// settlement calculator) imports from one authoritative source.
const List<MemberModel> kCanonicalMembers = [
  MemberModel(
    id: 'm001',
    name: 'Piyush Kashyap',
    initials: 'PK',
    colorIndex: 0,
    isCurrentUser: true,
  ),
  MemberModel(id: 'm002', name: 'Sunil Kumawat', initials: 'SK', colorIndex: 1),
  MemberModel(
      id: 'm003', name: 'Yogesh Chaturvedi', initials: 'YC', colorIndex: 2),
  MemberModel(
      id: 'm004', name: 'Kshitij Khandelwal', initials: 'KK', colorIndex: 3),
  MemberModel(
      id: 'm005', name: 'Sandeep Choudhary', initials: 'SC', colorIndex: 4),
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
  List<TripEntry> forMonth(int month, int year) =>
      _trips.where((t) => t.date.month == month && t.date.year == year).toList()
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

  /// Returns an empty list — fresh installs start with no trips so the
  /// CRUD flow is easy to verify without noise.
  static List<TripEntry> _seed() => [];
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

/// Initialises and exposes the [TripLocalStore] singleton.
/// Consumers that need the loaded store should `await` this future.
final tripLocalStoreProvider = FutureProvider<TripLocalStore>((ref) async {
  final store = TripLocalStore();
  await store.initialize();
  return store;
});
