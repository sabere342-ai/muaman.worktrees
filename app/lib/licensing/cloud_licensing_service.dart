import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../platform/platform_capabilities.dart';
import 'cloud_licensing_repository.dart';
import 'entitlement_cache.dart';
import 'license_exception.dart';
import 'offline_grace_policy.dart';
import 's6_device_identity.dart';
import 's8_cache_integrity.dart';

/// Client-side combined entitlement state derived from three dimensions:
/// 1. License Entitlement (server-resolved)
/// 2. Device Activation (server-resolved)
/// 3. Connectivity State (client-detected)
enum CloudEntitlementState {
  /// No license exists for this shop.
  noLicense,

  /// Trial is active and device is activated — writes allowed.
  entitled,

  /// Trial or license is active, device activated, but offline (cached).
  entitledCached,

  /// Trial/license is active, but device is not registered/activated.
  activating,

  /// Device never successfully activated, offline.
  offlineNoActivation,

  /// Trial or license has expired.
  expired,

  /// License is active but device activation was revoked.
  deviceRevoked,

  /// License is active but offline beyond grace window.
  staleOffline,

  /// License has been suspended.
  suspended,

  /// License has been revoked.
  revoked,

  /// No license and online — no entitlement.
  offlineNoLicense,

  /// Clock tamper suspected — online revalidation required.
  clockTamper,
}

/// Snapshot of cloud licensing state for UI and enforcement.
class CloudEntitlementSnapshot {
  final CloudEntitlementState state;
  final bool hasLicense;
  final String? licenseStatus;
  final bool isTrial;
  final bool trialActive;
  final DateTime? trialExpiresAt;
  final int? daysRemaining;
  final int? maxDevices;
  final int currentDevices;
  final bool deviceActivated;
  final bool isOnline;
  final DateTime? serverTime;
  final DateTime? cachedTime;
  final String? errorMessage;
  final bool isRevoked;
  final DateTime? revokedAt;

  const CloudEntitlementSnapshot({
    required this.state,
    required this.hasLicense,
    this.licenseStatus,
    required this.isTrial,
    required this.trialActive,
    this.trialExpiresAt,
    this.daysRemaining,
    this.maxDevices,
    required this.currentDevices,
    required this.deviceActivated,
    required this.isOnline,
    this.serverTime,
    this.cachedTime,
    this.errorMessage,
    this.isRevoked = false,
    this.revokedAt,
  });

  /// Whether writes are allowed in this entitlement state.
  bool get allowsWrites =>
      state == CloudEntitlementState.entitled ||
      state == CloudEntitlementState.entitledCached;

  /// Whether writes are blocked.
  bool get blocksWrites => !allowsWrites;

  static const unknown = CloudEntitlementSnapshot(
    state: CloudEntitlementState.offlineNoLicense,
    hasLicense: false,
    isTrial: false,
    trialActive: false,
    currentDevices: 0,
    deviceActivated: false,
    isOnline: false,
  );
}

/// Cloud-backed licensing orchestration service.
///
/// Combines server-side entitlement resolution, local cache, offline grace
/// policy, and device activation into a single service that the rest of the
/// app consults for licensing decisions.
///
/// The flow is:
/// 1. On login/initialization: resolveEntitlement(shopId)
/// 2. Server response → EntitlementSnapshot → cache locally
/// 3. Offline: use cache within grace window
/// 4. Enforcement: enforceActive() → throws if writes blocked
class CloudLicensingService {
  static final CloudLicensingService _instance = CloudLicensingService._();
  factory CloudLicensingService() => _instance;
  CloudLicensingService._();

  static CloudLicensingService get instance => _instance;

  final CloudLicensingRepository _repository = CloudLicensingRepository();
  final EntitlementCache _cache = EntitlementCache();
  final OfflineGracePolicy _gracePolicy = OfflineGracePolicy();

  S6DeviceIdentity? _s6Identity;

  CloudEntitlementSnapshot _currentState = CloudEntitlementSnapshot.unknown;
  String? _activeShopId;
  String? _installationId;
  bool _initialized = false;

  /// Current entitlement snapshot.
  CloudEntitlementSnapshot get currentState => _currentState;

  /// The active shop ID this service is tracking.
  String? get activeShopId => _activeShopId;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Get the installation ID (generated once, stored persistently).
  Future<String> getInstallationId() async {
    _installationId ??= await _cache.getInstallationId();
    return _installationId!;
  }

  /// Initialize the service. Called once during app startup.
  ///
  /// Loads cached state for the active shop and attempts online resolution
  /// if cloud is available.
  Future<void> initialize({
    String? shopId,
    bool isCloudLinked = false,
  }) async {
    _installationId = await _cache.getInstallationId();

    if (shopId != null) {
      _activeShopId = shopId;

      // Load cached state. S8: a cache is only trustworthy for offline
      // authority if it is S8-bound and its binding verifies against the
      // current S6 device identity and the protected trusted-time high-water
      // (anti-rollback). Pre-S8/unbound/invalid/unverifiable caches fail
      // closed and require online revalidation (OLD_CACHE_REQUIRES_ONLINE_
      // REVALIDATION / N).
      final cached = await _cache.load(shopId);
      if (cached != null) {
        final verified = await _verifyCachedForOffline(cached, shopId);
        _currentState = verified
            ? _resolveStateFromCache(cached)
            : _requiresRevalidationState(cached);
      }
      // Attempt online resolution if cloud is available
      if (isCloudLinked && AppConfig.isConfigured) {
        try {
          await resolveEntitlement(shopId);
        } catch (_) {
          // Offline — keep cached state
        }
      }
    }

    _initialized = true;
  }

  /// Resolve entitlement for a shop from the server.
  ///
  /// This is the primary server-authoritative operation. It calls the
  /// verify_license_entitlement RPC and caches the result.
  Future<CloudEntitlementSnapshot> resolveEntitlement(String shopId) async {
    try {
      final result = await _repository.verifyLicenseEntitlement(shopId);

      if (_isMalformedSecurityState(result)) {
        // FAIL CLOSED: malformed/missing security-relevant server fields must
        // never fabricate entitlement. Treat as blocked pending valid server
        // resolution.
        _activeShopId = shopId;
        _currentState = CloudEntitlementSnapshot(
          state: CloudEntitlementState.noLicense,
          hasLicense: false,
          isTrial: false,
          trialActive: false,
          currentDevices: result.currentDevices,
          deviceActivated: false,
          isOnline: true,
          serverTime: result.serverTime,
          errorMessage: 'Malformed entitlement state from server',
        );
        return _currentState;
      }

      // Create cache snapshot
      final serverTimeUtc = result.serverTime.toUtc();
      final snapshot = EntitlementSnapshot(
        shopId: shopId,
        hasLicense: result.hasLicense,
        licenseStatus: result.licenseStatus,
        isTrial: result.isTrial,
        trialActive: result.trialActive,
        trialStartedAt: result.trialStartedAt,
        trialExpiresAt: result.trialExpiresAt,
        daysRemaining: result.daysRemaining,
        activatedAt: result.activatedAt,
        subscriptionExpiresAt: result.subscriptionExpiresAt,
        maxDevices: result.maxDevices,
        currentDevices: result.currentDevices,
        deviceSlotAvailable: result.deviceSlotAvailable,
        serverTimeAtVerification: serverTimeUtc,
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
        isRevoked: result.isRevoked,
        revokedAt: result.revokedAt,
      );

      // S8: persist the trusted server-time high-water (monotonic, protected
      // store) and bind the cache with a device signature so tampering is
      // detectable and replay/rollback fails closed.
      final boundOutcome = await _persistTrustedAndBind(snapshot, shopId);

      if (!boundOutcome.bound) {
        // Secure identity unavailable / a materially stale authoritative
        // response cannot establish fresh offline authority. Fail closed:
        // do not grant offline-capable entitledCached from this response; the
        // live server authority (R1) is still reflected by state resolution.
        _activeShopId = shopId;
        _currentState = _requiresRevalidationState(snapshot);
        return _currentState;
      }

      // Cache the S8-bound result
      await _cache.save(boundOutcome.snapshot);
      await _cache.recordWallClock(DateTime.now());

      // Resolve combined state
      _activeShopId = shopId;
      _currentState = _resolveStateFromServer(result);
      return _currentState;
    } catch (e) {
      // Server unreachable — use cached state
      final cached = await _cache.load(shopId);
      if (cached != null) {
        _currentState = _resolveStateFromCache(cached);
      } else {
        _currentState = CloudEntitlementSnapshot(
          state: CloudEntitlementState.offlineNoLicense,
          hasLicense: false,
          isTrial: false,
          trialActive: false,
          currentDevices: 0,
          deviceActivated: false,
          isOnline: false,
          errorMessage: e.toString(),
        );
      }
      return _currentState;
    }
  }

  /// Start a 14-day trial for a shop.
  Future<void> startTrial(String shopId) async {
    await _repository.startTrial(shopId);
    // Re-resolve entitlement after trial start
    await resolveEntitlement(shopId);
  }

  /// Register this device for a shop.
  Future<DeviceRegistrationResult> registerDevice(String shopId) async {
    final installationId = await getInstallationId();
    return await _repository.registerDevice(
      shopId: shopId,
      installationId: installationId,
      platform: _detectPlatform(),
      deviceName: _getDeviceName(),
    );
  }

  /// Activate this device under the shop license.
  Future<DeviceActivationResult> activateDevice(String shopId) async {
    final installationId = await getInstallationId();
    return await _repository.activateDevice(
      shopId: shopId,
      installationId: installationId,
    );
  }

  /// Owner deactivates a device.
  Future<bool> deactivateDevice(String activationId) async {
    return await _repository.deactivateDevice(activationId);
  }

  /// Get the device list for a shop (owner-only).
  Future<List<Map<String, dynamic>>> getDeviceList(String shopId) async {
    return await _repository.getDeviceList(shopId);
  }

  /// Force online revalidation.
  Future<CloudEntitlementSnapshot> refreshEntitlement(String shopId) async {
    return await resolveEntitlement(shopId);
  }

  /// Switch to a different shop and resolve its entitlement.
  Future<CloudEntitlementSnapshot> switchShop(String newShopId) async {
    _activeShopId = newShopId;
    return await resolveEntitlement(newShopId);
  }

  /// Enforcement boundary check.
  ///
  /// Throws [CloudLicenseWriteBlockedException] if writes are not allowed.
  /// Called by [DatabaseHelper._enforceLicensing] before every business write.
  Future<void> enforceActive() async {
    if (_currentState.blocksWrites) {
      throw CloudLicenseWriteBlockedException(
        _getBlockMessage(_currentState.state),
      );
    }
  }

  /// Clear cached entitlement for a shop.
  Future<void> clearCache(String shopId) async {
    await _cache.clear(shopId);
  }

  /// Clear all state (e.g., on logout).
  void reset() {
    _currentState = CloudEntitlementSnapshot.unknown;
    _activeShopId = null;
    _initialized = false;
  }

  /// Pure server-state resolution for a single [EntitlementResult].
  ///
  /// Exposed for deterministic testing of the server→client state mapping
  /// (including H-Gap-1 REVOKED precedence) without requiring a live cloud
  /// round trip. Production callers continue to use [resolveEntitlement],
  /// which also persists the authoritative cache snapshot.
  @visibleForTesting
  CloudEntitlementSnapshot resolveStateFromServerForTest(
      EntitlementResult result) {
    return _resolveStateFromServer(result);
  }

  /// Pure cache-state resolution for a single cached [EntitlementSnapshot].
  ///
  /// Exposed for deterministic offline/grace testing.
  @visibleForTesting
  CloudEntitlementSnapshot resolveStateFromCacheForTest(
      EntitlementSnapshot cached) {
    return _resolveStateFromCache(cached);
  }

  /// Determine whether a malformed/missing security-relevant server state is
  /// present (fail-closed). Exposed for deterministic testing.
  @visibleForTesting
  bool isMalformedSecurityStateForTest(EntitlementResult result) {
    return _isMalformedSecurityState(result);
  }

  // ─── S8 cache-integrity / trusted-time helpers ───────────────────────

  /// Verify a cached snapshot is trustworthy for offline authority:
  /// 1. S8-bound (has signature + public key);
  /// 2. device-bound (public key matches the current S6 device identity and
  ///    the signature verifies over the canonical payload);
  /// 3. anti-rollback (the cache's trusted baseline is not behind the
  ///    independently-protected high-water).
  ///
  /// Anything that cannot be proven fails closed (returns false) and routes
  /// to online revalidation (R6/R7/R3/Section 19).
  Future<bool> _verifyCachedForOffline(
      EntitlementSnapshot cached, String shopId) async {
    if (!cached.isS8Bound) return false;
    try {
      final installationId =
          _installationId ?? await _cache.getInstallationId();
      final device = await _s8DeviceIdentity();
      final identity = await device.loadOrCreate().then((o) => o.identity);
      final publicKey = await identity.publicKeyBase64Url();
      if (publicKey != cached.s8PublicKey) return false;

      final payloadOk = await S8CacheIntegrity.verify(
        s: cached,
        installationId: installationId,
        userBoundary: cached.effectiveUserBoundary,
        publicKeyBase64Url: cached.s8PublicKey!,
        signatureBase64Url: cached.s8Signature!,
      );
      if (!payloadOk) return false;

      final highWater = await device.readTrustedTimeHighWater();
      final baseline =
          cached.lastTrustedServerTimeUtc ?? cached.serverTimeAtVerification;
      if (S8CacheIntegrity.isReplayOrRollback(
          cacheHighWater: baseline, protectedHighWater: highWater)) {
        return false;
      }
      return true;
    } catch (_) {
      // Secure identity unavailable / protected store failed -> fail closed.
      return false;
    }
  }

  /// Resolve a snapshot into a fail-closed "requires online revalidation"
  /// state (never entitledCached) for unbound/invalid/unverifiable caches.
  CloudEntitlementSnapshot _requiresRevalidationState(
      EntitlementSnapshot cached) {
    return CloudEntitlementSnapshot(
      state: CloudEntitlementState.staleOffline,
      hasLicense: cached.hasLicense,
      licenseStatus: cached.licenseStatus,
      isTrial: cached.isTrial,
      trialActive: cached.trialActive,
      trialExpiresAt: cached.trialExpiresAt,
      daysRemaining: cached.daysRemaining,
      maxDevices: cached.maxDevices,
      currentDevices: cached.currentDevices,
      deviceActivated: cached.deviceSlotAvailable,
      isOnline: false,
      serverTime: cached.serverTimeAtVerification,
      cachedTime: cached.lastSuccessfulVerificationAt,
      isRevoked: cached.isRevoked,
      revokedAt: cached.revokedAt,
    );
  }

  /// Persist the monotonic trusted server-time high-water in the protected
  /// store and bind the cache with a device signature.
  ///
  /// Returns the bound snapshot plus a `bound` flag. When the S6 secure
  /// identity is unavailable, or the fresh authoritative response is
  /// materially stale relative to the protected high-water (anti-replay,
  /// R1/T19), the result is NOT bound and offline authority is not granted
  /// from this response.
  Future<_S8BindOutcome> _persistTrustedAndBind(
      EntitlementSnapshot snapshot, String shopId) async {
    try {
      final device = await _s8DeviceIdentity();
      final identity = await device.loadOrCreate().then((o) => o.identity);

      final protectedHighWater = await device.readTrustedTimeHighWater();

      // Anti-replay: a materially stale authoritative response is not accepted
      // as a fresh authority baseline (Section 12 / T19).
      if (S8CacheIntegrity.isStaleAuthority(
          serverTime: snapshot.serverTimeAtVerification,
          protectedHighWater: protectedHighWater)) {
        return _S8BindOutcome(snapshot: snapshot, bound: false);
      }

      final highWater = S8CacheIntegrity.advanceHighWater(
        serverTime: snapshot.serverTimeAtVerification,
        protectedHighWater: protectedHighWater,
      );
      final installationId =
          _installationId ?? await _cache.getInstallationId();

      final bound = snapshot.copyWith(
        s8PublicKey: await identity.publicKeyBase64Url(),
        graceBasis: S8CacheIntegrity.inferGraceBasis(snapshot),
        lastTrustedServerTimeUtc: highWater.toUtc(),
        userBoundary: snapshot.shopId,
      );
      final signature = await S8CacheIntegrity.signBase64Url(
        s: bound,
        installationId: installationId,
        userBoundary: bound.effectiveUserBoundary,
        identity: identity,
      );
      await device.writeTrustedTimeHighWater(highWater);
      return _S8BindOutcome(
        snapshot: bound.copyWith(s8Signature: signature),
        bound: true,
      );
    } catch (_) {
      // Secure identity unavailable / protected store failed -> fail closed.
      return _S8BindOutcome(snapshot: snapshot, bound: false);
    }
  }

  /// Lazily obtain the S6 device identity service backed by the platform
  /// protected secret store (DPAPI / Keystore).
  Future<S6DeviceIdentity> _s8DeviceIdentity() async {
    _s6Identity ??= S6DeviceIdentity(createDefaultS6DeviceSecretStore());
    return _s6Identity!;
  }

  // ─── Private state / helpers (pre-existing) ─────────────────────────

  CloudEntitlementSnapshot _resolveStateFromServer(EntitlementResult result) {
    final status = result.licenseStatus;

    // H-Gap-1: REVOKED precedence. S3 returns a revoked license as
    // has_license=false + license_status='REVOKED' + is_revoked=true. This
    // authoritative determination MUST happen before the generic no-license
    // resolution so a revocation is not misclassified as a mere noLicense.
    final normalizedStatus = status?.toUpperCase();
    if (result.isRevoked || normalizedStatus == 'REVOKED') {
      return CloudEntitlementSnapshot(
        state: CloudEntitlementState.revoked,
        hasLicense: result.hasLicense,
        licenseStatus: status,
        isTrial: result.isTrial,
        trialActive: false,
        currentDevices: result.currentDevices,
        deviceActivated: false,
        isOnline: true,
        serverTime: result.serverTime,
        isRevoked: true,
        revokedAt: result.revokedAt,
      );
    }

    if (!result.hasLicense) {
      return CloudEntitlementSnapshot(
        state: CloudEntitlementState.noLicense,
        hasLicense: false,
        isTrial: false,
        trialActive: false,
        currentDevices: result.currentDevices,
        deviceActivated: false,
        isOnline: true,
        serverTime: result.serverTime,
      );
    }

    // Expired / Suspended / Revoked
    if (status == 'EXPIRED') {
      return CloudEntitlementSnapshot(
        state: CloudEntitlementState.expired,
        hasLicense: true,
        licenseStatus: status,
        isTrial: result.isTrial,
        trialActive: false,
        trialExpiresAt: result.trialExpiresAt,
        daysRemaining: result.daysRemaining,
        maxDevices: result.maxDevices,
        currentDevices: result.currentDevices,
        deviceActivated: result.deviceSlotAvailable,
        isOnline: true,
        serverTime: result.serverTime,
      );
    }
    if (status == 'SUSPENDED') {
      return CloudEntitlementSnapshot(
        state: CloudEntitlementState.suspended,
        hasLicense: true,
        licenseStatus: status,
        isTrial: false,
        trialActive: false,
        currentDevices: result.currentDevices,
        deviceActivated: false,
        isOnline: true,
        serverTime: result.serverTime,
      );
    }

    // Trial or Active license
    if (result.isTrial && !result.trialActive) {
      return CloudEntitlementSnapshot(
        state: CloudEntitlementState.expired,
        hasLicense: true,
        licenseStatus: status,
        isTrial: true,
        trialActive: false,
        trialExpiresAt: result.trialExpiresAt,
        daysRemaining: 0,
        maxDevices: result.maxDevices,
        currentDevices: result.currentDevices,
        deviceActivated: result.deviceSlotAvailable,
        isOnline: true,
        serverTime: result.serverTime,
      );
    }

    // Entitled (trial or paid) — writes allowed
    return CloudEntitlementSnapshot(
      state: CloudEntitlementState.entitled,
      hasLicense: true,
      licenseStatus: status,
      isTrial: result.isTrial,
      trialActive: result.trialActive,
      trialExpiresAt: result.trialExpiresAt,
      daysRemaining: result.daysRemaining,
      maxDevices: result.maxDevices,
      currentDevices: result.currentDevices,
      deviceActivated: result.deviceSlotAvailable,
      isOnline: true,
      serverTime: result.serverTime,
    );
  }

  CloudEntitlementSnapshot _resolveStateFromCache(EntitlementSnapshot cached) {
    // Unknown/incompatible cache schema must never be trusted for entitlement.
    // Treat as non-authoritative → blocked pending server revalidation.
    if (!cached.isCompatibleSchema()) {
      return CloudEntitlementSnapshot(
        state: CloudEntitlementState.staleOffline,
        hasLicense: cached.hasLicense,
        licenseStatus: cached.licenseStatus,
        isTrial: cached.isTrial,
        trialActive: cached.trialActive,
        trialExpiresAt: cached.trialExpiresAt,
        daysRemaining: cached.daysRemaining,
        maxDevices: cached.maxDevices,
        currentDevices: cached.currentDevices,
        deviceActivated: cached.deviceSlotAvailable,
        isOnline: false,
        serverTime: cached.serverTimeAtVerification,
        cachedTime: cached.lastSuccessfulVerificationAt,
        isRevoked: cached.isRevoked,
        revokedAt: cached.revokedAt,
      );
    }

    // Cached authoritative revocation must remain blocked offline regardless
    // of grace. Never let offline grace override cached revoked/non-entitled.
    if (cached.isRevoked ||
        cached.licenseStatus == 'REVOKED' ||
        cached.licenseStatus == 'SUSPENDED') {
      final state = cached.isRevoked || cached.licenseStatus == 'REVOKED'
          ? CloudEntitlementState.revoked
          : CloudEntitlementState.suspended;
      return CloudEntitlementSnapshot(
        state: state,
        hasLicense: cached.hasLicense,
        licenseStatus: cached.licenseStatus,
        isTrial: cached.isTrial,
        trialActive: cached.trialActive,
        trialExpiresAt: cached.trialExpiresAt,
        daysRemaining: cached.daysRemaining,
        maxDevices: cached.maxDevices,
        currentDevices: cached.currentDevices,
        deviceActivated: cached.deviceSlotAvailable,
        isOnline: false,
        serverTime: cached.serverTimeAtVerification,
        cachedTime: cached.lastSuccessfulVerificationAt,
        isRevoked: cached.isRevoked,
        revokedAt: cached.revokedAt,
      );
    }

    // Non-entitled cached states
    if (_gracePolicy.isCachedNonEntitled(cached)) {
      return CloudEntitlementSnapshot(
        state: CloudEntitlementState.expired,
        hasLicense: cached.hasLicense,
        licenseStatus: cached.licenseStatus,
        isTrial: cached.isTrial,
        trialActive: false,
        trialExpiresAt: cached.trialExpiresAt,
        daysRemaining: cached.daysRemaining,
        maxDevices: cached.maxDevices,
        currentDevices: cached.currentDevices,
        deviceActivated: cached.deviceSlotAvailable,
        isOnline: false,
        serverTime: cached.serverTimeAtVerification,
        cachedTime: cached.lastSuccessfulVerificationAt,
        isRevoked: cached.isRevoked,
        revokedAt: cached.revokedAt,
      );
    }

    // Check grace window
    if (_gracePolicy.isWithinGraceWindow(cached)) {
      return CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitledCached,
        hasLicense: cached.hasLicense,
        licenseStatus: cached.licenseStatus,
        isTrial: cached.isTrial,
        trialActive: cached.trialActive,
        trialExpiresAt: cached.trialExpiresAt,
        daysRemaining: cached.daysRemaining,
        maxDevices: cached.maxDevices,
        currentDevices: cached.currentDevices,
        deviceActivated: cached.deviceSlotAvailable,
        isOnline: false,
        serverTime: cached.serverTimeAtVerification,
        cachedTime: cached.lastSuccessfulVerificationAt,
        isRevoked: cached.isRevoked,
        revokedAt: cached.revokedAt,
      );
    }

    // Beyond grace window — stale
    return CloudEntitlementSnapshot(
      state: CloudEntitlementState.staleOffline,
      hasLicense: cached.hasLicense,
      licenseStatus: cached.licenseStatus,
      isTrial: cached.isTrial,
      trialActive: cached.trialActive,
      trialExpiresAt: cached.trialExpiresAt,
      daysRemaining: cached.daysRemaining,
      maxDevices: cached.maxDevices,
      currentDevices: cached.currentDevices,
      deviceActivated: cached.deviceSlotAvailable,
      isOnline: false,
      serverTime: cached.serverTimeAtVerification,
      cachedTime: cached.lastSuccessfulVerificationAt,
      isRevoked: cached.isRevoked,
      revokedAt: cached.revokedAt,
    );
  }

  /// Fail-closed determination for malformed/missing security-relevant server
  /// fields. A revoked license that omits its revocation signal must still fail
  /// closed (never fabricate entitlement), and a genuinely entitled result
  /// must not be rejected due to unrelated optional fields.
  bool _isMalformedSecurityState(EntitlementResult result) {
    if (result.isRevoked || result.licenseStatus?.toUpperCase() == 'REVOKED') {
      return false;
    }
    // If the server explicitly says it granted a license without any usable
    // entitlement signal, that is malformed security state → fail closed.
    if (result.hasLicense && result.licenseStatus == null && !result.isTrial) {
      return true;
    }
    return false;
  }

  String _getBlockMessage(CloudEntitlementState state) {
    switch (state) {
      case CloudEntitlementState.noLicense:
        return 'يتطلب تفعيل الرخصة';
      case CloudEntitlementState.expired:
        return 'انتهت الصلاحية. يرجى تفعيل الرخصة.';
      case CloudEntitlementState.suspended:
        return 'تم تعليق الرخصة. يرجى التواصل مع I Tech.';
      case CloudEntitlementState.revoked:
        return 'تم إلغاء الرخصة. يرجى التواصل مع I Tech.';
      case CloudEntitlementState.deviceRevoked:
        return 'هذا الجهاز لم يعد مصرحاً به.';
      case CloudEntitlementState.staleOffline:
        return 'يتطلب التحقق من الرخصة. يرجى الاتصال بالإنترنت.';
      case CloudEntitlementState.offlineNoLicense:
        return 'يتطلب اتصال بالإنترنت للتحقق من الرخصة.';
      case CloudEntitlementState.offlineNoActivation:
        return 'يتطلب اتصال بالإنترنت لتفعيل الجهاز.';
      case CloudEntitlementState.activating:
        return 'جاري تفعيل الجهاز...';
      case CloudEntitlementState.clockTamper:
        return 'تم اكتشاف تغيير غير طبيعي في الوقت.';
      case CloudEntitlementState.entitled:
      case CloudEntitlementState.entitledCached:
        return '';
    }
  }

  String _detectPlatform() =>
      detectPlatformLabelFor(isAndroidPlatform: PlatformCapabilities.isAndroid);

  String? _getDeviceName() =>
      detectDeviceNameFor(isAndroidPlatform: PlatformCapabilities.isAndroid);
}

/// Result of S8 cache-binding: the (possibly bound) snapshot and whether it
/// was successfully bound with a device signature and trusted high-water.
class _S8BindOutcome {
  final EntitlementSnapshot snapshot;
  final bool bound;

  _S8BindOutcome({required this.snapshot, required this.bound});
}

/// Truthful platform reporting mapping (Phase K D6).
///
/// The server contract (`devices.platform`) accepts 'windows' | 'android'
/// only; the client reports what is actually running. Host-VM tests run on
/// the desktop path, preserving historical behavior.
@visibleForTesting
String detectPlatformLabelFor({required bool isAndroidPlatform}) {
  return isAndroidPlatform ? 'android' : 'windows';
}

/// Truthful device-name reporting (Phase K D6): Android devices are no
/// longer reported as a generic desktop.
@visibleForTesting
String detectDeviceNameFor({required bool isAndroidPlatform}) {
  return isAndroidPlatform ? 'Android' : 'Desktop';
}
