import '../../expenses/models/expense.dart';
import '../../members/models/member.dart';
import '../../settlements/models/settlement_record.dart';
import '../models/balance.dart';

class DebtCalculator {
  /// Minimum meaningful amount: 1 cent.
  static const _epsilonCents = 1;

  static List<MemberBalance> calculateNetBalances(
    List<Member> members,
    List<Expense> expenses,
    List<ExpenseSplit> splits, {
    List<SettlementRecord> settlements = const [],
    List<ExpensePayer> payers = const [],
  }) {
    // All arithmetic in integer cents — no floating-point accumulation errors.
    final balances = <String, int>{};
    for (final member in members) {
      balances[member.id] = 0;
    }

    // Build a map of expense_id -> list of payers for multi-payer lookup
    final payersByExpense = <String, List<ExpensePayer>>{};
    for (final payer in payers) {
      payersByExpense.putIfAbsent(payer.expenseId, () => []).add(payer);
    }

    // Add what each member paid (in cents)
    for (final expense in expenses) {
      final expensePayers = payersByExpense[expense.id];
      if (expensePayers != null && expensePayers.isNotEmpty) {
        for (final payer in expensePayers) {
          balances[payer.memberId] =
              (balances[payer.memberId] ?? 0) + payer.amountCents;
        }
      } else {
        // Backward compat: single payer from expense.paidById
        balances[expense.paidById] =
            (balances[expense.paidById] ?? 0) + expense.amountCents;
      }
    }

    // Subtract what each member owes (in cents)
    for (final split in splits) {
      balances[split.memberId] =
          (balances[split.memberId] ?? 0) - split.amountCents;
    }

    // Apply settlements: fromMember paid toMember (in cents)
    for (final s in settlements) {
      balances[s.fromMemberId] =
          (balances[s.fromMemberId] ?? 0) + s.amountCents;
      balances[s.toMemberId] =
          (balances[s.toMemberId] ?? 0) - s.amountCents;
    }

    return members.map((member) {
      return MemberBalance(
        member: member,
        netBalanceCents: balances[member.id] ?? 0,
      );
    }).toList();
  }

  static List<Settlement> calculateSettlements(
    List<Member> members,
    List<Expense> expenses,
    List<ExpenseSplit> splits, {
    List<SettlementRecord> settlements = const [],
    List<ExpensePayer> payers = const [],
  }) {
    final netBalances = calculateNetBalances(
      members, expenses, splits,
      settlements: settlements, payers: payers,
    );
    final result = <Settlement>[];

    final creditors = <_BalanceEntry>[];
    final debtors = <_BalanceEntry>[];

    for (final mb in netBalances) {
      if (mb.netBalanceCents > _epsilonCents) {
        creditors.add(_BalanceEntry(member: mb.member, amountCents: mb.netBalanceCents));
      } else if (mb.netBalanceCents < -_epsilonCents) {
        debtors.add(_BalanceEntry(member: mb.member, amountCents: -mb.netBalanceCents));
      }
    }

    creditors.sort((a, b) => b.amountCents.compareTo(a.amountCents));
    debtors.sort((a, b) => b.amountCents.compareTo(a.amountCents));

    int ci = 0, di = 0;
    while (ci < creditors.length && di < debtors.length) {
      final transfer = creditors[ci].amountCents < debtors[di].amountCents
          ? creditors[ci].amountCents
          : debtors[di].amountCents;

      if (transfer >= _epsilonCents) {
        result.add(Settlement(
          fromMember: debtors[di].member,
          toMember: creditors[ci].member,
          amountCents: transfer,
        ));
      }

      creditors[ci].amountCents -= transfer;
      debtors[di].amountCents -= transfer;

      if (creditors[ci].amountCents < _epsilonCents) ci++;
      if (debtors[di].amountCents < _epsilonCents) di++;
    }

    return result;
  }
}

class _BalanceEntry {
  final Member member;
  int amountCents;

  _BalanceEntry({required this.member, required this.amountCents});
}
