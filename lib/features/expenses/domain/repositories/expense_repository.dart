import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<ExpenseEntity> createExpense({
    required String tripId,
    required String type,
    required double amount,
    required String description,
    required String addedBy,
    String? receiptUrl,
  });

  Future<ExpenseEntity?> getExpenseById(String expenseId);

  Future<List<ExpenseEntity>> getExpensesByTrip(String tripId);

  Future<List<ExpenseEntity>> getExpensesByType(String type);

  Future<ExpenseEntity> updateExpense(ExpenseEntity expense);

  Future<void> deleteExpense(String expenseId);

  Future<List<ExpenseEntity>> getUnsyncedExpenses();

  Future<void> markExpenseAsSynced(String expenseId);

  Future<Map<String, double>> getExpensesByTypeTotal(String tripId);
}
