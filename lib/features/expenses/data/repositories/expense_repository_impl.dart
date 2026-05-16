import 'package:uuid/uuid.dart';
import '../../../../core/database/exceptions.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../../../../core/database/models/expense_model.dart' as db;

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDatasource _localDatasource;

  ExpenseRepositoryImpl({required ExpenseLocalDatasource localDatasource})
      : _localDatasource = localDatasource;

  @override
  Future<ExpenseEntity> createExpense({
    required String tripId,
    required String type,
    required double amount,
    required String description,
    required String addedBy,
    String? receiptUrl,
  }) async {
    try {
      final expenseId = const Uuid().v4();
      final dbExpense = db.ExpenseModel.create(
        expenseId: expenseId,
        tripId: tripId,
        type: type,
        amount: amount,
        description: description,
        addedBy: addedBy,
        receiptUrl: receiptUrl,
      );

      final created = await _localDatasource.createExpense(dbExpense);
      return _mapDbToEntity(created);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to create expense',
        originalError: e,
      );
    }
  }

  @override
  Future<ExpenseEntity?> getExpenseById(String expenseId) async {
    try {
      final expense = await _localDatasource.getExpenseById(expenseId);
      return expense != null ? _mapDbToEntity(expense) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get expense',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByTrip(String tripId) async {
    try {
      final expenses = await _localDatasource.getExpensesByTrip(tripId);
      return expenses.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get expenses by trip',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByType(String type) async {
    try {
      final expenses = await _localDatasource.getExpensesByType(type);
      return expenses.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get expenses by type',
        originalError: e,
      );
    }
  }

  @override
  Future<ExpenseEntity> updateExpense(ExpenseEntity expense) async {
    try {
      final existing =
          await _localDatasource.getExpenseById(expense.id);
      if (existing == null) {
        throw EntityNotFoundError(
          entityType: 'Expense',
          entityId: expense.id,
        );
      }

      existing
        ..type = expense.type
        ..amount = expense.amount
        ..description = expense.description
        ..receiptUrl = expense.receiptUrl
        ..updatedAt = DateTime.now();

      final updated = await _localDatasource.updateExpense(existing);
      return _mapDbToEntity(updated);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      final existing = await _localDatasource.getExpenseById(expenseId);
      if (existing == null) {
        throw EntityNotFoundError(
          entityType: 'Expense',
          entityId: expenseId,
        );
      }
      await _localDatasource.deleteExpense(expenseId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ExpenseEntity>> getUnsyncedExpenses() async {
    try {
      final expenses = await _localDatasource.getUnsyncedExpenses();
      return expenses.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get unsynced expenses',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markExpenseAsSynced(String expenseId) async {
    try {
      await _localDatasource.markExpenseAsSynced(expenseId);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to mark expense as synced',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, double>> getExpensesByTypeTotal(String tripId) async {
    try {
      final expenses = await getExpensesByTrip(tripId);
      final totals = <String, double>{};

      for (final expense in expenses) {
        totals.update(
          expense.type,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      return totals;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get expense totals by type',
        originalError: e,
      );
    }
  }

  ExpenseEntity _mapDbToEntity(db.ExpenseModel expense) {
    return ExpenseEntity(
      id: expense.expenseId,
      tripId: expense.tripId,
      type: expense.type,
      amount: expense.amount,
      description: expense.description,
      receiptUrl: expense.receiptUrl,
      addedBy: expense.addedBy,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }
}
