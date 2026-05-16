/// Presentation-layer models for the Settlements feature.
///
/// These are self-contained plain Dart classes used exclusively by the UI.
/// No codegen, no Isar, no Firebase — pure data containers with business
/// logic for displaying balances and payment flows.
///
/// Settlement logic:
///   Net Balance   = Total Driven − Total Owed as Passenger
///   Positive net  → member is owed money (creditor)
///   Negative net  → member owes money (debtor)
///
/// Optimized payments use the "minimum transactions" algorithm:
///   repeatedly match the largest debtor with the largest creditor.

// ── Member balance ────────────────────────────────────────────────────────────

/// Balance status constants.
class BalanceStatus {
  BalanceStatus._();
  static const String credit = 'credit'; // owed money (positive net)
  static const String debit = 'debit'; // owes money  (negative net)
  static const String settled = 'settled'; // exactly zero
}

class MemberBalance {
  final String memberId;
  final String memberName;
  final String memberInitials;
  final int colorIndex;
  final bool isCurrentUser;

  /// Positive = owed money; negative = owes money.
  final double netBalance;

  /// Total amount this member drove (paid upfront).
  final double totalDriven;

  /// Total amount this member consumed as a passenger.
  final double totalRideCharges;

  /// Number of trips driven this month.
  final int tripsDriven;

  const MemberBalance({
    required this.memberId,
    required this.memberName,
    required this.memberInitials,
    required this.colorIndex,
    required this.isCurrentUser,
    required this.netBalance,
    required this.totalDriven,
    required this.totalRideCharges,
    required this.tripsDriven,
  });

  String get status {
    if (netBalance > 0.5) return BalanceStatus.credit;
    if (netBalance < -0.5) return BalanceStatus.debit;
    return BalanceStatus.settled;
  }

  double get absBalance => netBalance.abs();
}

// ── Payment suggestion ────────────────────────────────────────────────────────

/// Payment status constants.
class PaymentStatus {
  PaymentStatus._();
  static const String pending = 'pending';
  static const String confirmed = 'confirmed'; // payer confirmed
  static const String completed = 'completed'; // both sides confirmed
}

/// One optimized payment in the settlement graph.
class PaymentSuggestion {
  final String id;
  final String fromId;
  final String fromName;
  final String fromInitials;
  final int fromColorIndex;

  final String toId;
  final String toName;
  final String toInitials;
  final int toColorIndex;

  final double amount;
  String status; // mutable so UI can toggle in-place

  PaymentSuggestion({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.fromInitials,
    required this.fromColorIndex,
    required this.toId,
    required this.toName,
    required this.toInitials,
    required this.toColorIndex,
    required this.amount,
    this.status = PaymentStatus.pending,
  });

  bool get isPending => status == PaymentStatus.pending;
  bool get isConfirmed => status == PaymentStatus.confirmed;
  bool get isCompleted => status == PaymentStatus.completed;

  PaymentSuggestion copyWith({
    String? status,
    double? amount,
  }) {
    return PaymentSuggestion(
      id: id,
      fromId: fromId,
      fromName: fromName,
      fromInitials: fromInitials,
      fromColorIndex: fromColorIndex,
      toId: toId,
      toName: toName,
      toInitials: toInitials,
      toColorIndex: toColorIndex,
      amount: amount ?? this.amount,
      status: status ?? this.status,
    );
  }
}

// ── Monthly settlement ────────────────────────────────────────────────────────

/// Settlement status constants.
class SettlementStatusConst {
  SettlementStatusConst._();
  static const String draft = 'draft';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
}

/// Top-level monthly settlement model shown on the summary screen.
class MonthlySettlement {
  final String id;
  final int month;
  final int year;

  final List<MemberBalance> memberBalances;
  final List<PaymentSuggestion> payments;

  /// Total rupees that changed hands this month across all trips.
  final double totalExpense;

  /// Total number of trips in the month.
  final int totalTrips;

  String status;

  MonthlySettlement({
    required this.id,
    required this.month,
    required this.year,
    required this.memberBalances,
    required this.payments,
    required this.totalExpense,
    required this.totalTrips,
    this.status = SettlementStatusConst.draft,
  });

  int get completedPayments =>
      payments.where((p) => p.isCompleted).length;

  int get pendingPayments =>
      payments.where((p) => p.isPending).length;

  double get settlementProgress =>
      payments.isEmpty ? 0 : completedPayments / payments.length;

  bool get isFullySettled => pendingPayments == 0 && payments.isNotEmpty;
}
