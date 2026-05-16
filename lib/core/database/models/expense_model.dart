/// Expense model for trip charges (fuel, toll, parking, other)
/// Plain Dart class — no Isar codegen required
class ExpenseModel {
  /// Local primary key
  int? id;

  /// Firebase reference (cloudId)
  late String expenseId;

  /// Synchronization status
  late String syncStatus; // "pending" | "synced" | "failed"

  /// Timestamps for sync tracking
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Trip reference
  late String tripId;

  /// Expense details
  late String type; // "fuel" | "toll" | "parking" | "other"
  late double amount;
  late String? description;
  late String? receiptUrl;

  /// Metadata
  late String? addedBy;
  late DateTime? editedAt;
  late String? editHistory;

  ExpenseModel();

  /// Create from parameters
  ExpenseModel.create({
    required this.expenseId,
    required this.tripId,
    required this.type,
    required this.amount,
    this.description,
    this.addedBy,
    this.receiptUrl,
    this.syncStatus = 'pending',
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  /// Get display type name
  String get typeDisplayName => switch (type) {
        'fuel' => 'Fuel',
        'toll' => 'Toll',
        'parking' => 'Parking',
        'other' => 'Other',
        _ => type,
      };

  /// Check if expense can be edited (not locked)
  bool canEdit(DateTime? expenseLockDate) {
    if (expenseLockDate == null) return true;
    return createdAt.isBefore(expenseLockDate);
  }

  /// Copy with modifications
  ExpenseModel copyWith({
    String? expenseId,
    String? tripId,
    String? type,
    double? amount,
    String? description,
    String? receiptUrl,
    String? addedBy,
    String? syncStatus,
  }) {
    return ExpenseModel()
      ..id = id
      ..expenseId = expenseId ?? this.expenseId
      ..tripId = tripId ?? this.tripId
      ..type = type ?? this.type
      ..amount = amount ?? this.amount
      ..description = description ?? this.description
      ..receiptUrl = receiptUrl ?? this.receiptUrl
      ..addedBy = addedBy ?? this.addedBy
      ..syncStatus = syncStatus ?? this.syncStatus
      ..editedAt = DateTime.now()
      ..createdAt = createdAt
      ..updatedAt = DateTime.now();
  }

  @override
  String toString() =>
      'ExpenseModel(id: $id, expenseId: $expenseId, tripId: $tripId, '
      'type: $type, amount: $amount)';
}
