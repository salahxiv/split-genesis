import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SQL Migration 002', () {
    late String sql;

    setUpAll(() {
      final file = File('supabase/migrations/002_api_first_migration.sql');
      sql = file.readAsStringSync();
    });

    test('migration file exists and is non-empty', () {
      expect(sql, isNotEmpty);
    });

    test('adds expense_date and currency to expenses', () {
      expect(sql, contains('ALTER TABLE expenses ADD COLUMN IF NOT EXISTS expense_date'));
      expect(sql, contains('ALTER TABLE expenses ADD COLUMN IF NOT EXISTS currency'));
    });

    test('adds currency and type to groups', () {
      expect(sql, contains('ALTER TABLE groups ADD COLUMN IF NOT EXISTS currency'));
      expect(sql, contains('ALTER TABLE groups ADD COLUMN IF NOT EXISTS type'));
    });

    test('creates expense_payers table', () {
      expect(sql, contains('CREATE TABLE IF NOT EXISTS expense_payers'));
      expect(sql, contains('REFERENCES expenses(id) ON DELETE CASCADE'));
    });

    test('creates expense_comments table', () {
      expect(sql, contains('CREATE TABLE IF NOT EXISTS expense_comments'));
    });

    test('enables RLS on new tables', () {
      expect(sql, contains('ALTER TABLE expense_payers ENABLE ROW LEVEL SECURITY'));
      expect(sql, contains('ALTER TABLE expense_comments ENABLE ROW LEVEL SECURITY'));
    });

    test('creates RLS policies for new tables', () {
      expect(sql, contains('expense payers in their groups'));
      expect(sql, contains('expense comments in their groups'));
    });

    test('adds new tables to realtime publication', () {
      expect(sql, contains('ADD TABLE expense_payers'));
      expect(sql, contains('ADD TABLE expense_comments'));
    });

    test('creates views for group-level access', () {
      expect(sql, contains('CREATE OR REPLACE VIEW expense_splits_by_group'));
      expect(sql, contains('CREATE OR REPLACE VIEW expense_payers_by_group'));
    });

    test('creates upsert_expense RPC function', () {
      expect(sql, contains('CREATE OR REPLACE FUNCTION upsert_expense'));
      expect(sql, contains('p_expense JSONB'));
      expect(sql, contains('p_splits JSONB'));
      expect(sql, contains('p_payers JSONB'));
    });

    test('upsert_expense handles ON CONFLICT', () {
      expect(sql, contains('ON CONFLICT (id) DO UPDATE'));
    });

    test('upsert_expense deletes old splits/payers before re-insert', () {
      expect(sql, contains('DELETE FROM expense_splits WHERE expense_id = v_expense_id'));
      expect(sql, contains('DELETE FROM expense_payers WHERE expense_id = v_expense_id'));
    });

    test('creates member_has_expenses RPC function', () {
      expect(sql, contains('CREATE OR REPLACE FUNCTION member_has_expenses'));
      expect(sql, contains('p_member_id UUID'));
      expect(sql, contains('RETURNS boolean'));
    });

    test('member_has_expenses checks all three tables', () {
      expect(sql, contains('FROM expenses WHERE paid_by_id = p_member_id'));
      expect(sql, contains('FROM expense_payers WHERE member_id = p_member_id'));
      expect(sql, contains('FROM expense_splits WHERE member_id = p_member_id'));
    });

    test('backfills expense_date from created_at', () {
      expect(sql, contains('UPDATE expenses SET expense_date = created_at WHERE expense_date IS NULL'));
    });
  });
}
