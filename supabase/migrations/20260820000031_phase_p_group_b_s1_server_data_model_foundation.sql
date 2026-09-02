-- Phase P Group B S1: Server Data Model / Migration Foundation
--
-- ADDITIVE, IDEMPOTENT / REPLAY-SAFE data-model foundation ONLY.
--
-- Non-goals (deferred to later governed slices):
--   * NO row backfill of existing licenses/devices/invitations
--   * NO tier / entitlement enforcement (S2)
--   * NO device trust / proof-of-possession (S4)
--   * NO invitation token issuance / validation (S4)
--   * NO accept_invitation / invite-employee behavior change (S4)
--   * NO production deployment (S11)
--
-- This migration only makes the governed S1 schema representable:
--   plans authoritative tier source (P-OD8), devices PENDING_APPROVAL +
--   public-key/approval metadata, invitations token-hash storage, and a
--   device_audit_log surface.

-- =============================================================================
-- 1. plans — authoritative, deterministic tier source (P-OD8 foundation)
-- =============================================================================

CREATE TABLE IF NOT EXISTS plans (
  key             TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  user_limit      INTEGER,
  device_limit    INTEGER,
  trial_days      INTEGER,
  billing_cadence TEXT DEFAULT 'monthly',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE plans IS
  'S1: server-authoritative commercial tier reference (P-OD8). NULL user_limit/device_limit = unlimited.';

CREATE UNIQUE INDEX IF NOT EXISTS idx_plans_key ON plans(key);

-- billing_cadence semantic contract (owner correction):
--   NULL      = Trial / non-subscription / compatibility
--   'monthly' = monthly paid subscription cadence
--   'annual'  = annual paid subscription cadence
-- The column is intentionally NULLABLE (Trial seed stores explicit NULL).
ALTER TABLE plans
  DROP CONSTRAINT IF EXISTS plans_billing_cadence_check;

ALTER TABLE plans
  ADD CONSTRAINT plans_billing_cadence_check
  CHECK (billing_cadence IS NULL OR billing_cadence IN ('monthly', 'annual'));

-- Deterministic seeds (replay-safe; never overwrite on re-run).
INSERT INTO plans (key, name, user_limit, device_limit, trial_days, billing_cadence)
VALUES
  ('trial',        'Trial',        1,    1,    14,   NULL),
  ('starter',      'Starter',      2,    3,    NULL, 'monthly'),
  ('professional', 'Professional', 5,    10,   NULL, 'monthly'),
  ('enterprise',   'Enterprise',   NULL, NULL, NULL, 'monthly')
ON CONFLICT (key) DO NOTHING;

-- =============================================================================
-- 2. licenses — additive binding foundation (backfill is S2)
-- =============================================================================

ALTER TABLE licenses
  ADD COLUMN IF NOT EXISTS plan_key TEXT REFERENCES plans(key);

ALTER TABLE licenses
  ADD COLUMN IF NOT EXISTS user_limit INTEGER;

COMMENT ON COLUMN licenses.plan_key IS 'S1: nullable FK to plans — binding for later tier resolution (S2). Existing rows untouched.';
COMMENT ON COLUMN licenses.user_limit IS 'S1: nullable user quota (NULL until derived). Existing rows untouched.';

CREATE INDEX IF NOT EXISTS idx_licenses_plan_key ON licenses(plan_key);

-- =============================================================================
-- 3. devices — PENDING_APPROVAL status + public-key / approval metadata
-- =============================================================================

-- Extend the device status lifecycle with PENDING_APPROVAL (P-OD13 foundation).
-- Replay-safe: the drop/re-add is guarded and idempotent.
ALTER TABLE devices
  DROP CONSTRAINT IF EXISTS devices_status_check;

ALTER TABLE devices
  ADD CONSTRAINT devices_status_check
  CHECK (status IN ('ACTIVE', 'REVOKED', 'LOST', 'PENDING_APPROVAL'));

-- Public-key foundation: PUBLIC material only. Never private keys/secrets here.
ALTER TABLE devices
  ADD COLUMN IF NOT EXISTS public_key TEXT;

ALTER TABLE devices
  ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);

ALTER TABLE devices
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

ALTER TABLE devices
  ADD COLUMN IF NOT EXISTS revoked_by UUID REFERENCES auth.users(id);

ALTER TABLE devices
  ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ;

COMMENT ON COLUMN devices.public_key IS 'S1: public key material only (no private/secret material). Proof-of-possession enforced in later slice.';
COMMENT ON COLUMN devices.approved_by IS 'S1: auth user who approved this device (approval lifecycle foundation).';
COMMENT ON COLUMN devices.approved_at IS 'S1: timestamp of device approval.';
COMMENT ON COLUMN devices.revoked_by IS 'S1: auth user who revoked this device.';
COMMENT ON COLUMN devices.revoked_at IS 'S1: timestamp of device revocation.';

CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(shop_id, status);

-- =============================================================================
-- 4. invitations — token-hash storage foundation (S4 owns validation)
-- =============================================================================

ALTER TABLE invitations
  ADD COLUMN IF NOT EXISTS token_hash TEXT;

ALTER TABLE invitations
  ADD COLUMN IF NOT EXISTS accepted_by UUID REFERENCES auth.users(id);

COMMENT ON COLUMN invitations.token_hash IS 'S1: server-stored HASH of a one-time pairing token. Never plaintext tokens.';
COMMENT ON COLUMN invitations.accepted_by IS 'S1: auth user who accepted the invitation (acceptance validation is S4).';

CREATE INDEX IF NOT EXISTS idx_invitations_token_hash
  ON invitations(token_hash)
  WHERE token_hash IS NOT NULL;

-- =============================================================================
-- 5. device_audit_log — approval / revocation audit surface (P-OD13)
-- =============================================================================

CREATE TABLE IF NOT EXISTS device_audit_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id       UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  device_id     UUID REFERENCES devices(id) ON DELETE CASCADE,
  actor_user_id UUID NOT NULL,
  action        TEXT NOT NULL,
  detail        JSONB DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE device_audit_log IS
  'S1: audit trail for device approval/revocation/lost/proof lifecycle. No secrets or PII in detail.';

CREATE INDEX IF NOT EXISTS idx_device_audit_shop
  ON device_audit_log(shop_id, created_at DESC);

-- =============================================================================
-- 6. RLS on NEW tables ONLY (plans, device_audit_log)
-- =============================================================================
-- SELECT-only, ACTIVE-membership based. INSERT/UPDATE/DELETE reserved to
-- service_role (no client policies). Existing business-table RLS untouched.

-- plans: global reference metadata with no shop_id — SELECT eligibility follows
-- the governed active-membership model (any ACTIVE member may read the tier
-- reference surface). No client mutations.
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'plans' AND policyname = 'plans_select'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY plans_select ON plans
        FOR SELECT TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM shop_members
            WHERE shop_members.user_id = auth.uid()
              AND shop_members.status = 'ACTIVE'
          )
        )
    $policy$;
  END IF;
END
$$;

-- device_audit_log: tenant isolation bound by shop_id.
ALTER TABLE device_audit_log ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'device_audit_log' AND policyname = 'shop_device_audit_isolation'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY shop_device_audit_isolation ON device_audit_log
        FOR SELECT USING (
          EXISTS (
            SELECT 1 FROM shop_members
            WHERE shop_members.shop_id = device_audit_log.shop_id
              AND shop_members.user_id = auth.uid()
              AND shop_members.status = 'ACTIVE'
          )
        )
    $policy$;
  END IF;
END
$$;
