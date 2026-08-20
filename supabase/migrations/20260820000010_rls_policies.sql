-- Phase C Migration 10: Row-Level Security policies
-- Implements shop-isolation RLS on all 7 cloud tables.
--
-- Security model:
--   - RLS is enabled on all 7 tables (fail-closed by default)
--   - Unauthenticated users have NO access to any table
--   - Authenticated users can only access rows belonging to shops they are a member of
--   - Shop membership is verified via the shop_members table
--   - Only ACTIVE memberships grant access
--   - INSERT/UPDATE/DELETE on all tables are restricted to service_role only
--     (server functions handle mutations via SECURITY DEFINER)
--   - Owner access is not separately distinguished in RLS;
--     the owner is a member with role='owner' in shop_members

-- =============================================================================
-- shops table
-- =============================================================================

ALTER TABLE shops ENABLE ROW LEVEL SECURITY;

-- Policy: shop_isolation
-- Authenticated users can read shops where they are an ACTIVE member.
CREATE POLICY shop_isolation ON shops
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = shops.id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- INSERT/UPDATE/DELETE: service_role only (no client-side policies = denied)

-- =============================================================================
-- shop_members table
-- =============================================================================

ALTER TABLE shop_members ENABLE ROW LEVEL SECURITY;

-- Policy: shop_member_isolation
-- Authenticated users can read membership records for shops they belong to.
CREATE POLICY shop_member_isolation ON shop_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members sm
      WHERE sm.shop_id = shop_members.shop_id
        AND sm.user_id = auth.uid()
        AND sm.status = 'ACTIVE'
    )
  );

-- INSERT/UPDATE/DELETE: service_role only

-- =============================================================================
-- roles table
-- =============================================================================

ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- Policy: shop_roles_isolation
-- Authenticated users can read roles for shops they belong to.
CREATE POLICY shop_roles_isolation ON roles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = roles.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- INSERT/UPDATE/DELETE: service_role only

-- =============================================================================
-- role_permissions_cloud table
-- =============================================================================

ALTER TABLE role_permissions_cloud ENABLE ROW LEVEL SECURITY;

-- Policy: shop_role_permissions_isolation
-- Authenticated users can read permission assignments for roles in shops they belong to.
-- Requires a join through roles to resolve shop_id.
CREATE POLICY shop_role_permissions_isolation ON role_permissions_cloud
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM roles
      JOIN shop_members ON shop_members.shop_id = roles.shop_id
      WHERE roles.id = role_permissions_cloud.role_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- INSERT/UPDATE/DELETE: service_role only

-- =============================================================================
-- devices table
-- =============================================================================

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

-- Policy: shop_devices_isolation
-- Authenticated users can read devices registered to shops they belong to.
CREATE POLICY shop_devices_isolation ON devices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = devices.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- INSERT/UPDATE/DELETE: service_role only

-- =============================================================================
-- licenses table
-- =============================================================================

ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;

-- Policy: shop_licenses_isolation
-- Authenticated users can read licenses for shops they belong to.
CREATE POLICY shop_licenses_isolation ON licenses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM shop_members
      WHERE shop_members.shop_id = licenses.shop_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- INSERT/UPDATE/DELETE: service_role only

-- =============================================================================
-- activations table
-- =============================================================================

ALTER TABLE activations ENABLE ROW LEVEL SECURITY;

-- Policy: shop_activations_isolation
-- Authenticated users can read activations for licenses belonging to shops they belong to.
-- Requires a join through licenses to resolve shop_id.
CREATE POLICY shop_activations_isolation ON activations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM licenses
      JOIN shop_members ON shop_members.shop_id = licenses.shop_id
      WHERE licenses.id = activations.license_id
        AND shop_members.user_id = auth.uid()
        AND shop_members.status = 'ACTIVE'
    )
  );

-- INSERT/UPDATE/DELETE: service_role only
