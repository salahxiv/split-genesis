-- ============================================
-- 002: Sync Supabase schema with SQLite v8
-- Adds missing columns/tables + RPC functions + views
-- ============================================

-- ============================================
-- SCHEMA ADDITIONS
-- ============================================

-- expenses: add expense_date, currency
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS expense_date TIMESTAMPTZ;
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';
-- Backfill expense_date from created_at
UPDATE expenses SET expense_date = created_at WHERE expense_date IS NULL;

-- groups: add currency, type
ALTER TABLE groups ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';
ALTER TABLE groups ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'other';

-- expense_payers table
CREATE TABLE IF NOT EXISTS expense_payers (
  id UUID PRIMARY KEY,
  expense_id UUID REFERENCES expenses(id) ON DELETE CASCADE,
  member_id UUID REFERENCES members(id) ON DELETE CASCADE,
  amount DOUBLE PRECISION NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_expense_payers_expense_id ON expense_payers(expense_id);

-- expense_comments table
CREATE TABLE IF NOT EXISTS expense_comments (
  id UUID PRIMARY KEY,
  expense_id UUID REFERENCES expenses(id) ON DELETE CASCADE,
  member_name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_expense_comments_expense_id ON expense_comments(expense_id);

-- ============================================
-- RLS for new tables
-- ============================================

ALTER TABLE expense_payers ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage expense payers in their groups"
  ON expense_payers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM expenses
      JOIN groups ON groups.id = expenses.group_id
      WHERE expenses.id = expense_payers.expense_id
      AND (auth.uid() = ANY(groups.member_user_ids) OR auth.uid() = groups.created_by_user_id)
    )
  );

CREATE POLICY "Users can manage expense comments in their groups"
  ON expense_comments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM expenses
      JOIN groups ON groups.id = expenses.group_id
      WHERE expenses.id = expense_comments.expense_id
      AND (auth.uid() = ANY(groups.member_user_ids) OR auth.uid() = groups.created_by_user_id)
    )
  );

-- ============================================
-- REALTIME for new tables
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE expense_payers;
ALTER PUBLICATION supabase_realtime ADD TABLE expense_comments;

-- ============================================
-- VIEWS: group-level access to splits and payers
-- ============================================

CREATE OR REPLACE VIEW expense_splits_by_group AS
SELECT es.*, e.group_id
FROM expense_splits es
JOIN expenses e ON e.id = es.expense_id;

CREATE OR REPLACE VIEW expense_payers_by_group AS
SELECT ep.*, e.group_id
FROM expense_payers ep
JOIN expenses e ON e.id = ep.expense_id;

-- ============================================
-- RPC: Atomic upsert of expense + splits + payers
-- ============================================

CREATE OR REPLACE FUNCTION upsert_expense(
  p_expense JSONB,
  p_splits JSONB,
  p_payers JSONB
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_expense_id UUID;
  v_split JSONB;
  v_payer JSONB;
BEGIN
  v_expense_id := (p_expense->>'id')::UUID;

  -- Upsert the expense
  INSERT INTO expenses (id, description, amount, paid_by_id, group_id, created_at, expense_date, category, split_type, currency, updated_at)
  VALUES (
    v_expense_id,
    p_expense->>'description',
    (p_expense->>'amount')::DOUBLE PRECISION,
    (p_expense->>'paid_by_id')::UUID,
    (p_expense->>'group_id')::UUID,
    (p_expense->>'created_at')::TIMESTAMPTZ,
    (p_expense->>'expense_date')::TIMESTAMPTZ,
    COALESCE(p_expense->>'category', 'general'),
    COALESCE(p_expense->>'split_type', 'equal'),
    COALESCE(p_expense->>'currency', 'USD'),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    description = EXCLUDED.description,
    amount = EXCLUDED.amount,
    paid_by_id = EXCLUDED.paid_by_id,
    expense_date = EXCLUDED.expense_date,
    category = EXCLUDED.category,
    split_type = EXCLUDED.split_type,
    currency = EXCLUDED.currency,
    updated_at = NOW();

  -- Delete old splits and payers, then re-insert
  DELETE FROM expense_splits WHERE expense_id = v_expense_id;
  DELETE FROM expense_payers WHERE expense_id = v_expense_id;

  -- Insert splits
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

  -- Insert payers
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

-- ============================================
-- RPC: Check if member has expenses across tables
-- ============================================

CREATE OR REPLACE FUNCTION member_has_expenses(p_member_id UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check expenses.paid_by_id
  IF EXISTS (SELECT 1 FROM expenses WHERE paid_by_id = p_member_id) THEN
    RETURN true;
  END IF;

  -- Check expense_payers
  IF EXISTS (SELECT 1 FROM expense_payers WHERE member_id = p_member_id) THEN
    RETURN true;
  END IF;

  -- Check expense_splits
  IF EXISTS (SELECT 1 FROM expense_splits WHERE member_id = p_member_id) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;
