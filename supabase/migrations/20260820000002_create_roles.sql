-- Phase C Migration 02: Create roles table
-- roles: per-shop role definitions
--
-- System roles (owner, employee, salesOnly) are seeded via seed.sql.
-- Custom roles may be added per-shop in future phases.
-- The is_system flag distinguishes built-in roles from user-defined ones.

CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_system BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(shop_id, name)
);

COMMENT ON TABLE roles IS 'Per-shop role definitions — system roles (owner, employee, salesOnly) plus optional custom roles';
COMMENT ON COLUMN roles.shop_id IS 'FK to shops — NULL for system-wide roles, set for shop-specific roles';
COMMENT ON COLUMN roles.name IS 'Role name — must be unique within the shop scope';
COMMENT ON COLUMN roles.is_system IS 'TRUE for built-in roles (owner, employee, salesOnly), FALSE for custom roles';

-- Index on shop_id for efficient lookup of roles within a shop
CREATE INDEX idx_roles_shop_id ON roles(shop_id);
