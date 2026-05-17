import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/persistence_service.dart';
import '../../data/datasources/settlement_calculator.dart';
import '../../data/models/settlement_models.dart';
import '../../../trips/data/models/trip_entry_model.dart';
import '../../../trips/presentation/providers/trips_provider.dart';

// ── Storage key ───────────────────────────────────────────────────────────────

/// JSON file key for persisted payment records.
/// Bumped from v1 (statuses-only) because the schema now stores full records.
const _kPaymentsKey = 'settlements_payments_v1';

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
/// ## Payment IDs
///   Canonical key format: `pay_<fromId>_<toId>_<month>_<year>`
///   This is the key in [_payments] for every record.
///
///   Completed payments are displayed with a `settled_` prefix ID so that
///   [resetPayment] can distinguish them from active suggestions and strip
///   the prefix when looking up the record.
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

  /// payment id (canonical `pay_...` key) → [PaymentRecord].
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
      // confirmed → completed: update record, full recompute.
      // Net balances change — the settled amount is removed from outstanding.
      final existing = _payments[paymentId];
      _payments[paymentId] = existing != null
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
  /// [displayId] may be a `pay_` active ID (pending/confirmed) or a
  /// `settled_` display ID (completed).  The `settled_` prefix is stripped
  /// to find the canonical `pay_` key in [_payments].
  void resetPayment(String displayId) {
    // Resolve to the canonical key stored in _payments.
    final key = displayId.startsWith('settled_')
        ? 'pay_${displayId.substring('settled_'.length)}'
        : displayId;

    final wasCompleted = _payments[key]?.status == PaymentStatus.completed;
    _payments.remove(key);
    _flushPayments();

    if (wasCompleted) {
      // Net balances change — full recompute.
      _compute();
      return;
    }

    // Only a confirmed status was cleared — update in-place.
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
