/// I-TECH Licensing Module.
///
/// Implements T3-2 Licensing Technical Contract:
/// - Ed25519 asymmetric signature verification
/// - CBOR canonical entitlement token serialization
/// - Windows device identity (MachineGuid + CPU + Board)
/// - DPAPI-protected local activation state
/// - Deterministic entitlement state machine
/// - Application-boundary write enforcement
/// - Non-destructive restricted mode
///
/// Phase E additions:
/// - Cloud-backed licensing via Supabase RPCs
/// - Server-authoritative entitlement resolution
/// - Offline grace with bounded staleness
/// - Device activation per shop
library licensing;

export 'license_state.dart';
export 'device_identity.dart';
export 'entitlement_token.dart';
export 'secure_store.dart';
export 'licensing_service.dart';
export 'cloud_licensing_service.dart';
export 'cloud_licensing_repository.dart';
export 'entitlement_cache.dart';
export 'offline_grace_policy.dart';
export 'license_exception.dart';
