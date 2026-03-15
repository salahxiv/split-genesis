import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_settings_service.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../settlements/models/settlement_record.dart';
import '../../settlements/providers/settlements_provider.dart';
import '../../expenses/models/expense.dart';
import '../models/balance.dart';
import '../services/debt_calculator.dart';

final watchedSplitsByGroupProvider =
    FutureProvider.family<List<ExpenseSplit>, String>((ref, groupId) async {
  ref.watch(expensesProvider(groupId));
  return ref.read(expenseRepositoryProvider).getSplitsByGroup(groupId);
});

final watchedPayersByGroupProvider =
    FutureProvider.family<List<ExpensePayer>, String>((ref, groupId) async {
  ref.watch(expensesProvider(groupId));
  return ref.read(expenseRepositoryProvider).getPayersByGroup(groupId);
});

class GroupComputedData {
  final List<MemberBalance> balances;
  final List<Settlement> settlements;
  final double totalSpend;
  final Map<String, String> memberMap;
  final List<SettlementRecord> settlementRecords;

  /// Multi-currency balances — one entry per member, each with a per-currency
  /// breakdown. CEO decision (Issue #54): no auto-conversion; show each
  /// currency separately.
  final List<MultiCurrencyBalance> multiCurrencyBalances;

  const GroupComputedData({
    required this.balances,
    required this.settlements,
    required this.totalSpend,
    required this.memberMap,
    required this.settlementRecords,
    required this.multiCurrencyBalances,
  });
}

final groupComputedDataProvider =
    FutureProvider.family<GroupComputedData, String>((ref, groupId) async {
  final swTotal = Stopwatch()..start();
  debugPrint('[PERF] groupComputedDataProvider($groupId) START');

  // Kick off all provider futures simultaneously, then await them together
  final membersFuture = ref.watch(membersProvider(groupId).future);
  final expensesFuture = ref.watch(expensesProvider(groupId).future);
  final settlementRecordsFuture = ref.watch(settlementRecordsProvider(groupId).future);
  final splitsFuture = ref.watch(watchedSplitsByGroupProvider(groupId).future);
  final payersFuture = ref.watch(watchedPayersByGroupProvider(groupId).future);

  // Await all in parallel instead of sequentially
  final membersResult = await membersFuture;
  final expensesResult = await expensesFuture;
  final settlementRecords = await settlementRecordsFuture;
  final splits = await splitsFuture;
  final payers = await payersFuture;
  debugPrint('[PERF]   all data fetched in: ${swTotal.elapsedMilliseconds}ms');

  final members = membersResult;
  final expenses = expensesResult;

  // Determine group display currency (balances always shown in group currency)
  final groups = ref.read(groupsProvider).valueOrNull ?? [];
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => throw StateError('Group $groupId not found'),
  );
  final displayCurrency = group.currency;

  // Read app settings for simplify-debts toggle (default: true)
  final appSettings = ref.read(appSettingsProvider);
  final simplifyDebts = appSettings.simplifyDebts;

  debugPrint('[PERF]   members=${members.length}, expenses=${expenses.length}, settlements=${settlementRecords.length}, splits=${splits.length}, payers=${payers.length}, simplifyDebts=$simplifyDebts');

  var sw = Stopwatch()..start();
  final balances = DebtCalculator.calculateNetBalances(
    members, expenses, splits,
    settlements: settlementRecords, payers: payers,
    displayCurrency: displayCurrency,
  );
  final settlements = DebtCalculator.calculateSettlements(
    members, expenses, splits,
    settlements: settlementRecords, payers: payers,
    displayCurrency: displayCurrency,
    simplifyDebts: simplifyDebts,
  );
  debugPrint('[PERF]   DebtCalculator: ${sw.elapsedMilliseconds}ms');

  // Multi-currency balances: per-currency breakdown, no conversion (Issue #54)
  sw = Stopwatch()..start();
  final multiCurrencyBalances = DebtCalculator.calculateMultiCurrencyBalances(
    members, expenses, splits,
    settlements: settlementRecords, payers: payers,
    settlementCurrency: displayCurrency,
  );
  debugPrint('[PERF]   MultiCurrencyBalances: ${sw.elapsedMilliseconds}ms');

  final totalSpend = expenses.fold(0, (sum, e) => sum + e.amountCents) / 100.0;
  final memberMap = {for (var m in members) m.id: m.name};

  debugPrint('[PERF] groupComputedDataProvider($groupId) DONE in ${swTotal.elapsedMilliseconds}ms');
  return GroupComputedData(
    balances: balances,
    settlements: settlements,
    totalSpend: totalSpend,
    memberMap: memberMap,
    settlementRecords: settlementRecords,
    multiCurrencyBalances: multiCurrencyBalances,
  );
});

// Keep backward-compatible providers that derive from the consolidated one
final balancesProvider =
    FutureProvider.family<List<MemberBalance>, String>((ref, groupId) async {
  final data = await ref.watch(groupComputedDataProvider(groupId).future);
  return data.balances;
});

final settlementsProvider =
    FutureProvider.family<List<Settlement>, String>((ref, groupId) async {
  final data = await ref.watch(groupComputedDataProvider(groupId).future);
  return data.settlements;
});
