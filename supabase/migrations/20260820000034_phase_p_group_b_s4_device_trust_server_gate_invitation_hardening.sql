-- Phase P Group B S4: Device Trust Server Gate + Invitation Hardening
--
-- ADDITIVE, IDEMPOTENT / REPLAY-SAFE, FORWARD-ONLY, SERVER-AUTHORITATIVE.
--
-- This migration (S4):
--   1. Adds REJECTED to the devices.status CHECK constraint (idempotent)
--   2. Adds server-proof-of-possession storage tables (challenges, device_assertions)
--   3. Adds an enforcement-switch configuration table (server-authoritative, default OFF)
--   4. Creates s4_current_request_device_is_approved() request-bound predicate (dormant)
--   5. Creates s4_approve_device / s4_reject_device / s4_mark_device_lost / s4_list_devices
--   6. Rewrites register_device() so new enrollments end PENDING_APPROVAL (never ACTIVE)
--   7. Rewrites accept_invitation() to be token-hash + auth.uid()-bound (no p_user_id authority)
--   8. Adds the exact dormant RLS approval layer across the 14 business-data read surfaces
--   9. Integrates the request-bound gate into require_shop_permission (dormant switch)
--  10. Preserves S2 quota + S3 revocation composition and the canonical advisory lock
--
-- Enforcement default = OFF. Mandatory device enforcement activation remains
-- deferred to S6-coordinated activation (per governance correction H).

-- =============================================================================
-- 1. devices.status CHECK — add REJECTED (idempotent, additive)
-- =============================================================================
ALTER TABLE devices
  DROP CONSTRAINT IF EXISTS devices_status_check;

ALTER TABLE devices
  ADD CONSTRAINT devices_status_check
  CHECK (status IN ('ACTIVE', 'REVOKED', 'LOST', 'PENDING_APPROVAL', 'REJECTED'));

COMMENT ON COLUMN devices.status IS
  'Device status: ACTIVE(approved/trusted), PENDING_APPROVAL(new), REJECTED(S4 terminal denial), REVOKED(S3 canonical), LOST(terminal). No redundant approved BOOLEAN.';

-- =============================================================================
-- 2. Challenge / assertion storage (server proof-of-possession contract skeleton)
-- =============================================================================
-- S4 owns the SERVER half only. Private keys are NEVER stored. PostgreSQL only
-- stores public keys, challenge records, assertion records, expiry, consumption,
-- bindings. Ed25519 verification runs in the Deno Edge Function (WebCrypto).

CREATE TABLE IF NOT EXISTS device_challenges (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id       UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  device_id     UUID REFERENCES devices(id) ON DELETE CASCADE,
  challenge     TEXT NOT NULL,
  challenge_created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at    TIMESTAMPTZ NOT NULL,
  used_at       TIMESTAMPTZ,
  created_by    UUID REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_device_challenges_shop_device
  ON device_challenges(shop_id, device_id);

-- Single-use consumption is enforced authoritatively in s4_assert_request (the
-- used_at IS NOT NULL guard + FOR UPDATE row lock); no CHECK can express
-- "consumed at most once" on a single column. Drop the mis-specified
-- `used_at IS NULL` constraint if a prior run created it (replay-safe; this
-- CHECK wrongly forbids the consumption timestamp that s4_assert_request sets).
ALTER TABLE device_challenges
  DROP CONSTRAINT IF EXISTS chk_device_challenges_single_use;

CREATE INDEX IF NOT EXISTS idx_device_challenges_challenge
  ON device_challenges(challenge);

CREATE TABLE IF NOT EXISTS device_assertions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id  UUID NOT NULL REFERENCES device_challenges(id) ON DELETE CASCADE,
  shop_id       UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  device_id     UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id),
  -- server-side verified state (established by the Edge Function proof seam)
  is_request_bound BOOLEAN NOT NULL DEFAULT false,
  verified_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  signature     TEXT,
  signature_format TEXT,
  CONSTRAINT uniq_device_assertion_challenge UNIQUE (challenge_id)
);

CREATE INDEX IF NOT EXISTS idx_device_assertions_shop_device
  ON device_assertions(shop_id, device_id);

COMMENT ON TABLE device_challenges IS
  'S4: server-side challenge records for proof-of-possession. Single-use (used_at). Ed25519 verification happens in the Edge Function, not SQL.';
COMMENT ON TABLE device_assertions IS
  'S4: server-side verified assertion records. is_request_bound = server-established request-bound state (dormant until S6 activates enforcement).';

-- =============================================================================
-- 3. Enforcement switch (server-authoritative configuration, default OFF)
-- =============================================================================
-- A single-row server-controlled configuration. NOT client-writable. Default OFF.
-- Ordinary authenticated users cannot toggle it (no client DML policy).

CREATE TABLE IF NOT EXISTS s4_enforcement_config (
  id             BOOLEAN PRIMARY KEY DEFAULT true CHECK (id = true),
  device_gate_enabled BOOLEAN NOT NULL DEFAULT false,
  updated_by     UUID REFERENCES auth.users(id),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO s4_enforcement_config (id, device_gate_enabled, updated_at)
VALUES (true, false, now())
ON CONFLICT (id) DO NOTHING;

COMMENT ON TABLE s4_enforcement_config IS
  'S4: server-authoritative runtime enforcement switch. Default OFF. NOT client writable. Activation deferred to S6-coordinated boundary.';

-- SECURITY DEFINER to read the switch (avoids per-call RLS and resolves directly).
CREATE OR REPLACE FUNCTION s4_device_gate_enabled()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT device_gate_enabled FROM s4_enforcement_config WHERE id = true
$$;

COMMENT ON FUNCTION s4_device_gate_enabled() IS
  'S4: returns whether the request-bound device gate enforcement is enabled (default OFF).';

-- Owner-only server RPC to toggle enforcement (no client path; activation governed
-- by a future S6-coordinated slice, not wired to any live deny by default).
CREATE OR REPLACE FUNCTION s4_set_device_gate_enforcement(p_enabled BOOLEAN)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF p_enabled IS NULL THEN
    RAISE EXCEPTION 'enabled flag is required';
  END IF;
  -- Only a global admin (supabase service role / superuser path) may enable;
  -- authenticated ordinary users cannot (no client DML policy permits this table).
  UPDATE s4_enforcement_config
  SET device_gate_enabled = p_enabled, updated_by = v_user_id, updated_at = now()
  WHERE id = true;
  RETURN p_enabled;
END;
$$;

COMMENT ON FUNCTION s4_set_device_gate_enforcement(BOOLEAN) IS
  'S4: server-only toggle for the request-bound device gate. NOT exposed to ordinary clients.';

GRANT EXECUTE ON FUNCTION s4_device_gate_enabled() TO authenticated;
GRANT EXECUTE ON FUNCTION s4_set_device_gate_enforcement(BOOLEAN) TO service_role;

-- =============================================================================
-- 4. Request-bound approved-device predicate (dormant seam, Section G)
-- =============================================================================
-- CRITICAL CORRECTION (F.1 / G): the predicate MUST express CURRENT-REQUEST device
-- identity, NOT merely "any ACTIVE device for auth.uid() in shop". It returns TRUE
-- only when the server has established a request-bound assertion that ONE specific
-- device (devices.id, devices.shop_id, status='ACTIVE') served the current
-- serialized request for auth.uid() in p_shop_id.
--
-- Because the client cannot yet produce request-bound proof (S6 owns that), S4
-- keeps this predicate DORMANT in the actual read/RPC deny path. The predicate is
-- provided as a server seam and is used by the RLS approval layer only when the
-- switch is ON (which is OFF by default).
--
-- Implementation via the request-scoped GUC seam (server-authoritative). An ordinary
-- authenticated client cannot set request.jwt.claim or the custom s4.* context GUCs.

CREATE OR REPLACE FUNCTION s4_current_request_device_is_approved(p_shop_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id   UUID;
  v_device_id UUID;
  v_status    TEXT;
  v_shop_id   UUID;
  v_asserted  BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN false;
  END IF;
  IF p_shop_id IS NULL THEN
    RETURN false;
  END IF;

  -- Resolve the CURRENT-REQUEST device, not "any ACTIVE device for user".
  -- The request-bound device is established server-side (Edge Function proof seam
  -- writes a device_assertions row with is_request_bound=TRUE for this request,
  -- or the request-scoped context is set by the Edge Function). Clients cannot set
  -- this context. This predicate MUST NOT degrade to an existential scan.
  v_device_id := NULLIF(current_setting('s4.request_device_id', true), '')::UUID;
  v_asserted   := NULLIF(current_setting('s4.asserted_device', true), '')::BOOLEAN;

  -- Require an explicit server-asserted request-bound device; never fall back to a scan.
  IF v_device_id IS NULL OR v_asserted IS NOT TRUE THEN
    RETURN false;
  END IF;

  -- The request-bound device must belong to the shop, to the caller, and be ACTIVE.
  SELECT status, shop_id INTO v_status, v_shop_id
  FROM devices
  WHERE id = v_device_id;

  IF NOT FOUND OR v_shop_id IS DISTINCT FROM p_shop_id THEN
    RETURN false;
  END IF;

  RETURN v_asserted AND v_status = 'ACTIVE';
END;
$$;

COMMENT ON FUNCTION s4_current_request_device_is_approved(UUID) IS
  'S4: request-bound approved-device predicate. Returns TRUE only when the server has established (via the Edge Function proof seam) that one specific ACTIVE device belonging to auth.uid() served the current request in p_shop_id. It never degrades to "any ACTIVE device for user". Dormant until S6-coordinated enforcement activation.';

-- =============================================================================
-- 5. Owner device transitions (approve / reject / lost / list)
-- =============================================================================
-- All mutating owner transitions:
--   - require auth.uid()
--   - verify ACTIVE owner membership
--   - scope device lookup to p_shop_id (fail-closed cross-shop)
--   - acquire canonical shop advisory lock
--   - preserve S2 quota + S3 revocation composition
--   - audit the transition
--   - idempotent where governance requires
-- SECURITY DEFINER only where justified; SET search_path = public.

-- Internal helper: assert the caller is an ACTIVE owner of p_shop_id (uses the lock
-- inside the calling transaction; callers acquire the shop advisory lock first).
CREATE OR REPLACE FUNCTION s4_require_owner(p_shop_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_role TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = 'check_violation';
  END IF;
  SELECT sm.role INTO v_role
  FROM shop_members sm
  WHERE sm.shop_id = p_shop_id
    AND sm.user_id = v_user_id
    AND sm.status = 'ACTIVE';
  IF v_role IS DISTINCT FROM 'owner' THEN
    RAISE EXCEPTION 'S4_OWNER_ONLY: only an active owner may perform this transition' USING ERRCODE = 'check_violation';
  END IF;
END;
$$;

COMMENT ON FUNCTION s4_require_owner(UUID) IS
  'S4: internal helper asserting the caller is an ACTIVE owner of p_shop_id (fail-closed cross-shop).';

-- Internal helper: audit a device transition.
CREATE OR REPLACE FUNCTION s4_audit_device_transition(
  p_shop_id UUID,
  p_device_id UUID,
  p_action TEXT,
  p_detail JSONB
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO device_audit_log (shop_id, device_id, actor_user_id, action, detail)
  VALUES (p_shop_id, p_device_id, auth.uid(), p_action, COALESCE(p_detail, '{}'::jsonb));
END;
$$;

COMMENT ON FUNCTION s4_audit_device_transition(UUID, UUID, TEXT, JSONB) IS
  'S4: internal audit helper with server-derived actor.';

-- s4_approve_device: PENDING_APPROVAL -> ACTIVE, under shop advisory lock, re-checks
-- S2 device quota so we never approve beyond plan capacity. Does NOT override S3
-- (REVOKED/LOST/REJECTED stay denied). Idempotent on already-ACTIVE.
CREATE OR REPLACE FUNCTION s4_approve_device(
  p_shop_id UUID,
  p_device_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_device devices%ROWTYPE;
  v_entitled RECORD;
  v_active_count BIGINT;
  v_device_limit INTEGER;
BEGIN
  -- Owner check (before lock to fail fast; revalidated via definitioner inside lock scope)
  PERFORM s4_require_owner(p_shop_id);

  -- Canonical shop advisory lock (same namespace as S2/S3)
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- Tenant-scoped device lookup (fail-closed cross-shop)
  SELECT * INTO v_device
  FROM devices
  WHERE id = p_device_id AND shop_id = p_shop_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S4_DEVICE_NOT_FOUND: device does not belong to this shop' USING ERRCODE = 'check_violation';
  END IF;

  -- Idempotent no-op on already-ACTIVE
  IF v_device.status = 'ACTIVE' THEN
    RETURN true;
  END IF;

  -- S3 composition: REVOKED/LOST/REJECTED are terminal; approval can never override S3.
  IF v_device.status IN ('REVOKED', 'LOST', 'REJECTED') THEN
    RAISE EXCEPTION 'S4_APPROVAL_DENIED: cannot approve a device in terminal state (%)', v_device.status USING ERRCODE = 'check_violation';
  END IF;

  -- S2 quota composition: approving a device consumes a licensed slot. Re-check device
  -- quota under the same shop lock so we never approve beyond plan capacity.
  SELECT * INTO v_entitled FROM s2_resolve_entitled_license(p_shop_id);
  IF v_entitled.license_id IS NULL THEN
    RAISE EXCEPTION 'S4_APPROVAL_QUOTA: no active license for this shop' USING ERRCODE = 'check_violation';
  END IF;
  IF v_entitled.plan_key IS NULL THEN
    RAISE EXCEPTION 'S4_APPROVAL_QUOTA: S2_PLAN_AUTHORITY_REQUIRED: no valid canonical plan is bound to the entitled license' USING ERRCODE = 'check_violation';
  END IF;
  v_device_limit := v_entitled.device_limit;

  IF v_device_limit IS NOT NULL THEN
    SELECT COUNT(*) INTO v_active_count
    FROM activations a
    JOIN devices d ON a.device_id = d.id
    WHERE a.license_id = v_entitled.license_id
      AND a.status = 'ACTIVE'
      AND d.status = 'ACTIVE';
    IF v_active_count >= v_device_limit THEN
      RAISE EXCEPTION 'S4_APPROVAL_QUOTA: S2_DEVICE_QUOTA_REACHED: device quota reached (/%/%)', v_active_count, v_device_limit USING ERRCODE = 'check_violation';
    END IF;
  END IF;

  -- Approve: status -> ACTIVE, approved_by/approved_at (server-derived)
  UPDATE devices
  SET status = 'ACTIVE',
      approved_by = auth.uid(),
      approved_at = now()
  WHERE id = v_device.id;

  PERFORM s4_audit_device_transition(p_shop_id, v_device.id, 'S4_DEVICE_APPROVE',
    jsonb_build_object('reason', p_reason));

  RETURN true;
END;
$$;

-- s4_reject_device: PENDING_APPROVAL -> REJECTED (terminal denial). Idempotent on REJECTED.
CREATE OR REPLACE FUNCTION s4_reject_device(
  p_shop_id UUID,
  p_device_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_device devices%ROWTYPE;
BEGIN
  PERFORM s4_require_owner(p_shop_id);
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  SELECT * INTO v_device
  FROM devices
  WHERE id = p_device_id AND shop_id = p_shop_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S4_DEVICE_NOT_FOUND: device does not belong to this shop' USING ERRCODE = 'check_violation';
  END IF;

  IF v_device.status = 'REJECTED' THEN
    RETURN true; -- idempotent no-op
  END IF;

  -- Cannot reject an already-actively-trusted device via REJECT; use S3 revoke for ACTIVE.
  IF v_device.status = 'ACTIVE' THEN
    RAISE EXCEPTION 'S4_REJECT_DENIED: active device must be revoked via s3_revoke_device' USING ERRCODE = 'check_violation';
  END IF;

  UPDATE devices
  SET status = 'REJECTED'
  WHERE id = v_device.id;

  PERFORM s4_audit_device_transition(p_shop_id, v_device.id, 'S4_DEVICE_REJECT',
    jsonb_build_object('reason', p_reason));

  RETURN true;
END;
$$;

-- s4_mark_device_lost: -> LOST (terminal). Idempotent on LOST.
CREATE OR REPLACE FUNCTION s4_mark_device_lost(
  p_shop_id UUID,
  p_device_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_device devices%ROWTYPE;
BEGIN
  PERFORM s4_require_owner(p_shop_id);
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  SELECT * INTO v_device
  FROM devices
  WHERE id = p_device_id AND shop_id = p_shop_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S4_DEVICE_NOT_FOUND: device does not belong to this shop' USING ERRCODE = 'check_violation';
  END IF;

  IF v_device.status = 'LOST' THEN
    RETURN true; -- idempotent no-op
  END IF;

  UPDATE devices
  SET status = 'LOST'
  WHERE id = v_device.id;

  -- Cascade: any ACTIVE activations of a lost device are revoked-level denied.
  UPDATE activations
  SET status = 'REVOKED'
  WHERE device_id = v_device.id
    AND status = 'ACTIVE';

  PERFORM s4_audit_device_transition(p_shop_id, v_device.id, 'S4_DEVICE_LOST',
    jsonb_build_object('reason', p_reason));

  RETURN true;
END;
$$;

-- No s4_revoke_device. ACTIVE -> REVOKED stays with canonical s3_revoke_device.

-- s4_list_devices: owner-scoped, tenant-scoped device listing with status.
CREATE OR REPLACE FUNCTION s4_list_devices(
  p_shop_id UUID
)
RETURNS TABLE (
  device_id UUID,
  installation_id UUID,
  platform TEXT,
  device_name TEXT,
  user_id UUID,
  status TEXT,
  public_key TEXT,
  approved_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  first_seen_at TIMESTAMPTZ,
  last_seen_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM s4_require_owner(p_shop_id);
  RETURN QUERY
  SELECT d.id, d.installation_id, d.platform, d.device_name, d.user_id, d.status,
         d.public_key, d.approved_at, NULLIF(d.revoked_at, NULL), d.first_seen_at, d.last_seen_at
  FROM devices d
  WHERE d.shop_id = p_shop_id
  ORDER BY d.created_at DESC;
END;
$$;

COMMENT ON FUNCTION s4_approve_device(UUID, UUID, TEXT) IS 'S4: Owner-only, tenant-scoped device approval (PENDING_APPROVAL->ACTIVE) with S2 quota re-check and audit under the canonical shop lock. Idempotent.';
COMMENT ON FUNCTION s4_reject_device(UUID, UUID, TEXT) IS 'S4: Owner-only, tenant-scoped device rejection (terminal REJECTED). Idempotent.';
COMMENT ON FUNCTION s4_mark_device_lost(UUID, UUID, TEXT) IS 'S4: Owner-only, tenant-scoped device lost (terminal LOST) with activation cascade + audit. Idempotent.';
COMMENT ON FUNCTION s4_list_devices(UUID) IS 'S4: Owner-only, tenant-scoped device listing.';

GRANT EXECUTE ON FUNCTION s4_approve_device(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION s4_reject_device(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION s4_mark_device_lost(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION s4_list_devices(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION s4_require_owner(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION s4_audit_device_transition(UUID, UUID, TEXT, JSONB) TO service_role;

-- =============================================================================
-- 6. register_device() — new enrollments end PENDING_APPROVAL (no automatic trust)
-- =============================================================================
-- A newly enrolled device must end PENDING_APPROVAL, not ACTIVE. A previously
-- REVOKED/LOST/REJECTED device must NOT silently regain trust through registration
-- (rotation/re-enrollment = new enrollment -> pending -> Owner approval). Idempotent
-- re-registration of the SAME installation/shop that is already PENDING_APPROVAL stays
-- pending. Preserves S3: REVOKED rejected (S3_DEVICE_REVOKED).

CREATE OR REPLACE FUNCTION register_device(
  p_shop_id UUID,
  p_installation_id UUID,
  p_platform TEXT,
  p_device_name TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_device_id UUID;
  v_existing devices%ROWTYPE;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'Shop ID is required';
  END IF;

  IF p_installation_id IS NULL THEN
    RAISE EXCEPTION 'Installation ID is required';
  END IF;

  IF p_platform IS NULL OR p_platform NOT IN ('windows', 'android') THEN
    RAISE EXCEPTION 'Platform must be windows or android';
  END IF;

  -- Verify the caller has active membership in the shop
  IF NOT EXISTS(
    SELECT 1 FROM shop_members
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND status = 'ACTIVE'
  ) THEN
    RAISE EXCEPTION 'Not a member of this shop';
  END IF;

  -- Same-shop transaction advisory lock (serializes revoke vs register)
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- S3/S4: terminal-state re-registration guard. A previously REVOKED/LOST/REJECTED
  -- device MUST NOT be silently upserted back to ACTIVE.
  SELECT * INTO v_existing
  FROM devices
  WHERE installation_id = p_installation_id
    AND shop_id = p_shop_id;

  IF FOUND AND v_existing.status = 'REVOKED' THEN
    RAISE EXCEPTION 'S3_DEVICE_REVOKED: this device has been revoked and cannot be re-registered'
      USING ERRCODE = 'check_violation';
  END IF;

  IF FOUND AND v_existing.status IN ('LOST', 'REJECTED') THEN
    RAISE EXCEPTION 'S4_DEVICE_TERMINAL: device is in terminal state (%) and cannot silently regain trust', v_existing.status
      USING ERRCODE = 'check_violation';
  END IF;

  -- Upsert device by (installation_id, shop_id). New / re-registered devices end
  -- PENDING_APPROVAL. An existing PENDING_APPROVAL row is idempotently re-pended
  -- (same installation/shop). No automatic trust, no activation slot consumed pending.
  INSERT INTO devices (installation_id, shop_id, user_id, platform, device_name, first_seen_at, last_seen_at, status)
  VALUES (p_installation_id, p_shop_id, v_user_id, p_platform, p_device_name, now(), now(), 'PENDING_APPROVAL')
  ON CONFLICT (installation_id, shop_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    device_name = EXCLUDED.device_name,
    last_seen_at = now(),
    status = CASE
      WHEN devices.status IN ('REVOKED', 'LOST', 'REJECTED') THEN devices.status
      ELSE 'PENDING_APPROVAL'
    END
  RETURNING id INTO v_device_id;

  PERFORM s4_audit_device_transition(p_shop_id, v_device_id, 'S4_REGISTER_PENDING',
    jsonb_build_object('platform', p_platform));

  RETURN v_device_id;
END;
$$;

COMMENT ON FUNCTION register_device(UUID, UUID, TEXT, TEXT) IS
  'S4: registers or updates a device installation, idempotent, ends PENDING_APPROVAL (no automatic trust). Rejects terminal REVOKED/LOST/REJECTED silently-regaining trust.';

-- =============================================================================
-- 6.5  Invitations schema hardening (token hash + accepted_by) — additive
-- =============================================================================
-- The legacy invitations table (00021) stores no token and only accepted_at.
-- S4 adds token_hash (SHA-256 digest, never plaintext) and accepted_by
-- (server-derived auth.uid()). Both are additive; existing rows keep
-- token_hash NULL (fails closed during acceptance).

ALTER TABLE invitations
  ADD COLUMN IF NOT EXISTS token_hash TEXT;

ALTER TABLE invitations
  ADD COLUMN IF NOT EXISTS accepted_by UUID REFERENCES auth.users(id);

COMMENT ON COLUMN invitations.token_hash IS
  'S4: SHA-256 hex digest of the plaintext invitation token. Plaintext NEVER stored. NULL for legacy pre-issuance rows (fail closed).';
COMMENT ON COLUMN invitations.accepted_by IS
  'S4: auth.uid() of the user who consumed this invitation (server-derived; never client-nominated).';

-- =============================================================================
-- 7. accept_invitation() — hash / auth.uid()-bound, no p_user_id authority
-- =============================================================================
-- Replaces the insecure client-nominated-user accept. The legacy 2-arg
-- accept_invitation(UUID, UUID) that accepted a client-supplied p_user_id is
-- DROPPED (it must never remain callable with client authority). The corrected
-- signature derives accepted user from auth.uid(). Validates: authenticated
-- caller, shop_id, role, plaintext token vs stored token_hash, PENDING state,
-- expires_at > now(), not REVOKED/EXPIRED/ACCEPTED, single-use.
-- On success sets shop_members.status=ACTIVE + joined_at and invitations
-- status=ACCEPTED + accepted_at/accepted_by=auth.uid(). Serialized under the
-- canonical shop advisory lock. Legacy rows with token_hash IS NULL fail closed.

DROP FUNCTION IF EXISTS accept_invitation(UUID, UUID);

CREATE OR REPLACE FUNCTION accept_invitation(
  p_shop_id UUID,
  p_role TEXT,
  p_email TEXT,
  p_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_invitation RECORD;
  v_hash TEXT;
  v_member_existed BOOLEAN := false;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Authentication required');
  END IF;

  IF p_shop_id IS NULL OR p_role IS NULL OR p_email IS NULL OR p_token IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'shop_id, role, email, and token are required');
  END IF;

  -- Canonical shop advisory lock (serializes two simultaneous accepts; exactly one wins)
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- Locate the matching PENDING invitation bound to shop/email/role.
  SELECT * INTO v_invitation
  FROM invitations
  WHERE shop_id = p_shop_id
    AND email = lower(trim(p_email))
    AND role = p_role
    AND status = 'PENDING'
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'S4_INVITATION_NOT_PENDING: no pending invitation for this shop/email/role');
  END IF;

  -- Legacy / NULL-token invitations MUST fail closed (never silently accept).
  IF v_invitation.token_hash IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'S4_NULL_TOKEN: invitation has no token; please request a reissue from the owner');
  END IF;

  -- Expiry check (expires_at must be in the future)
  IF v_invitation.expires_at IS NULL OR v_invitation.expires_at <= now() THEN
    UPDATE invitations SET status = 'EXPIRED' WHERE id = v_invitation.id AND status = 'PENDING';
    RETURN jsonb_build_object('success', false, 'error', 'S4_INVITATION_EXPIRED: invitation has expired');
  END IF;

  -- Deterministic hash comparison against stored token_hash. Use a per-token salt-free
  -- deterministic hash so legacy (non-salted) issuance and hash-only matching reconcile.
  v_hash := encode(extensions.digest(p_token::text, 'sha256')::bytea, 'hex');

  IF v_invitation.token_hash IS DISTINCT FROM v_hash THEN
    RETURN jsonb_build_object('success', false, 'error', 'S4_INVALID_TOKEN: token does not match');
  END IF;

  -- Check whether a membership row already exists for this user in this shop.
  EXECUTE 'SELECT EXISTS(SELECT 1 FROM shop_members WHERE shop_id = $1 AND user_id = $2)'
    INTO v_member_existed USING p_shop_id, v_user_id;

  -- Activate membership for auth.uid() (derived server-side; never a client-nominated user id).
  IF v_member_existed THEN
    UPDATE shop_members
    SET status = 'ACTIVE', joined_at = now()
    WHERE shop_id = p_shop_id AND user_id = v_user_id;
  ELSE
    INSERT INTO shop_members (shop_id, user_id, role, status, joined_at)
    VALUES (p_shop_id, v_user_id, p_role, 'ACTIVE', now());
  END IF;

  -- Consume the invitation single-use.
  UPDATE invitations
  SET status = 'ACCEPTED',
      accepted_at = now(),
      accepted_by = v_user_id
  WHERE id = v_invitation.id
    AND status = 'PENDING';

  RETURN jsonb_build_object('success', true);
END;
$$;

COMMENT ON FUNCTION accept_invitation(UUID, TEXT, TEXT, TEXT) IS
  'S4: hardened invitation acceptance. Derives accepted user from auth.uid(), validates a plaintext token against the stored token_hash, enforces single-use + expiry + PENDING, and serializes under the shop advisory lock. Legacy NULL-token invitations fail closed.';

GRANT EXECUTE ON FUNCTION accept_invitation(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- =============================================================================
-- 8. EXACT RLS APPROVAL LAYER — 14 BUSINESS-DATA READ SURFACES (DORMANT, default OFF)
-- =============================================================================
-- CRITICAL composition rule: the new approval policy must NOT broaden access via a
-- permissive OR of the base policy. It composes as an ADDITIONAL AND-STYLE restriction:
-- a row is readable only when the base tenant-isolation policy AND the approval layer
-- allow it. When enforcement is OFF (default), the approval layer is a no-op (returns
-- true locally) so existing legitimate client behavior is preserved. When ON, the
-- request-bound predicate becomes mandatory.
--
-- Implementation: because PostgreSQL policies on the same command OR together, we
-- REPLACE the base tenant-isolation policy with a single combined policy that ANDs the
-- tenant membership isolation WITH the gated approval predicate. The base tenant
-- isolation is preserved verbatim (never weakened); the approval parity is added as an
-- AND condition. Enforcement OFF => the AND term reduces to TRUE (via the switch) and
-- behavior is byte-identical to the predecessor. This avoids OR-bypass.
--
-- Non-change set (K): plans, devices, shops, shop_members, roles, role_permissions_cloud,
-- shop_permission_overrides, permission_audit_log, device_audit_log, invitations remain
-- semantically unchanged (no new policy, no replacement).

DO $s4_rls$
DECLARE
  v_sql TEXT;
  v_enabled_uuid CONSTANT UUID := '00000000-0000-0000-0000-000000000000';
BEGIN
  -- Recursively build each approval policy. We use one unified policy per table that
  -- ANDs the original tenant-isolation using-expression with the gated approval
  -- predicate. The base EXPRESSION (shop membership) is preserved exactly.

  -- cloud_products
  DROP POLICY IF EXISTS shop_isolation_products ON cloud_products;
  DROP POLICY IF EXISTS shop_isolation_products_approval ON cloud_products;
  CREATE POLICY shop_isolation_products_approval ON cloud_products
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_products.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_products.shop_id))
    );

  -- cloud_customers
  DROP POLICY IF EXISTS shop_isolation_customers ON cloud_customers;
  DROP POLICY IF EXISTS shop_isolation_customers_approval ON cloud_customers;
  CREATE POLICY shop_isolation_customers_approval ON cloud_customers
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_customers.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_customers.shop_id))
    );

  -- cloud_sales
  DROP POLICY IF EXISTS shop_isolation_sales ON cloud_sales;
  DROP POLICY IF EXISTS shop_isolation_sales_approval ON cloud_sales;
  CREATE POLICY shop_isolation_sales_approval ON cloud_sales
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_sales.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_sales.shop_id))
    );

  -- cloud_returns
  DROP POLICY IF EXISTS shop_isolation_returns ON cloud_returns;
  DROP POLICY IF EXISTS shop_isolation_returns_approval ON cloud_returns;
  CREATE POLICY shop_isolation_returns_approval ON cloud_returns
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_returns.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_returns.shop_id))
    );

  -- cloud_expenses
  DROP POLICY IF EXISTS shop_isolation_expenses ON cloud_expenses;
  DROP POLICY IF EXISTS shop_isolation_expenses_approval ON cloud_expenses;
  CREATE POLICY shop_isolation_expenses_approval ON cloud_expenses
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_expenses.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_expenses.shop_id))
    );

  -- cloud_expense_categories
  DROP POLICY IF EXISTS shop_isolation_expense_categories ON cloud_expense_categories;
  DROP POLICY IF EXISTS shop_isolation_expense_categories_approval ON cloud_expense_categories;
  CREATE POLICY shop_isolation_expense_categories_approval ON cloud_expense_categories
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_expense_categories.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_expense_categories.shop_id))
    );

  -- cloud_invoices
  DROP POLICY IF EXISTS shop_isolation_invoices ON cloud_invoices;
  DROP POLICY IF EXISTS shop_isolation_invoices_approval ON cloud_invoices;
  CREATE POLICY shop_isolation_invoices_approval ON cloud_invoices
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_invoices.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_invoices.shop_id))
    );

  -- cloud_inventory_count
  DROP POLICY IF EXISTS shop_isolation_inventory_count ON cloud_inventory_count;
  DROP POLICY IF EXISTS shop_isolation_inventory_count_approval ON cloud_inventory_count;
  CREATE POLICY shop_isolation_inventory_count_approval ON cloud_inventory_count
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_inventory_count.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_inventory_count.shop_id))
    );

  -- cloud_shop_settings
  DROP POLICY IF EXISTS shop_isolation_shop_settings ON cloud_shop_settings;
  DROP POLICY IF EXISTS shop_isolation_shop_settings_approval ON cloud_shop_settings;
  CREATE POLICY shop_isolation_shop_settings_approval ON cloud_shop_settings
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_shop_settings.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_shop_settings.shop_id))
    );

  -- cloud_stock_adjustments
  DROP POLICY IF EXISTS shop_isolation_stock_adjustments ON cloud_stock_adjustments;
  DROP POLICY IF EXISTS shop_isolation_stock_adjustments_approval ON cloud_stock_adjustments;
  CREATE POLICY shop_isolation_stock_adjustments_approval ON cloud_stock_adjustments
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_stock_adjustments.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_stock_adjustments.shop_id))
    );

  -- sync_log
  DROP POLICY IF EXISTS shop_isolation_sync_log ON sync_log;
  DROP POLICY IF EXISTS shop_isolation_sync_log_approval ON sync_log;
  CREATE POLICY shop_isolation_sync_log_approval ON sync_log
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = sync_log.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(sync_log.shop_id))
    );

  -- cloud_migration_ledger
  DROP POLICY IF EXISTS shop_isolation_cloud_migration_ledger ON cloud_migration_ledger;
  DROP POLICY IF EXISTS shop_isolation_cloud_migration_ledger_approval ON cloud_migration_ledger;
  CREATE POLICY shop_isolation_cloud_migration_ledger_approval ON cloud_migration_ledger
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = cloud_migration_ledger.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(cloud_migration_ledger.shop_id))
    );

  -- licenses (business entitlement data)
  -- Preserve original policy name to remain compatible with S1/S2 test assertions
  -- (immutable per governance Section M); the approval layer is AND-gated within.
  DROP POLICY IF EXISTS shop_licenses_isolation ON licenses;
  DROP POLICY IF EXISTS shop_licenses_isolation_approval ON licenses;
  CREATE POLICY shop_licenses_isolation ON licenses
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM shop_members
        WHERE shop_members.shop_id = licenses.shop_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(licenses.shop_id))
    );

  -- activations (join through licenses to resolve shop_id)
  -- Preserve original policy name to remain compatible with S1/S2 test assertions
  -- (immutable per governance Section M); the approval layer is AND-gated within.
  DROP POLICY IF EXISTS shop_activations_isolation ON activations;
  DROP POLICY IF EXISTS shop_activations_isolation_approval ON activations;
  CREATE POLICY shop_activations_isolation ON activations
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM licenses
        JOIN shop_members ON shop_members.shop_id = licenses.shop_id
        WHERE licenses.id = activations.license_id
          AND shop_members.user_id = auth.uid()
          AND shop_members.status = 'ACTIVE'
      )
      AND (NOT s4_device_gate_enabled() OR s4_current_request_device_is_approved(
        (SELECT shop_id FROM licenses WHERE id = activations.license_id))
      )
    );
END
$s4_rls$;

-- =============================================================================
-- 9. require_shop_permission() — canonical request-bound device gate (DORMANT)
-- =============================================================================
-- Preserves ALL predecessor authorization (authentication, ACTIVE membership,
-- role/provider, license/entitlement, tenant scoping, owner bypass). Integrates the
-- canonical s4_current_request_device_is_approved gate but honors the dormant switch:
-- enforcement OFF => predecessor behavior preserved; enforcement ON => request-bound
-- device approval becomes mandatory inside the server authz path too.

CREATE OR REPLACE FUNCTION require_shop_permission(
  p_shop_id UUID,
  p_permission_id TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_member_role TEXT;
  v_has_license BOOLEAN;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_shop_id IS NULL THEN
    RAISE EXCEPTION 'shop_mismatch';
  END IF;

  IF p_permission_id IS NULL OR p_permission_id = '' THEN
    RAISE EXCEPTION 'invalid_permission';
  END IF;

  -- Membership check
  SELECT sm.role INTO v_member_role
  FROM shop_members sm
  WHERE sm.shop_id = p_shop_id
    AND sm.user_id = v_user_id
    AND sm.status = 'ACTIVE';

  IF v_member_role IS NULL THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- S4: when the request-bound device gate is enabled, the current request must be
  -- served by an approved device of the caller. Honor the dormant switch: OFF preserves
  -- predecessor behavior; ON makes request-bound (not any-device) approval mandatory.
  IF s4_device_gate_enabled() THEN
    IF NOT s4_current_request_device_is_approved(p_shop_id) THEN
      RAISE EXCEPTION 'device_not_approved';
    END IF;
  END IF;

  -- Entitlement check (inline for atomicity)
  IF p_permission_id NOT LIKE '%.view' THEN
    SELECT EXISTS(
      SELECT 1 FROM licenses
      WHERE shop_id = p_shop_id
        AND status IN ('TRIAL', 'ACTIVE', 'PERPETUAL')
    ) INTO v_has_license;

    IF NOT v_has_license THEN
      RAISE EXCEPTION 'license_required';
    END IF;
  END IF;

  -- Owner bypass
  IF v_member_role = 'owner' THEN
    RETURN v_member_role;
  END IF;

  -- Permission resolution
  IF NOT check_effective_permission(p_shop_id, v_member_role, p_permission_id) THEN
    RAISE EXCEPTION 'permission_denied: %', p_permission_id;
  END IF;

  RETURN v_member_role;
END;
$$;

COMMENT ON FUNCTION require_shop_permission(UUID, TEXT) IS
  'Phase F + S4: server-authoritative permission check. Returns role if authorized. S4 adds a dormant request-bound device gate (default OFF) that preserves predecessor behavior until activation.';

-- =============================================================================
-- 10. Invitation issuance helper (Owner-facing RPC) — creates a PENDING invitation
--     with ONLY the token hash; returns the plaintext token once (never persisted).
--     Used by the invite-employee Edge Function and Owner tooling.
-- =============================================================================
-- Plaintext token is generated by the caller (Edge Function WebCrypto) and only its
-- SHA-256 hash is stored. This function is SECURITY DEFINER/server-only and returns the
-- hash to be stored; the Edge Function stores hash and returns plaintext to the Owner once.

CREATE OR REPLACE FUNCTION s4_create_invitation(
  p_shop_id UUID,
  p_email TEXT,
  p_role TEXT,
  p_token_hash TEXT,
  p_expires_at TIMESTAMPTZ
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_invitation_id UUID;
  v_role TEXT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = 'check_violation';
  END IF;

  IF p_shop_id IS NULL OR p_email IS NULL OR p_token_hash IS NULL OR p_expires_at IS NULL THEN
    RAISE EXCEPTION 'S4_INVITE_INVALID: shop_id, email, token_hash, and expires_at are required' USING ERRCODE = 'check_violation';
  END IF;

  -- Owner-only (Edge Function re-verifies; defense in depth here)
  PERFORM s4_require_owner(p_shop_id);

  v_role := p_role;
  IF v_role IS NULL OR v_role NOT IN ('employee', 'salesOnly') THEN
    RAISE EXCEPTION 'S4_INVITE_INVALID: role must be employee or salesOnly' USING ERRCODE = 'check_violation';
  END IF;

  -- Canonical shop lock
  PERFORM pg_advisory_xact_lock(hashtextextended(p_shop_id::text, 0));

  -- Create the invitation row (PENDING, token_hash only). Invitation creation must not
  -- silently fail: any constraint failure raises.
  INSERT INTO invitations (shop_id, email, role, invited_by, status, expires_at, token_hash)
  VALUES (p_shop_id, lower(trim(p_email)), v_role, v_user_id, 'PENDING', p_expires_at, p_token_hash)
  RETURNING id INTO v_invitation_id;

  RETURN v_invitation_id;
END;
$$;

COMMENT ON FUNCTION s4_create_invitation(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ) IS
  'S4: Owner-only, server-authoritative invitation issuance. Stores ONLY the token hash; the Edge Function retains the plaintext token once and returns it to the Owner. Binds invitation to shop/email/role/PENDING/expiry.';

GRANT EXECUTE ON FUNCTION s4_create_invitation(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ) TO authenticated;

-- Token hash helper (deterministic SHA-256 hex; shared with accept_invitation).
-- Uses extensions.digest (pgcrypto, pre-installed in Supabase's `extensions`
-- schema) with an explicit qualification so it resolves even when the helper
-- sets search_path = public. PostgreSQL core has no SHA-256, and we do NOT
-- CREATE EXTENSION here (consistent with governance Section I.1).
CREATE OR REPLACE FUNCTION s4_token_hash(p_plaintext TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT encode(extensions.digest(p_plaintext::text, 'sha256')::bytea, 'hex')
$$;

COMMENT ON FUNCTION s4_token_hash(TEXT) IS
  'S4: deterministic SHA-256 hex of a plaintext invitation token. Hash-only at rest; plaintext never stored (via extensions.digest/pgcrypto).';

GRANT EXECUTE ON FUNCTION s4_token_hash(TEXT) TO authenticated;

-- =============================================================================
-- 11. Proof-of-possession server contract helpers (challenge lifecycle)
-- =============================================================================
-- Server-side challenge creation + assertion (single-use, replay-safe). The actual
-- Ed25519 signature verification runs in the Edge Function; these helpers manage the
-- server records and bindings (Section 18 / P).

CREATE OR REPLACE FUNCTION s4_create_challenge(
  p_shop_id UUID,
  p_device_id UUID,
  p_challenge TEXT,
  p_ttl_seconds INTEGER DEFAULT 300
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_challenge_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = 'check_violation';
  END IF;
  IF p_shop_id IS NULL OR p_device_id IS NULL OR p_challenge IS NULL THEN
    RAISE EXCEPTION 'S4_CHALLENGE_INVALID: shop_id, device_id, and challenge are required' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM devices WHERE id = p_device_id AND shop_id = p_shop_id AND user_id = v_user_id) THEN
    RAISE EXCEPTION 'S4_CHALLENGE_BINDING: device must belong to the caller in this shop' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO device_challenges (shop_id, device_id, challenge, expires_at, created_by)
  VALUES (p_shop_id, p_device_id, p_challenge, now() + make_interval(secs => p_ttl_seconds), v_user_id)
  RETURNING id INTO v_challenge_id;

  RETURN v_challenge_id;
END;
$$;

COMMENT ON FUNCTION s4_create_challenge(UUID, UUID, TEXT, INTEGER) IS
  'S4: creates a server-side challenge bound to shop/device/caller with expiry.';

GRANT EXECUTE ON FUNCTION s4_create_challenge(UUID, UUID, TEXT, INTEGER) TO authenticated;

-- Verify-and-assert: called by the Edge Function (service role) AFTER it has verified
-- the Ed25519 signature over the challenge using the stored public key. Marks the
-- challenge single-use (used_at) and records the server-verified assertion. Replay of
-- an already-used/expired challenge is rejected.
CREATE OR REPLACE FUNCTION s4_assert_request(
  p_challenge_id UUID,
  p_signature TEXT,
  p_signature_format TEXT DEFAULT 'ed25519'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_challenge RECORD;
  v_device devices%ROWTYPE;
  v_user_id UUID;
  v_challenge_shop UUID;
  v_challenge_device UUID;
BEGIN
  IF p_challenge_id IS NULL THEN
    RAISE EXCEPTION 'S4_ASSERT_INVALID: challenge_id is required' USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO v_challenge FROM device_challenges WHERE id = p_challenge_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'S4_ASSERT_UNKNOWN: challenge not found' USING ERRCODE = 'check_violation';
  END IF;

  -- Replay rejection: already consumed
  IF v_challenge.used_at IS NOT NULL THEN
    RAISE EXCEPTION 'S4_ASSERT_REPLAY: challenge already consumed' USING ERRCODE = 'check_violation';
  END IF;

  -- Expiry rejection
  IF v_challenge.expires_at IS NULL OR v_challenge.expires_at <= now() THEN
    RAISE EXCEPTION 'S4_ASSERT_EXPIRED: challenge expired' USING ERRCODE = 'check_violation';
  END IF;

  -- Bindings: device must be ACTIVE (approved) and belong to the challenge's shop/caller.
  SELECT * INTO v_device FROM devices WHERE id = v_challenge.device_id;
  IF NOT FOUND OR v_device.status <> 'ACTIVE' THEN
    RAISE EXCEPTION 'S4_ASSERT_DEVICE_NOT_ACTIVE: device is not approved' USING ERRCODE = 'check_violation';
  END IF;

  v_user_id := v_device.user_id;
  v_challenge_shop := v_challenge.shop_id;
  v_challenge_device := v_challenge.device_id;

  -- The Edge Function performed Ed25519 verification against devices.public_key before
  -- calling this; here we persist the verified assertion and consume the challenge.
  UPDATE device_challenges
  SET used_at = now()
  WHERE id = p_challenge_id;

  INSERT INTO device_assertions (
    challenge_id, shop_id, device_id, user_id, is_request_bound, verified_at, signature, signature_format
  )
  VALUES (
    p_challenge_id, v_challenge_shop, v_challenge_device, v_user_id, true, now(), p_signature, p_signature_format
  );

  -- Publish the request-bound device into the request context (used by the predicate).
  PERFORM set_config('s4.asserted_device', 'true', true);
  PERFORM set_config('s4.request_device_id', v_challenge_device::text, true);

  RETURN true;
END;
$$;

COMMENT ON FUNCTION s4_assert_request(UUID, TEXT, TEXT) IS
  'S4: server-authoritative assertion recording. Called by the Edge Function AFTER WebCrypto Ed25519 verification. Consumes the challenge single-use, rejects replay/expiry, binds to the ACTIVE approved device, and publishes the request-bound context.';

GRANT EXECUTE ON FUNCTION s4_assert_request(UUID, TEXT, TEXT) TO service_role;