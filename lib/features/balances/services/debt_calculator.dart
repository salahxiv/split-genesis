import '../../expenses/models/expense.dart';
import '../../members/models/member.dart';
import '../../settlements/models/settlement_record.dart';
import '../models/balance.dart';

class DebtCalculator {
  static const _epsilon = 0.01;

  static List<MemberBalance> calculateNetBalances(
    List<Member> members,
    List<Expense> expenses,
    List<ExpenseSplit> splits, {
    List<SettlementRecord> settlements = const [],
    List<ExpensePayer> payers = const [],
  }) {
    final balances = <String, double>{};
    for (final member in members) {
      balances[member.id] = 0.0;
    }

    // Build a map of expense_id -> list of payers for multi-payer lookup
    final payersByExpense = <String, List<ExpensePayer>>{};
    for (final payer in payers) {
      payersByExpense.putIfAbsent(payer.expenseId, () => []).add(payer);
    }

    // Add what each member paid
    for (final expense in expenses) {
      final expensePayers = payersByExpense[expense.id];
      if (expensePayers != null && expensePayers.isNotEmpty) {
        // Multi-payer: use the payer records
        for (final payer in expensePayers) {
          balances[payer.memberId] =
              (balances[payer.memberId] ?? 0) + payer.amount;
        }
      } else {
        // Backward compatibility: single payer from expense.paidById
        balances[expense.paidById] =
            (balances[expense.paidById] ?? 0) + expense.amount;
      }
    }

    // Subtract what each member owes
    for (final split in splits) {
      balances[split.memberId] =
          (balances[split.memberId] ?? 0) - split.amount;
    }

    // Apply settlements: fromMember paid toMember
    for (final s in settlements) {
      balances[s.fromMemberId] =
          (balances[s.fromMemberId] ?? 0) + s.amount;
      balances[s.toMemberId] =
          (balances[s.toMemberId] ?? 0) - s.amount;
    }

    return members.map((member) {
      return MemberBalance(
        member: member,
        netBalance: balances[member.id] ?? 0.0,
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
      members, expenses, splits, settlements: settlements, payers: payers,
    );
    final result = <Settlement>[];

    final creditors = <_BalanceEntry>[];
    final debtors = <_BalanceEntry>[];

    for (final mb in netBalances) {
      if (mb.netBalance > _epsilon) {
        creditors.add(_BalanceEntry(member: mb.member, amount: mb.netBalance));
      } else if (mb.netBalance < -_epsilon) {
        debtors.add(_BalanceEntry(member: mb.member, amount: -mb.netBalance));
      }
    }

    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    int ci = 0, di = 0;
    while (ci < creditors.length && di < debtors.length) {
      final transfer = creditors[ci].amount < debtors[di].amount
          ? creditors[ci].amount
          : debtors[di].amount;

      if (transfer > _epsilon) {
        result.add(Settlement(
          fromMember: debtors[di].member,
          toMember: creditors[ci].member,
          amount: (transfer * 100).roundToDouble() / 100,
        ));
      }

      creditors[ci].amount -= transfer;
      debtors[di].amount -= transfer;

      if (creditors[ci].amount < _epsilon) ci++;
      if (debtors[di].amount < _epsilon) di++;
    }

    return result;
  }
}

class _BalanceEntry {
  final Member member;
  double amount;

  _BalanceEntry({required this.member, required this.amount});
}
