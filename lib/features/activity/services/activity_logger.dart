import 'package:uuid/uuid.dart';
import '../models/activity_entry.dart';
import '../repositories/activity_repository.dart';

class ActivityLogger {
  static final ActivityLogger instance = ActivityLogger._();
  final _repo = ActivityRepository();

  ActivityLogger._();

  Future<void> logExpenseCreated({
    required String groupId,
    required String description,
    required double amount,
    required String paidByName,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.expenseCreated,
      description: '$paidByName added "$description" for \$${amount.toStringAsFixed(2)}',
      memberName: paidByName,
      metadata: {'amount': amount, 'expense_description': description},
    );
  }

  Future<void> logExpenseUpdated({
    required String groupId,
    required String description,
    required double amount,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.expenseUpdated,
      description: 'Updated "$description" (\$${amount.toStringAsFixed(2)})',
      metadata: {'amount': amount, 'expense_description': description},
    );
  }

  Future<void> logExpenseDeleted({
    required String groupId,
    required String description,
    required double amount,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.expenseDeleted,
      description: 'Deleted "$description" (\$${amount.toStringAsFixed(2)})',
      metadata: {'amount': amount, 'expense_description': description},
    );
  }

  Future<void> logSettlementRecorded({
    required String groupId,
    required String fromName,
    required String toName,
    required double amount,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.settlementRecorded,
      description: '$fromName paid $toName \$${amount.toStringAsFixed(2)}',
      memberName: fromName,
      metadata: {'amount': amount, 'from': fromName, 'to': toName},
    );
  }

  Future<void> logSettlementDeleted({
    required String groupId,
    required String fromName,
    required String toName,
    required double amount,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.settlementDeleted,
      description: 'Deleted payment: $fromName to $toName (\$${amount.toStringAsFixed(2)})',
      metadata: {'amount': amount, 'from': fromName, 'to': toName},
    );
  }

  Future<void> logMemberAdded({
    required String groupId,
    required String memberName,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.memberAdded,
      description: '$memberName joined the group',
      memberName: memberName,
    );
  }

  Future<void> logMemberRemoved({
    required String groupId,
    required String memberName,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.memberRemoved,
      description: '$memberName was removed from the group',
      memberName: memberName,
    );
  }

  Future<void> logGroupCreated({
    required String groupId,
    required String groupName,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.groupCreated,
      description: 'Group "$groupName" was created',
    );
  }

  Future<void> logGroupRenamed({
    required String groupId,
    required String oldName,
    required String newName,
  }) async {
    await _log(
      groupId: groupId,
      type: ActivityType.groupRenamed,
      description: 'Group renamed from "$oldName" to "$newName"',
      metadata: {'old_name': oldName, 'new_name': newName},
    );
  }

  Future<void> _log({
    required String groupId,
    required ActivityType type,
    required String description,
    String? memberName,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = ActivityEntry(
      id: const Uuid().v4(),
      groupId: groupId,
      type: type,
      description: description,
      memberName: memberName,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    await _repo.insertActivity(entry);
  }
}
