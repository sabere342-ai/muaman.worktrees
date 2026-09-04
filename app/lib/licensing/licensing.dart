/// I-TECH Licensing Module.
///
/// Canonical licensing surface (Post S9 — legacy Ed25519 retirement):
/// - Device proof-of-possession (S6) Ed25519 identity
/// - S6 per-install device identity
/// - S8 device-bound protected cache integrity
/// - Cloud-backed licensing via Supabase RPCs
/// - Server-authoritative entitlement resolution
/// - Offline grace with bounded staleness
/// - Device activation per shop
/// - Hardware fingerprint compatibility metadata
///
/// The legacy entitlement-token Ed25519 verifier surface and the superseded
/// `LicensingService`/`ActivationClient` local activation authority were
/// retired under S9 and are intentionally NOT exported here.
library licensing;

export 'device_identity.dart';
export 'cloud_licensing_service.dart';
export 'cloud_licensing_repository.dart';
export 'entitlement_cache.dart';
export 'offline_grace_policy.dart';
export 'license_exception.dart';
