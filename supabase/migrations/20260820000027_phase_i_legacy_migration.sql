-- Phase I Migration 27: Legacy Data Migration Core
-- cloud_migration_ledger (D5) + dedicated one-shot ingest RPC family (D4)
-- used by LegacyMigrationService. Deliberately SEPARATE from the Phase H
-- continuous-sync path: migration never touches sync_queue and never runs
-- through the SyncEngine upload loop (D7).
--
-- This migration is ADDITIVE ONLY.
--
-- Frozen ledger contract (plan D5):
--   UNIQUE(batch_id, local_table, local_id)            -- per-batch mapping
--   UNIQUE(shop_id, local_table, content_fingerprint)  -- cross-batch idempotency
-- status ∈ IMPORTED | SKIPPED_DUPLICATE | CONFLICT

-- ============================================================================
-- 1. cloud_migration_ledger table
-- ============================================================================

CREATE TABLE IF NOT EXISTS cloud_migration_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id TEXT NOT NULL,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  local_table TEXT NOT NULL,
  local_id BIGINT NOT NULL,
  cloud_uuid UUID NOT NULL,
  content_fingerprint TEXT NOT NULL,
  server_version INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL CHECK (status IN ('IMPORTED', 'SKIPPED_DUPLICATE', 'CONFLICT')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uniq_ledger_batch_local UNIQUE (batch_id, local_table, local_id),
  CONSTRAINT uniq_ledger_shop_fingerprint UNIQUE (shop_id, local_table, content_fingerprint),
  CONSTRAINT chk_ledger_table CHECK (local_table IN (
    'products', 'sales', 'returns', 'expenses', 'expense_categories',
    'customers', 'invoices', 'inventory_count', 'app_settings'
  ))
);

CREATE INDEX IF NOT EXISTS idx_cloud_migration_ledger_batch
  ON cloud_migration_ledger (batch_id);
CREATE INDEX IF NOT EXISTS idx_cloud_migration_ledger_shop
  ON cloud_migration_ledger (shop_id, local_table);

-- RLS: owners can audit their own shop's ledger; all writes go through the
-- SECURITY DEFINER functions below (same pattern as sync_log).
ALTER TABLE cloud_migration_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY shop_isolation_cloud_migration_ledger ON cloud_migration_ledger
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = cloud_migration_ledger.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- ============================================================================
-- 2. migration_upsert_chunk (D4/D10/D13)
-- ============================================================================
-- Imports one chunk atomically: every row lands in its target cloud table AND
-- the ledger in the same transaction, with per-row verdicts:
--   IMPORTED          new cloud row created
--   SKIPPED_DUPLICATE identical business payload already migrated (ledger hit)
--   CONFLICT          natural-key collision, existing cloud row wins (D13)
--
-- p_rows element shape (produced by MigrationChunkRowRequest.toJson):
--   { "local_id": int, "fingerprint": text, "payload": jsonb }
--
-- Natural keys (D13): products.barcode, invoices.invoice_number,
-- expense_categories.name, customers.(name, phone). Tables without a natural
-- key always append (history semantics).

CREATE OR REPLACE FUNCTION migration_upsert_chunk(
  p_batch_id TEXT,
  p_shop_id UUID,
  p_local_table TEXT,
  p_rows JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row JSONB;
  v_local_id BIGINT;
  v_fingerprint TEXT;
  v_payload JSONB;
  v_existing RECORD;
  v_new_uuid UUID;
  v_version INTEGER;
  v_results JSONB := '[]'::JSONB;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  IF p_batch_id IS NULL OR trim(p_batch_id) = '' THEN
    RAISE EXCEPTION 'batch id is required';
  END IF;

  -- Table whitelist (D1): only the nine migration-universe families.
  IF p_local_table NOT IN (
    'products', 'sales', 'returns', 'expenses', 'expense_categories',
    'customers', 'invoices', 'inventory_count', 'app_settings'
  ) THEN
    RAISE EXCEPTION 'table % is not part of the legacy migration universe',
      p_local_table;
  END IF;

  IF p_rows IS NULL OR jsonb_typeof(p_rows) != 'array' THEN
    RAISE EXCEPTION 'rows must be a JSON array';
  END IF;

  FOR v_row IN SELECT * FROM jsonb_array_elements(p_rows)
  LOOP
    v_local_id := (v_row->>'local_id')::BIGINT;
    v_fingerprint := v_row->>'fingerprint';
    v_payload := v_row->'payload';

    IF v_local_id IS NULL OR v_fingerprint IS NULL OR v_payload IS NULL THEN
      RAISE EXCEPTION 'malformed row: local_id, fingerprint and payload are required';
    END IF;

    -- (a) Per-batch replay of the very same local row → return the durable
    --     verdict already stored for it (idempotent resend after crash).
    SELECT * INTO v_existing
    FROM cloud_migration_ledger
    WHERE batch_id = p_batch_id
      AND local_table = p_local_table
      AND local_id = v_local_id;
    IF FOUND THEN
      v_results := v_results || jsonb_build_object(
        'local_id', v_local_id,
        'status', v_existing.status,
        'cloud_uuid', v_existing.cloud_uuid,
        'server_version', v_existing.server_version);
      CONTINUE;
    END IF;

    -- (b) Cross-batch idempotency on content identity (D10).
    SELECT * INTO v_existing
    FROM cloud_migration_ledger
    WHERE shop_id = p_shop_id
      AND local_table = p_local_table
      AND content_fingerprint = v_fingerprint;
    IF FOUND THEN
      INSERT INTO cloud_migration_ledger (
        batch_id, shop_id, local_table, local_id,
        cloud_uuid, content_fingerprint, server_version, status
      ) VALUES (
        p_batch_id, p_shop_id, p_local_table, v_local_id,
        v_existing.cloud_uuid, v_fingerprint, v_existing.server_version,
        'SKIPPED_DUPLICATE');
      v_results := v_results || jsonb_build_object(
        'local_id', v_local_id,
        'status', 'SKIPPED_DUPLICATE',
        'cloud_uuid', v_existing.cloud_uuid,
        'server_version', v_existing.server_version);
      CONTINUE;
    END IF;

    -- (c) Natural-key collision check (D13): existing cloud row wins; the
    --     colliding row is recorded as CONFLICT, never overwritten/deleted.
    v_existing := NULL;
    IF p_local_table = 'products' THEN
      SELECT id, server_version INTO v_existing FROM cloud_products
      WHERE shop_id = p_shop_id AND barcode = trim(v_payload->>'barcode')
        AND deleted_at IS NULL;
    ELSIF p_local_table = 'expense_categories' THEN
      SELECT id, server_version INTO v_existing FROM cloud_expense_categories
      WHERE shop_id = p_shop_id AND name = trim(v_payload->>'name');
    ELSIF p_local_table = 'customers' THEN
      SELECT id, server_version INTO v_existing FROM cloud_customers
      WHERE shop_id = p_shop_id
        AND name = trim(v_payload->>'name')
        AND COALESCE(phone, '') = COALESCE(v_payload->>'phone', '');
    ELSIF p_local_table = 'invoices' THEN
      SELECT id, server_version INTO v_existing FROM cloud_invoices
      WHERE shop_id = p_shop_id
        AND invoice_number = trim(v_payload->>'invoice_number')
        AND deleted_at IS NULL;
    END IF;

    IF v_existing IS NOT NULL THEN
      INSERT INTO cloud_migration_ledger (
        batch_id, shop_id, local_table, local_id,
        cloud_uuid, content_fingerprint, server_version, status
      ) VALUES (
        p_batch_id, p_shop_id, p_local_table, v_local_id,
        v_existing.id, v_fingerprint, v_existing.server_version, 'CONFLICT');
      v_results := v_results || jsonb_build_object(
        'local_id', v_local_id,
        'status', 'CONFLICT',
        'cloud_uuid', v_existing.id,
        'server_version', v_existing.server_version);
      CONTINUE;
    END IF;

    -- (d) Fresh import: entity row + ledger entry in the SAME transaction.
    IF p_local_table = 'products' THEN
      INSERT INTO cloud_products (
        shop_id, name, barcode, opening_quantity, sold_quantity,
        returned_quantity, current_quantity, cost_price,
        total_inventory_cost, inventory_adjustment
      ) VALUES (
        p_shop_id, v_payload->>'name', v_payload->>'barcode',
        COALESCE((v_payload->>'opening_quantity')::INTEGER, 0),
        COALESCE((v_payload->>'sold_quantity')::INTEGER, 0),
        COALESCE((v_payload->>'returned_quantity')::INTEGER, 0),
        COALESCE((v_payload->>'current_quantity')::INTEGER, 0),
        COALESCE((v_payload->>'cost_price')::NUMERIC, 0),
        COALESCE((v_payload->>'total_inventory_cost')::NUMERIC, 0),
        COALESCE((v_payload->>'inventory_adjustment')::INTEGER, 0)
      ) RETURNING id, server_version INTO v_new_uuid, v_version;
    ELSIF p_local_table = 'expense_categories' THEN
      INSERT INTO cloud_expense_categories (shop_id, name)
      VALUES (p_shop_id, v_payload->>'name')
      RETURNING id, server_version INTO v_new_uuid, v_version;
    ELSIF p_local_table = 'customers' THEN
      INSERT INTO cloud_customers (
        shop_id, name, phone, address, notes, is_active, is_system
      ) VALUES (
        p_shop_id, v_payload->>'name', v_payload->>'phone',
        v_payload->>'address', v_payload->>'notes',
        COALESCE((v_payload->>'is_active')::BOOLEAN, true),
        COALESCE((v_payload->>'is_system')::BOOLEAN, false)
      ) RETURNING id, server_version INTO v_new_uuid, v_version;
    ELSIF p_local_table = 'expenses' THEN
      INSERT INTO cloud_expenses (
        shop_id, date, description, amount, category_name, category_id
      ) VALUES (
        p_shop_id, (v_payload->>'date')::TIMESTAMPTZ,
        v_payload->>'description',
        COALESCE((v_payload->>'amount')::NUMERIC, 0),
        v_payload->>'category_name',
        NULLIF(v_payload->>'category_id', '')::UUID
      ) RETURNING id, server_version INTO v_new_uuid, v_version;
    ELSIF p_local_table = 'inventory_count' THEN
      INSERT INTO cloud_inventory_count (
        shop_id, product_id, actual_quantity, notes, count_date
      ) VALUES (
        p_shop_id, NULLIF(v_payload->>'product_id', '')::UUID,
        COALESCE((v_payload->>'actual_quantity')::INTEGER, 0),
        COALESCE(v_payload->>'notes', ''),
        (v_payload->>'count_date')::TIMESTAMPTZ
      ) RETURNING id, server_version INTO v_new_uuid, v_version;
    ELSIF p_local_table = 'sales' THEN
      INSERT INTO cloud_sales (
        shop_id, date, product_name, barcode, quantity, sale_price,
        total_sale_value, cost_price, cogs
      ) VALUES (
        p_shop_id, (v_payload->>'date')::TIMESTAMPTZ,
        v_payload->>'product_name', v_payload->>'barcode',
        COALESCE((v_payload->>'quantity')::INTEGER, 0),
        COALESCE((v_payload->>'sale_price')::NUMERIC, 0),
        COALESCE((v_payload->>'total_sale_value')::NUMERIC, 0),
        COALESCE((v_payload->>'cost_price')::NUMERIC, 0),
        COALESCE((v_payload->>'cogs')::NUMERIC, 0)
      ) RETURNING id, server_version INTO v_new_uuid, v_version;
    ELSIF p_local_table = 'invoices' THEN
      INSERT INTO cloud_invoices (
        shop_id, invoice_number, date, customer_name, customer_id,
        payment_method, total_amount, total_items
      ) VALUES (
        p_shop_id, v_payload->>'invoice_number',
        (v_payload->>'date')::TIMESTAMPTZ,
        v_payload->>'customer_name',
        NULLIF(v_payload->>'customer_id', '')::UUID,
        v_payload->>'payment_method',
        COALESCE((v_payload->>'total_amount')::NUMERIC, 0),
        COALESCE((v_payload->>'total_items')::INTEGER, 0)
      ) RETURNING id, server_version INTO v_new_uuid, v_version;
    ELSIF p_local_table = 'returns' THEN
      INSERT INTO cloud_returns (
        shop_id, date, product_name, barcode, quantity, sale_price,
        total_return_value, cost_price, returned_cogs
      ) VALUES (
        p_shop_id, (v_payload->>'date')::TIMESTAMPTZ,
        v_payload->>'product_name', v_payload->>'barcode',
        COALESCE((v_payload->>'quantity')::INTEGER, 0),
        COALESCE((v_payload->>'sale_price')::NUMERIC, 0),
        COALESCE((v_payload->>'total_return_value')::NUMERIC, 0),
        COALESCE((v_payload->>'cost_price')::NUMERIC, 0),
        COALESCE((v_payload->>'returned_cogs')::NUMERIC, 0)
      ) RETURNING id, server_version INTO v_new_uuid, v_version;
    ELSE -- app_settings → cloud_shop_settings (composite PK, no surrogate id)
      INSERT INTO cloud_shop_settings (shop_id, setting_key, setting_value)
      VALUES (p_shop_id, v_payload->>'setting_key',
              v_payload->>'setting_value')
      ON CONFLICT (shop_id, setting_key) DO UPDATE
        SET setting_value = EXCLUDED.setting_value,
            updated_at = now();
      -- cloud_shop_settings has no surrogate uuid; the ledger still needs a
      -- stable cloud reference, so we derive a deterministic one from the
      -- natural key pair (first 32 hex chars of a SHA-256 = valid UUID text).
      v_new_uuid := substr(
        encode(sha256((p_shop_id::TEXT || '|app_settings|' ||
                       v_payload->>'setting_key')::BYTEA), 'hex'), 1, 32
      )::UUID;
      v_version := 1;
    END IF;

    INSERT INTO cloud_migration_ledger (
      batch_id, shop_id, local_table, local_id,
      cloud_uuid, content_fingerprint, server_version, status
    ) VALUES (
      p_batch_id, p_shop_id, p_local_table, v_local_id,
      v_new_uuid, v_fingerprint, v_version, 'IMPORTED');

    v_results := v_results || jsonb_build_object(
      'local_id', v_local_id,
      'status', 'IMPORTED',
      'cloud_uuid', v_new_uuid,
      'server_version', v_version);
  END LOOP;

  RETURN jsonb_build_object('results', v_results);
END;
$$;

-- ============================================================================
-- 3. migration_post_pass_links (P9 / D6)
-- ============================================================================
-- Repairs invoice↔sale links on the cloud side using fully resolved uuid
-- pairs supplied by the client. Both sides must belong to this batch's ledger.

CREATE OR REPLACE FUNCTION migration_post_pass_links(
  p_batch_id TEXT,
  p_shop_id UUID,
  p_links JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_link JSONB;
  v_linked INTEGER := 0;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  IF p_links IS NULL OR jsonb_typeof(p_links) != 'array' THEN
    RAISE EXCEPTION 'links must be a JSON array';
  END IF;

  FOR v_link IN SELECT * FROM jsonb_array_elements(p_links)
  LOOP
    UPDATE cloud_sales s
    SET invoice_id = NULLIF(v_link->>'invoice_cloud_uuid', '')::UUID,
        updated_at = now()
    WHERE s.id = NULLIF(v_link->>'sale_cloud_uuid', '')::UUID
      AND s.shop_id = p_shop_id
      AND EXISTS (
        SELECT 1 FROM cloud_migration_ledger l
        WHERE l.batch_id = p_batch_id AND l.shop_id = p_shop_id
          AND l.local_table = 'sales' AND l.cloud_uuid = s.id)
      AND (
        NULLIF(v_link->>'invoice_cloud_uuid', '')::UUID IS NULL
        OR EXISTS (
          SELECT 1 FROM cloud_migration_ledger l2
          WHERE l2.batch_id = p_batch_id AND l2.shop_id = p_shop_id
            AND l2.local_table = 'invoices'
            AND l2.cloud_uuid = NULLIF(v_link->>'invoice_cloud_uuid', '')::UUID)
      );
    v_linked := v_linked + 1;
  END LOOP;

  RETURN jsonb_build_object('linked', v_linked);
END;
$$;

-- ============================================================================
-- 4. migration_fetch_ledger (D5/D12 — resume + completeness source of truth)
-- ============================================================================

CREATE OR REPLACE FUNCTION migration_fetch_ledger(
  p_batch_id TEXT,
  p_shop_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
      'local_table', l.local_table,
      'local_id', l.local_id,
      'cloud_uuid', l.cloud_uuid,
      'server_version', l.server_version,
      'status', l.status
    ) ORDER BY l.local_table, l.local_id)
    FROM cloud_migration_ledger l
    WHERE l.batch_id = p_batch_id AND l.shop_id = p_shop_id
  ), '[]'::JSONB);
END;
$$;

-- ============================================================================
-- 5. migration_reconcile_batch (D15 — aggregates via ledger join)
-- ============================================================================

CREATE OR REPLACE FUNCTION migration_reconcile_batch(
  p_batch_id TEXT,
  p_shop_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tables JSONB;
  v_financials JSONB;
  v_imported_rows JSONB;
BEGIN
  PERFORM require_shop_permission(p_shop_id, 'admin.settings.access');

  -- Per-table ledger status counts.
  SELECT COALESCE(jsonb_object_agg(local_table, counts), '{}'::JSONB)
  INTO v_tables
  FROM (
    SELECT local_table, jsonb_build_object(
      'IMPORTED', COUNT(*) FILTER (WHERE status = 'IMPORTED'),
      'SKIPPED_DUPLICATE', COUNT(*) FILTER (WHERE status = 'SKIPPED_DUPLICATE'),
      'CONFLICT', COUNT(*) FILTER (WHERE status = 'CONFLICT')
    ) AS counts
    FROM cloud_migration_ledger
    WHERE batch_id = p_batch_id AND shop_id = p_shop_id
    GROUP BY local_table
  ) t;

  -- D14 financial sums over cloud rows attributable to this batch.
  SELECT jsonb_build_object(
    'sales.total_sale_value', COALESCE((
      SELECT SUM(s.total_sale_value) FROM cloud_sales s
      JOIN cloud_migration_ledger l
        ON l.cloud_uuid = s.id AND l.batch_id = p_batch_id
       AND l.local_table = 'sales' AND l.status = 'IMPORTED'
      WHERE s.shop_id = p_shop_id), 0),
    'sales.cogs', COALESCE((
      SELECT SUM(s.cogs) FROM cloud_sales s
      JOIN cloud_migration_ledger l
        ON l.cloud_uuid = s.id AND l.batch_id = p_batch_id
       AND l.local_table = 'sales' AND l.status = 'IMPORTED'
      WHERE s.shop_id = p_shop_id), 0),
    'invoices.total_amount', COALESCE((
      SELECT SUM(i.total_amount) FROM cloud_invoices i
      JOIN cloud_migration_ledger l
        ON l.cloud_uuid = i.id AND l.batch_id = p_batch_id
       AND l.local_table = 'invoices' AND l.status = 'IMPORTED'
      WHERE i.shop_id = p_shop_id), 0),
    'expenses.amount', COALESCE((
      SELECT SUM(e.amount) FROM cloud_expenses e
      JOIN cloud_migration_ledger l
        ON l.cloud_uuid = e.id AND l.batch_id = p_batch_id
       AND l.local_table = 'expenses' AND l.status = 'IMPORTED'
      WHERE e.shop_id = p_shop_id), 0),
    'returns.returned_cogs', COALESCE((
      SELECT SUM(r.returned_cogs) FROM cloud_returns r
      JOIN cloud_migration_ledger l
        ON l.cloud_uuid = r.id AND l.batch_id = p_batch_id
       AND r.deleted_at IS NULL
       AND l.local_table = 'returns' AND l.status = 'IMPORTED'
      WHERE r.shop_id = p_shop_id), 0)
  )
  INTO v_financials;

  -- Cloud-side imported-row parity: distinct cloud rows attributable to this
  -- batch via the ledger join must equal the ledger IMPORTED counts.
  SELECT jsonb_build_object(
    'products', (SELECT COUNT(*) FROM cloud_products p
                 JOIN cloud_migration_ledger l ON l.cloud_uuid = p.id
                  AND l.batch_id = p_batch_id AND l.local_table = 'products'
                 WHERE l.status = 'IMPORTED'),
    'expense_categories', (SELECT COUNT(*) FROM cloud_expense_categories c
                 JOIN cloud_migration_ledger l ON l.cloud_uuid = c.id
                  AND l.batch_id = p_batch_id AND l.local_table = 'expense_categories'
                 WHERE l.status = 'IMPORTED'),
    'customers', (SELECT COUNT(*) FROM cloud_customers cu
                 JOIN cloud_migration_ledger l ON l.cloud_uuid = cu.id
                  AND l.batch_id = p_batch_id AND l.local_table = 'customers'
                 WHERE l.status = 'IMPORTED'),
    'expenses', (SELECT COUNT(*) FROM cloud_expenses e
                 JOIN cloud_migration_ledger l ON l.cloud_uuid = e.id
                  AND l.batch_id = p_batch_id AND l.local_table = 'expenses'
                 WHERE l.status = 'IMPORTED'),
    'inventory_count', (SELECT COUNT(*) FROM cloud_inventory_count ic
                 JOIN cloud_migration_ledger l ON l.cloud_uuid = ic.id
                  AND l.batch_id = p_batch_id AND l.local_table = 'inventory_count'
                 WHERE l.status = 'IMPORTED'),
    'sales', (SELECT COUNT(*) FROM cloud_sales s
                 JOIN cloud_migration_ledger l ON l.cloud_uuid = s.id
                  AND l.batch_id = p_batch_id AND l.local_table = 'sales'
                 WHERE l.status = 'IMPORTED'),
    'invoices', (SELECT COUNT(*) FROM cloud_invoices i
                 JOIN cloud_migration_ledger l ON l.cloud_uuid = i.id
                  AND l.batch_id = p_batch_id AND l.local_table = 'invoices'
                 WHERE l.status = 'IMPORTED'),
    'returns', (SELECT COUNT(*) FROM cloud_returns r
                 JOIN cloud_migration_ledger l ON l.cloud_uuid = r.id
                  AND l.batch_id = p_batch_id AND l.local_table = 'returns'
                 WHERE l.status = 'IMPORTED'),
    'app_settings', (SELECT COUNT(*) FROM cloud_shop_settings ss
                 JOIN cloud_migration_ledger l
                   ON l.cloud_uuid =
                      substr(encode(sha256((p_shop_id::TEXT || '|app_settings|' || ss.setting_key)::BYTEA), 'hex'), 1, 32)::UUID
                  AND l.batch_id = p_batch_id AND l.local_table = 'app_settings'
                 WHERE ss.shop_id = p_shop_id AND l.status = 'IMPORTED')
  )
  INTO v_imported_rows;

  RETURN jsonb_build_object(
    'tables', v_tables,
    'financials', v_financials,
    'imported_rows', v_imported_rows
  );
END;
$$;
