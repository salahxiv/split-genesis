import 'dart:convert';

enum ActivityType {
  expenseCreated,
  expenseUpdated,
  expenseDeleted,
  settlementRecorded,
  settlementDeleted,
  memberAdded,
  memberRemoved,
  groupCreated,
  groupRenamed,
  memberJoined,
}

class ActivityEntry {
  final String id;
  final String groupId;
  final ActivityType type;
  final String description;
  final String? memberName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String syncStatus;

  ActivityEntry({
    required this.id,
    required this.groupId,
    required this.type,
    required this.description,
    this.memberName,
    required this.timestamp,
    this.metadata,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'type': type.name,
      'description': description,
      'member_name': memberName,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toApiMap() {
    final map = toMap();
    map.remove('sync_status');
    // API expects JSONB directly, not encoded string
    if (metadata != null) {
      map['metadata'] = metadata;
    }
    return map;
  }

  factory ActivityEntry.fromMap(Map<String, dynamic> map) {
    return ActivityEntry(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      type: ActivityType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ActivityType.expenseCreated,
      ),
      description: map['description'] as String,
      memberName: map['member_name'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
