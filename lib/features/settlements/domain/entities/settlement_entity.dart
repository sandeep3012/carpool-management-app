/// Settlement transaction entity
class SettlementTransactionEntity {
  final String from;
  final String to;
  final double amount;
  final DateTime createdAt;

  const SettlementTransactionEntity({
    required this.from,
    required this.to,
    required this.amount,
    required this.createdAt,
  });

  SettlementTransactionEntity copyWith({
    String? from,
    String? to,
    double? amount,
    DateTime? createdAt,
  }) {
    return SettlementTransactionEntity(
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Settlement domain entity (pure Dart, no dependencies)
class SettlementEntity {
  final String id;
  final int month;
  final int year;
  final DateTime settlementDate;
  final String status;
  final Map<String, double> memberBalances;
  final List<SettlementTransactionEntity> transactions;
  final String? generatedBy;
  final String? approvedBy;
  final DateTime? approvalDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SettlementEntity({
    required this.id,
    required this.month,
    required this.year,
    required this.settlementDate,
    required this.status,
    required this.memberBalances,
    required this.transactions,
    this.generatedBy,
    this.approvedBy,
    this.approvalDate,
    required this.createdAt,
    required this.updatedAt,
  });

  SettlementEntity copyWith({
    String? id,
    int? month,
    int? year,
    DateTime? settlementDate,
    String? status,
    Map<String, double>? memberBalances,
    List<SettlementTransactionEntity>? transactions,
    String? generatedBy,
    String? approvedBy,
    DateTime? approvalDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SettlementEntity(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      settlementDate: settlementDate ?? this.settlementDate,
      status: status ?? this.status,
      memberBalances: memberBalances ?? this.memberBalances,
      transactions: transactions ?? this.transactions,
      generatedBy: generatedBy ?? this.generatedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvalDate: approvalDate ?? this.approvalDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
