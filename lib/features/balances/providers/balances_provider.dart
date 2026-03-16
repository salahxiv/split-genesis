import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/services/auth_service.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../settlements/models/settlement_record.dart';
import '../../settlements/providers/settlements_provider.dart';
import '../../expenses/models/expense.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/balance.dart';
import '../services/debt_calculator.dart';

final watchedSplitsByGroupProvider =
    FutureProvider.autoDispose.family<List<ExpenseSplit>, String>((ref, groupId) async {
  ref.watch(expensesProvider(groupId));
  return ref.read(expenseRepositoryProvider).getSplitsByGroup(groupId);
});

final watchedPayersByGroupProvider =
    FutureProvider.autoDispose.family<List<ExpensePayer>, String>((ref, groupId) async {
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
    FutureProvider.autoDispose.family<GroupComputedData, String>((ref, groupId) async {
  // Keep alive for 30s after last watcher disconnects to survive navigation transitions
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), link.close);
  ref.onDispose(timer.cancel);

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
    FutureProvider.autoDispose.family<List<MemberBalance>, String>((ref, groupId) async {
  final data = await ref.watch(groupComputedDataProvider(groupId).future);
  return data.balances;
});

final settlementsProvider =
    FutureProvider.autoDispose.family<List<Settlement>, String>((ref, groupId) async {
  final data = await ref.watch(groupComputedDataProvider(groupId).future);
  return data.settlements;
});

/// Enum representing the current user's balance status in a group.
enum UserBalanceStatus { positive, negative, settled, unknown }

/// User balance result for a specific group.
class GroupUserBalance {
  final double? amount; // null if name not set or no match
  final UserBalanceStatus status;
  final String currency;

  const GroupUserBalance({
    required this.amount,
    required this.status,
    required this.currency,
  });

  bool get isKnown => amount != null;
}

/// Provider that computes the current user's net balance in a group.
/// Matches by userId first, falls back to displayName for backwards compatibility.
final groupUserBalanceProvider =
    FutureProvider.autoDispose.family<GroupUserBalance, String>((ref, groupId) async {
  final computed = await ref.watch(groupComputedDataProvider(groupId).future);
  final displayName = ref.watch(displayNameProvider);

  // Get the group currency from groups provider
  final groups = ref.read(groupsProvider).valueOrNull ?? [];
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => throw StateError('Group $groupId not found'),
  );
  final currency = group.currency;

  final currentUserId = AuthService.instance.userId;
  final hasMultipleCurrencies = computed.multiCurrencyBalances.any(
    (mcb) => mcb.currencyBalances.length > 1 ||
        (mcb.currencyBalances.isNotEmpty &&
         mcb.currencyBalances.keys.first != currency),
  );

  double? balance;

  // Primary match: by userId (robust)
  if (currentUserId != null) {
    if (!hasMultipleCurrencies) {
      for (final mb in computed.balances) {
        if (mb.member.userId == currentUserId) {
          balance = mb.netBalance;
          break;
        }
      }
    } else {
      for (final mcb in computed.multiCurrencyBalances) {
        if (mcb.member.userId == currentUserId) {
          balance = mcb.amountFor(currency);
          break;
        }
      }
    }
  }

  // Fallback match: by displayName (backwards compatibility)
  if (balance == null && displayName.trim().isNotEmpty) {
    final lowerName = displayName.trim().toLowerCase();
    if (!hasMultipleCurrencies) {
      for (final mb in computed.balances) {
        if (mb.member.name.toLowerCase() == lowerName) {
          balance = mb.netBalance;
          break;
        }
      }
    } else {
      for (final mcb in computed.multiCurrencyBalances) {
        if (mcb.member.name.toLowerCase() == lowerName) {
          balance = mcb.amountFor(currency);
          break;
        }
      }
    }
  }

  if (balance == null) {
    return GroupUserBalance(amount: null, status: UserBalanceStatus.unknown, currency: currency);
  }

  final status = balance > 0.01
      ? UserBalanceStatus.positive
      : balance < -0.01
          ? UserBalanceStatus.negative
          : UserBalanceStatus.settled;

  return GroupUserBalance(amount: balance, status: status, currency: currency);
});
