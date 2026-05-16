import '../../../../core/database/isar_service.dart';
import '../../../../core/database/models/expense_model.dart' as db;

abstract class ExpenseLocalDatasource {
  Future<db.ExpenseModel> createExpense(db.ExpenseModel expense);

  Future<db.ExpenseModel?> getExpenseById(String expenseId);

  Future<List<db.ExpenseModel>> getExpensesByTrip(String tripId);

  Future<List<db.ExpenseModel>> getExpensesByType(String type);

  Future<db.ExpenseModel> updateExpense(db.ExpenseModel expense);

  Future<void> deleteExpense(String expenseId);

  Future<List<db.ExpenseModel>> getUnsyncedExpenses();

  Future<void> markExpenseAsSynced(String expenseId);
}

class ExpenseLocalDatasourceImpl implements ExpenseLocalDatasource {
  final IsarService _isar;

  ExpenseLocalDatasourceImpl({required IsarService isar}) : _isar = isar;

  @override
  Future<db.ExpenseModel> createExpense(db.ExpenseModel expense) async {
    await _isar.txn(() async {
      await _isar.expenses.put(expense);
    });
    return expense;
  }

  @override
  Future<db.ExpenseModel?> getExpenseById(String expenseId) async {
    return _isar.expenses.filterFirst((e) => e.expenseId == expenseId);
  }

  @override
  Future<List<db.ExpenseModel>> getExpensesByTrip(String tripId) async {
    return _isar.expenses.filter((e) => e.tripId == tripId);
  }

  @override
  Future<List<db.ExpenseModel>> getExpensesByType(String type) async {
    return _isar.expenses.filter((e) => e.type == type);
  }

  @override
  Future<db.ExpenseModel> updateExpense(db.ExpenseModel expense) async {
    await _isar.txn(() async {
      await _isar.expenses.put(expense);
    });
    return expense;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    final expense = await getExpenseById(expenseId);
    if (expense != null) {
      await _isar.txn(() async {
        await _isar.expenses.delete(expense.id);
      });
    }
  }

  @override
  Future<List<db.ExpenseModel>> getUnsyncedExpenses() async {
    return _isar.expenses.filter((e) => e.syncStatus == 'pending');
  }

  @override
  Future<void> markExpenseAsSynced(String expenseId) async {
    final expense = await getExpenseById(expenseId);
    if (expense != null) {
      expense.syncStatus = 'synced';
      expense.updatedAt = DateTime.now();
      await _isar.txn(() async {
        await _isar.expenses.put(expense);
      });
    }
  }
}
