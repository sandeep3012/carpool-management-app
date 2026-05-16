import '../../../../core/database/isar_service.dart';
import '../../../../core/database/models/settlement_model.dart' as db;

abstract class SettlementLocalDatasource {
  Future<db.SettlementModel> createSettlement(db.SettlementModel settlement);

  Future<db.SettlementModel?> getSettlementById(String settlementId);

  Future<db.SettlementModel?> getSettlementByMonthYear(int month, int year);

  Future<List<db.SettlementModel>> getSettlementsByStatus(String status);

  Future<List<db.SettlementModel>> getAllSettlements();

  Future<db.SettlementModel> updateSettlement(db.SettlementModel settlement);

  Future<void> deleteSettlement(String settlementId);

  Future<List<db.SettlementModel>> getUnsyncedSettlements();

  Future<void> markSettlementAsSynced(String settlementId);
}

class SettlementLocalDatasourceImpl implements SettlementLocalDatasource {
  final IsarService _isar;

  SettlementLocalDatasourceImpl({required IsarService isar}) : _isar = isar;

  @override
  Future<db.SettlementModel> createSettlement(
      db.SettlementModel settlement) async {
    await _isar.txn(() async {
      await _isar.settlements.put(settlement);
    });
    return settlement;
  }

  @override
  Future<db.SettlementModel?> getSettlementById(String settlementId) async {
    return _isar.settlements
        .filterFirst((s) => s.settlementId == settlementId);
  }

  @override
  Future<db.SettlementModel?> getSettlementByMonthYear(
      int month, int year) async {
    return _isar.settlements
        .filterFirst((s) => s.month == month && s.year == year);
  }

  @override
  Future<List<db.SettlementModel>> getSettlementsByStatus(
      String status) async {
    return _isar.settlements.filter((s) => s.status == status);
  }

  @override
  Future<List<db.SettlementModel>> getAllSettlements() async {
    return _isar.settlements.findAll();
  }

  @override
  Future<db.SettlementModel> updateSettlement(
      db.SettlementModel settlement) async {
    await _isar.txn(() async {
      await _isar.settlements.put(settlement);
    });
    return settlement;
  }

  @override
  Future<void> deleteSettlement(String settlementId) async {
    final settlement = await getSettlementById(settlementId);
    if (settlement != null) {
      await _isar.txn(() async {
        await _isar.settlements.delete(settlement.id);
      });
    }
  }

  @override
  Future<List<db.SettlementModel>> getUnsyncedSettlements() async {
    return _isar.settlements.filter((s) => s.syncStatus == 'pending');
  }

  @override
  Future<void> markSettlementAsSynced(String settlementId) async {
    final settlement = await getSettlementById(settlementId);
    if (settlement != null) {
      settlement.syncStatus = 'synced';
      settlement.updatedAt = DateTime.now();
      await _isar.txn(() async {
        await _isar.settlements.put(settlement);
      });
    }
  }
}
