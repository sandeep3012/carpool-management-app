import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/settlement_mock_datasource.dart';
import '../../data/models/settlement_models.dart';

// ── Settlement notifier ───────────────────────────────────────────────────────

/// Owns the live [MonthlySettlement] state and all mutation operations.
///
/// The notifier is the single source of truth for the settlement screen.
/// When a payment is confirmed or completed it mutates the in-memory store
/// and rebuilds the state so the UI reflects the change immediately.
class SettlementNotifier extends StateNotifier<AsyncValue<MonthlySettlement>> {
  SettlementNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() {
    try {
      // Simulate a brief async load (swap for repo call later)
      final settlement = SettlementMockDatasource.getSettlement();
      state = AsyncValue.data(settlement);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh the settlement from the mock store (e.g. after a payment update).
  void refresh() => _load();

  /// Advance a payment: pending → confirmed → completed.
  void confirmPayment(String paymentId) {
    SettlementMockDatasource.confirmPayment(paymentId);
    _load();
  }

  /// Jump a payment directly to completed.
  void completePayment(String paymentId) {
    SettlementMockDatasource.completePayment(paymentId);
    _load();
  }

  /// Undo a payment back to pending (for demo / testing).
  void resetPayment(String paymentId) {
    SettlementMockDatasource.resetPayment(paymentId);
    _load();
  }
}

final settlementProvider =
    StateNotifierProvider<SettlementNotifier, AsyncValue<MonthlySettlement>>(
  (ref) => SettlementNotifier(),
);

// ── Derived providers ────────────────────────────────────────────────────────

/// Pending payments only (drives the "action needed" section).
final pendingPaymentsProvider = Provider<List<PaymentSuggestion>>((ref) {
  return ref.watch(settlementProvider).maybeWhen(
        data: (s) => s.payments.where((p) => p.isPending).toList(),
        orElse: () => [],
      );
});

/// Completed payments (drives the "settled" section).
final completedPaymentsProvider = Provider<List<PaymentSuggestion>>((ref) {
  return ref.watch(settlementProvider).maybeWhen(
        data: (s) =>
            s.payments.where((p) => p.isCompleted || p.isConfirmed).toList(),
        orElse: () => [],
      );
});

/// Current user's balance (for the personal balance banner).
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

/// Settlement progress (0.0 – 1.0) for the progress indicator.
final settlementProgressProvider = Provider<double>((ref) {
  return ref.watch(settlementProvider).maybeWhen(
        data: (s) => s.settlementProgress,
        orElse: () => 0.0,
      );
});
