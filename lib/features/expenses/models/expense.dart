class Expense {
  final String id;
  final String description;
  final int amountCents;
  final String paidById;
  final String groupId;
  final DateTime createdAt;
  final DateTime expenseDate;
  final String category;
  final String splitType;
  final String currency;
  final DateTime? updatedAt;
  final String syncStatus;

  /// Convenience getter for display – do NOT use in arithmetic.
  double get amount => amountCents / 100;

  Expense({
    required this.id,
    required this.description,
    required this.amountCents,
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
      'amount_cents': amountCents,
      // Keep legacy `amount` column populated so old DB versions can still read.
      'amount': amountCents / 100.0,
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
    map.remove('amount_cents'); // API still uses `amount` (float)
    return map;
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['created_at'] as String);
    final int cents;
    if (map['amount_cents'] != null) {
      cents = (map['amount_cents'] as num).toInt();
    } else {
      cents = ((map['amount'] as num).toDouble() * 100).round();
    }
    return Expense(
      id: map['id'] as String,
      description: map['description'] as String,
      amountCents: cents,
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
  final int amountCents;

  /// Convenience getter for display – do NOT use in arithmetic.
  double get amount => amountCents / 100;

  ExpensePayer({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.amountCents,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'member_id': memberId,
      'amount_cents': amountCents,
      'amount': amountCents / 100.0,
    };
  }

  factory ExpensePayer.fromMap(Map<String, dynamic> map) {
    final int cents;
    if (map['amount_cents'] != null) {
      cents = (map['amount_cents'] as num).toInt();
    } else {
      cents = ((map['amount'] as num).toDouble() * 100).round();
    }
    return ExpensePayer(
      id: map['id'] as String,
      expenseId: map['expense_id'] as String,
      memberId: map['member_id'] as String,
      amountCents: cents,
    );
  }
}

class ExpenseSplit {
  final String id;
  final String expenseId;
  final String memberId;
  final int amountCents;

  /// Convenience getter for display – do NOT use in arithmetic.
  double get amount => amountCents / 100;

  ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.amountCents,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'member_id': memberId,
      'amount_cents': amountCents,
      'amount': amountCents / 100.0,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    final int cents;
    if (map['amount_cents'] != null) {
      cents = (map['amount_cents'] as num).toInt();
    } else {
      cents = ((map['amount'] as num).toDouble() * 100).round();
    }
    return ExpenseSplit(
      id: map['id'] as String,
      expenseId: map['expense_id'] as String,
      memberId: map['member_id'] as String,
      amountCents: cents,
    );
  }
}
