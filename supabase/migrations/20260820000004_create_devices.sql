-- Phase C Migration 04: Create devices table
-- devices: device registration and tracking
--
-- Tracks each physical device that connects to a shop.
-- installation_id is the locally-generated UUID from Phase B's device-bound model.
-- platform is restricted to 'windows' or 'android'.
-- status tracks device lifecycle: ACTIVE -> REVOKED or LOST.

CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installation_id UUID NOT NULL,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  platform TEXT NOT NULL CHECK (platform IN ('windows', 'android')),
  device_name TEXT,
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'REVOKED', 'LOST')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE devices IS 'Device registration and tracking — each row is a physical device connected to a shop';
COMMENT ON COLUMN devices.installation_id IS 'Locally-generated UUID identifying the device installation (from Phase B)';
COMMENT ON COLUMN devices.shop_id IS 'FK to shops — the shop this device is registered to (CASCADE DELETE)';
COMMENT ON COLUMN devices.user_id IS 'FK to auth.users — the last user who logged in on this device (nullable)';
COMMENT ON COLUMN devices.platform IS 'Device platform: windows or android';
COMMENT ON COLUMN devices.device_name IS 'Optional human-readable device name';
COMMENT ON COLUMN devices.first_seen_at IS 'Timestamp of first registration/connection';
COMMENT ON COLUMN devices.last_seen_at IS 'Timestamp of most recent activity';
COMMENT ON COLUMN devices.status IS 'Device status: ACTIVE, REVOKED, or LOST';

-- Index on shop_id for efficient lookup of devices within a shop
CREATE INDEX idx_devices_shop_id ON devices(shop_id);

-- Index on installation_id for efficient lookup by device identity
CREATE INDEX idx_devices_installation_id ON devices(installation_id);
