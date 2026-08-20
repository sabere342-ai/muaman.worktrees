-- Phase C Migration 03: Create role_permissions_cloud table
-- role_permissions_cloud: per-shop permission assignments
--
-- Each row maps a single permission to a role within a shop.
-- permission_id uses the same stable IDs as the local AppPermission enum
-- (e.g., 'dashboard.view', 'inventory.edit', 'sales.create').
-- The UNIQUE(role_id, permission_id) constraint prevents duplicate assignments.

CREATE TABLE role_permissions_cloud (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(role_id, permission_id)
);

COMMENT ON TABLE role_permissions_cloud IS 'Per-shop permission assignments — maps permission IDs to roles';
COMMENT ON COLUMN role_permissions_cloud.role_id IS 'FK to roles — the role this permission is assigned to (CASCADE DELETE)';
COMMENT ON COLUMN role_permissions_cloud.permission_id IS 'Stable permission identifier matching AppPermission.id (e.g., inventory.edit)';

-- Index on role_id for efficient lookup of all permissions for a role
CREATE INDEX idx_role_permissions_cloud_role_id ON role_permissions_cloud(role_id);
