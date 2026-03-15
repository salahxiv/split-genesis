-- Fix RLS Performance: wrap auth.uid() in (select auth.uid()) to evaluate once per query
-- instead of once per row. Supabase recommendation for better query performance.

-- ============================================
-- GROUPS
-- ============================================

DROP POLICY IF EXISTS "Users can view their groups" ON groups;
DROP POLICY IF EXISTS "Users can insert groups" ON groups;
DROP POLICY IF EXISTS "Users can update their groups" ON groups;

CREATE POLICY "Users can view their groups"
  ON groups FOR SELECT
  USING ((select auth.uid()) = ANY(member_user_ids) OR (select auth.uid()) = created_by_user_id);

CREATE POLICY "Users can insert groups"
  ON groups FOR INSERT
  WITH CHECK ((select auth.uid()) = created_by_user_id);

CREATE POLICY "Users can update their groups"
  ON groups FOR UPDATE
  USING ((select auth.uid()) = ANY(member_user_ids) OR (select auth.uid()) = created_by_user_id);

-- ============================================
-- MEMBERS
-- ============================================

DROP POLICY IF EXISTS "Users can manage members in their groups" ON members;

CREATE POLICY "Users can manage members in their groups"
  ON members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM groups
      WHERE groups.id = members.group_id
      AND ((select auth.uid()) = ANY(groups.member_user_ids) OR (select auth.uid()) = groups.created_by_user_id)
    )
  );

-- ============================================
-- EXPENSES
-- ============================================

DROP POLICY IF EXISTS "Users can manage expenses in their groups" ON expenses;

CREATE POLICY "Users can manage expenses in their groups"
  ON expenses FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM groups
      WHERE groups.id = expenses.group_id
      AND ((select auth.uid()) = ANY(groups.member_user_ids) OR (select auth.uid()) = groups.created_by_user_id)
    )
  );

-- ============================================
-- EXPENSE SPLITS
-- ============================================

DROP POLICY IF EXISTS "Users can manage expense splits in their groups" ON expense_splits;

CREATE POLICY "Users can manage expense splits in their groups"
  ON expense_splits FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM expenses
      JOIN groups ON groups.id = expenses.group_id
      WHERE expenses.id = expense_splits.expense_id
      AND ((select auth.uid()) = ANY(groups.member_user_ids) OR (select auth.uid()) = groups.created_by_user_id)
    )
  );

-- ============================================
-- SETTLEMENTS
-- ============================================

DROP POLICY IF EXISTS "Users can manage settlements in their groups" ON settlements;

CREATE POLICY "Users can manage settlements in their groups"
  ON settlements FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM groups
      WHERE groups.id = settlements.group_id
      AND ((select auth.uid()) = ANY(groups.member_user_ids) OR (select auth.uid()) = groups.created_by_user_id)
    )
  );
