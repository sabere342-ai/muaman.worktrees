-- Phase C Migration 00: Create shops table
-- shops: tenant identity — source of truth for multi-tenancy
--
-- Each shop represents a single store/tenant in the system.
-- The owner_user_id links to Supabase Auth users.
-- settings is a JSONB column for flexible per-shop configuration.

CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  settings JSONB DEFAULT '{}'::jsonb
);

COMMENT ON TABLE shops IS 'Tenant identity — each row represents one store managed by I Tech';
COMMENT ON COLUMN shops.id IS 'Cloud UUID primary key, generated via gen_random_uuid()';
COMMENT ON COLUMN shops.name IS 'Display name of the shop, set by the owner during creation';
COMMENT ON COLUMN shops.owner_user_id IS 'FK to auth.users — the account that owns this shop';
COMMENT ON COLUMN shops.settings IS 'Flexible JSONB configuration for per-shop settings';

-- Index on owner_user_id for efficient lookup of shops owned by a user
CREATE INDEX idx_shops_owner_user_id ON shops(owner_user_id);

-- Index on updated_at for sync/diff queries
CREATE INDEX idx_shops_updated_at ON shops(updated_at);
