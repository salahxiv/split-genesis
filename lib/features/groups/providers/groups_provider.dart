import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/auth_service.dart';
import '../../activity/services/activity_logger.dart';
import '../../members/models/member.dart';
import '../../members/providers/members_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/group.dart';
import '../repositories/group_repository.dart';

final groupRepositoryProvider = Provider((ref) => GroupRepository());

final groupsProvider =
    AsyncNotifierProvider<GroupsNotifier, List<Group>>(GroupsNotifier.new);

class GroupsNotifier extends AsyncNotifier<List<Group>> {
  @override
  Future<List<Group>> build() async {
    final sw = Stopwatch()..start();
    final result = await ref.read(groupRepositoryProvider).getAllGroups();
    debugPrint('[PERF] groupsProvider.build(): ${sw.elapsedMilliseconds}ms (${result.length} groups)');
    return result;
  }

  Future<Group> addGroup(String name, {String currency = 'USD', String type = 'other'}) async {
    final currentUserId = AuthService.instance.userId;
    final group = Group(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      createdByUserId: currentUserId,
      currency: currency,
      type: type,
    );
    await ref.read(groupRepositoryProvider).insertGroup(group);

    // Auto-link: Creator wird automatisch als Member mit userId angelegt
    final displayName = ref.read(displayNameProvider);
    if (displayName.trim().isNotEmpty) {
      final creatorMember = Member(
        id: const Uuid().v4(),
        name: displayName.trim(),
        groupId: group.id,
        userId: currentUserId,
      );
      await ref.read(memberRepositoryProvider).insertMember(creatorMember);
    }

    await ActivityLogger.instance.logGroupCreated(
      groupId: group.id,
      groupName: name,
    );
    ref.invalidateSelf();
    return group;
  }

  Future<void> renameGroup(String id, String newName) async {
    final repo = ref.read(groupRepositoryProvider);
    final group = await repo.getGroup(id);
    final oldName = group.name;
    await repo.updateGroupName(id, newName);
    await ActivityLogger.instance.logGroupRenamed(
      groupId: id,
      oldName: oldName,
      newName: newName,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteGroup(String id) async {
    await ref.read(groupRepositoryProvider).deleteGroup(id);
    ref.invalidateSelf();
  }
}
