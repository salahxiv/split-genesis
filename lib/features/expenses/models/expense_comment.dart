class ExpenseComment {
  final String id;
  final String expenseId;
  final String memberName;
  final String content;
  final DateTime createdAt;
  final String syncStatus;

  ExpenseComment({
    required this.id,
    required this.expenseId,
    required this.memberName,
    required this.content,
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'member_name': memberName,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  factory ExpenseComment.fromMap(Map<String, dynamic> map) {
    return ExpenseComment(
      id: map['id'] as String,
      expenseId: map['expense_id'] as String,
      memberName: map['member_name'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
