import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/settlement_calculator.dart';
import '../../data/models/settlement_models.dart';
import '../../../trips/data/models/trip_entry_model.dart';
import '../../../trips/presentation/providers/trips_provider.dart';

// ── Settlement notifier ───────────────────────────────────────────────────────

/// Owns the live [MonthlySettlement] and all payment-status mutations.
///
/// The settlement is **recomputed from real trip data** whenever the trip list
/// or the displayed month changes (via [ref.listen]).  Payment confirmations
/// (pending → confirmed → completed) are held in [_statuses] and carried
/// forward through each recomputation so UI progress isn't lost when a new
/// trip is added mid-month.
///
/// Statuses reset automatically when the user navigates to a different month,
/// because the greedy algorithm produces a fresh set of payment suggestions.
class SettlementNotifier
    extends StateNotifier<AsyncValue<MonthlySettlement>> {
  SettlementNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Recompute whenever the trip list changes (covers month changes too,
    // since tripsForMonthProvider watches calendarMonthProvider).
    _ref.listen<List<TripEntry>>(
      tripsForMonthProvider,
      (prev, next) => _compute(clearStatuses: prev == null),
      fireImmediately: true,
    );
  }

  final Ref _ref;

  // Payment status overrides: stable payment id → PaymentStatus constant.
  // Cleared when the displayed month changes (stale statuses from last month).
  final Map<String, String> _statuses = {};
  CalendarMonth? _lastMonth;

  // ── Computation ───────────────────────────────────────────────────────────

  void _compute({bool clearStatuses = false}) {
    try {
      final month = _ref.read(calendarMonthProvider);

      // Clear statuses when the user navigates to a different month.
      if (_lastMonth != null && _lastMonth != month) {
        _statuses.clear();
      }
      if (clearStatuses) _statuses.clear();
      _lastMonth = month;

      final trips = _ref.read(tripsForMonthProvider);
      final members = _ref.read(membersProvider);

      final settlement = SettlementCalculator.calculate(
        month: month.month,
        year: month.year,
        trips: trips,
        members: members,
        preservedStatuses: Map.unmodifiable(_statuses),
      );

      state = AsyncValue.data(settlement);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Force a full recompute (e.g. pull-to-refresh on the settlement screen).
  void refresh() => _compute();

  // ── Payment mutations ─────────────────────────────────────────────────────

  /// Advance a payment: pending → confirmed → completed.
  void confirmPayment(String paymentId) {
    final settlement = state.valueOrNull;
    if (settlement == null) return;

    final idx = settlement.payments.indexWhere((p) => p.id == paymentId);
    if (idx < 0) return;

    final p = settlement.payments[idx];
    final newStatus =
        p.isPending ? PaymentStatus.confirmed : PaymentStatus.completed;

    _statuses[paymentId] = newStatus;
    _updatePayment(settlement, idx, p.copyWith(status: newStatus));
  }

  /// Reset a payment back to pending (undo / demo convenience).
  void resetPayment(String paymentId) {
    final settlement = state.valueOrNull;
    if (settlement == null) return;

    final idx = settlement.payments.indexWhere((p) => p.id == paymentId);
    if (idx < 0) return;

    _statuses.remove(paymentId);
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
      status: settlement.status,
    ));
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
