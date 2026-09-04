import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'entitlement_cache.dart';
import 'offline_grace_policy.dart';
import 's6_device_identity.dart';
import 's6_proof_of_possession.dart';

/// Phase P Group B S8 — tamper / cache / clock enforcement convergence
/// (device-bound cache authenticity + trusted-time anti-rollback).
///
/// S8 delivers:
///   * a canonical byte-deterministic integrity payload bound to the governed
///     security fields (tenant, installation, user, schema, status,
///     revocation, trial, subscription, server-time baseline, trusted
///     high-water, grace basis);
///   * an Ed25519 signature over that payload using the S6 per-install private
///     key -> DEVICE-BOUND TAMPER EVIDENCE (NOT a server signature; see
///     Governance Section L);
///   * anti-rollback helpers that reject a cache whose trusted baseline is
///     behind the independently-protected high-water (Governance M / Section
///     19). A valid signature does not equal current authority.
///
/// The signature is the strongest local guarantee obtainable without a server
/// secret. Per Governance Section I it is explicitly NOT protection against a
/// fully compromised root/admin client — the server remains the authority
/// (R1). A hash-only scheme is rejected because an attacker with file-write
/// access can recompute a hash (Governance Section 16); Ed25519 binds the
/// payload to the S6 private key the attacker does not hold.
class S8CacheIntegrity {
  S8CacheIntegrity._();

  /// Integrity-envelope version. Distinct from [kEntitlementCacheSchemaVersion]
  /// so an S8-bound cache carries both a compatible payload schema AND a
  /// recognized integrity version. Unknown/future integrity versions fail
  /// closed (R9/T11).
  static const int kS8IntegrityVersion = 1;

  /// The canonical integrity payload is the UTF-8 bytes of a fixed-key-order
  /// JSON object with no insignificant whitespace and UTC-normalized
  /// timestamps — deterministically reconstructible from equivalent semantic
  /// values (same discipline as [S6CanonicalEnvelope]).
  static String canonicalJson({
    required EntitlementSnapshot s,
    required String installationId,
    required String userBoundary,
  }) {
    const s8Version = kS8IntegrityVersion;
    final schema = s.schemaVersion;
    final shop = s.shopId;
    final status = s.licenseStatus ?? 'null';
    final revokedAt = _fmt(s.revokedAt);
    final trialExpires = _fmt(s.trialExpiresAt);
    final subExpires = _fmt(s.subscriptionExpiresAt);
    final serverTime = _fmt(s.serverTimeAtVerification);
    final highWater = _fmt(s.lastTrustedServerTimeUtc);
    final grace = s.graceBasis ?? inferGraceBasis(s);

    final b = StringBuffer('{');
    b.write('"v":$s8Version,');
    b.write('"schema":$schema,');
    b.write('"shop":${_jsonStr(shop)},');
    b.write('"install":${_jsonStr(installationId)},');
    b.write('"user":${_jsonStr(userBoundary)},');
    b.write('"status":${_jsonStr(status)},');
    b.write('"revoked":${s.isRevoked},');
    b.write('"revokedAt":$revokedAt,');
    b.write('"trial":${s.isTrial},');
    b.write('"trialActive":${s.trialActive},');
    b.write('"trialExpires":$trialExpires,');
    b.write('"subExpires":$subExpires,');
    b.write('"serverTime":$serverTime,');
    b.write('"highWater":$highWater,');
    b.write('"grace":${_jsonStr(grace)}');
    b.write('}');
    return b.toString();
  }

  /// Canonical byte representation of the integrity payload.
  static Uint8List canonicalBytes({
    required EntitlementSnapshot s,
    required String installationId,
    required String userBoundary,
  }) {
    return Uint8List.fromList(utf8.encode(canonicalJson(
        s: s, installationId: installationId, userBoundary: userBoundary)));
  }

  /// Infer the authenticated grace basis (TRIAL / PAID / PERPETUAL) used for
  /// the offline-window decision. Deterministic; never a locally-editable
  /// value (Governance Section 21).
  static String inferGraceBasis(EntitlementSnapshot s) {
    if (s.isTrial || s.trialActive || s.licenseStatus == 'TRIAL') {
      return 'TRIAL';
    }
    if (s.licenseStatus == 'PERPETUAL') return 'PERPETUAL';
    return 'PAID';
  }

  /// Sign the canonical payload with the S6 per-install identity.
  /// Returns a canonical base64url (no padding) 64-byte Ed25519 signature.
  static Future<String> signBase64Url({
    required EntitlementSnapshot s,
    required String installationId,
    required String userBoundary,
    required S6Identity identity,
  }) async {
    final signature = await identity.sign(canonicalBytes(
        s: s, installationId: installationId, userBoundary: userBoundary));
    return S6ProofOfPossession.encodeBase64UrlNoPadding(
        Uint8List.fromList(signature.bytes));
  }

  /// Verify an Ed25519 signature over the canonical payload against a
  /// canonical base64url public key. Rejects malformed encodings.
  static Future<bool> verify({
    required EntitlementSnapshot s,
    required String installationId,
    required String userBoundary,
    required String publicKeyBase64Url,
    required String signatureBase64Url,
  }) async {
    final pub = S6ProofOfPossession.decodeStrict(publicKeyBase64Url, 32);
    final sig = S6ProofOfPossession.decodeStrict(signatureBase64Url, 64);
    if (pub == null || sig == null) return false;
    final algorithm = Ed25519();
    final publicKey = SimplePublicKey(pub, type: KeyPairType.ed25519);
    return algorithm.verify(
      canonicalBytes(
          s: s, installationId: installationId, userBoundary: userBoundary),
      signature: Signature(sig, publicKey: publicKey),
    );
  }

  /// Whether the cache's trusted baseline represents authority older than the
  /// independently-protected high-water (replay/rollback) -> FAIL CLOSED
  /// (Governance Section 19 / T3/T5). A valid signature does not prove current
  /// authority.
  ///
  /// Strict monotonic comparison: any cache baseline strictly below the
  /// protected high-water is rejected as older authority. When no protected
  /// high-water has ever been established there is nothing older to roll back
  /// to, so no replay is detected.
  static bool isReplayOrRollback({
    required DateTime cacheHighWater,
    DateTime? protectedHighWater,
  }) {
    if (protectedHighWater == null) return false;
    return cacheHighWater.toUtc().isBefore(protectedHighWater.toUtc());
  }

  /// Whether a freshly-returned authoritative [server_time] is materially
  /// stale relative to the protected high-water (anti-replay; R1/T19). The
  /// sub-5-minute edge is resolved conservatively using the governed
  /// [OfflineGracePolicy.clockSkewTolerance]; beyond it the response is not
  /// accepted as a fresh authority baseline.
  static bool isStaleAuthority({
    required DateTime serverTime,
    DateTime? protectedHighWater,
  }) {
    if (protectedHighWater == null) return false;
    const tolerance = OfflineGracePolicy.clockSkewTolerance;
    return serverTime
        .toUtc()
        .isBefore(protectedHighWater.toUtc().subtract(tolerance));
  }

  /// Monotonic high-water advance: the persisted trusted high-water can only
  /// increase. A fresh authoritative [server_time] advances it only when newer.
  static DateTime advanceHighWater({
    required DateTime serverTime,
    DateTime? protectedHighWater,
  }) {
    final st = serverTime.toUtc();
    final prev = protectedHighWater?.toUtc();
    if (prev == null) return st;
    return st.isAfter(prev) ? st : prev;
  }

  static String _fmt(DateTime? d) =>
      d == null ? 'null' : d.toUtc().toIso8601String();

  static String _jsonStr(String value) => jsonEncode(value);
}
