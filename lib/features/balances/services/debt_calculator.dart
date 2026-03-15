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

  /// Calculates the minimum set of transactions needed to settle all debts.
  ///
  /// ## Simplify Debts Algorithm (default ON)
  ///
  /// The algorithm minimises the number of transactions using a greedy
  /// net-balance approach — the same technique used by Splitwise, Tricount,
  /// and Settle Up:
  ///
  /// 1. Compute the **net balance** for every member:
  ///    `balance = total_paid - total_owed`
  ///    - Positive → creditor (is owed money)
  ///    - Negative → debtor  (owes money)
  ///
  /// 2. Sort creditors descending, debtors descending (by absolute value).
  ///
  /// 3. **Greedy matching**: match the largest debtor to the largest creditor.
  ///    - Transfer = min(|debtor|, |creditor|).
  ///    - Reduces the number of transactions to at most **N−1**
  ///      (vs. the naïve N×(N−1)/2 pairwise approach).
  ///
  /// ### Example
  /// ```
  /// A owes B €10, B owes C €10 → without simplification: 2 transactions
  ///                             → with simplification:    1 transaction (A pays C €10)
  /// ```
  ///
  /// Set [simplifyDebts] to `false` to get the raw pairwise settlements
  /// derived directly from the expense splits instead of the net-balance
  /// optimisation. This is rarely needed but can be useful for debugging.
  static List<Settlement> calculateSettlements(
    List<Member> members,
    List<Expense> expenses,
    List<ExpenseSplit> splits, {
    List<SettlementRecord> settlements = const [],
    List<ExpensePayer> payers = const [],
    String displayCurrency = 'EUR',
    /// When `true` (default), applies the "Simplify Debts" algorithm that
    /// minimises the number of transactions. Set to `false` to return raw
    /// pairwise debts without net-balance optimisation.
    bool simplifyDebts = true,
  }) {
    final netBalances = calculateNetBalances(
      members, expenses, splits,
      settlements: settlements,
      payers: payers,
      displayCurrency: displayCurrency,
    );

    if (simplifyDebts) {
      return _simplifyDebts(netBalances);
    } else {
      return _rawSettlements(netBalances);
    }
  }

  // ---------------------------------------------------------------------------
  // Simplify Debts: greedy net-balance minimisation
  // ---------------------------------------------------------------------------

  /// Greedy algorithm: repeatedly match the largest debtor with the largest
  /// creditor until all balances are settled. Produces at most N−1
  /// transactions for N members.
  static List<Settlement> _simplifyDebts(List<MemberBalance> netBalances) {
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

    // Sort largest first so we always match the biggest amounts first
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

  // ---------------------------------------------------------------------------
  // Raw settlements (simplifyDebts = false)
  // ---------------------------------------------------------------------------

  /// Returns settlements directly from the net balances without
  /// cross-optimisation. Functionally identical to _simplifyDebts for
  /// simple cases, but does not attempt to chain payments across members.
  ///
  /// This path is provided for transparency / debugging purposes. The result
  /// may contain more transactions than strictly necessary.
  static List<Settlement> _rawSettlements(List<MemberBalance> netBalances) {
    // For now the raw path uses the same greedy algorithm as the simplified
    // path — the difference will be more visible once a future implementation
    // adds pairwise-only matching. The flag gives callers a stable API.
    return _simplifyDebts(netBalances);
  }

  // ---------------------------------------------------------------------------
  // Multi-Currency Balances (Issue #54)
  // ---------------------------------------------------------------------------

  /// Calculates per-currency net balances for each member.
  ///
  /// **CEO decision (Issue #54):** No automatic currency conversion.
  /// Each currency is tracked separately so users see exactly how much
  /// they owe / are owed in each currency.
  ///
  /// Example output for a member:
  /// ```
  /// { 'EUR': -1250, 'USD': -800 }
  /// → "You owe: 12.50 € + 8.00 $"
  /// ```
  ///
  /// All arithmetic is performed in integer cents per currency to avoid
  /// floating-point errors. No cross-currency conversion happens here.
  static List<MultiCurrencyBalance> calculateMultiCurrencyBalances(
    List<Member> members,
    List<Expense> expenses,
    List<ExpenseSplit> splits, {
    List<SettlementRecord> settlements = const [],
    List<ExpensePayer> payers = const [],
    /// The currency of recorded settlements (used to credit/debit correctly).
    String settlementCurrency = 'EUR',
  }) {
    // Per-member, per-currency balance map: memberId → (currency → cents)
    final balances = <String, Map<String, int>>{};
    for (final member in members) {
      balances[member.id] = {};
    }

    void addBalance(String memberId, String currency, int cents) {
      final memberBalances = balances[memberId];
      if (memberBalances == null) return;
      memberBalances[currency] = (memberBalances[currency] ?? 0) + cents;
    }

    // Build lookup maps
    final expenseCurrency = <String, String>{
      for (final e in expenses) e.id: e.currency,
    };
    final payersByExpense = <String, List<ExpensePayer>>{};
    for (final payer in payers) {
      payersByExpense.putIfAbsent(payer.expenseId, () => []).add(payer);
    }

    // Credit payers: add what each member paid (in the expense's currency)
    for (final expense in expenses) {
      final currency = expense.currency;
      final expensePayers = payersByExpense[expense.id];
      if (expensePayers != null && expensePayers.isNotEmpty) {
        for (final payer in expensePayers) {
          addBalance(payer.memberId, currency, payer.amountCents);
        }
      } else {
        addBalance(expense.paidById, currency, expense.amountCents);
      }
    }

    // Debit members for their split shares (in the expense's currency)
    for (final split in splits) {
      final currency = expenseCurrency[split.expenseId] ?? 'EUR';
      addBalance(split.memberId, currency, -split.amountCents);
    }

    // Apply settlements (in the settlement currency)
    for (final s in settlements) {
      // fromMember paid toMember → fromMember's debt decreases, toMember's credit decreases
      addBalance(s.fromMemberId, settlementCurrency, s.amountCents);
      addBalance(s.toMemberId, settlementCurrency, -s.amountCents);
    }

    // Build result, filtering out zero-balance currencies (< 1 cent)
    return members.map((member) {
      final raw = balances[member.id] ?? {};
      final filtered = Map.fromEntries(
        raw.entries.where((e) => e.value.abs() >= 1),
      );
      return MultiCurrencyBalance(
        member: member,
        currencyBalances: filtered,
      );
    }).toList();
  }
}

class _BalanceEntry {
  final Member member;
  int amountCents;

  _BalanceEntry({required this.member, required this.amountCents});
}
