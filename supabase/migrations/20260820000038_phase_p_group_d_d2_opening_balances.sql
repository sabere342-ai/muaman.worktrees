-- Phase P Group D D2 (P-OD5): Opening Balances
-- Tables: cloud_accounts, cloud_opening_balance_entries
-- SECURITY DEFINER functions: account CRUD + opening balance RPC
-- RLS: shop-scoped SELECT-only policies
-- Indexes: shop_id, account_id, effective_date, idempotency_key UNIQUE
--
-- Owner decisions resolved (A/C/A/C/A/B/A):
--   D2-01 A: additive per-shop account catalog, seeded EMPTY
--   D2-02 C: type-aware direction (CASH/BANK/RECEIVABLE_SUMMARY positive=asset;
--            PAYABLE_SUMMARY/CAPITAL positive=obligation)
--   D2-03 A: negatives REJECTED, CHECK (amount >= 0)
--   D2-04 C: per-entry effective_date column, indexed
--   D2-05 A: append-only; corrections via corrective adjustment entries
--   D2-06 B: owner set/correct; owner+employee read-only; salesOnly denied
--   D2-07 A: dedicated setup workflow
--
-- This migration is ADDITIVE ONLY - no destructive changes to existing data.
-- D1 tables (cloud_cost_history, migrations 00036/00037) are NOT touched.

-- ============================================================================
-- 1. TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS cloud_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  account_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  server_version INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS cloud_opening_balance_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES cloud_accounts(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  effective_date DATE NOT NULL,
  entry_kind TEXT NOT NULL,
  corrects_entry_id UUID REFERENCES cloud_opening_balance_entries(id) ON DELETE SET NULL,
  correction_reason TEXT,
  notes TEXT,
  idempotency_key TEXT NOT NULL UNIQUE,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  server_version INTEGER NOT NULL DEFAULT 0
);

-- ============================================================================
-- 2. CONSTRAINTS
-- ============================================================================

-- D2-02: account_type must be a valid type (type-aware direction)
ALTER TABLE cloud_accounts
  ADD CONSTRAINT chk_cloud_account_type
  CHECK (account_type IN ('CASH', 'BANK', 'RECEIVABLE_SUMMARY', 'PAYABLE_SUMMARY', 'CAPITAL'));

-- D2-03: amount must be zero or positive (negatives rejected)
ALTER TABLE cloud_opening_balance_entries
  ADD CONSTRAINT chk_ob_amount_nonneg
  CHECK (amount >= 0);

-- D2-05: entry_kind must be a valid kind (append-only: OPENING / ADJUSTMENT / CORRECTION)
ALTER TABLE cloud_opening_balance_entries
  ADD CONSTRAINT chk_ob_entry_kind
  CHECK (entry_kind IN ('OPENING', 'ADJUSTMENT', 'CORRECTION'));

-- ============================================================================
-- 3. INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_cloud_accounts_shop ON cloud_accounts(shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_accounts_type ON cloud_accounts(account_type);
CREATE INDEX IF NOT EXISTS idx_cloud_accounts_deleted ON cloud_accounts(deleted_at) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_cloud_ob_entries_shop ON cloud_opening_balance_entries(shop_id);
CREATE INDEX IF NOT EXISTS idx_cloud_ob_entries_account ON cloud_opening_balance_entries(account_id);
CREATE INDEX IF NOT EXISTS idx_cloud_ob_entries_effective_date ON cloud_opening_balance_entries(effective_date);
CREATE INDEX IF NOT EXISTS idx_cloud_ob_entries_entry_kind ON cloud_opening_balance_entries(entry_kind);

-- ============================================================================
-- 4. RLS
-- ============================================================================

ALTER TABLE cloud_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_opening_balance_entries ENABLE ROW LEVEL SECURITY;

-- SELECT-only for authenticated shop members (canonical shape, D2-06 B: owner+employee read)
CREATE POLICY cloud_accounts_select ON cloud_accounts
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members sm
      WHERE sm.shop_id = cloud_accounts.shop_id
        AND sm.user_id = auth.uid()
        AND sm.status = 'ACTIVE'
    )
  );

CREATE POLICY cloud_ob_entries_select ON cloud_opening_balance_entries
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members sm
      WHERE sm.shop_id = cloud_opening_balance_entries.shop_id
        AND sm.user_id = auth.uid()
        AND sm.status = 'ACTIVE'
    )
  );

-- D2-06=B: NO permissive INSERT/UPDATE/DELETE policies with (true).
-- All mutations go through SECURITY DEFINER RPCs with require_shop_permission.

-- ============================================================================
-- 5. SECURITY DEFINER FUNCTIONS
-- ============================================================================

-- --- Account CRUD ---

CREATE OR REPLACE FUNCTION create_cloud_account(
  p_shop_id UUID,
  p_name TEXT,
  p_account_type TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
  v_role TEXT;
BEGIN
  -- D2-06=B: require inventory.edit permission
  v_role := require_shop_permission(p_shop_id, 'inventory.edit');

  -- D2-06=B: owner-only set/correct — only owner can create accounts
  IF v_role != 'owner' THEN
    RAISE EXCEPTION 'permission_denied: accounting.edit';
  END IF;

  -- D2-02: validate account_type
  IF p_account_type NOT IN ('CASH', 'BANK', 'RECEIVABLE_SUMMARY', 'PAYABLE_SUMMARY', 'CAPITAL') THEN
    RAISE EXCEPTION 'invalid_account_type';
  END IF;

  IF trim(p_name) = '' THEN
    RAISE EXCEPTION 'account_name_required';
  END IF;

  INSERT INTO cloud_accounts (shop_id, name, account_type, created_by)
  VALUES (p_shop_id, trim(p_name), p_account_type, auth.uid())
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION update_cloud_account(
  p_shop_id UUID,
  p_account_id UUID,
  p_name TEXT,
  p_account_type TEXT,
  p_deleted BOOLEAN DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  -- D2-06=B: require inventory.edit permission
  v_role := require_shop_permission(p_shop_id, 'inventory.edit');

  -- D2-06=B: owner-only set/correct
  IF v_role != 'owner' THEN
    RAISE EXCEPTION 'permission_denied: accounting.edit';
  END IF;

  IF p_name IS NOT NULL AND trim(p_name) = '' THEN
    RAISE EXCEPTION 'account_name_required';
  END IF;

  IF p_account_type IS NOT NULL AND p_account_type NOT IN ('CASH', 'BANK', 'RECEIVABLE_SUMMARY', 'PAYABLE_SUMMARY', 'CAPITAL') THEN
    RAISE EXCEPTION 'invalid_account_type';
  END IF;

  UPDATE cloud_accounts
  SET name = CASE WHEN p_name IS NOT NULL THEN trim(p_name) ELSE name END,
      account_type = CASE WHEN p_account_type IS NOT NULL THEN p_account_type ELSE account_type END,
      deleted_at = CASE WHEN p_deleted IS NOT NULL AND p_deleted THEN now()
                        WHEN p_deleted IS NOT NULL AND NOT p_deleted
                        THEN NULL ELSE deleted_at END,
      updated_at = now(),
      server_version = server_version + 1
  WHERE id = p_account_id
    AND shop_id = p_shop_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'account_not_found';
  END IF;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION list_cloud_accounts(
  p_shop_id UUID
)
RETURNS TABLE (
  id UUID,
  shop_id UUID,
  name TEXT,
  account_type TEXT,
  created_at TIMESTAMPTZ,
  created_by UUID,
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  server_version INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  -- D2-06=B: require inventory.view permission (owner + employee read)
  v_role := require_shop_permission(p_shop_id, 'inventory.view');

  RETURN QUERY
  SELECT a.id, a.shop_id, a.name, a.account_type,
         a.created_at, a.created_by, a.updated_at, a.deleted_at, a.server_version
  FROM cloud_accounts a
  WHERE a.shop_id = p_shop_id
  ORDER BY a.name ASC;
END;
$$;

-- --- Opening Balance Entry RPCs ---

CREATE OR REPLACE FUNCTION create_cloud_opening_balance(
  p_shop_id UUID,
  p_account_id UUID,
  p_amount NUMERIC(12,2),
  p_effective_date DATE,
  p_entry_kind TEXT,
  p_corrects_entry_id UUID DEFAULT NULL,
  p_correction_reason TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
  v_role TEXT;
  v_account_shop UUID;
BEGIN
  -- D2-06=B: require inventory.edit permission
  v_role := require_shop_permission(p_shop_id, 'inventory.edit');

  -- D2-06=B: owner-only set/correct — only owner can create opening balance entries
  IF v_role != 'owner' THEN
    RAISE EXCEPTION 'permission_denied: accounting.edit';
  END IF;

  -- Verify the account belongs to this shop
  SELECT shop_id INTO v_account_shop
  FROM cloud_accounts
  WHERE id = p_account_id AND shop_id = p_shop_id;
  IF v_account_shop IS NULL THEN
    RAISE EXCEPTION 'account_not_found';
  END IF;

  -- D2-03: amount must be >= 0
  IF p_amount < 0 THEN
    RAISE EXCEPTION 'negative_amount_rejected';
  END IF;

  -- D2-05: entry_kind must be valid
  IF p_entry_kind NOT IN ('OPENING', 'ADJUSTMENT', 'CORRECTION') THEN
    RAISE EXCEPTION 'invalid_entry_kind';
  END IF;

  -- D2-05: CORRECTION entries must reference the entry being corrected
  IF p_entry_kind = 'CORRECTION' AND p_corrects_entry_id IS NULL THEN
    RAISE EXCEPTION 'correction_requires_corrects_entry_id';
  END IF;

  -- Idempotency: if an idempotency_key is provided, return existing id
  IF p_idempotency_key IS NOT NULL THEN
    SELECT id INTO v_id
    FROM cloud_opening_balance_entries
    WHERE idempotency_key = p_idempotency_key
      AND shop_id = p_shop_id
      AND account_id = p_account_id
      AND entry_kind = p_entry_kind;
    IF v_id IS NOT NULL THEN
      RETURN v_id;
    END IF;
  END IF;

  INSERT INTO cloud_opening_balance_entries (
    shop_id, account_id, amount, effective_date, entry_kind,
    corrects_entry_id, correction_reason, notes, idempotency_key, created_by
  ) VALUES (
    p_shop_id, p_account_id, p_amount, p_effective_date, p_entry_kind,
    p_corrects_entry_id, p_correction_reason, p_notes, p_idempotency_key, auth.uid()
  ) RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION list_cloud_opening_balances(
  p_shop_id UUID,
  p_account_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  shop_id UUID,
  account_id UUID,
  amount NUMERIC(12,2),
  effective_date DATE,
  entry_kind TEXT,
  corrects_entry_id UUID,
  correction_reason TEXT,
  notes TEXT,
  idempotency_key TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  server_version INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  -- D2-06=B: require inventory.view permission (owner + employee read)
  v_role := require_shop_permission(p_shop_id, 'inventory.view');

  RETURN QUERY
  SELECT e.id, e.shop_id, e.account_id, e.amount, e.effective_date,
         e.entry_kind, e.corrects_entry_id, e.correction_reason, e.notes,
         e.idempotency_key, e.created_by, e.created_at, e.updated_at,
         e.server_version
  FROM cloud_opening_balance_entries e
  WHERE e.shop_id = p_shop_id
    AND (p_account_id IS NULL OR e.account_id = p_account_id)
  ORDER BY e.created_at DESC, e.id;
END;
$$;

-- ============================================================================
-- 6. GRANTS / REVOKES
-- ============================================================================

-- Revoke all from PUBLIC
REVOKE ALL ON TABLE cloud_accounts FROM PUBLIC;
REVOKE ALL ON TABLE cloud_opening_balance_entries FROM PUBLIC;

REVOKE ALL ON FUNCTION create_cloud_account FROM PUBLIC;
REVOKE ALL ON FUNCTION update_cloud_account FROM PUBLIC;
REVOKE ALL ON FUNCTION list_cloud_accounts FROM PUBLIC;
REVOKE ALL ON FUNCTION create_cloud_opening_balance FROM PUBLIC;
REVOKE ALL ON FUNCTION list_cloud_opening_balances FROM PUBLIC;

-- Grant EXECUTE to authenticated (owner bypass + permission check inside functions)
GRANT EXECUTE ON FUNCTION create_cloud_account TO authenticated;
GRANT EXECUTE ON FUNCTION update_cloud_account TO authenticated;
GRANT EXECUTE ON FUNCTION list_cloud_accounts TO authenticated;
GRANT EXECUTE ON FUNCTION create_cloud_opening_balance TO authenticated;
GRANT EXECUTE ON FUNCTION list_cloud_opening_balances TO authenticated;

-- Direct table DML revoked from authenticated (defense-in-depth)
REVOKE INSERT, UPDATE, DELETE ON cloud_accounts FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON cloud_opening_balance_entries FROM authenticated;
