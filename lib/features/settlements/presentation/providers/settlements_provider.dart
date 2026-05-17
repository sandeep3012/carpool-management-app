import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/persistence_service.dart';
import '../../data/datasources/settlement_calculator.dart';
import '../../data/models/settlement_models.dart';
import '../../../trips/data/models/trip_entry_model.dart';
import '../../../trips/presentation/providers/trips_provider.dart';

// ── Storage key ───────────────────────────────────────────────────────────────

/// JSON file key for persisted payment records.
/// v1: status-only strings (legacy — discarded).
/// v2: full PaymentRecord objects, completed at pay_... key (legacy — discarded).
/// v3: full PaymentRecord objects; completed records at unique settled_...[_N]
///     keys so historical completions survive subsequent trip-edit cycles.
const _kPaymentsKey = 'settlements_payments_v3';

// ── Payment record ────────────────────────────────────────────────────────────

/// Persisted record for a payment that has been acted upon (confirmed or
/// completed).  Stores all display fields so the calculator can reconstruct
/// the full [PaymentSuggestion] for the "Settled" section without re-joining
/// the member list.
///
/// The map key is always the stable `pay_<fromId>_<toId>_<month>_<year>` ID.
class PaymentRecord {
  final String status;
  final double amount;
  final int month;
  final int year;
  final String fromId;
  final String fromName;
  final String fromInitials;
  final int fromColorIndex;
  final String toId;
  final String toName;
  final String toInitials;
  final int toColorIndex;

  const PaymentRecord({
    required this.status,
    required this.amount,
    required this.month,
    required this.year,
    required this.fromId,
    required this.fromName,
    required this.fromInitials,
    required this.fromColorIndex,
    required this.toId,
    required this.toName,
    required this.toInitials,
    required this.toColorIndex,
  });

  PaymentRecord copyWith({String? status}) => PaymentRecord(
        status: status ?? this.status,
        amount: amount,
        month: month,
        year: year,
        fromId: fromId,
        fromName: fromName,
        fromInitials: fromInitials,
        fromColorIndex: fromColorIndex,
        toId: toId,
        toName: toName,
        toInitials: toInitials,
        toColorIndex: toColorIndex,
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'amount': amount,
        'month': month,
        'year': year,
        'fromId': fromId,
        'fromName': fromName,
        'fromInitials': fromInitials,
        'fromColorIndex': fromColorIndex,
        'toId': toId,
        'toName': toName,
        'toInitials': toInitials,
        'toColorIndex': toColorIndex,
      };

  static PaymentRecord? fromJson(Map<String, dynamic> json) {
    try {
      return PaymentRecord(
        status: json['status'] as String,
        amount: (json['amount'] as num).toDouble(),
        month: json['month'] as int,
        year: json['year'] as int,
        fromId: json['fromId'] as String,
        fromName: json['fromName'] as String,
        fromInitials: json['fromInitials'] as String,
        fromColorIndex: json['fromColorIndex'] as int,
        toId: json['toId'] as String,
        toName: json['toName'] as String,
        toInitials: json['toInitials'] as String,
        toColorIndex: json['toColorIndex'] as int,
      );
    } catch (_) {
      return null; // malformed record — skip gracefully
    }
  }
}

// ── Settlement notifier ───────────────────────────────────────────────────────

/// Owns the live [MonthlySettlement] and all payment-status mutations.
///
/// ## Lifecycle
///   1. Construction: state starts as [AsyncValue.loading].
///   2. [_initAsync] loads persisted [PaymentRecord]s from disk, THEN
///      subscribes to [tripsForMonthProvider].  The async init guarantees
///      that the first [_compute] call already has the restored records.
///   3. [_compute] runs whenever the trip list or calendar month changes.
///   4. Payment mutations update [_payments], flush to disk, then either
///      update state in-place (confirmed) or trigger a full recompute
///      (completed / reset) to reconcile net balances correctly.
///
/// ## Key scheme
///   `pay_<fromId>_<toId>_<month>_<year>`
///     — Temporary "in-flight" key for CONFIRMED records only.
///       At most one per (from, to, month) pair at any time.
///       Removed when the payment completes or is reset.
///
///   `settled_<fromId>_<toId>_<month>_<year>[_N]`
///     — Permanent key for each COMPLETED record.
///       Accumulated — never overwritten.  When the same pair completes a
///       second settlement cycle (after a trip edit), a new sequence suffix
///       (_2, _3, …) is appended so both records coexist.
///
///   This separation prevents the historical overwrite bug: a trip edit that
///   creates a new active suggestion for an already-settled pair does NOT
///   corrupt the prior completion record, because the new confirmation writes
///   to a fresh unique key rather than back to the original `pay_` key.
///
/// ## Reconciliation
///   On every [_compute] call the [_payments] map is split into:
///   - completed records  → passed as [CompletedPayment]s to the calculator
///     which subtracts their amounts from gross balances (net outstanding)
///   - confirmed records  → passed as [confirmedStatuses] map (status display
///     only — no balance adjustment until the receiver also confirms)
///   Only records whose [month]/[year] match the currently-viewed calendar
///   month are considered, so multi-month data coexists without collision.
class SettlementNotifier
    extends StateNotifier<AsyncValue<MonthlySettlement>> {
  SettlementNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initAsync();
  }

  final Ref _ref;

  /// `pay_...` → confirmed [PaymentRecord]; `settled_...[_N]` → completed [PaymentRecord].
  /// Persisted across restarts; loaded before the first [_compute].
  final Map<String, PaymentRecord> _payments = {};

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _initAsync() async {
    try {
      final raw = await PersistenceService.loadJson(_kPaymentsKey);
      if (raw is Map<String, dynamic>) {
        for (final entry in raw.entries) {
          if (entry.value is Map<String, dynamic>) {
            final record =
                PaymentRecord.fromJson(entry.value as Map<String, dynamic>);
            if (record != null) _payments[entry.key] = record;
          }
        }
      }
    } catch (_) {
      // Persistence failure is non-fatal — start with empty records.
    }

    // Subscribe to trip changes.  fireImmediately triggers the first
    // _compute call with the already-loaded records.
    _ref.listen<List<TripEntry>>(
      tripsForMonthProvider,
      (_, __) => _compute(),
      fireImmediately: true,
    );
  }

  // ── Computation ───────────────────────────────────────────────────────────

  void _compute() {
    try {
      final calMonth = _ref.read(calendarMonthProvider);
      final trips = _ref.read(tripsForMonthProvider);
      final members = _ref.read(membersProvider);

      final currentMonth = calMonth.month;
      final currentYear = calMonth.year;

      // Split records into completed (balance adjustment) and confirmed
      // (status display only) — filtered to the current calendar month.
      final completedPayments = <CompletedPayment>[];
      final confirmedStatuses = <String, String>{};

      for (final entry in _payments.entries) {
        final record = entry.value;
        if (record.month != currentMonth || record.year != currentYear) {
          continue; // different month — not relevant to this calculation
        }

        if (record.status == PaymentStatus.completed) {
          completedPayments.add(CompletedPayment(
            originalId: entry.key,
            fromId: record.fromId,
            fromName: record.fromName,
            fromInitials: record.fromInitials,
            fromColorIndex: record.fromColorIndex,
            toId: record.toId,
            toName: record.toName,
            toInitials: record.toInitials,
            toColorIndex: record.toColorIndex,
            amount: record.amount,
          ));
        } else if (record.status == PaymentStatus.confirmed) {
          confirmedStatuses[entry.key] = PaymentStatus.confirmed;
        }
      }

      final settlement = SettlementCalculator.calculate(
        month: currentMonth,
        year: currentYear,
        trips: trips,
        members: members,
        completedPayments: completedPayments,
        confirmedStatuses: confirmedStatuses,
      );

      state = AsyncValue.data(settlement);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Force a full recompute (e.g. pull-to-refresh).
  void refresh() => _compute();

  // ── Persistence ───────────────────────────────────────────────────────────

  /// Fire-and-forget persist of [_payments].  Failures are non-fatal.
  void _flushPayments() {
    PersistenceService.saveJson(
      _kPaymentsKey,
      {
        for (final entry in _payments.entries)
          entry.key: entry.value.toJson(),
      },
    );
  }

  // ── Payment mutations ─────────────────────────────────────────────────────

  /// Advance a payment through its status lifecycle:
  ///   pending → confirmed   (payer confirms sending)   — in-place update,
  ///                                                       no balance change.
  ///   confirmed → completed (receiver confirms receipt) — full recompute so
  ///                                                       net balances adjust.
  void confirmPayment(String paymentId) {
    final settlement = state.valueOrNull;
    if (settlement == null) return;

    final idx = settlement.payments.indexWhere((p) => p.id == paymentId);
    if (idx < 0) return;

    final p = settlement.payments[idx];
    final calMonth = _ref.read(calendarMonthProvider);

    if (p.isPending) {
      // pending → confirmed: store record, update in-place.
      // Balance cards do NOT change yet — only the payer has acted.
      _payments[paymentId] = PaymentRecord(
        status: PaymentStatus.confirmed,
        amount: p.amount,
        month: calMonth.month,
        year: calMonth.year,
        fromId: p.fromId,
        fromName: p.fromName,
        fromInitials: p.fromInitials,
        fromColorIndex: p.fromColorIndex,
        toId: p.toId,
        toName: p.toName,
        toInitials: p.toInitials,
        toColorIndex: p.toColorIndex,
      );
      _flushPayments();
      _updatePayment(settlement, idx, p.copyWith(status: PaymentStatus.confirmed));
    } else if (p.isConfirmed) {
      // confirmed → completed: move record from pay_... to a unique settled_...
      // key so the historical completion is never overwritten by a future
      // settlement cycle for the same pair.
      //
      // The pay_... confirmed record is removed and replaced by a new
      // settled_...[_N] completed record.  Net balances change — full recompute.
      final existing = _payments[paymentId];
      final settledKey = _nextSettledKey(paymentId);
      _payments.remove(paymentId); // remove the transient confirmed record
      _payments[settledKey] = existing != null
          ? existing.copyWith(status: PaymentStatus.completed)
          : PaymentRecord(
              status: PaymentStatus.completed,
              amount: p.amount,
              month: calMonth.month,
              year: calMonth.year,
              fromId: p.fromId,
              fromName: p.fromName,
              fromInitials: p.fromInitials,
              fromColorIndex: p.fromColorIndex,
              toId: p.toId,
              toName: p.toName,
              toInitials: p.toInitials,
              toColorIndex: p.toColorIndex,
            );
      _flushPayments();
      _compute(); // full recompute — net balances must adjust
    }
  }

  /// Reset a payment back to pending (undo / demo convenience).
  ///
  /// [displayId] is the direct [_payments] key — no prefix conversion needed:
  ///   `settled_...[_N]` keys map to completed records (balance changes).
  ///   `pay_...` keys map to confirmed records (in-place status reset).
  void resetPayment(String displayId) {
    final wasCompleted = _payments[displayId]?.status == PaymentStatus.completed;
    _payments.remove(displayId);
    _flushPayments();

    if (wasCompleted) {
      // Completed record removed — net balances change.
      _compute();
      return;
    }

    // Confirmed record cleared — flip status back to pending in-place.
    final settlement = state.valueOrNull;
    if (settlement == null) {
      _compute();
      return;
    }
    final idx = settlement.payments.indexWhere((p) => p.id == displayId);
    if (idx < 0) {
      _compute(); // fallback
      return;
    }
    _updatePayment(
      settlement,
      idx,
      settlement.payments[idx].copyWith(status: PaymentStatus.pending),
    );
  }

  /// Returns a unique `settled_...[_N]` key for a completed payment.
  ///
  /// Completed records accumulate — they are never overwritten.  When the same
  /// (from, to, month, year) pair completes a second settlement cycle (e.g.
  /// after a trip edit), the sequence suffix ensures both records coexist:
  ///   `settled_A_B_5_2025`    — first completion
  ///   `settled_A_B_5_2025_2`  — second completion
  ///   `settled_A_B_5_2025_3`  — third completion, etc.
  String _nextSettledKey(String payKey) {
    final base = 'settled_${payKey.substring('pay_'.length)}';
    if (!_payments.containsKey(base)) return base;
    var seq = 2;
    while (_payments.containsKey('${base}_$seq')) {
      seq++;
    }
    return '${base}_$seq';
  }

  void _updatePayment(
    MonthlySettlement settlement,
    int idx,
    PaymentSuggestion updated,
  ) {
    final payments = List<PaymentSuggestion>.from(settlement.payments);
    payments[idx] = updated;
    state = AsyncValue.data(MonthlySettlement(
      id: settlement.id,
      month: settlement.month,
      year: settlement.year,
      memberBalances: settlement.memberBalances,
      payments: payments,
      totalExpense: settlement.totalExpense,
      totalTrips: settlement.totalTrips,
      status: _deriveStatus(payments),
    ));
  }

  static String _deriveStatus(List<PaymentSuggestion> payments) {
    if (payments.isEmpty) return SettlementStatusConst.draft;
    if (payments.every((p) => p.isCompleted)) {
      return SettlementStatusConst.completed;
    }
    return SettlementStatusConst.inProgress;
  }
}

final settlementProvider =
    StateNotifierProvider<SettlementNotifier, AsyncValue<MonthlySettlement>>(
  (ref) => SettlementNotifier(ref),
);

// ── Derived providers ─────────────────────────────────────────────────────────

/// Payments that still need action (pending or payer-confirmed).
final pendingPaymentsProvider = Provider<List<PaymentSuggestion>>((ref) {
  return ref.watch(settlementProvider).maybeWhen(
        data: (s) =>
            s.payments.where((p) => p.isPending || p.isConfirmed).toList(),
        orElse: () => [],
      );
});

/// Payments that are fully completed.
final completedPaymentsProvider = Provider<List<PaymentSuggestion>>((ref) {
  return ref.watch(settlementProvider).maybeWhen(
        data: (s) => s.payments.where((p) => p.isCompleted).toList(),
        orElse: () => [],
      );
});

/// Current user's balance for the personal balance banner.
final myBalanceProvider = Provider<MemberBalance?>((ref) {
  return ref.watch(settlementProvider).maybeWhen(
        data: (s) {
          try {
            return s.memberBalances.firstWhere((b) => b.isCurrentUser);
          } catch (_) {
            return null;
          }
        },
        orElse: () => null,
      );
});

/// Settlement progress 0.0 – 1.0 for the progress bar.
final settlementProgressProvider = Provider<double>((ref) {
  return ref.watch(settlementProvider).maybeWhen(
        data: (s) => s.settlementProgress,
        orElse: () => 0.0,
      );
});
