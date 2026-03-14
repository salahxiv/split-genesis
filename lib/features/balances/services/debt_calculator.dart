import '../../../core/utils/currency_utils.dart';
import '../../expenses/models/expense.dart';
import '../../members/models/member.dart';
import '../../settlements/models/settlement_record.dart';
import '../models/balance.dart';

class DebtCalculator {
  /// Minimum meaningful amount: 1 cent.
  static const _epsilonCents = 1;

  /// All arithmetic is performed in EUR cents to avoid multi-currency addition
  /// errors. Display conversion back to the group currency happens in the UI.
  static List<MemberBalance> calculateNetBalances(
    List<Member> members,
    List<Expense> expenses,
    List<ExpenseSplit> splits, {
    List<SettlementRecord> settlements = const [],
    List<ExpensePayer> payers = const [],
    /// The currency in which to express the resulting balances (group currency).
    String displayCurrency = 'EUR',
  }) {
    // All arithmetic in integer EUR-cents — no floating-point accumulation errors.
    final balances = <String, int>{};
    for (final member in members) {
      balances[member.id] = 0;
    }

    // Build a lookup of expense_id -> currency for multi-currency conversion
    final expenseCurrency = <String, String>{
      for (final e in expenses) e.id: e.currency,
    };

    // Build a map of expense_id -> list of payers for multi-payer lookup
    final payersByExpense = <String, List<ExpensePayer>>{};
    for (final payer in payers) {
      payersByExpense.putIfAbsent(payer.expenseId, () => []).add(payer);
    }

    // Add what each member paid — convert to EUR cents first
    for (final expense in expenses) {
      final currency = expense.currency;
      final expensePayers = payersByExpense[expense.id];
      if (expensePayers != null && expensePayers.isNotEmpty) {
        for (final payer in expensePayers) {
          final eurCents = CurrencyConverter.toEurCents(payer.amountCents, currency);
          balances[payer.memberId] = (balances[payer.memberId] ?? 0) + eurCents;
        }
      } else {
        // Backward compat: single payer from expense.paidById
        final eurCents = CurrencyConverter.toEurCents(expense.amountCents, currency);
        balances[expense.paidById] = (balances[expense.paidById] ?? 0) + eurCents;
      }
    }

    // Subtract what each member owes — splits inherit their expense's currency
    for (final split in splits) {
      final currency = expenseCurrency[split.expenseId] ?? 'EUR';
      final eurCents = CurrencyConverter.toEurCents(split.amountCents, currency);
      balances[split.memberId] = (balances[split.memberId] ?? 0) - eurCents;
    }

    // Apply settlements: fromMember paid toMember.
    // Settlements are stored in the group's display currency.
    for (final s in settlements) {
      final eurCents = CurrencyConverter.toEurCents(s.amountCents, displayCurrency);
      balances[s.fromMemberId] = (balances[s.fromMemberId] ?? 0) + eurCents;
      balances[s.toMemberId]   = (balances[s.toMemberId]   ?? 0) - eurCents;
    }

    // Convert results back to the group's display currency
    return members.map((member) {
      final eurCents = balances[member.id] ?? 0;
      final displayCents = CurrencyConverter.fromEurCents(eurCents, displayCurrency);
      return MemberBalance(
        member: member,
        netBalanceCents: displayCents,
      );
    }).toList();
  }

  static List<Settlement> calculateSettlements(
    List<Member> members,
    List<Expense> expenses,
    List<ExpenseSplit> splits, {
    List<SettlementRecord> settlements = const [],
    List<ExpensePayer> payers = const [],
    String displayCurrency = 'EUR',
  }) {
    final netBalances = calculateNetBalances(
      members, expenses, splits,
      settlements: settlements,
      payers: payers,
      displayCurrency: displayCurrency,
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
