class SettlementRecord {
  final String id;
  final String groupId;
  final String fromMemberId;
  final String toMemberId;
  final int amountCents;
  final DateTime createdAt;
  final String? fromMemberName;
  final String? toMemberName;
  final DateTime? updatedAt;
  final String syncStatus;

  /// Convenience getter for display.
  double get amount => amountCents / 100;

  SettlementRecord({
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountCents,
    required this.createdAt,
    this.fromMemberName,
    this.toMemberName,
    this.updatedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'from_member_id': fromMemberId,
      'to_member_id': toMemberId,
      'amount': amountCents / 100.0,
      'from_member_name': fromMemberName,
      'to_member_name': toMemberName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toApiMap() {
    final map = toMap();
    map.remove('sync_status');
    return map;
  }

  factory SettlementRecord.fromMap(Map<String, dynamic> map) {
    final int cents;
    if (map['amount_cents'] != null) {
      cents = (map['amount_cents'] as num).toInt();
    } else {
      cents = ((map['amount'] as num).toDouble() * 100).round();
    }
    return SettlementRecord(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      fromMemberId: map['from_member_id'] as String,
      toMemberId: map['to_member_id'] as String,
      amountCents: cents,
      createdAt: DateTime.parse(map['created_at'] as String),
      fromMemberName: map['from_member_name'] as String?,
      toMemberName: map['to_member_name'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
