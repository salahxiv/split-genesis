import '../../members/models/member.dart';

/// A suggested settlement between two members.
/// [amountCents] is the amount in integer cents; use [amount] only for display.
class Settlement {
  final Member fromMember;
  final Member toMember;
  final int amountCents;

  /// Convenience getter for display.
  double get amount => amountCents / 100;

  Settlement({
    required this.fromMember,
    required this.toMember,
    required this.amountCents,
  });
}

/// A member's net balance in integer cents.
/// Positive = is owed money; negative = owes money.
class MemberBalance {
  final Member member;
  final int netBalanceCents;

  /// Convenience getter for display.
  double get netBalance => netBalanceCents / 100;

  MemberBalance({
    required this.member,
    required this.netBalanceCents,
  });
}

/// Multi-currency balance for a single member.
///
/// **CEO decision (Issue #54):** No automatic currency conversion.
/// Each currency is shown separately so users can see exactly how much
/// they owe / are owed in every currency.
///
/// Example: "You owe 12.50 € + 8.00 $"
///
/// [currencyBalances] maps ISO 4217 currency code → net amount in cents.
/// Positive = is owed that amount; negative = owes that amount.
class MultiCurrencyBalance {
  final Member member;

  /// Map of currencyCode → net cents.
  /// Positive = creditor, negative = debtor for that currency.
  final Map<String, int> currencyBalances;

  MultiCurrencyBalance({
    required this.member,
    required this.currencyBalances,
  });

  /// Returns only the currencies where this member owes money (negative cents).
  Map<String, int> get owedCurrencies => Map.fromEntries(
    currencyBalances.entries.where((e) => e.value < -0),
  );

  /// Returns only the currencies where this member is owed money (positive cents).
  Map<String, int> get owingCurrencies => Map.fromEntries(
    currencyBalances.entries.where((e) => e.value > 0),
  );

  /// True when all currency balances are effectively zero (±1 cent).
  bool get isSettledUp => currencyBalances.values.every((v) => v.abs() <= 1);

  /// Convenience: get cents for a specific currency (0 if not present).
  int centsFor(String currency) => currencyBalances[currency] ?? 0;

  /// Convenience: get amount (double) for a specific currency.
  double amountFor(String currency) => centsFor(currency) / 100;
}

