-- Phase C Migration 01: Create shop_members table
-- shop_members: user-tenant membership — maps users to shops with roles
--
-- A user can belong to multiple shops but can only have one membership per shop.
-- The role field uses CHECK constraints matching the 3 local roles: owner, employee, salesOnly.
-- The status field tracks the membership lifecycle: INVITED -> ACTIVE -> SUSPENDED/REVOKED.

CREATE TABLE shop_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'employee', 'salesOnly')),
  status TEXT NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED')),
  invited_at TIMESTAMPTZ,
  joined_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(shop_id, user_id)
);

COMMENT ON TABLE shop_members IS 'User-tenant membership — maps authenticated users to shops with roles and status';
COMMENT ON COLUMN shop_members.shop_id IS 'FK to shops — the shop this membership belongs to (CASCADE DELETE)';
COMMENT ON COLUMN shop_members.user_id IS 'FK to auth.users — the user who holds this membership';
COMMENT ON COLUMN shop_members.role IS 'Role within the shop: owner, employee, or salesOnly';
COMMENT ON COLUMN shop_members.status IS 'Membership status: INVITED, ACTIVE, SUSPENDED, or REVOKED';
COMMENT ON COLUMN shop_members.invited_at IS 'Timestamp when the user was invited to the shop';
COMMENT ON COLUMN shop_members.joined_at IS 'Timestamp when the user accepted the invitation';

-- Index on shop_id for efficient lookup of all members of a shop
CREATE INDEX idx_shop_members_shop_id ON shop_members(shop_id);

-- Index on user_id for efficient lookup of all shops a user belongs to
CREATE INDEX idx_shop_members_user_id ON shop_members(user_id);

-- Composite index for the common query: find membership for a specific user in a specific shop
CREATE INDEX idx_shop_members_shop_user ON shop_members(shop_id, user_id);
