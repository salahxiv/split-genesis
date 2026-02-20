class Expense {
  final String id;
  final String description;
  final double amount;
  final String paidById;
  final String groupId;
  final DateTime createdAt;
  final DateTime expenseDate;
  final String category;
  final String splitType;
  final String currency;
  final DateTime? updatedAt;
  final String syncStatus;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.groupId,
    required this.createdAt,
    DateTime? expenseDate,
    this.category = 'general',
    this.splitType = 'equal',
    this.currency = 'USD',
    this.updatedAt,
    this.syncStatus = 'pending',
  }) : expenseDate = expenseDate ?? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'paid_by_id': paidById,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
      'expense_date': expenseDate.toIso8601String(),
      'category': category,
      'split_type': splitType,
      'currency': currency,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toApiMap() {
    final map = toMap();
    map.remove('sync_status');
    return map;
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['created_at'] as String);
    return Expense(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidById: map['paid_by_id'] as String,
      groupId: map['group_id'] as String,
      createdAt: createdAt,
      expenseDate: map['expense_date'] != null
          ? DateTime.parse(map['expense_date'] as String)
          : createdAt,
      category: map['category'] as String? ?? 'general',
      splitType: map['split_type'] as String? ?? 'equal',
      currency: map['currency'] as String? ?? 'USD',
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}

class ExpensePayer {
  final String id;
  final String expenseId;
  final String memberId;
  final double amount;

  ExpensePayer({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'member_id': memberId,
      'amount': amount,
    };
  }

  factory ExpensePayer.fromMap(Map<String, dynamic> map) {
    return ExpensePayer(
      id: map['id'] as String,
      expenseId: map['expense_id'] as String,
      memberId: map['member_id'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

class ExpenseSplit {
  final String id;
  final String expenseId;
  final String memberId;
  final double amount;

  ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'member_id': memberId,
      'amount': amount,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      id: map['id'] as String,
      expenseId: map['expense_id'] as String,
      memberId: map['member_id'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}
