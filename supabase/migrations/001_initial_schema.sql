-- Split Genesis: Firebase → Supabase Migration
-- Flat tables (no subcollections like Firestore)

-- ============================================
-- TABLES
-- ============================================

CREATE TABLE groups (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  share_code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by_user_id UUID REFERENCES auth.users(id),
  member_user_ids UUID[] DEFAULT '{}'
);

CREATE TABLE members (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE expenses (
  id UUID PRIMARY KEY,
  description TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  paid_by_id UUID REFERENCES members(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  category TEXT NOT NULL DEFAULT 'general',
  split_type TEXT NOT NULL DEFAULT 'equal'
);

CREATE TABLE expense_splits (
  id UUID PRIMARY KEY,
  expense_id UUID REFERENCES expenses(id) ON DELETE CASCADE,
  member_id UUID REFERENCES members(id) ON DELETE CASCADE,
  amount DOUBLE PRECISION NOT NULL
);

CREATE TABLE settlements (
  id UUID PRIMARY KEY,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  from_member_id UUID REFERENCES members(id) ON DELETE CASCADE,
  to_member_id UUID REFERENCES members(id) ON DELETE CASCADE,
  amount DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  from_member_name TEXT,
  to_member_name TEXT
);

CREATE TABLE activity_log (
  id UUID PRIMARY KEY,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  description TEXT NOT NULL,
  member_name TEXT,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_members_group_id ON members(group_id);
CREATE INDEX idx_expenses_group_id ON expenses(group_id);
CREATE INDEX idx_expense_splits_expense_id ON expense_splits(expense_id);
CREATE INDEX idx_settlements_group_id ON settlements(group_id);
CREATE INDEX idx_activity_log_group_id ON activity_log(group_id);
CREATE INDEX idx_groups_share_code ON groups(share_code);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- Groups: users can see/modify groups they belong to
CREATE POLICY "Users can view their groups"
  ON groups FOR SELECT
  USING (auth.uid() = ANY(member_user_ids) OR auth.uid() = created_by_user_id);

CREATE POLICY "Users can insert groups"
  ON groups FOR INSERT
  WITH CHECK (auth.uid() = created_by_user_id);

CREATE POLICY "Users can update their groups"
  ON groups FOR UPDATE
  USING (auth.uid() = ANY(member_user_ids) OR auth.uid() = created_by_user_id);

-- Allow finding groups by share_code (for joining)
CREATE POLICY "Anyone can find groups by share code"
  ON groups FOR SELECT
  USING (share_code IS NOT NULL);

-- Members: accessible if user belongs to the group
CREATE POLICY "Users can manage members in their groups"
  ON members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM groups
      WHERE groups.id = members.group_id
      AND (auth.uid() = ANY(groups.member_user_ids) OR auth.uid() = groups.created_by_user_id)
    )
  );

-- Expenses: accessible if user belongs to the group
CREATE POLICY "Users can manage expenses in their groups"
  ON expenses FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM groups
      WHERE groups.id = expenses.group_id
      AND (auth.uid() = ANY(groups.member_user_ids) OR auth.uid() = groups.created_by_user_id)
    )
  );

-- Expense splits: accessible if user belongs to the group
CREATE POLICY "Users can manage expense splits in their groups"
  ON expense_splits FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM expenses
      JOIN groups ON groups.id = expenses.group_id
      WHERE expenses.id = expense_splits.expense_id
      AND (auth.uid() = ANY(groups.member_user_ids) OR auth.uid() = groups.created_by_user_id)
    )
  );

-- Settlements: accessible if user belongs to the group
CREATE POLICY "Users can manage settlements in their groups"
  ON settlements FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM groups
      WHERE groups.id = settlements.group_id
      AND (auth.uid() = ANY(groups.member_user_ids) OR auth.uid() = groups.created_by_user_id)
    )
  );

-- Activity log: accessible if user belongs to the group
CREATE POLICY "Users can manage activity log in their groups"
  ON activity_log FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM groups
      WHERE groups.id = activity_log.group_id
      AND (auth.uid() = ANY(groups.member_user_ids) OR auth.uid() = groups.created_by_user_id)
    )
  );

-- ============================================
-- REALTIME
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE groups;
ALTER PUBLICATION supabase_realtime ADD TABLE members;
ALTER PUBLICATION supabase_realtime ADD TABLE expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE expense_splits;
ALTER PUBLICATION supabase_realtime ADD TABLE settlements;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_log;
