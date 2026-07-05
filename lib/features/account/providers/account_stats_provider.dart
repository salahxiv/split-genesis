import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../settlements/providers/settlements_provider.dart';

/// Lifetime sum (in euros) of expenses where the current user paid.
///
/// Reads members + expenses for every group the user is part of in parallel
/// (via Future.wait), then sums the cent amounts on the main isolate. With
/// keepAlive(2 min) the result is cached so the Account screen doesn't
/// re-aggregate on every visit.
final lifetimeSpentProvider = FutureProvider.autoDispose<double>((ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 2), link.close);

  final userId = AuthService.instance.userId;
  if (userId == null) return 0.0;

  final groups = await ref.watch(groupsProvider.future);

  final perGroupCents = await Future.wait(groups.map((group) async {
    final members = await ref.watch(membersProvider(group.id).future);
    final me = members.where((m) => m.userId == userId).firstOrNull;
    if (me == null) return 0;

    final expenses = await ref.watch(expensesProvider(group.id).future);
    var sum = 0;
    for (final e in expenses) {
      if (e.paidById == me.id) sum += e.amountCents;
    }
    return sum;
  }));

  return perGroupCents.fold<int>(0, (a, b) => a + b) / 100.0;
});

/// Lifetime sum of settlements where the current user has paid someone back.
final lifetimeSettledProvider = FutureProvider.autoDispose<double>((ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 2), link.close);

  final userId = AuthService.instance.userId;
  if (userId == null) return 0.0;

  final groups = await ref.watch(groupsProvider.future);

  final perGroupCents = await Future.wait(groups.map((group) async {
    final members = await ref.watch(membersProvider(group.id).future);
    final me = members.where((m) => m.userId == userId).firstOrNull;
    if (me == null) return 0;

    final settlements = await ref.watch(settlementRecordsProvider(group.id).future);
    var sum = 0;
    for (final s in settlements) {
      if (s.fromMemberId == me.id) sum += s.amountCents;
    }
    return sum;
  }));

  return perGroupCents.fold<int>(0, (a, b) => a + b) / 100.0;
});
