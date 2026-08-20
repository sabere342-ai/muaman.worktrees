import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:cryptography/cryptography.dart';

/// Ed25519 public key used for offline token verification.
/// Embedded at build time. NOT a secret — extraction has no security impact.
///
/// This is a placeholder key_id=1 public key for development.
/// In production, this would be the real server's public key.
const int currentKeyId = 1;

/// T3-2 §12: Entitlement token structure.
///
/// A signed, machine-readable document that proves the client is entitled
/// to operate. CBOR-encoded, Ed25519-signed.
class EntitlementToken {
  final int tokenVersion;
  final int keyId;
  final String licenseId;
  final String businessId;
  final String productId;
  final Entitlements entitlements;
  final Uint8List device_id_hash;
  final int activationGeneration;
  final int issuedAt;
  final int notBefore;

  const EntitlementToken({
    required this.tokenVersion,
    required this.keyId,
    required this.licenseId,
    required this.businessId,
    required this.productId,
    required this.entitlements,
    required this.device_id_hash,
    required this.activationGeneration,
    required this.issuedAt,
    required this.notBefore,
  });

  /// Serialize the token payload to canonical CBOR (without signature).
  /// Keys are sorted alphabetically for deterministic encoding per T3-2 §11.
  Uint8List canonicalPayloadBytes() {
    final map = CborMap({
      CborString('activation_generation'):
          CborInt(BigInt.from(activationGeneration)),
      CborString('business_id'): CborString(businessId),
      CborString('device_id_hash'): CborBytes(device_id_hash),
      CborString('entitlements'): _entitlementsToCbor(),
      CborString('issued_at'): CborInt(BigInt.from(issuedAt)),
      CborString('key_id'): CborInt(BigInt.from(keyId)),
      CborString('license_id'): CborString(licenseId),
      CborString('not_before'): CborInt(BigInt.from(notBefore)),
      CborString('product_id'): CborString(productId),
      CborString('token_version'): CborInt(BigInt.from(tokenVersion)),
    });
    return Uint8List.fromList(cborEncode(map));
  }

  CborMap _entitlementsToCbor() {
    return CborMap({
      CborString('device_limit'):
          CborInt(BigInt.from(entitlements.deviceLimit)),
      CborString('features'): CborList(
        entitlements.features.map((f) => CborString(f)).toList(),
      ),
      CborString('tier'): CborString(entitlements.tier),
    });
  }

  /// Full signed token bytes: payload_bytes || signature_bytes.
  Uint8List toSignedBytes(Uint8List signature) {
    final payload = canonicalPayloadBytes();
    final combined = Uint8List(payload.length + signature.length);
    combined.setAll(0, payload);
    combined.setAll(payload.length, signature);
    return combined;
  }

  /// Extract the signature portion from signed bytes.
  static Uint8List extractSignature(Uint8List signedBytes) {
    if (signedBytes.length < 64) {
      throw ArgumentError('Signed token too short');
    }
    return signedBytes.sublist(signedBytes.length - 64);
  }

  /// Extract the payload portion from signed bytes.
  static Uint8List extractPayload(Uint8List signedBytes) {
    if (signedBytes.length < 64) {
      throw ArgumentError('Signed token too short');
    }
    return signedBytes.sublist(0, signedBytes.length - 64);
  }

  /// Deserialize a token from canonical CBOR payload bytes.
  static EntitlementToken fromPayloadBytes(Uint8List payloadBytes) {
    final decoded = cborDecode(payloadBytes);
    if (decoded is! CborMap) {
      throw FormatException('Token payload is not a CBOR map');
    }
    return _fromCborMap(decoded);
  }

  /// Parse a complete signed token (payload + signature).
  static ParsedToken parseSigned(Uint8List signedBytes) {
    final payload = extractPayload(signedBytes);
    final signature = extractSignature(signedBytes);
    final token = fromPayloadBytes(payload);
    return ParsedToken(
        token: token, payloadBytes: payload, signature: signature);
  }

  static EntitlementToken _fromCborMap(CborMap map) {
    final entitlementsMap = map[CborString('entitlements')] as CborMap;
    final featuresList = entitlementsMap[CborString('features')] as CborList;

    return EntitlementToken(
      tokenVersion: (map[CborString('token_version')] as CborInt).toInt(),
      keyId: (map[CborString('key_id')] as CborInt).toInt(),
      licenseId: (map[CborString('license_id')] as CborString).toString(),
      businessId: (map[CborString('business_id')] as CborString).toString(),
      productId: (map[CborString('product_id')] as CborString).toString(),
      entitlements: Entitlements(
        tier: (entitlementsMap[CborString('tier')] as CborString).toString(),
        deviceLimit:
            (entitlementsMap[CborString('device_limit')] as CborInt).toInt(),
        features:
            featuresList.map((e) => (e as CborString).toString()).toList(),
      ),
      device_id_hash: Uint8List.fromList(
          (map[CborString('device_id_hash')] as CborBytes).bytes),
      activationGeneration:
          (map[CborString('activation_generation')] as CborInt).toInt(),
      issuedAt: (map[CborString('issued_at')] as CborInt).toInt(),
      notBefore: (map[CborString('not_before')] as CborInt).toInt(),
    );
  }

  /// Serialize to JSON (for debugging / storage of non-sensitive metadata).
  Map<String, dynamic> toJson() => {
        'token_version': tokenVersion,
        'key_id': keyId,
        'license_id': licenseId,
        'business_id': businessId,
        'product_id': productId,
        'entitlements': {
          'tier': entitlements.tier,
          'device_limit': entitlements.deviceLimit,
          'features': entitlements.features,
        },
        'device_id_hash': base64Encode(device_id_hash),
        'activation_generation': activationGeneration,
        'issued_at': issuedAt,
        'not_before': notBefore,
      };
}

/// Parsed result containing token, raw payload, and signature.
class ParsedToken {
  final EntitlementToken token;
  final Uint8List payloadBytes;
  final Uint8List signature;

  const ParsedToken({
    required this.token,
    required this.payloadBytes,
    required this.signature,
  });
}

/// Entitlement sub-map per T3-2 §12.
class Entitlements {
  final String tier;
  final int deviceLimit;
  final List<String> features;

  const Entitlements({
    required this.tier,
    required this.deviceLimit,
    required this.features,
  });
}

/// Verification result per T3-2 §22 state machine.
class TokenVerificationResult {
  final bool isValid;
  final EntitlementToken? token;
  final String? error;
  final String? errorCode;

  const TokenVerificationResult({
    required this.isValid,
    this.token,
    this.error,
    this.errorCode,
  });

  static TokenVerificationResult success(EntitlementToken token) {
    return TokenVerificationResult(isValid: true, token: token);
  }

  static TokenVerificationResult failure(String error, String code) {
    return TokenVerificationResult(
      isValid: false,
      error: error,
      errorCode: code,
    );
  }
}

/// Cryptographic verification of entitlement tokens.
///
/// Uses Ed25519 signature verification with the embedded public key.
/// The private signing key NEVER exists in the client.
class EntitlementVerifier {
  final List<TrustedKey> _trustedKeys;

  EntitlementVerifier({List<TrustedKey>? trustedKeys})
      : _trustedKeys = trustedKeys ?? _defaultTrustedKeys;

  /// Verify a signed entitlement token.
  ///
  /// Checks:
  /// 1. CBOR payload parses correctly
  /// 2. Signature is valid Ed25519
  /// 3. key_id is in trusted set
  /// 4. token_version is supported
  /// 5. business_id matches expected
  /// 6. device_id_hash matches current device
  Future<TokenVerificationResult> verify({
    required Uint8List signedBytes,
    String? expectedBusinessId,
    Uint8List? expectedDeviceIdHash,
  }) async {
    if (signedBytes.length < 64) {
      return TokenVerificationResult.failure(
        'Token too short',
        'MALFORMED_TOKEN',
      );
    }

    final parsed = EntitlementToken.parseSigned(signedBytes);

    // Check token_version
    if (parsed.token.tokenVersion > 1) {
      return TokenVerificationResult.failure(
        'Unsupported token version ${parsed.token.tokenVersion}',
        'UNSUPPORTED_TOKEN_VERSION',
      );
    }

    // Check key_id
    final trustedKey = _trustedKeys.where(
      (k) => k.keyId == parsed.token.keyId,
    );
    if (trustedKey.isEmpty) {
      return TokenVerificationResult.failure(
        'Unknown key_id ${parsed.token.keyId}',
        'UNKNOWN_KEY_ID',
      );
    }

    // Verify Ed25519 signature
    final algorithm = Ed25519();
    final publicKey = SimplePublicKey(
      trustedKey.first.publicKeyBytes,
      type: KeyPairType.ed25519,
    );

    try {
      final isValid = await algorithm.verify(
        parsed.payloadBytes,
        signature: Signature(parsed.signature, publicKey: publicKey),
      );
      if (!isValid) {
        return TokenVerificationResult.failure(
          'Signature verification failed',
          'INVALID_SIGNATURE',
        );
      }
    } catch (e) {
      return TokenVerificationResult.failure(
        'Signature verification error: $e',
        'INVALID_SIGNATURE',
      );
    }

    // Check business_id match
    if (expectedBusinessId != null &&
        parsed.token.businessId != expectedBusinessId) {
      return TokenVerificationResult.failure(
        'Business ID mismatch',
        'BUSINESS_MISMATCH',
      );
    }

    // Check device_id_hash match
    if (expectedDeviceIdHash != null) {
      if (parsed.token.device_id_hash.length != expectedDeviceIdHash.length) {
        return TokenVerificationResult.failure(
          'Device ID hash length mismatch',
          'DEVICE_MISMATCH',
        );
      }
      if (!_constantTimeCompare(
          parsed.token.device_id_hash, expectedDeviceIdHash)) {
        return TokenVerificationResult.failure(
          'Device ID hash mismatch',
          'DEVICE_MISMATCH',
        );
      }
    }

    return TokenVerificationResult.success(parsed.token);
  }

  /// Constant-time comparison to prevent timing attacks.
  static bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// A trusted signing key for token verification.
class TrustedKey {
  final int keyId;
  final Uint8List publicKeyBytes;

  const TrustedKey({
    required this.keyId,
    required this.publicKeyBytes,
  });
}

/// Default trusted keys for development/testing.
/// In production, these would be replaced with real server keys.
const _defaultTrustedKeys = <TrustedKey>[];
