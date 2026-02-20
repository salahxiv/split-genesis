import '../../members/models/member.dart';

class Settlement {
  final Member fromMember;
  final Member toMember;
  final double amount;

  Settlement({
    required this.fromMember,
    required this.toMember,
    required this.amount,
  });
}

class MemberBalance {
  final Member member;
  final double netBalance;

  MemberBalance({
    required this.member,
    required this.netBalance,
  });
}
