import 'dart:convert';

/// Settlement model for monthly expense settlements
/// Plain Dart class — no Isar codegen required
class SettlementModel {
  /// Local primary key
  int? id;

  /// Firebase reference (cloudId)
  late String settlementId;

  /// Synchronization status
  late String syncStatus; // "pending" | "synced" | "failed"

  /// Timestamps for sync tracking
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Settlement period
  late int month; // 1-12
  late int year;
  late DateTime settlementDate;

  /// Status tracking
  late String status; // "draft" | "pending" | "settled"

  /// Member balances: Key: userId, Value: balance amount
  late Map<String, double> memberBalances;

  /// Settlement transactions as JSON strings
  late List<String> transactionsJson;

  /// Metadata
  late String? generatedBy;
  late String? approvedBy;
  late DateTime? approvalDate;
  late String? notes;

  SettlementModel();

  /// Create from parameters
  SettlementModel.create({
    required this.settlementId,
    required this.month,
    required this.year,
    required this.memberBalances,
    required this.transactionsJson,
    this.status = 'draft',
    this.syncStatus = 'pending',
    this.generatedBy,
  })  : settlementDate = DateTime.now(),
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  /// Get month-year display string
  String get monthYearString {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[month - 1]} $year';
  }

  /// Get member balance for specific user
  double getMemberBalance(String userId) {
    return memberBalances[userId] ?? 0.0;
  }

  /// Parse transactions from JSON
  List<SettlementTransaction> getTransactions() {
    return transactionsJson
        .map((json) => SettlementTransaction.fromJson(json))
        .toList();
  }

  /// Check if settlement can be edited
  bool canEdit() => status != 'settled';

  /// Mark settlement as pending (ready for approval)
  void markAsPending(String approverUserId) {
    status = 'pending';
    approvedBy = approverUserId;
    updatedAt = DateTime.now();
  }

  /// Approve settlement
  void approve(String approvingAdminId) {
    status = 'settled';
    approvedBy = approvingAdminId;
    approvalDate = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Calculate total amount involved
  double getTotalAmount() {
    return getTransactions().fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Validate settlement (balances should sum to ~0)
  bool isValid() {
    final total =
        memberBalances.values.fold<double>(0, (sum, balance) => sum + balance);
    return total.abs() < 0.01;
  }

  /// Copy with modifications
  SettlementModel copyWith({
    String? settlementId,
    int? month,
    int? year,
    String? status,
    Map<String, double>? memberBalances,
    List<String>? transactionsJson,
    String? generatedBy,
    String? approvedBy,
    DateTime? approvalDate,
    String? syncStatus,
    String? notes,
  }) {
    return SettlementModel()
      ..id = id
      ..settlementId = settlementId ?? this.settlementId
      ..month = month ?? this.month
      ..year = year ?? this.year
      ..status = status ?? this.status
      ..memberBalances = memberBalances ?? this.memberBalances
      ..transactionsJson = transactionsJson ?? this.transactionsJson
      ..generatedBy = generatedBy ?? this.generatedBy
      ..approvedBy = approvedBy ?? this.approvedBy
      ..approvalDate = approvalDate ?? this.approvalDate
      ..syncStatus = syncStatus ?? this.syncStatus
      ..notes = notes ?? this.notes
      ..settlementDate = settlementDate
      ..createdAt = createdAt
      ..updatedAt = DateTime.now();
  }

  @override
  String toString() =>
      'SettlementModel(id: $id, settlementId: $settlementId, '
      'month: $month, year: $year, status: $status, '
      'memberCount: ${memberBalances.length})';
}

/// Represents a single settlement transaction
class SettlementTransaction {
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime createdAt;

  SettlementTransaction({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.createdAt,
  });

  /// Convert to JSON string
  String toJson() => jsonEncode({
        'from': fromUserId,
        'to': toUserId,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
      });

  /// Create from JSON string
  static SettlementTransaction fromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return SettlementTransaction(
      fromUserId: data['from'] as String,
      toUserId: data['to'] as String,
      amount: (data['amount'] as num).toDouble(),
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  /// Get display description
  String getDescription(String fromName, String toName) =>
      '$fromName pays ₹${amount.toStringAsFixed(2)} to $toName';

  @override
  String toString() =>
      'SettlementTransaction(from: $fromUserId, to: $toUserId, '
      'amount: ₹$amount)';
}
