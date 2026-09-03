import 'dart:convert';
import '../services/app_settings.dart';

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
  });

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
      };

  factory EntitlementSnapshot.fromJson(Map<String, dynamic> json) {
    return EntitlementSnapshot(
      schemaVersion: json['schemaVersion'] as int? ??
          kEntitlementCacheSchemaVersion,
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
