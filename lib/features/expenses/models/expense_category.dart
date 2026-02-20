import 'package:flutter/material.dart';

class ExpenseCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const expenseCategories = <ExpenseCategory>[
  ExpenseCategory(key: 'general', label: 'General', icon: Icons.receipt, color: Color(0xFF8E8E93)),
  ExpenseCategory(key: 'food', label: 'Food', icon: Icons.restaurant, color: Color(0xFFFF9500)),
  ExpenseCategory(key: 'groceries', label: 'Groceries', icon: Icons.shopping_cart, color: Color(0xFF34C759)),
  ExpenseCategory(key: 'transport', label: 'Transport', icon: Icons.directions_car, color: Color(0xFF007AFF)),
  ExpenseCategory(key: 'accommodation', label: 'Lodging', icon: Icons.hotel, color: Color(0xFF5856D6)),
  ExpenseCategory(key: 'shopping', label: 'Shopping', icon: Icons.shopping_bag, color: Color(0xFFFF2D55)),
  ExpenseCategory(key: 'entertainment', label: 'Fun', icon: Icons.movie, color: Color(0xFFAF52DE)),
  ExpenseCategory(key: 'utilities', label: 'Utilities', icon: Icons.bolt, color: Color(0xFFFFCC00)),
  ExpenseCategory(key: 'drinks', label: 'Drinks', icon: Icons.local_bar, color: Color(0xFFFF6482)),
  ExpenseCategory(key: 'health', label: 'Health', icon: Icons.medical_services, color: Color(0xFFFF3B30)),
  ExpenseCategory(key: 'gifts', label: 'Gifts', icon: Icons.card_giftcard, color: Color(0xFFFF69B4)),
  ExpenseCategory(key: 'subscriptions', label: 'Subs', icon: Icons.subscriptions, color: Color(0xFF5AC8FA)),
  ExpenseCategory(key: 'sports', label: 'Sports', icon: Icons.sports_soccer, color: Color(0xFF30D158)),
  ExpenseCategory(key: 'travel', label: 'Travel', icon: Icons.flight, color: Color(0xFF64D2FF)),
];

final categoryMap = {for (var c in expenseCategories) c.key: c};

ExpenseCategory getCategoryData(String key) {
  return categoryMap[key] ?? expenseCategories.first;
}
