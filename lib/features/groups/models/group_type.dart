import 'package:flutter/material.dart';

class GroupTypeData {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const GroupTypeData({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const groupTypes = <GroupTypeData>[
  GroupTypeData(key: 'trip', label: 'Trip', icon: Icons.flight, color: Color(0xFF007AFF)),
  GroupTypeData(key: 'household', label: 'Household', icon: Icons.home, color: Color(0xFF34C759)),
  GroupTypeData(key: 'couple', label: 'Couple', icon: Icons.favorite, color: Color(0xFFFF2D55)),
  GroupTypeData(key: 'event', label: 'Event', icon: Icons.celebration, color: Color(0xFFFF9500)),
  GroupTypeData(key: 'other', label: 'Other', icon: Icons.group, color: Color(0xFF8E8E93)),
];

final groupTypeMap = {for (var t in groupTypes) t.key: t};

GroupTypeData getGroupTypeData(String key) {
  return groupTypeMap[key] ?? groupTypes.last;
}
