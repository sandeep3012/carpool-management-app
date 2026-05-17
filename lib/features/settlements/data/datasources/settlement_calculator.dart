import '../../data/models/settlement_models.dart';
import '../../../trips/data/models/trip_entry_model.dart';

/// Pure settlement engine — zero external dependencies.
///
/// ## Business rules (from PRD)
///
///   Driver Contribution = total trip expense for trips the member drove
///   Ride Charge         = per-person share for every trip the member attended
///   Net Balance         = Driver Contribution − Total Ride Charges
///
///   Positive net → creditor (others owe them money)
///   Negative net → debtor   (they owe money to others)
///
/// ## Greedy minimum-transactions algorithm
///
///   Sort creditors descending, debtors descending (by abs value).
///   Repeatedly match the largest creditor with the largest debtor:
///     payment = min(creditor.balance, debtor.balance)
///   Terminate when all balances are within ±₹0.50 (floating-point tolerance).
///
/// Payment IDs are stable across recalculations for the same from/to/month:
///   `pay_<fromId>_<toId>_<month>_<year>`
/// This allows [preservedStatuses] to carry forward UI confirmations.
class SettlementCalculator {
  SettlementCalculator._();

  /// Build a complete [MonthlySettlement] from real trip data.
  ///
  /// [preservedStatuses] maps a payment id to its current UI status so that
  /// "confirmed" / "completed" states survive settlement recomputation when
  /// new trips are added mid-month.
  static MonthlySettlement calculate({
    required int month,
    required int year,
    required List<TripEntry> trips,
    required List<MemberModel> members,
    Map<String, String> preservedStatuses = const {},
  }) {
    final balances = _computeBalances(trips, members);
    final payments =
        _computePayments(balances, preservedStatuses, month, year);
    final totalExpense = trips.fold<double>(
      0,
      (sum, t) => sum + t.expenses.totalExpense,
    );

    return MonthlySettlement(
      id: 'settlement_${year}_${month.toString().padLeft(2, '0')}',
      month: month,
      year: year,
      memberBalances: balances,
      payments: payments,
      totalExpense: totalExpense,
      totalTrips: trips.length,
      status: SettlementStatusConst.inProgress,
    );
  }

  // ── Net balance computation ───────────────────────────────────────────────

  static List<MemberBalance> _computeBalances(
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
      final net = paid - owed;

      return MemberBalance(
        memberId: m.id,
        memberName: m.name,
        memberInitials: m.initials,
        colorIndex: m.colorIndex,
        isCurrentUser: m.isCurrentUser,
        netBalance: net,
        totalDriven: paid,
        totalRideCharges: owed,
        tripsDriven: driven[m.id] ?? 0,
      );
    }).toList();
  }

  // ── Greedy min-transactions algorithm ────────────────────────────────────

  static List<PaymentSuggestion> _computePayments(
    List<MemberBalance> balances,
    Map<String, String> preservedStatuses,
    int month,
    int year,
  ) {
    const kTolerance = 0.50; // amounts below ₹0.50 are treated as settled

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

      // Stable id keyed on from + to + month + year.
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
        status: preservedStatuses[stableId] ?? PaymentStatus.pending,
      ));

      creditor.remaining -= amount;
      debtor.remaining -= amount;

      if (creditor.remaining < kTolerance) credits.removeAt(0);
      if (debtor.remaining < kTolerance) debits.removeAt(0);
    }

    return suggestions;
  }
}

/// Mutable ledger entry for the greedy algorithm.
class _Ledger {
  final MemberBalance b;
  double remaining;

  _Ledger(this.b) : remaining = b.netBalance.abs();
}
