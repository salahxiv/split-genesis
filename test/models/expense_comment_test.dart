import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/expenses/models/expense_comment.dart';

void main() {
  group('ExpenseComment model', () {
    late ExpenseComment testComment;

    setUp(() {
      testComment = ExpenseComment(
        id: 'c1',
        expenseId: 'e1',
        memberName: 'Alice',
        content: 'This looks right',
        createdAt: DateTime(2024, 3, 15, 10, 30),
      );
    });

    test('toMap/fromMap roundtrip preserves all fields', () {
      final map = testComment.toMap();
      final restored = ExpenseComment.fromMap(map);

      expect(restored.id, testComment.id);
      expect(restored.expenseId, testComment.expenseId);
      expect(restored.memberName, testComment.memberName);
      expect(restored.content, testComment.content);
      expect(restored.createdAt, testComment.createdAt);
      expect(restored.syncStatus, testComment.syncStatus);
    });

    test('toMap includes sync_status', () {
      final map = testComment.toMap();
      expect(map.containsKey('sync_status'), isTrue);
      expect(map['sync_status'], 'pending');
    });

    test('toMap includes sync_status when synced', () {
      final synced = ExpenseComment(
        id: 'c2',
        expenseId: 'e1',
        memberName: 'Bob',
        content: 'OK',
        createdAt: DateTime.now(),
        syncStatus: 'synced',
      );
      expect(synced.toMap()['sync_status'], 'synced');
    });

    test('fromMap defaults sync_status to pending when missing', () {
      final map = {
        'id': 'c3',
        'expense_id': 'e1',
        'member_name': 'Charlie',
        'content': 'Test',
        'created_at': '2024-01-01T00:00:00.000',
      };
      final comment = ExpenseComment.fromMap(map);
      expect(comment.syncStatus, 'pending');
    });

    test('fromMap parses Supabase timestamp format', () {
      final map = {
        'id': 'c4',
        'expense_id': 'e1',
        'member_name': 'Dave',
        'content': 'Supabase test',
        'created_at': '2024-03-15T10:30:00.123456+00:00',
      };
      final comment = ExpenseComment.fromMap(map);
      expect(comment.createdAt.year, 2024);
      expect(comment.createdAt.month, 3);
      expect(comment.createdAt.day, 15);
    });

    test('unicode content (emojis, special chars)', () {
      final comment = ExpenseComment(
        id: 'c5',
        expenseId: 'e1',
        memberName: 'Eve \u{1F600}',
        content: 'Looks good! \u{1F44D}\u{1F3FB} caf\u00E9 \u00A5100',
        createdAt: DateTime(2024, 1, 1),
      );
      final map = comment.toMap();
      final restored = ExpenseComment.fromMap(map);

      expect(restored.content, comment.content);
      expect(restored.memberName, comment.memberName);
    });

    test('empty content string', () {
      final comment = ExpenseComment(
        id: 'c6',
        expenseId: 'e1',
        memberName: 'Frank',
        content: '',
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = ExpenseComment.fromMap(comment.toMap());
      expect(restored.content, '');
    });
  });
}
