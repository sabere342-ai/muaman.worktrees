-- Phase C Migration 05: Create licenses table
-- licenses: shop-scoped licensing
--
-- Each shop has one license record tracking its subscription/trial state.
-- The license_key is a unique human-readable identifier.
-- Status tracks the licensing lifecycle: TRIAL -> ACTIVE -> EXPIRED/SUSPENDED/PERPETUAL.
-- Trial dates are managed by server-side functions (start_trial, verify_trial_status).

CREATE TABLE licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  license_key TEXT UNIQUE NOT NULL,
  plan TEXT,
  status TEXT NOT NULL DEFAULT 'TRIAL'
    CHECK (status IN ('TRIAL', 'ACTIVE', 'EXPIRED', 'SUSPENDED', 'PERPETUAL')),
  trial_started_at TIMESTAMPTZ,
  trial_expires_at TIMESTAMPTZ,
  activated_at TIMESTAMPTZ,
  subscription_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE licenses IS 'Shop-scoped licensing — tracks subscription and trial state per shop';
COMMENT ON COLUMN licenses.shop_id IS 'FK to shops — the shop this license belongs to (CASCADE DELETE)';
COMMENT ON COLUMN licenses.license_key IS 'Unique human-readable license identifier';
COMMENT ON COLUMN licenses.plan IS 'Subscription plan name (nullable until plan is assigned)';
COMMENT ON COLUMN licenses.status IS 'License status: TRIAL, ACTIVE, EXPIRED, SUSPENDED, or PERPETUAL';
COMMENT ON COLUMN licenses.trial_started_at IS 'Server timestamp when the trial period began';
COMMENT ON COLUMN licenses.trial_expires_at IS 'Server timestamp when the trial period expires';
COMMENT ON COLUMN licenses.activated_at IS 'Server timestamp when the license was activated';
COMMENT ON COLUMN licenses.subscription_expires_at IS 'Server timestamp when the subscription expires';

-- Index on shop_id for efficient lookup of a shop's license
CREATE INDEX idx_licenses_shop_id ON licenses(shop_id);

-- Index on license_key for direct lookup by key
CREATE INDEX idx_licenses_license_key ON licenses(license_key);
