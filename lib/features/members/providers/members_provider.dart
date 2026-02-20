import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../activity/services/activity_logger.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';

final memberRepositoryProvider = Provider((ref) => MemberRepository());

final membersProvider =
    AsyncNotifierProvider.family<MembersNotifier, List<Member>, String>(
        MembersNotifier.new);

class MembersNotifier extends FamilyAsyncNotifier<List<Member>, String> {
  @override
  Future<List<Member>> build(String arg) async {
    final sw = Stopwatch()..start();
    final result = await ref.read(memberRepositoryProvider).getMembersByGroup(arg);
    debugPrint('[PERF] membersProvider($arg).build(): ${sw.elapsedMilliseconds}ms (${result.length} members)');
    return result;
  }

  Future<void> addMember(String name) async {
    final member = Member(
      id: const Uuid().v4(),
      name: name,
      groupId: arg,
    );
    await ref.read(memberRepositoryProvider).insertMember(member);
    await ActivityLogger.instance.logMemberAdded(
      groupId: arg,
      memberName: name,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteMember(String id) async {
    final members = state.valueOrNull ?? [];
    final member = members.where((m) => m.id == id).firstOrNull;
    await ref.read(memberRepositoryProvider).deleteMember(id);
    if (member != null) {
      await ActivityLogger.instance.logMemberRemoved(
        groupId: arg,
        memberName: member.name,
      );
    }
    ref.invalidateSelf();
  }
}
