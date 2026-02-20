import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/settlement_record.dart';
import '../repositories/settlement_repository.dart';

final settlementRepositoryProvider =
    Provider((ref) => SettlementRepository());

final settlementRecordsProvider = AsyncNotifierProvider.family<
    SettlementRecordsNotifier, List<SettlementRecord>, String>(
    SettlementRecordsNotifier.new);

class SettlementRecordsNotifier
    extends FamilyAsyncNotifier<List<SettlementRecord>, String> {
  @override
  Future<List<SettlementRecord>> build(String arg) async {
    final sw = Stopwatch()..start();
    final result = await ref
        .read(settlementRepositoryProvider)
        .getSettlementsByGroup(arg);
    debugPrint('[PERF] settlementRecordsProvider($arg).build(): ${sw.elapsedMilliseconds}ms (${result.length} records)');
    return result;
  }

  Future<void> addSettlement({
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required String fromMemberName,
    required String toMemberName,
  }) async {
    final record = SettlementRecord(
      id: const Uuid().v4(),
      groupId: arg,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: amount,
      createdAt: DateTime.now(),
      fromMemberName: fromMemberName,
      toMemberName: toMemberName,
    );
    await ref.read(settlementRepositoryProvider).insertSettlement(record);
    ref.invalidateSelf();
  }

  Future<void> deleteSettlement(String id) async {
    await ref.read(settlementRepositoryProvider).deleteSettlement(id);
    ref.invalidateSelf();
  }
}
