-- Phase C Seed Data: System roles
-- Seeds the 3 system roles that match the local AppPermission model.
-- These roles are global (shop_id = NULL) and serve as templates.
-- Per-shop roles are created by create_shop_with_owner().

INSERT INTO roles (shop_id, name, is_system)
VALUES
  (NULL, 'owner', true),
  (NULL, 'employee', true),
  (NULL, 'salesOnly', true)
ON CONFLICT (shop_id, name) DO NOTHING;

-- 18 system permissions seeded as role_permissions_cloud for each system role.
-- Permission IDs match the stable AppPermission.id values from permissions.dart.

-- Owner: all 18 permissions
INSERT INTO role_permissions_cloud (role_id, permission_id)
SELECT r.id, p.permission_id
FROM roles r
CROSS JOIN (VALUES
  ('dashboard.view'),
  ('inventory.view'),
  ('inventory.edit'),
  ('inventory.delete'),
  ('sales.view'),
  ('sales.create'),
  ('sales.history.view'),
  ('sales.delete'),
  ('returns.view'),
  ('returns.create'),
  ('returns.delete'),
  ('expenses.view'),
  ('expenses.create'),
  ('expenses.delete'),
  ('stocktake.view'),
  ('admin.users.manage'),
  ('admin.permissions.manage'),
  ('admin.settings.access')
) AS p(permission_id)
WHERE r.name = 'owner' AND r.shop_id IS NULL
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Employee: all except delete operations and admin powers (11 permissions)
INSERT INTO role_permissions_cloud (role_id, permission_id)
SELECT r.id, p.permission_id
FROM roles r
CROSS JOIN (VALUES
  ('dashboard.view'),
  ('inventory.view'),
  ('inventory.edit'),
  ('sales.view'),
  ('sales.create'),
  ('sales.history.view'),
  ('returns.view'),
  ('returns.create'),
  ('expenses.view'),
  ('expenses.create'),
  ('stocktake.view')
) AS p(permission_id)
WHERE r.name = 'employee' AND r.shop_id IS NULL
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- SalesOnly: only sales view and creation (2 permissions)
INSERT INTO role_permissions_cloud (role_id, permission_id)
SELECT r.id, p.permission_id
FROM roles r
CROSS JOIN (VALUES
  ('sales.view'),
  ('sales.create')
) AS p(permission_id)
WHERE r.name = 'salesOnly' AND r.shop_id IS NULL
ON CONFLICT (role_id, permission_id) DO NOTHING;
