/// Expense domain entity (pure Dart, no dependencies)
class ExpenseEntity {
  final String id;
  final String tripId;
  final String type;
  final double amount;
  final String? description;
  final String? receiptUrl;
  final String? addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseEntity({
    required this.id,
    required this.tripId,
    required this.type,
    required this.amount,
    this.description,
    this.receiptUrl,
    this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  ExpenseEntity copyWith({
    String? id,
    String? tripId,
    String? type,
    double? amount,
    String? description,
    String? receiptUrl,
    String? addedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
