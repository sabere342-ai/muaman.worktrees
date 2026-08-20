-- Phase C Migration 06: Create activations table
-- activations: device-license binding
--
-- Each activation links a device to a license, representing one active installation.
-- A device can have multiple activations over time (e.g., after revocation and re-activation).
-- last_verified_at is updated by periodic server-side verification checks.

CREATE TABLE activations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  license_id UUID NOT NULL REFERENCES licenses(id) ON DELETE CASCADE,
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_verified_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'ACTIVE'
);

COMMENT ON TABLE activations IS 'Device-license binding — links devices to their active license';
COMMENT ON COLUMN activations.license_id IS 'FK to licenses — the license this activation is bound to (CASCADE DELETE)';
COMMENT ON COLUMN activations.device_id IS 'FK to devices — the device this activation represents (CASCADE DELETE)';
COMMENT ON COLUMN activations.activated_at IS 'Server timestamp when the activation was created';
COMMENT ON COLUMN activations.last_verified_at IS 'Server timestamp of the most recent license verification check';
COMMENT ON COLUMN activations.status IS 'Activation status (currently ACTIVE only, extensible later)';

-- Index on license_id for efficient lookup of all activations for a license
CREATE INDEX idx_activations_license_id ON activations(license_id);

-- Index on device_id for efficient lookup of all activations for a device
CREATE INDEX idx_activations_device_id ON activations(device_id);
