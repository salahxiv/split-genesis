-- ============================================
-- Security Fix Migration — 2026-03-15
-- Fixes Issues #76, #77, #78, #79
-- ============================================

-- ============================================
-- #76: Storage RLS — Private receipts bucket
-- Bucket must be set to private in Supabase Dashboard.
-- ============================================

-- Only group members can read their group's receipts.
-- Storage path convention: receipts/<group_id>/<expense_id>.jpg
-- The first folder segment is the group_id.
CREATE POLICY "Group members can access receipts"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'receipts'
  AND EXISTS (
    SELECT 1 FROM groups
    WHERE groups.id::text = (storage.foldername(name))[1]
    AND (
      auth.uid() = ANY(groups.member_user_ids)
      OR auth.uid() = groups.created_by_user_id
    )
  )
);

-- Only group members can upload receipts into their own groups.
CREATE POLICY "Group members can upload receipts"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'receipts'
  AND EXISTS (
    SELECT 1 FROM groups
    WHERE groups.id::text = (storage.foldername(name))[1]
    AND (
      auth.uid() = ANY(groups.member_user_ids)
      OR auth.uid() = groups.created_by_user_id
    )
  )
);

-- Only group members can delete receipts from their groups.
CREATE POLICY "Group members can delete receipts"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'receipts'
  AND EXISTS (
    SELECT 1 FROM groups
    WHERE groups.id::text = (storage.foldername(name))[1]
    AND (
      auth.uid() = ANY(groups.member_user_ids)
      OR auth.uid() = groups.created_by_user_id
    )
  )
);

-- ============================================
-- #77: Drop broad share_code policy, add SECURITY DEFINER RPC
-- ============================================

-- Drop the over-broad policy that exposes all group data to anyone
DROP POLICY IF EXISTS "Anyone can find groups by share code" ON groups;
DROP POLICY IF EXISTS "Anyone can find groups by share_code" ON groups;

-- Secure function: only returns id + name + member_count — no sensitive fields
-- SECURITY DEFINER runs as function owner, so it bypasses the member-only RLS
-- intentionally to allow unauthenticated/pre-join lookup.
CREATE OR REPLACE FUNCTION find_group_by_share_code(p_share_code TEXT)
RETURNS TABLE(id UUID, name TEXT, member_count INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate input length to prevent abuse
  IF length(p_share_code) > 64 THEN
    RAISE EXCEPTION 'Invalid share code';
  END IF;

  RETURN QUERY
    SELECT
      g.id,
      g.name,
      COALESCE(array_length(g.member_user_ids, 1), 0)::INT AS member_count
    FROM groups g
    WHERE g.share_code = p_share_code;
END;
$$;

-- Revoke direct table execute — only the RPC can be called by anon/authenticated
REVOKE EXECUTE ON FUNCTION find_group_by_share_code(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION find_group_by_share_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION find_group_by_share_code(TEXT) TO anon;

-- ============================================
-- #78: Add auth checks to SECURITY DEFINER RPCs
-- ============================================

-- Replace upsert_expense with auth-guarded version
CREATE OR REPLACE FUNCTION upsert_expense(
  p_expense JSONB,
  p_splits  JSONB,
  p_payers  JSONB
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_expense_id UUID;
  v_group_id   UUID;
  v_split      JSONB;
  v_payer      JSONB;
BEGIN
  v_expense_id := (p_expense->>'id')::UUID;
  v_group_id   := (p_expense->>'group_id')::UUID;

  -- #78 Auth check: caller must be a member of the target group
  IF NOT EXISTS (
    SELECT 1 FROM groups
    WHERE id = v_group_id
      AND (
        auth.uid() = ANY(member_user_ids)
        OR auth.uid() = created_by_user_id
      )
  ) THEN
    RAISE EXCEPTION 'Access denied: not a member of group %', v_group_id;
  END IF;

  -- Upsert the expense
  INSERT INTO expenses (
    id, description, amount, paid_by_id, group_id,
    created_at, expense_date, category, split_type, currency, updated_at
  )
  VALUES (
    v_expense_id,
    p_expense->>'description',
    (p_expense->>'amount')::DOUBLE PRECISION,
    (p_expense->>'paid_by_id')::UUID,
    v_group_id,
    (p_expense->>'created_at')::TIMESTAMPTZ,
    (p_expense->>'expense_date')::TIMESTAMPTZ,
    COALESCE(p_expense->>'category', 'general'),
    COALESCE(p_expense->>'split_type', 'equal'),
    COALESCE(p_expense->>'currency', 'USD'),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    description  = EXCLUDED.description,
    amount       = EXCLUDED.amount,
    paid_by_id   = EXCLUDED.paid_by_id,
    expense_date = EXCLUDED.expense_date,
    category     = EXCLUDED.category,
    split_type   = EXCLUDED.split_type,
    currency     = EXCLUDED.currency,
    updated_at   = NOW();

  -- Replace splits and payers atomically
  DELETE FROM expense_splits WHERE expense_id = v_expense_id;
  DELETE FROM expense_payers WHERE expense_id = v_expense_id;

  FOR v_split IN SELECT * FROM jsonb_array_elements(p_splits)
  LOOP
    INSERT INTO expense_splits (id, expense_id, member_id, amount)
    VALUES (
      (v_split->>'id')::UUID,
      v_expense_id,
      (v_split->>'member_id')::UUID,
      (v_split->>'amount')::DOUBLE PRECISION
    );
  END LOOP;

  FOR v_payer IN SELECT * FROM jsonb_array_elements(p_payers)
  LOOP
    INSERT INTO expense_payers (id, expense_id, member_id, amount)
    VALUES (
      (v_payer->>'id')::UUID,
      v_expense_id,
      (v_payer->>'member_id')::UUID,
      (v_payer->>'amount')::DOUBLE PRECISION
    );
  END LOOP;
END;
$$;

-- Replace member_has_expenses with auth + membership-scoped version
CREATE OR REPLACE FUNCTION member_has_expenses(p_member_id UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- #78 Auth check: caller must be authenticated
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Scope check to groups the caller belongs to — prevents cross-group enumeration
  IF EXISTS (
    SELECT 1 FROM expenses e
    JOIN groups g ON g.id = e.group_id
    WHERE e.paid_by_id = p_member_id
      AND (auth.uid() = ANY(g.member_user_ids) OR auth.uid() = g.created_by_user_id)
  ) THEN
    RETURN true;
  END IF;

  IF EXISTS (
    SELECT 1 FROM expense_payers ep
    JOIN expenses e ON e.id = ep.expense_id
    JOIN groups g ON g.id = e.group_id
    WHERE ep.member_id = p_member_id
      AND (auth.uid() = ANY(g.member_user_ids) OR auth.uid() = g.created_by_user_id)
  ) THEN
    RETURN true;
  END IF;

  IF EXISTS (
    SELECT 1 FROM expense_splits es
    JOIN expenses e ON e.id = es.expense_id
    JOIN groups g ON g.id = e.group_id
    WHERE es.member_id = p_member_id
      AND (auth.uid() = ANY(g.member_user_ids) OR auth.uid() = g.created_by_user_id)
  ) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

-- ============================================
-- #79: Replace unprotected views with auth-guarded RPC functions
-- The views had no RLS and exposed data across all groups via PostgREST.
-- Replacement RPCs enforce group membership before returning data.
-- ============================================

DROP VIEW IF EXISTS expense_splits_by_group;
DROP VIEW IF EXISTS expense_payers_by_group;

-- Secure replacement for expense_splits_by_group view
CREATE OR REPLACE FUNCTION get_splits_by_group(p_group_id UUID)
RETURNS TABLE(
  id UUID,
  expense_id UUID,
  member_id UUID,
  amount DOUBLE PRECISION,
  group_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Auth check: caller must be a member of the group
  IF NOT EXISTS (
    SELECT 1 FROM groups
    WHERE id = p_group_id
      AND (
        auth.uid() = ANY(member_user_ids)
        OR auth.uid() = created_by_user_id
      )
  ) THEN
    RAISE EXCEPTION 'Access denied: not a member of group %', p_group_id;
  END IF;

  RETURN QUERY
    SELECT es.id, es.expense_id, es.member_id, es.amount, p_group_id AS group_id
    FROM expense_splits es
    JOIN expenses e ON e.id = es.expense_id
    WHERE e.group_id = p_group_id;
END;
$$;

-- Secure replacement for expense_payers_by_group view
CREATE OR REPLACE FUNCTION get_payers_by_group(p_group_id UUID)
RETURNS TABLE(
  id UUID,
  expense_id UUID,
  member_id UUID,
  amount DOUBLE PRECISION,
  group_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Auth check: caller must be a member of the group
  IF NOT EXISTS (
    SELECT 1 FROM groups
    WHERE id = p_group_id
      AND (
        auth.uid() = ANY(member_user_ids)
        OR auth.uid() = created_by_user_id
      )
  ) THEN
    RAISE EXCEPTION 'Access denied: not a member of group %', p_group_id;
  END IF;

  RETURN QUERY
    SELECT ep.id, ep.expense_id, ep.member_id, ep.amount, p_group_id AS group_id
    FROM expense_payers ep
    JOIN expenses e ON e.id = ep.expense_id
    WHERE e.group_id = p_group_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION get_splits_by_group(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_splits_by_group(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION get_payers_by_group(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_payers_by_group(UUID) TO authenticated;
