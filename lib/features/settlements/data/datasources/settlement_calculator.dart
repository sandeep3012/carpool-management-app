import '../../data/models/settlement_models.dart';
import '../../../trips/data/models/trip_entry_model.dart';

/// Pure settlement engine — zero external dependencies.
///
/// ## Business rules
///
///   Driver Contribution = total trip expense for trips the member drove
///   Ride Charge         = per-person share for every trip the member attended
///   Gross Net Balance   = Driver Contribution − Total Ride Charges
///
///   Positive gross net → creditor (others owe them money)
///   Negative gross net → debtor   (they owe money to others)
///
/// ## Reconciliation (net outstanding)
///
///   Net Outstanding Balance = Gross Balance − Σ(completed payment amounts)
///
///   For each completed payment (from → to):
///     - from's balance improves by `amount` (less debt / more credit)
///     - to's balance decreases by `amount`  (less credit / more debt)
///
///   Member balance cards show NET outstanding — not gross historical totals.
///   The greedy algorithm is applied to net balances, so only the remaining
///   unpaid amount generates active payment suggestions.
///
/// ## Greedy minimum-transactions algorithm
///
///   Sort creditors descending, debtors descending (by absolute value).
///   Repeatedly match the largest creditor with the largest debtor:
///     payment = min(creditor.remaining, debtor.remaining)
///   Terminate when all balances are within ±₹0.50 (floating-point tolerance).
///
/// ## Payment IDs
///
///   Active suggestions: `pay_<fromId>_<toId>_<month>_<year>`
///     — stable across recomputes for the same from/to/month so that
///       [confirmedStatuses] survives trips being added mid-month.
///
///   Completed display entries: `settled_<fromId>_<toId>_<month>_<year>`
///     — avoids ID collision with new active suggestions for the same pair
///       after a reset; prefix is stripped by [SettlementNotifier.resetPayment].
class SettlementCalculator {
  SettlementCalculator._();

  /// Build a complete [MonthlySettlement] from real trip data.
  ///
  /// [completedPayments] are fully-settled payments.  Their amounts are
  /// subtracted from gross balances to produce net outstanding balances, and
  /// they are reconstructed as [PaymentSuggestion] entries for the UI's
  /// "Settled" display section.
  ///
  /// [confirmedStatuses] maps `pay_` payment ids → `'confirmed'` so the
  /// intermediate confirmation state survives mid-month recomputes without
  /// changing the net balance (balance only adjusts on completion).
  static MonthlySettlement calculate({
    required int month,
    required int year,
    required List<TripEntry> trips,
    required List<MemberModel> members,
    List<CompletedPayment> completedPayments = const [],
    Map<String, String> confirmedStatuses = const {},
  }) {
    // Step 1: Gross balances from trips.
    final grossBalances = _computeGrossBalances(trips, members);

    // Step 2: Net outstanding = gross − completed settlement amounts.
    final netBalances =
        _adjustForCompletedPayments(grossBalances, completedPayments);

    // Step 3: Active payment suggestions from net balances only.
    final activePayments =
        _computePayments(netBalances, confirmedStatuses, month, year);

    // Step 4: Reconstruct completed entries for the "Settled" display section.
    //         Use 'settled_' prefix to avoid ID clash with any future active
    //         suggestion for the same member pair in this month.
    final completedSuggestions = completedPayments
        .map(
          (cp) => PaymentSuggestion(
            id: 'settled_${cp.fromId}_${cp.toId}_${month}_$year',
            fromId: cp.fromId,
            fromName: cp.fromName,
            fromInitials: cp.fromInitials,
            fromColorIndex: cp.fromColorIndex,
            toId: cp.toId,
            toName: cp.toName,
            toInitials: cp.toInitials,
            toColorIndex: cp.toColorIndex,
            amount: cp.amount,
            status: PaymentStatus.completed,
          ),
        )
        .toList();

    // Active suggestions first, completed entries below.
    final allPayments = [...activePayments, ...completedSuggestions];

    final totalExpense = trips.fold<double>(
      0,
      (sum, t) => sum + t.expenses.totalExpense,
    );

    return MonthlySettlement(
      id: 'settlement_${year}_${month.toString().padLeft(2, '0')}',
      month: month,
      year: year,
      memberBalances: netBalances, // net — not gross
      payments: allPayments,
      totalExpense: totalExpense,
      totalTrips: trips.length,
      status: _deriveStatus(allPayments),
    );
  }

  // ── Gross balance computation ─────────────────────────────────────────────

  static List<MemberBalance> _computeGrossBalances(
    List<TripEntry> trips,
    List<MemberModel> members,
  ) {
    final amountPaid = <String, double>{};
    final amountOwed = <String, double>{};
    final driven = <String, int>{};

    for (final m in members) {
      amountPaid[m.id] = 0;
      amountOwed[m.id] = 0;
      driven[m.id] = 0;
    }

    for (final trip in trips) {
      final total = trip.expenses.totalExpense;
      final count = trip.attendees.length;
      final share = count > 0 ? total / count : 0.0;

      // Driver paid the full expense upfront.
      amountPaid[trip.driver.id] =
          (amountPaid[trip.driver.id] ?? 0) + total;
      driven[trip.driver.id] = (driven[trip.driver.id] ?? 0) + 1;

      // Every attendee (including driver) owes their per-person share.
      for (final attendee in trip.attendees) {
        if (amountOwed.containsKey(attendee.id)) {
          amountOwed[attendee.id] = amountOwed[attendee.id]! + share;
        }
      }
    }

    return members.map((m) {
      final paid = amountPaid[m.id] ?? 0;
      final owed = amountOwed[m.id] ?? 0;
      return MemberBalance(
        memberId: m.id,
        memberName: m.name,
        memberInitials: m.initials,
        colorIndex: m.colorIndex,
        isCurrentUser: m.isCurrentUser,
        netBalance: paid - owed,
        totalDriven: paid,
        totalRideCharges: owed,
        tripsDriven: driven[m.id] ?? 0,
      );
    }).toList();
  }

  // ── Net balance adjustment ────────────────────────────────────────────────

  /// Subtracts completed payment amounts from gross balances.
  ///
  /// For a payment where [from] pays [to]:
  ///   from.netBalance += amount  (less debt  / gained credit)
  ///   to.netBalance  -= amount   (less credit / gained debt from their perspective)
  static List<MemberBalance> _adjustForCompletedPayments(
    List<MemberBalance> grossBalances,
    List<CompletedPayment> completedPayments,
  ) {
    if (completedPayments.isEmpty) return grossBalances;

    final netMap = <String, double>{
      for (final b in grossBalances) b.memberId: b.netBalance,
    };

    for (final cp in completedPayments) {
      netMap[cp.fromId] = (netMap[cp.fromId] ?? 0) + cp.amount;
      netMap[cp.toId] = (netMap[cp.toId] ?? 0) - cp.amount;
    }

    return grossBalances
        .map(
          (b) => MemberBalance(
            memberId: b.memberId,
            memberName: b.memberName,
            memberInitials: b.memberInitials,
            colorIndex: b.colorIndex,
            isCurrentUser: b.isCurrentUser,
            netBalance: netMap[b.memberId] ?? b.netBalance,
            totalDriven: b.totalDriven,
            totalRideCharges: b.totalRideCharges,
            tripsDriven: b.tripsDriven,
          ),
        )
        .toList();
  }

  // ── Greedy min-transactions algorithm ────────────────────────────────────

  /// Generates the minimum number of payment suggestions to clear net balances.
  static List<PaymentSuggestion> _computePayments(
    List<MemberBalance> balances,
    Map<String, String> confirmedStatuses,
    int month,
    int year,
  ) {
    const kTolerance = 0.50; // amounts below ₹0.50 are treated as zero

    final credits = balances
        .where((b) => b.netBalance > kTolerance)
        .map((b) => _Ledger(b))
        .toList()
      ..sort((a, b) => b.remaining.compareTo(a.remaining));

    final debits = balances
        .where((b) => b.netBalance < -kTolerance)
        .map((b) => _Ledger(b))
        .toList()
      ..sort((a, b) => b.remaining.compareTo(a.remaining));

    final suggestions = <PaymentSuggestion>[];

    while (credits.isNotEmpty && debits.isNotEmpty) {
      final creditor = credits.first;
      final debtor = debits.first;

      final amount = creditor.remaining < debtor.remaining
          ? creditor.remaining
          : debtor.remaining;

      final stableId =
          'pay_${debtor.b.memberId}_${creditor.b.memberId}_${month}_$year';

      suggestions.add(PaymentSuggestion(
        id: stableId,
        fromId: debtor.b.memberId,
        fromName: debtor.b.memberName,
        fromInitials: debtor.b.memberInitials,
        fromColorIndex: debtor.b.colorIndex,
        toId: creditor.b.memberId,
        toName: creditor.b.memberName,
        toInitials: creditor.b.memberInitials,
        toColorIndex: creditor.b.colorIndex,
        amount: double.parse(amount.toStringAsFixed(2)),
        status: confirmedStatuses[stableId] ?? PaymentStatus.pending,
      ));

      creditor.remaining -= amount;
      debtor.remaining -= amount;

      if (creditor.remaining < kTolerance) credits.removeAt(0);
      if (debtor.remaining < kTolerance) debits.removeAt(0);
    }

    return suggestions;
  }

  // ── Settlement status ─────────────────────────────────────────────────────

  static String _deriveStatus(List<PaymentSuggestion> payments) {
    if (payments.isEmpty) return SettlementStatusConst.draft;
    if (payments.every((p) => p.isCompleted)) {
      return SettlementStatusConst.completed;
    }
    return SettlementStatusConst.inProgress;
  }
}

/// Mutable ledger entry for the greedy algorithm.
class _Ledger {
  final MemberBalance b;
  double remaining;

  _Ledger(this.b) : remaining = b.netBalance.abs();
}
