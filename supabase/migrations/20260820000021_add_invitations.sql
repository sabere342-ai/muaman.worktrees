-- Phase D Migration 21: Invitations table
-- Tracks employee invitations issued by shop owners.
--
-- Phase dependency: D (cloud auth & membership)
-- Rationale: The Edge Function `invite-employee` creates invitation records
-- that owners can later review. The table is additive only — no Phase C
-- objects are modified.

-- =============================================================================
-- invitations table
-- =============================================================================

CREATE TABLE IF NOT EXISTS invitations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('employee', 'salesOnly')),
  invited_by UUID REFERENCES auth.users(id),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL
);

-- Index for fast lookup by shop + email
CREATE INDEX IF NOT EXISTS idx_invitations_shop_email ON invitations (shop_id, email);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON invitations (status);

-- =============================================================================
-- RLS policies for invitations
-- =============================================================================

ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- Policy: Shop owners can view invitations for their shops
CREATE POLICY shop_owner_invitations_select ON invitations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = invitations.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.role = 'owner'
        AND shop_members.status = 'ACTIVE'
    )
  );

-- INSERT/UPDATE/DELETE: service-role only (Edge Function uses service-role)
