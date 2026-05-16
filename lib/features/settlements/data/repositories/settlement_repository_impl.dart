import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../../../core/database/exceptions.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_local_datasource.dart';
import '../../../../core/database/models/settlement_model.dart' as db;
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementLocalDatasource _localDatasource;
  final TripRepository _tripRepository;
  final ExpenseRepository _expenseRepository;
  final AuthRepository _authRepository;

  SettlementRepositoryImpl({
    required SettlementLocalDatasource localDatasource,
    required TripRepository tripRepository,
    required ExpenseRepository expenseRepository,
    required AuthRepository authRepository,
  })  : _localDatasource = localDatasource,
        _tripRepository = tripRepository,
        _expenseRepository = expenseRepository,
        _authRepository = authRepository;

  @override
  Future<SettlementEntity> generateSettlement(int month, int year) async {
    try {
      // Check if settlement already exists
      final existing =
          await _localDatasource.getSettlementByMonthYear(month, year);
      if (existing != null) {
        throw SettlementAlreadyExistsError(month: month, year: year);
      }

      // Get all trips for the month
      final trips = await _tripRepository.getTripsByMonth(month, year);
      if (trips.isEmpty) {
        throw InvalidSettlementError(
          reason: 'No trips found for the month',
        );
      }

      // Calculate balances
      final balances = <String, double>{};

      for (final trip in trips) {
        if (trip.totalExpense == 0) continue;

        final driver = trip.driverId;
        final attendees = trip.attendeeIds;
        final expensePerPerson = trip.expensePerPerson;

        balances.putIfAbsent(driver, () => 0.0);
        balances[driver] = (balances[driver] ?? 0.0) + trip.totalExpense;

        for (final attendee in attendees) {
          if (attendee != driver) {
            balances.putIfAbsent(attendee, () => 0.0);
            balances[attendee] =
                (balances[attendee] ?? 0.0) - expensePerPerson;
          }
        }
      }

      // Optimize transactions
      final optimizedTransactions = _optimizeTransactions(balances);

      // Convert to JSON
      final transactionsJson = optimizedTransactions
          .map((t) => jsonEncode({
                'from': t['from'],
                'to': t['to'],
                'amount': t['amount'],
                'createdAt': DateTime.now().toIso8601String(),
              }))
          .toList();

      final settlementId = const Uuid().v4();
      final currentUser = await _authRepository.getCurrentUser();

      final dbSettlement = db.SettlementModel.create(
        settlementId: settlementId,
        month: month,
        year: year,
        generatedBy: currentUser?.id ?? 'system',
        memberBalances: balances,
        transactionsJson: transactionsJson,
      );

      final created = await _localDatasource.createSettlement(dbSettlement);
      return _mapDbToEntity(created);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SettlementEntity?> getSettlement(int month, int year) async {
    try {
      final settlement =
          await _localDatasource.getSettlementByMonthYear(month, year);
      return settlement != null ? _mapDbToEntity(settlement) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get settlement',
        originalError: e,
      );
    }
  }

  @override
  Future<SettlementEntity?> getSettlementById(String settlementId) async {
    try {
      final settlement =
          await _localDatasource.getSettlementById(settlementId);
      return settlement != null ? _mapDbToEntity(settlement) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get settlement by ID',
        originalError: e,
      );
    }
  }

  @override
  Future<List<SettlementEntity>> getAllSettlements() async {
    try {
      final settlements = await _localDatasource.getAllSettlements();
      return settlements.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get all settlements',
        originalError: e,
      );
    }
  }

  @override
  Future<List<SettlementEntity>> getSettlementsByStatus(String status) async {
    try {
      final settlements =
          await _localDatasource.getSettlementsByStatus(status);
      return settlements.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get settlements by status',
        originalError: e,
      );
    }
  }

  @override
  Future<SettlementEntity> approveSettlement(
    String settlementId,
    String approverId,
  ) async {
    try {
      final settlement =
          await _localDatasource.getSettlementById(settlementId);
      if (settlement == null) {
        throw EntityNotFoundError(
          entityType: 'Settlement',
          entityId: settlementId,
        );
      }

      settlement
        ..status = 'settled'
        ..approvedBy = approverId
        ..approvalDate = DateTime.now()
        ..updatedAt = DateTime.now();

      final updated = await _localDatasource.updateSettlement(settlement);
      return _mapDbToEntity(updated);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SettlementEntity> rejectSettlement(String settlementId) async {
    try {
      final settlement =
          await _localDatasource.getSettlementById(settlementId);
      if (settlement == null) {
        throw EntityNotFoundError(
          entityType: 'Settlement',
          entityId: settlementId,
        );
      }

      settlement
        ..status = 'draft'
        ..approvedBy = null
        ..approvalDate = null
        ..updatedAt = DateTime.now();

      final updated = await _localDatasource.updateSettlement(settlement);
      return _mapDbToEntity(updated);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteSettlement(String settlementId) async {
    try {
      final settlement =
          await _localDatasource.getSettlementById(settlementId);
      if (settlement == null) {
        throw EntityNotFoundError(
          entityType: 'Settlement',
          entityId: settlementId,
        );
      }
      await _localDatasource.deleteSettlement(settlementId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<SettlementEntity>> getUnsyncedSettlements() async {
    try {
      final settlements = await _localDatasource.getUnsyncedSettlements();
      return settlements.map(_mapDbToEntity).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get unsynced settlements',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markSettlementAsSynced(String settlementId) async {
    try {
      await _localDatasource.markSettlementAsSynced(settlementId);
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to mark settlement as synced',
        originalError: e,
      );
    }
  }

  @override
  Future<double> getMemberBalance(
      String memberId, int month, int year) async {
    try {
      final settlement = await getSettlement(month, year);
      if (settlement == null) return 0.0;
      return settlement.memberBalances[memberId] ?? 0.0;
    } catch (e) {
      throw DatabaseException(
        message: 'Failed to get member balance',
        originalError: e,
      );
    }
  }

  SettlementEntity _mapDbToEntity(db.SettlementModel settlement) {
    final transactions = settlement.getTransactions();
    return SettlementEntity(
      id: settlement.settlementId,
      month: settlement.month,
      year: settlement.year,
      settlementDate: settlement.settlementDate,
      status: settlement.status,
      memberBalances: settlement.memberBalances,
      transactions: transactions
          .map((t) => SettlementTransactionEntity(
                from: t.fromUserId,
                to: t.toUserId,
                amount: t.amount,
                createdAt: t.createdAt,
              ))
          .toList(),
      generatedBy: settlement.generatedBy,
      approvedBy: settlement.approvedBy,
      approvalDate: settlement.approvalDate,
      createdAt: settlement.createdAt,
      updatedAt: settlement.updatedAt,
    );
  }

  List<Map<String, dynamic>> _optimizeTransactions(
      Map<String, double> balances) {
    final result = <Map<String, dynamic>>[];
    final debtors = <String, double>{};
    final creditors = <String, double>{};

    balances.forEach((member, balance) {
      if (balance > 0) {
        creditors[member] = balance;
      } else if (balance < 0) {
        debtors[member] = -balance;
      }
    });

    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      final debtor = debtors.keys.first;
      final creditor = creditors.keys.first;
      final amount = debtors[debtor]!;
      final credit = creditors[creditor]!;
      final transaction = amount < credit ? amount : credit;

      result.add({
        'from': debtor,
        'to': creditor,
        'amount': transaction,
      });

      debtors[debtor] = amount - transaction;
      creditors[creditor] = credit - transaction;

      if (debtors[debtor]! <= 0) debtors.remove(debtor);
      if (creditors[creditor]! <= 0) creditors.remove(creditor);
    }

    return result;
  }
}
