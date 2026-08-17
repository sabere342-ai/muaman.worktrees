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
library licensing;

export 'license_state.dart';
export 'device_identity.dart';
export 'entitlement_token.dart';
export 'secure_store.dart';
export 'licensing_service.dart';
