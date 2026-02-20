import 'package:uuid/uuid.dart';

class Group {
  final String id;
  final String name;
  final DateTime createdAt;
  final String shareCode;
  final String? createdByUserId;
  final String currency;
  final String type;
  final DateTime? updatedAt;
  final String syncStatus;

  Group({
    required this.id,
    required this.name,
    required this.createdAt,
    String? shareCode,
    this.createdByUserId,
    this.currency = 'USD',
    this.type = 'other',
    this.updatedAt,
    this.syncStatus = 'pending',
  }) : shareCode = shareCode ?? const Uuid().v4().substring(0, 8).toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'share_code': shareCode,
      'created_by_user_id': createdByUserId,
      'currency': currency,
      'type': type,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      shareCode: map['share_code'] as String?,
      createdByUserId: map['created_by_user_id'] as String?,
      currency: map['currency'] as String? ?? 'USD',
      type: map['type'] as String? ?? 'other',
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toApiMap() {
    final map = toMap();
    map.remove('sync_status');
    return map;
  }

  Group copyWith({
    String? name,
    String? createdByUserId,
    String? currency,
    String? type,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      shareCode: shareCode,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
