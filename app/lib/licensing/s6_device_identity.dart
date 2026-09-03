import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../platform/secure_secret_store.dart';
import 'secure_store_android.dart';

/// Phase P Group B S6 — per-install Ed25519 device identity.
///
/// This is a *cryptographic possession identity* (RFC 8032 Ed25519), distinct
/// from the legacy hardware/SSAID fingerprint ([DeviceIdentity]). The legacy
/// fingerprint is NOT a cryptographic possession proof and is never treated as
/// one by S6.
///
/// Lifecycle (Governance Section L):
/// - FIRST INSTALL -> generate exactly ONE per-install Ed25519 keypair
/// - NORMAL RESTART -> load and reuse the SAME identity
/// - CONCURRENT FIRST LOAD -> converging single-flight init (one identity)
/// - SECURE STORE LOST / REINSTALL -> new identity + governed re-enrollment
/// - CORRUPT PRIVATE MATERIAL -> fail closed (no fabricated identity)
/// - SERVER PUBLIC-KEY MISMATCH -> fail closed (no silent overwrite)
///
/// Private material NEVER leaves local protected storage except transient
/// in-process signing use. It is never logged, serialized to cache/AppSettings/
/// SQLite, uploaded, backed up, or written in production plaintext.
///
/// Representation: 32-byte Ed25519 seed persisted inside the platform
/// protected secret store. Public key: canonical base64url (no padding).
class S6DeviceIdentity {
  /// Storage key under which the 32-byte Ed25519 seed is protected at rest.
  static const String storageKey = 'itech.s6.device.seed';

  final SecureSecretStore _store;

  /// In-flight single-flight token so concurrent first-loads converge on one
  /// persisted identity (Governance Section L concurrency invariant).
  Future<S6Identity>? _initializing;

  S6DeviceIdentity(this._store);

  /// Load the existing persisted identity, or create exactly one on first run.
  ///
  /// Returns a [S6DeviceIdentityOutcome] describing whether the identity was
  /// freshly generated (first install / re-enrollment) or reused (restart).
  /// Failures to read/decrypt/corrupt material fail closed and surface as
  /// [S6DeviceIdentityException] so callers re-enroll through governed flow.
  Future<S6DeviceIdentityOutcome> loadOrCreate({String? overrideKey}) async {
    final inFlight = _initializing;
    if (inFlight != null) {
      final existing = await inFlight;
      return S6DeviceIdentityOutcome(
        identity: existing,
        isNew: false,
        createdAt: existing.createdAt,
      );
    }

    final started = _loadPersisted(overrideKey ?? storageKey);
    _initializing = started;
    try {
      final identity = await started;
      return S6DeviceIdentityOutcome(
        identity: identity,
        isNew: identity.createdFresh,
        createdAt: identity.createdAt,
      );
    } finally {
      if (identical(_initializing, started)) {
        _initializing = null;
      }
    }
  }

  Future<S6Identity> _loadPersisted(String key) async {
    String? raw;
    try {
      raw = await _store.read(key);
    } on S6DeviceIdentityException {
      rethrow;
    } on FormatException {
      throw const S6DeviceIdentityException(
          'S6_CORRUPT: persisted seed is not valid base64url');
    } catch (_) {
      // Protected store unavailable / decrypt failure (e.g. Keystore channel
      // PlatformException or DPAPI StateError). Fail closed so no fabricated
      // identity is ever produced when private material cannot be trusted.
      throw const S6DeviceIdentityException(
          'S6_STORAGE_UNAVAILABLE: secure store read failed, fail closed');
    }

    try {
      if (raw == null || raw.isEmpty) {
        return _createAndPersist(key);
      }

      // Parse stored record: base64url(seed)|createdAtMillis
      final parts = raw.split('|');
      if (parts.length != 2) {
        throw const S6DeviceIdentityException(
            'S6_CORRUPT: malformed persisted identity record');
      }
      final seed = _decodeBase64UrlStrict(parts[0]);
      if (seed == null || seed.length != 32) {
        throw const S6DeviceIdentityException(
            'S6_CORRUPT: persisted seed is not a valid 32-byte Ed25519 seed');
      }
      final createdAt = int.tryParse(parts[1]);
      if (createdAt == null) {
        throw const S6DeviceIdentityException(
            'S6_CORRUPT: invalid creation timestamp');
      }

      return await S6Identity._fromSeed(seed, createdAt: createdAt);
    } on FormatException {
      throw const S6DeviceIdentityException(
          'S6_CORRUPT: malformed persisted identity record');
    }
  }

  Future<S6Identity> _createAndPersist(String key) async {
    final keyPair = await Ed25519().newKeyPair();
    final seed = Uint8List.fromList(await keyPair.extractPrivateKeyBytes());
    if (seed.length != 32) {
      throw const S6DeviceIdentityException(
          'S6_GENERATE: unexpected private material length');
    }
    final createdAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    // base64url WITHOUT padding per Governance Section J.
    final record = '${_base64UrlNoPadding(seed)}|$createdAt';
    await _store.write(key, record);

    // Freshly generated identity in this call -> createdFresh MUST be true so
    // the caller can drive the governed first-install / re-enrollment flow.
    return S6Identity._created(keyPair, createdAt, fresh: true);
  }

  /// Deterministic canonicalization helpers exposed for tests/UI.
  static String publicKeyBase64Url(Uint8List rawPublicKey) =>
      _base64UrlNoPadding(rawPublicKey);

  static Uint8List? decodeSeedBase64Url(String value) =>
      _decodeBase64UrlStrict(value);

  static String _base64UrlNoPadding(List<int> bytes) {
    var b64 = base64UrlEncode(bytes);
    // base64UrlEncode already uses URL alphabet; strip any padding.
    return b64.replaceAll('=', '');
  }

  /// Strict strict padding-free base64url decode. Rejects malformed input,
  /// wrong alphabet, embedded whitespace, and non-canonical padding so the
  /// canonical representation is deterministic (Section J).
  static Uint8List? _decodeBase64UrlStrict(String value) {
    if (value.isEmpty) return null;
    // Only allow the base64url alphabet (no + / = space newline).
    if (RegExp(r'[^A-Za-z0-9_\-]').hasMatch(value)) return null;
    try {
      // base64Url.decode normalizes to base64 by padding; but we require the
      // caller to present the unpadded form to keep canonical encoding strict.
      if (value.contains('=')) return null;
      return base64Url.decode(base64Url.normalize(value));
    } catch (_) {
      return null;
    }
  }

  /// Remove the persisted identity (governed re-enrollment path).
  Future<void> delete() => _store.delete(storageKey);
}

/// A per-install Ed25519 identity bound to a single protected store.
class S6Identity {
  final SimpleKeyPair _keyPair;

  /// When the identity was first created (server clock independent).
  final int createdAt;

  /// Whether this identity record was created fresh during this load
  /// (true after first install / reinstall / secure-store loss).
  final bool createdFresh;

  static Future<S6Identity> _fromSeed(Uint8List seed,
      {required int createdAt}) async {
    final keyPair = await Ed25519().newKeyPairFromSeed(seed);
    return S6Identity._created(keyPair, createdAt, fresh: false);
  }

  S6Identity._created(SimpleKeyPair keyPair, this.createdAt, {bool fresh = true})
      : _keyPair = keyPair,
        createdFresh = fresh;

  /// Raw 32-byte Ed25519 public key.
  Future<Uint8List> publicKeyBytes() async {
    final pub = await _keyPair.extractPublicKey();
    return Uint8List.fromList(pub.bytes);
  }

  /// Canonical base64url (no padding) public key.
  Future<String> publicKeyBase64Url() async =>
      S6DeviceIdentity.publicKeyBase64Url(await publicKeyBytes());

  /// Internal accessor for signing (transient in-process use only). The
  /// private seed is never exposed to callers beyond this class boundary.
  Future<Signature> sign(List<int> message) async {
    return Ed25519().sign(message, keyPair: _keyPair);
  }
}

/// Result describing how an identity was obtained on a load.
class S6DeviceIdentityOutcome {
  final S6Identity identity;
  final bool isNew;
  final int createdAt;

  S6DeviceIdentityOutcome({
    required this.identity,
    required this.isNew,
    required this.createdAt,
  });
}

/// Fail-closed error raised when a persisted identity is unusable/corrupt.
class S6DeviceIdentityException implements Exception {
  final String reason;
  const S6DeviceIdentityException(this.reason);
  @override
  String toString() => 'S6DeviceIdentityException: $reason';
}

/// Test-only fixed per-install identity harness (NOT used in production).
///
/// This exists purely so tests can drive a deterministic identity without
/// touching the platform secret store, and to construct golden-vector
/// identities. It is unmistakably test-scoped.
class S6TestIdentity {
  /// Build a per-install identity from an explicit 32-byte seed.
  static Future<S6Identity> fromSeed(Uint8List seed, {int createdAt = 0}) async {
    final kp = await Ed25519().newKeyPairFromSeed(seed);
    return S6Identity._created(kp, createdAt);
  }
}

/// Resolves the S6 device-secret platform store (Governance M/N):
/// - Android: Keystore-backed channel store (class 2, reuses itech.app/secure_storage)
/// - Windows: S6-safe DPAPI CurrentUser store (no plaintext temp file)
///
/// Tests inject a controlled [SecureSecretStore] (commonly the in-memory fake)
/// instead of this factory so no platform channel or DPAPI round-trip runs.
SecureSecretStore createDefaultS6DeviceSecretStore() {
  if (Platform.isAndroid) {
    return const KeystoreChannelSecretStore();
  }
  if (Platform.isWindows) {
    return WindowsDpapiSecureSecretStore();
  }
  return InMemorySecureSecretStore();
}
