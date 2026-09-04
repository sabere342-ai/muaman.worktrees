import 'dart:convert';
import '../services/app_settings.dart';
import 's8_cache_integrity.dart';
import 's6_device_identity.dart';

/// Cache schema version written by this build.
///
/// Consumers must never trust a snapshot whose schema version is unknown or
/// incompatible (see [EntitlementSnapshot.isCompatibleSchema]) — matching
/// snapshots are treated as non-authoritative and require server revalidation.
const int kEntitlementCacheSchemaVersion = 1;

/// Cached snapshot of server-resolved entitlement data.
///
/// Stored locally for offline use. This is a CACHE ONLY — the server is always
/// the authority. Cached values may be used to maintain existing entitlement
/// during offline grace, but never to grant NEW entitlement.
class EntitlementSnapshot {
  final String shopId;
  final bool hasLicense;
  final String? licenseStatus;
  final bool isTrial;
  final bool trialActive;
  final DateTime? trialStartedAt;
  final DateTime? trialExpiresAt;
  final int? daysRemaining;
  final DateTime? activatedAt;
  final DateTime? subscriptionExpiresAt;
  final int? maxDevices;
  final int currentDevices;
  final bool deviceSlotAvailable;
  final DateTime serverTimeAtVerification;
  final DateTime localWallClockAtVerification;
  final DateTime lastSuccessfulVerificationAt;
  final bool isRevoked;
  final DateTime? revokedAt;
  final int schemaVersion;

  // ─── S8 integrity / trusted-time metadata (S8) ─────────────────────────
  /// Canonical base64url (no padding) Ed25519 signature over the canonical
  /// integrity payload. Null => cache is NOT S8-bound (pre-S8 / unbound) and
  /// is not trustworthy for offline authority.
  final String? s8Signature;

  /// Canonical base64url (no padding) S6 public key that produced the
  /// signature. Used for device binding (R6/T7).
  final String? s8PublicKey;

  /// Authenticated grace basis (TRIAL / PAID / PERPETUAL) used for the offline
  /// window (R10/R11). Never derived from an unbound/editable value.
  final String? graceBasis;

  /// Trusted server-time high-water (UTC) captured at verification — the
  /// monotonic anti-rollback baseline bound into the payload (K/M).
  final DateTime? lastTrustedServerTimeUtc;

  /// Identity/user boundary (R8). This product scopes entitlement per shop
  /// (tenant), so the boundary is the shop scope combined with the installation.
  final String userBoundary;

  const EntitlementSnapshot({
    required this.shopId,
    required this.hasLicense,
    this.licenseStatus,
    required this.isTrial,
    required this.trialActive,
    this.trialStartedAt,
    this.trialExpiresAt,
    this.daysRemaining,
    this.activatedAt,
    this.subscriptionExpiresAt,
    this.maxDevices,
    required this.currentDevices,
    required this.deviceSlotAvailable,
    required this.serverTimeAtVerification,
    required this.localWallClockAtVerification,
    required this.lastSuccessfulVerificationAt,
    this.isRevoked = false,
    this.revokedAt,
    this.schemaVersion = kEntitlementCacheSchemaVersion,
    this.s8Signature,
    this.s8PublicKey,
    this.graceBasis,
    this.lastTrustedServerTimeUtc,
    this.userBoundary = '',
  });

  /// Whether this snapshot carries S8 integrity binding metadata. A cache that
  /// is not S8-bound is not trustworthy for offline authority
  /// (OLD_CACHE_REQUIRES_ONLINE_REVALIDATION).
  bool get isS8Bound => s8Signature != null && s8PublicKey != null;

  /// Effective identity/user boundary for the bound payload: falls back to the
  /// tenant scope (shopId) when no explicit user boundary is set, matching the
  /// per-shop entitlement model (R8).
  String get effectiveUserBoundary =>
      userBoundary.isEmpty ? shopId : userBoundary;

  /// Whether this cached snapshot uses a schema version this build can
  /// safely consume. Unknown/future/incompatible versions are not trusted for
  /// entitlement decisions and MUST route to server revalidation.
  bool isCompatibleSchema() => schemaVersion == kEntitlementCacheSchemaVersion;

  /// Whether writes are allowed based on this cached snapshot.
  ///
  /// This is used for offline grace — only MAINTAINS existing entitlement,
  /// never grants NEW entitlement.
  bool get blocksWrites {
    if (isRevoked) return true;
    if (!hasLicense) return true;
    if (licenseStatus == 'EXPIRED' ||
        licenseStatus == 'SUSPENDED' ||
        licenseStatus == 'REVOKED') {
      return true;
    }
    if (isTrial && !trialActive) return true;
    return false;
  }

  /// Whether this cached snapshot is for a trial.
  bool get isTrialActive => isTrial && trialActive;

  /// Whether this cached snapshot is for an active paid license.
  bool get isPaidActive =>
      !isTrial && (licenseStatus == 'ACTIVE' || licenseStatus == 'PERPETUAL');

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'shopId': shopId,
        'hasLicense': hasLicense,
        'licenseStatus': licenseStatus,
        'isTrial': isTrial,
        'trialActive': trialActive,
        'trialStartedAt': trialStartedAt?.toIso8601String(),
        'trialExpiresAt': trialExpiresAt?.toIso8601String(),
        'daysRemaining': daysRemaining,
        'activatedAt': activatedAt?.toIso8601String(),
        'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
        'maxDevices': maxDevices,
        'currentDevices': currentDevices,
        'deviceSlotAvailable': deviceSlotAvailable,
        'serverTimeAtVerification': serverTimeAtVerification.toIso8601String(),
        'localWallClockAtVerification':
            localWallClockAtVerification.toIso8601String(),
        'lastSuccessfulVerificationAt':
            lastSuccessfulVerificationAt.toIso8601String(),
        'isRevoked': isRevoked,
        'revokedAt': revokedAt?.toIso8601String(),
        's8Signature': s8Signature,
        's8PublicKey': s8PublicKey,
        'graceBasis': graceBasis,
        'lastTrustedServerTimeUtc': lastTrustedServerTimeUtc?.toIso8601String(),
        'userBoundary': userBoundary,
      };

  factory EntitlementSnapshot.fromJson(Map<String, dynamic> json) {
    return EntitlementSnapshot(
      schemaVersion:
          json['schemaVersion'] as int? ?? kEntitlementCacheSchemaVersion,
      shopId: json['shopId'] as String,
      hasLicense: json['hasLicense'] as bool? ?? false,
      licenseStatus: json['licenseStatus'] as String?,
      isTrial: json['isTrial'] as bool? ?? false,
      trialActive: json['trialActive'] as bool? ?? false,
      trialStartedAt: json['trialStartedAt'] != null
          ? DateTime.parse(json['trialStartedAt'] as String)
          : null,
      trialExpiresAt: json['trialExpiresAt'] != null
          ? DateTime.parse(json['trialExpiresAt'] as String)
          : null,
      daysRemaining: json['daysRemaining'] as int?,
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'] as String)
          : null,
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.parse(json['subscriptionExpiresAt'] as String)
          : null,
      maxDevices: json['maxDevices'] as int?,
      currentDevices: json['currentDevices'] as int? ?? 0,
      deviceSlotAvailable: json['deviceSlotAvailable'] as bool? ?? false,
      serverTimeAtVerification:
          DateTime.parse(json['serverTimeAtVerification'] as String),
      localWallClockAtVerification:
          DateTime.parse(json['localWallClockAtVerification'] as String),
      lastSuccessfulVerificationAt:
          DateTime.parse(json['lastSuccessfulVerificationAt'] as String),
      isRevoked: json['isRevoked'] as bool? ?? false,
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'] as String)
          : null,
      s8Signature: json['s8Signature'] as String?,
      s8PublicKey: json['s8PublicKey'] as String?,
      graceBasis: json['graceBasis'] as String?,
      lastTrustedServerTimeUtc: json['lastTrustedServerTimeUtc'] != null
          ? DateTime.parse(json['lastTrustedServerTimeUtc'] as String)
          : null,
      userBoundary: json['userBoundary'] as String? ?? '',
    );
  }

  /// Return a copy of this snapshot with the S8 integrity / trusted-time
  /// metadata (and any other field) overridden. Used to bind a snapshot before
  /// authenticated persistence.
  EntitlementSnapshot copyWith({
    String? shopId,
    bool? hasLicense,
    String? licenseStatus,
    bool? isTrial,
    bool? trialActive,
    DateTime? trialStartedAt,
    DateTime? trialExpiresAt,
    int? daysRemaining,
    DateTime? activatedAt,
    DateTime? subscriptionExpiresAt,
    int? maxDevices,
    int? currentDevices,
    bool? deviceSlotAvailable,
    DateTime? serverTimeAtVerification,
    DateTime? localWallClockAtVerification,
    DateTime? lastSuccessfulVerificationAt,
    bool? isRevoked,
    DateTime? revokedAt,
    int? schemaVersion,
    String? s8Signature,
    String? s8PublicKey,
    String? graceBasis,
    DateTime? lastTrustedServerTimeUtc,
    String? userBoundary,
  }) {
    return EntitlementSnapshot(
      shopId: shopId ?? this.shopId,
      hasLicense: hasLicense ?? this.hasLicense,
      licenseStatus: licenseStatus ?? this.licenseStatus,
      isTrial: isTrial ?? this.isTrial,
      trialActive: trialActive ?? this.trialActive,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      activatedAt: activatedAt ?? this.activatedAt,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      maxDevices: maxDevices ?? this.maxDevices,
      currentDevices: currentDevices ?? this.currentDevices,
      deviceSlotAvailable: deviceSlotAvailable ?? this.deviceSlotAvailable,
      serverTimeAtVerification:
          serverTimeAtVerification ?? this.serverTimeAtVerification,
      localWallClockAtVerification:
          localWallClockAtVerification ?? this.localWallClockAtVerification,
      lastSuccessfulVerificationAt:
          lastSuccessfulVerificationAt ?? this.lastSuccessfulVerificationAt,
      isRevoked: isRevoked ?? this.isRevoked,
      revokedAt: revokedAt ?? this.revokedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      s8Signature: s8Signature ?? this.s8Signature,
      s8PublicKey: s8PublicKey ?? this.s8PublicKey,
      graceBasis: graceBasis ?? this.graceBasis,
      lastTrustedServerTimeUtc:
          lastTrustedServerTimeUtc ?? this.lastTrustedServerTimeUtc,
      userBoundary: userBoundary ?? this.userBoundary,
    );
  }
}

/// Local persistence of server-resolved entitlement snapshots.
///
/// Each snapshot is scoped by shop ID to support multi-shop isolation.
/// The cache is informational — if tampered with, the next server sync
/// overwrites with authoritative values.
class EntitlementCache {
  static const String _keyPrefix = 'cloud.license.';
  static const String _keyLastObservedClock =
      'cloud.license.lastObservedLocalClock';
  static const String _keyInstallationId = 'device.installationId';

  /// Save a server-resolved entitlement snapshot for a shop.
  Future<void> save(EntitlementSnapshot snapshot) async {
    final json = jsonEncode(snapshot.toJson());
    await AppSettings.setValue('$_keyPrefix${snapshot.shopId}', json);
  }

  /// Load the cached entitlement snapshot for a shop.
  Future<EntitlementSnapshot?> load(String shopId) async {
    final raw = await AppSettings.getValue('$_keyPrefix$shopId');
    if (raw.isEmpty) return null;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return EntitlementSnapshot.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Clear the cached entitlement for a shop.
  Future<void> clear(String shopId) async {
    await AppSettings.setValue('$_keyPrefix$shopId', '');
  }

  /// Sign and persist an S8-bound snapshot.
  ///
  /// Sets the authenticated `graceBasis`, `s8PublicKey`, `s8Signature`, and
  /// `lastTrustedServerTimeUtc`, then saves via [save]. [highWater] is the
  /// monotonic trusted server-time high-water to record. The cache is bound
  /// to [installationId] and the shop-scoped [userBoundary].
  Future<void> saveAuthenticated(
    EntitlementSnapshot snapshot, {
    required String installationId,
    required S6Identity identity,
    required DateTime highWater,
    String? userBoundary,
  }) async {
    final bound = snapshot.copyWith(
      s8PublicKey: await identity.publicKeyBase64Url(),
      graceBasis: S8CacheIntegrity.inferGraceBasis(snapshot),
      lastTrustedServerTimeUtc: highWater.toUtc(),
      userBoundary: userBoundary ?? snapshot.shopId,
    );
    final sig = await S8CacheIntegrity.signBase64Url(
      s: bound,
      installationId: installationId,
      userBoundary: bound.effectiveUserBoundary,
      identity: identity,
    );
    await save(bound.copyWith(s8Signature: sig));
  }

  /// Get the locally-generated installation identifier.
  ///
  /// This UUID is generated once and survives app restarts, login/logout,
  /// and shop switching. It does NOT survive uninstall + reinstall.
  Future<String> getInstallationId() async {
    var id = await AppSettings.getValue(_keyInstallationId);
    if (id.isEmpty) {
      id = _generateUuid();
      await AppSettings.setValue(_keyInstallationId, id);
    }
    return id;
  }

  /// Record the current local wall clock for tamper detection.
  Future<void> recordWallClock(DateTime clock) async {
    await AppSettings.setValue(_keyLastObservedClock, clock.toIso8601String());
  }

  /// Get the last observed local wall clock.
  Future<DateTime?> getLastObservedClock() async {
    final raw = await AppSettings.getValue(_keyLastObservedClock);
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Generate a simple UUID v4.
  String _generateUuid() {
    final random = List<int>.generate(16, (_) => 0);
    for (var i = 0; i < 16; i++) {
      random[i] = DateTime.now().microsecondsSinceEpoch ^ (i * 31);
    }
    random[6] = (random[6] & 0x0f) | 0x40;
    random[8] = (random[8] & 0x3f) | 0x80;
    final hex = random.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
