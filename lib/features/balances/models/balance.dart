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
