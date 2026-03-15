-- ============================================
-- Fix RLS Performance v2 — 2026-03-15
-- Fixes remaining auth.uid() wrapping for activity_log,
-- expense_payers, expense_comments, and merges the two
-- permissive SELECT policies on groups into one.
-- ============================================

-- ============================================
-- ACTIVITY LOG
-- ============================================

DROP POLICY IF EXISTS "Users can manage activity log in their groups" ON activity_log;

CREATE POLICY "Users can manage activity log in their groups"
  ON activity_log FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM groups
      WHERE groups.id = activity_log.group_id
      AND ((select auth.uid()) = ANY(groups.member_user_ids) OR (select auth.uid()) = groups.created_by_user_id)
    )
  );

-- ============================================
-- EXPENSE PAYERS
-- ============================================

DROP POLICY IF EXISTS "Users can manage expense payers in their groups" ON expense_payers;

CREATE POLICY "Users can manage expense payers in their groups"
  ON expense_payers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM expenses
      JOIN groups ON groups.id = expenses.group_id
      WHERE expenses.id = expense_payers.expense_id
      AND ((select auth.uid()) = ANY(groups.member_user_ids) OR (select auth.uid()) = groups.created_by_user_id)
    )
  );

-- ============================================
-- EXPENSE COMMENTS
-- ============================================

DROP POLICY IF EXISTS "Users can manage expense comments in their groups" ON expense_comments;

CREATE POLICY "Users can manage expense comments in their groups"
  ON expense_comments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM expenses
      JOIN groups ON groups.id = expenses.group_id
      WHERE expenses.id = expense_comments.expense_id
      AND ((select auth.uid()) = ANY(groups.member_user_ids) OR (select auth.uid()) = groups.created_by_user_id)
    )
  );

-- ============================================
-- GROUPS SELECT — merge two permissive SELECT policies into one
-- ============================================

DROP POLICY IF EXISTS "Users can view their groups" ON groups;
DROP POLICY IF EXISTS "Anyone can find groups by share code" ON groups;

CREATE POLICY "Users can view their groups"
  ON groups FOR SELECT
  USING (
    (select auth.uid()) = ANY(member_user_ids)
    OR (select auth.uid()) = created_by_user_id
    OR share_code IS NOT NULL
  );
