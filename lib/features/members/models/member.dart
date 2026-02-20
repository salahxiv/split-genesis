class Member {
  final String id;
  final String name;
  final String groupId;
  final DateTime? updatedAt;
  final String syncStatus;

  Member({
    required this.id,
    required this.name,
    required this.groupId,
    this.updatedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'group_id': groupId,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toApiMap() {
    final map = toMap();
    map.remove('sync_status');
    return map;
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as String,
      name: map['name'] as String,
      groupId: map['group_id'] as String,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
