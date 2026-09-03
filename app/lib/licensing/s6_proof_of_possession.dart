import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 's6_device_identity.dart';

/// Phase P Group B S6 — canonical proof-of-possession envelope.
///
/// The client signs the UTF-8 bytes of a *canonical* JSON object with a fixed
/// key order and no insignificant whitespace. The Edge Function reconstructs
/// those exact bytes from server-authoritative values and verifies with Deno
/// WebCrypto (Ed25519 / RFC 8032). Byte-identical canonical payload across
/// implementations is mandatory (Governance Section Q + golden vector X).
///
/// Wire representation (Section R): signature and public key are canonical
/// base64url WITHOUT padding. Malformed encodings are rejected, never silently
/// co-erced.
class S6CanonicalEnvelope {
  static const String protocol = 'itech-s6-pop';
  static const int version = 1;
  static const String purpose = 'device-proof';

  final String challengeId;
  final String challenge;
  final String shopId;
  final String deviceId;
  final String userId;
  final String installationId;
  final String expiresAt; // RFC3339 UTC

  const S6CanonicalEnvelope({
    required this.challengeId,
    required this.challenge,
    required this.shopId,
    required this.deviceId,
    required this.userId,
    required this.installationId,
    required this.expiresAt,
  });

  /// Canonical UTF-8 payload bytes with EXACT key order and no whitespace.
  ///
  /// Values are UUID/RFC3339/simple strings and the numeric version — none
  /// require JSON string escaping — so this literal construction is byte- and
  /// format-deterministic across Dart and Deno.
  Uint8List canonicalBytes() {
    final s = '{'
        '"protocol":"$protocol",'
        '"version":$version,'
        '"challenge_id":"$challengeId",'
        '"challenge":"$challenge",'
        '"shop_id":"$shopId",'
        '"device_id":"$deviceId",'
        '"user_id":"$userId",'
        '"installation_id":"$installationId",'
        '"expires_at":"$expiresAt",'
        '"purpose":"$purpose"'
        '}';
    return Uint8List.fromList(utf8.encode(s));
  }

  @override
  bool operator ==(Object other) =>
      other is S6CanonicalEnvelope &&
      other.challengeId == challengeId &&
      other.challenge == challenge &&
      other.shopId == shopId &&
      other.deviceId == deviceId &&
      other.userId == userId &&
      other.installationId == installationId &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(challengeId, challenge, shopId, deviceId,
      userId, installationId, expiresAt);
}

/// Produces and verifies Ed25519 proof-of-possession signatures over the
/// canonical envelope, mirroring the Deno WebCrypto verifier (Section S).
class S6ProofOfPossession {
  /// Sign the canonical envelope bytes with the per-install identity.
  /// Returns the raw 64-byte Ed25519 signature.
  static Future<Uint8List> sign(
    S6CanonicalEnvelope envelope,
    S6Identity identity,
  ) async {
    final signature = await identity.sign(envelope.canonicalBytes());
    return Uint8List.fromList(signature.bytes);
  }

  /// Convenience: sign and return canonical base64url (no padding).
  static Future<String> signBase64Url(
    S6CanonicalEnvelope envelope,
    S6Identity identity,
  ) async {
    final sig = await sign(envelope, identity);
    return encodeBase64UrlNoPadding(sig);
  }

  /// Verify an Ed25519 signature over the canonical envelope bytes using the
  /// per-install public key. Returns true only on a valid signature.
  static Future<bool> verify(
    S6CanonicalEnvelope envelope,
    Uint8List publicKey,
    Uint8List signature,
  ) async {
    final algorithm = Ed25519();
    final publicKeyObj = SimplePublicKey(
      publicKey,
      type: KeyPairType.ed25519,
    );
    final sigObj = Signature(signature, publicKey: publicKeyObj);
    return algorithm.verify(
      envelope.canonicalBytes(),
      signature: sigObj,
    );
  }

  /// Verify a signature supplied as canonical base64url (no padding) against a
  /// canonical base64url public key. Rejects malformed encodings.
  static Future<bool> verifyCanonical(
    S6CanonicalEnvelope envelope,
    String publicKeyB64,
    String signatureB64,
  ) async {
    final pub = decodeStrict(publicKeyB64, 32);
    final sig = decodeStrict(signatureB64, 64);
    if (pub == null || sig == null) return false;
    return verify(envelope, pub, sig);
  }

  /// Strict canonical base64url decode with an exact expected byte length.
  /// Rejects padding, non-URL alphabet, wrong length, and malformed input so
  /// the canonical representation stays deterministic (Section J/R).
  static Uint8List? decodeStrict(String value, int expectedLength) {
    if (value.isEmpty) return null;
    if (value.contains('=')) return null;
    if (RegExp(r'[^A-Za-z0-9_\-]').hasMatch(value)) return null;
    try {
      final decoded = base64Url.decode(base64Url.normalize(value));
      if (decoded.length != expectedLength) return null;
      return Uint8List.fromList(decoded);
    } catch (_) {
      return null;
    }
  }

  static String encodeBase64UrlNoPadding(List<int> bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');

  /// Validate a canonical Ed25519 raw public key: exactly 32 bytes.
  static bool isValidPublicKey(Uint8List publicKey) => publicKey.length == 32;

  /// Validate a canonical public key supplied in base64url form.
  static bool isValidPublicKeyBase64Url(String value) =>
      decodeStrict(value, 32) != null;
}

/// TEST-ONLY frozen golden vector (Governance Section X). Unmistakably
/// non-production: fixed deterministic TEST seed and fixed identifiers.
///
/// The exact public key, canonical payload bytes, and signature are computed
/// deterministically by both Dart and Deno and cross-verified. Never use these
/// values in production.
class S6GoldenVector {
  /// Fixed 32-byte TEST seed (byte values 0..31). NOT a production secret.
  static final Uint8List seed = Uint8List.fromList(
      List<int>.generate(32, (i) => i));

  static const String challengeId = 'c0000000-0000-0000-0000-000000000101';
  static const String challenge = 's6-golden-challenge-vector';
  static const String shopId = 'a0000000-0000-0000-0000-000000000701';
  static const String deviceId = 'd0000000-0000-0000-0000-000000000801';
  static const String userId = 'u0000000-0000-0000-0000-000000000901';
  static const String installationId = 'g0000000-0000-0000-0000-000000001001';
  static const String expiresAt = '2030-01-02T03:04:05Z';

  static S6CanonicalEnvelope envelope() =>
      const S6CanonicalEnvelope(
        challengeId: challengeId,
        challenge: challenge,
        shopId: shopId,
        deviceId: deviceId,
        userId: userId,
        installationId: installationId,
        expiresAt: expiresAt,
      );

  /// Canonical payload as a printable string (for golden reproducibility).
  static String canonicalJson() {
    final e = envelope();
    return utf8.decode(e.canonicalBytes());
  }
}
