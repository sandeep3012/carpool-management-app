import '../entities/settlement_entity.dart';

abstract class SettlementRepository {
  Future<SettlementEntity> generateSettlement(int month, int year);

  Future<SettlementEntity?> getSettlement(int month, int year);

  Future<SettlementEntity?> getSettlementById(String settlementId);

  Future<List<SettlementEntity>> getAllSettlements();

  Future<List<SettlementEntity>> getSettlementsByStatus(String status);

  Future<SettlementEntity> approveSettlement(
    String settlementId,
    String approverId,
  );

  Future<SettlementEntity> rejectSettlement(String settlementId);

  Future<void> deleteSettlement(String settlementId);

  Future<List<SettlementEntity>> getUnsyncedSettlements();

  Future<void> markSettlementAsSynced(String settlementId);

  Future<double> getMemberBalance(String memberId, int month, int year);
}
