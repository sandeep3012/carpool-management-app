import '../models/settlement_models.dart';

/// In-memory mock settlement store for May 2026.
///
/// Net balances are pre-calculated from the 10 recorded weekday trips:
///   Distance 45 km, Fuel ₹102/L, Mileage 15 kmpl → Fuel = ₹306/trip
///   + Toll ₹60 every day
///   + Parking / Other on selected days
///
/// Driver rotation (10 trips):
///   Rajesh × 2 | Priya × 2 | Suresh × 2 | Kavitha × 2 | Arun × 2
///
/// Optimized payments use the min-transactions greedy algorithm:
///   sort creditors desc, debtors desc, match heads repeatedly.
class SettlementMockDatasource {
  SettlementMockDatasource._();

  // ── Member meta ──────────────────────────────────────────────────────────

  static const _members = [
    (id: 'm001', name: 'Rajesh Kumar', initials: 'RK', colorIndex: 0, isMe: true),
    (id: 'm002', name: 'Priya Sharma', initials: 'PS', colorIndex: 1, isMe: false),
    (id: 'm003', name: 'Suresh Patel', initials: 'SP', colorIndex: 2, isMe: false),
    (id: 'm004', name: 'Kavitha Nair', initials: 'KN', colorIndex: 3, isMe: false),
    (id: 'm005', name: 'Arun Singh', initials: 'AS', colorIndex: 4, isMe: false),
  ];

  // ── Pre-calculated net balances ──────────────────────────────────────────
  //
  // Net = (Trips driven × net contribution per trip) − (Passenger share on
  //       non-driving trips).  Sum = 0 ✓
  //
  // Rajesh: drove Days 2 (₹366) + 14 (₹366). Net ≈ +₹145
  // Priya:  drove Days 5 (₹386) + 16 (₹366). Net ≈ +₹35
  // Suresh: drove Days 7 (₹396) + 19 (₹436). Net ≈ +₹85  (Day 19 had ₹50 other)
  // Kavitha:drove Days 9 (₹366) + 21 (₹366). Net ≈ −₹110
  // Arun:   drove Days 12(₹386) + 23 (₹366). Net ≈ −₹155

  static const _netBalances = {
    'm001': 145.0,
    'm002': 35.0,
    'm003': 85.0,
    'm004': -110.0,
    'm005': -155.0,
  };

  static const _totalDriven = {
    'm001': 732.0,   // 366 + 366
    'm002': 752.0,   // 386 + 366
    'm003': 832.0,   // 396 + 436
    'm004': 732.0,   // 366 + 366
    'm005': 752.0,   // 386 + 366
  };

  // ── In-memory payment store ──────────────────────────────────────────────

  static final List<PaymentSuggestion> _payments = _buildPayments();

  static List<PaymentSuggestion> _buildPayments() {
    // Greedy min-transactions algorithm applied to the net balances above.
    //
    // Result (4 payments to settle 5 people):
    //   1. Arun  (−155) → Rajesh (+145) : ₹145   [completed — already paid]
    //   2. Arun  (−10)  → Priya  (+35)  : ₹10    [confirmed — Arun confirmed]
    //   3. Kavitha(−110)→ Priya  (+25)  : ₹25    [pending]
    //   4. Kavitha(−85) → Suresh (+85)  : ₹85    [pending]

    String memberName(String id) =>
        _members.firstWhere((m) => m.id == id).name;
    String memberInitials(String id) =>
        _members.firstWhere((m) => m.id == id).initials;
    int memberColorIndex(String id) =>
        _members.firstWhere((m) => m.id == id).colorIndex;

    return [
      PaymentSuggestion(
        id: 'pay_001',
        fromId: 'm005', fromName: memberName('m005'),
        fromInitials: memberInitials('m005'),
        fromColorIndex: memberColorIndex('m005'),
        toId: 'm001', toName: memberName('m001'),
        toInitials: memberInitials('m001'),
        toColorIndex: memberColorIndex('m001'),
        amount: 145,
        status: PaymentStatus.completed,
      ),
      PaymentSuggestion(
        id: 'pay_002',
        fromId: 'm005', fromName: memberName('m005'),
        fromInitials: memberInitials('m005'),
        fromColorIndex: memberColorIndex('m005'),
        toId: 'm002', toName: memberName('m002'),
        toInitials: memberInitials('m002'),
        toColorIndex: memberColorIndex('m002'),
        amount: 10,
        status: PaymentStatus.confirmed,
      ),
      PaymentSuggestion(
        id: 'pay_003',
        fromId: 'm004', fromName: memberName('m004'),
        fromInitials: memberInitials('m004'),
        fromColorIndex: memberColorIndex('m004'),
        toId: 'm002', toName: memberName('m002'),
        toInitials: memberInitials('m002'),
        toColorIndex: memberColorIndex('m002'),
        amount: 25,
        status: PaymentStatus.pending,
      ),
      PaymentSuggestion(
        id: 'pay_004',
        fromId: 'm004', fromName: memberName('m004'),
        fromInitials: memberInitials('m004'),
        fromColorIndex: memberColorIndex('m004'),
        toId: 'm003', toName: memberName('m003'),
        toInitials: memberInitials('m003'),
        toColorIndex: memberColorIndex('m003'),
        amount: 85,
        status: PaymentStatus.pending,
      ),
    ];
  }

  // ── Balance builder ──────────────────────────────────────────────────────

  static List<MemberBalance> _buildBalances() {
    return _members.map((m) {
      final net = _netBalances[m.id]!;
      final driven = _totalDriven[m.id]!;
      return MemberBalance(
        memberId: m.id,
        memberName: m.name,
        memberInitials: m.initials,
        colorIndex: m.colorIndex,
        isCurrentUser: m.isMe,
        netBalance: net,
        totalDriven: driven,
        totalRideCharges: driven - net,
        tripsDriven: 2,
      );
    }).toList();
  }

  // ── Public API ──────────────────────────────────────────────────────────

  static MonthlySettlement getSettlement() {
    final balances = _buildBalances();
    return MonthlySettlement(
      id: 'settlement_2026_05',
      month: 5,
      year: 2026,
      memberBalances: balances,
      payments: _payments,
      totalExpense: 3820.0,   // sum of all 10 trip totals
      totalTrips: 10,
      status: SettlementStatusConst.inProgress,
    );
  }

  /// Update a payment's status (persisted in the in-memory list).
  static void confirmPayment(String paymentId) {
    final idx = _payments.indexWhere((p) => p.id == paymentId);
    if (idx < 0) return;
    final p = _payments[idx];
    _payments[idx] = p.copyWith(
      status: p.isPending ? PaymentStatus.confirmed : PaymentStatus.completed,
    );
  }

  /// Mark a payment as fully completed.
  static void completePayment(String paymentId) {
    final idx = _payments.indexWhere((p) => p.id == paymentId);
    if (idx < 0) return;
    _payments[idx] = _payments[idx].copyWith(status: PaymentStatus.completed);
  }

  /// Reset a payment back to pending.
  static void resetPayment(String paymentId) {
    final idx = _payments.indexWhere((p) => p.id == paymentId);
    if (idx < 0) return;
    _payments[idx] = _payments[idx].copyWith(status: PaymentStatus.pending);
  }

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String monthLabel(int month, int year) =>
      '${_monthNames[month]} $year';
}
