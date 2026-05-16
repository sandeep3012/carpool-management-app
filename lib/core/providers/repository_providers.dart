import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/isar_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/trips/domain/repositories/trip_repository.dart';
import '../../features/trips/data/datasources/trip_local_datasource.dart';
import '../../features/trips/data/datasources/trip_remote_datasource.dart';
import '../../features/trips/data/repositories/trip_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/data/datasources/expense_local_datasource.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/settlements/domain/repositories/settlement_repository.dart';
import '../../features/settlements/data/datasources/settlement_local_datasource.dart';
import '../../features/settlements/data/repositories/settlement_repository_impl.dart';
import '../../features/guests/domain/repositories/guest_repository.dart';
import '../../features/guests/data/repositories/guest_repository_impl.dart';
import '../../features/audit/domain/repositories/audit_log_repository.dart';
import '../../features/audit/data/repositories/audit_log_repository_impl.dart';

/// Datasource Providers

final tripLocalDatasourceProvider = Provider<TripLocalDatasource>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return TripLocalDatasourceImpl(isar: isar);
});

final tripRemoteDatasourceProvider = Provider<TripRemoteDatasource>((ref) {
  return TripRemoteDatasourceImpl();
});

final expenseLocalDatasourceProvider =
    Provider<ExpenseLocalDatasource>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return ExpenseLocalDatasourceImpl(isar: isar);
});

final settlementLocalDatasourceProvider =
    Provider<SettlementLocalDatasource>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return SettlementLocalDatasourceImpl(isar: isar);
});

/// Repository Providers

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return AuthRepositoryImpl(isar: isar);
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final localDatasource = ref.watch(tripLocalDatasourceProvider);
  final remoteDatasource = ref.watch(tripRemoteDatasourceProvider);
  return TripRepositoryImpl(
    localDatasource: localDatasource,
    remoteDatasource: remoteDatasource,
  );
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final localDatasource = ref.watch(expenseLocalDatasourceProvider);
  return ExpenseRepositoryImpl(localDatasource: localDatasource);
});

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  final localDatasource = ref.watch(settlementLocalDatasourceProvider);
  final tripRepository = ref.watch(tripRepositoryProvider);
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  return SettlementRepositoryImpl(
    localDatasource: localDatasource,
    tripRepository: tripRepository,
    expenseRepository: expenseRepository,
    authRepository: authRepository,
  );
});

final guestRepositoryProvider = Provider<GuestRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return GuestRepositoryImpl(isar: isar);
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return AuditLogRepositoryImpl(isar: isar);
});
