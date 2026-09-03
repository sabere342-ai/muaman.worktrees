import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/licensing/cloud_licensing_repository.dart';
import 'package:muaman_store/licensing/cloud_licensing_service.dart';
import 'package:muaman_store/licensing/entitlement_cache.dart';
import 'package:muaman_store/licensing/offline_grace_policy.dart';
import 'package:muaman_store/services/app_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase P Group B S5 — Client entitlement integration.
///
/// These tests prove the 25 governed scenarios from the S5 governance
/// contract. All state-resolution scenarios are exercised through the pure
/// `resolveStateFromServerForTest` / `resolveStateFromCacheForTest` seams so
/// no live Supabase round trip is required. Cache persistence scenarios use
/// the repository-native sqflite ffi database exactly like the existing
/// licensing integration tests.
void main() {
  // ────────────────────────────────────────────────────────────────────────
  // A. Server mapping / state resolution (Scenarios 1-12)
  // ────────────────────────────────────────────────────────────────────────
  group('A. Server mapping / state resolution', () {
    final service = CloudLicensingService();

    EntitlementResult result({
      required bool hasLicense,
      String? licenseStatus,
      bool isTrial = false,
      bool trialActive = false,
      DateTime? trialExpiresAt,
      DateTime? subscriptionExpiresAt,
      int? maxDevices,
      int currentDevices = 0,
      bool deviceSlotAvailable = false,
      DateTime? serverTime,
      bool isRevoked = false,
      DateTime? revokedAt,
    }) {
      return EntitlementResult(
        hasLicense: hasLicense,
        licenseStatus: licenseStatus,
        isTrial: isTrial,
        trialActive: trialActive,
        trialExpiresAt: trialExpiresAt,
        subscriptionExpiresAt: subscriptionExpiresAt,
        maxDevices: maxDevices,
        currentDevices: currentDevices,
        deviceSlotAvailable: deviceSlotAvailable,
        serverTime: serverTime ?? DateTime.utc(2026, 8, 20),
        isRevoked: isRevoked,
        revokedAt: revokedAt,
      );
    }

    test('Scenario 1: ACTIVE paid → entitled → writes allowed', () {
      final snap = service.resolveStateFromServerForTest(
        result(
          hasLicense: true,
          licenseStatus: 'ACTIVE',
          deviceSlotAvailable: true,
        ),
      );
      expect(snap.state, CloudEntitlementState.entitled);
      expect(snap.allowsWrites, true);
    });

    test('Scenario 2: TRIAL active → entitled → writes allowed', () {
      final snap = service.resolveStateFromServerForTest(
        result(
          hasLicense: true,
          licenseStatus: 'TRIAL',
          isTrial: true,
          trialActive: true,
          deviceSlotAvailable: true,
        ),
      );
      expect(snap.state, CloudEntitlementState.entitled);
      expect(snap.allowsWrites, true);
    });

    test('Scenario 3: TRIAL inactive/expired → expired → writes blocked', () {
      final snap = service.resolveStateFromServerForTest(
        result(
          hasLicense: true,
          licenseStatus: 'TRIAL',
          isTrial: true,
          trialActive: false,
        ),
      );
      expect(snap.state, CloudEntitlementState.expired);
      expect(snap.allowsWrites, false);
    });

    test(
        'Scenario 4: has_license=false + REVOKED + is_revoked=true → revoked, '
        'NOT noLicense, writes blocked (H-Gap-1)', () {
      final snap = service.resolveStateFromServerForTest(
        result(
          hasLicense: false,
          licenseStatus: 'REVOKED',
          isRevoked: true,
          revokedAt: DateTime.utc(2026, 8, 19),
        ),
      );
      expect(snap.state, CloudEntitlementState.revoked);
      expect(snap.state, isNot(CloudEntitlementState.noLicense));
      expect(snap.allowsWrites, false);
    });

    test('Scenario 4b: is_revoked=true alone → revoked even without status',
        () {
      final snap = service.resolveStateFromServerForTest(
        result(
          hasLicense: false,
          licenseStatus: null,
          isRevoked: true,
          revokedAt: DateTime.utc(2026, 8, 19),
        ),
      );
      expect(snap.state, CloudEntitlementState.revoked);
      expect(snap.allowsWrites, false);
    });

    test('Scenario 4c: license_status=REVOKED alone → revoked even if '
        'is_revoked absent', () {
      final snap = service.resolveStateFromServerForTest(
        result(hasLicense: false, licenseStatus: 'REVOKED'),
      );
      expect(snap.state, CloudEntitlementState.revoked);
      expect(snap.allowsWrites, false);
    });

    test('Scenario 5: EXPIRED → expired → blocked', () {
      final snap = service.resolveStateFromServerForTest(
        result(hasLicense: true, licenseStatus: 'EXPIRED'),
      );
      expect(snap.state, CloudEntitlementState.expired);
      expect(snap.allowsWrites, false);
    });

    test('Scenario 6: SUSPENDED → suspended → blocked', () {
      final snap = service.resolveStateFromServerForTest(
        result(hasLicense: true, licenseStatus: 'SUSPENDED'),
      );
      expect(snap.state, CloudEntitlementState.suspended);
      expect(snap.allowsWrites, false);
    });

    test('Scenario 7: has_license=false with no terminal signal → noLicense → '
        'blocked', () {
      final snap = service.resolveStateFromServerForTest(
        result(hasLicense: false, licenseStatus: null),
      );
      expect(snap.state, CloudEntitlementState.noLicense);
      expect(snap.allowsWrites, false);
    });

    test(
        'Scenario 8: is_revoked + revoked_at parsed from S3 16-column RPC '
        'and propagated', () {
      final data = {
        'has_license': false,
        'license_status': 'REVOKED',
        'is_trial': false,
        'trial_active': false,
        'trial_started_at': null,
        'trial_expires_at': null,
        'days_remaining': null,
        'hours_remaining': null,
        'activated_at': null,
        'subscription_expires_at': null,
        'max_devices': null,
        'current_devices': 0,
        'device_slot_available': false,
        'server_time': '2026-08-20T00:00:00Z',
        'is_revoked': true,
        'revoked_at': '2026-08-19T10:30:00Z',
      };
      final rpcResult = EntitlementResult.fromRpc(data);
      expect(rpcResult.isRevoked, true);
      expect(rpcResult.revokedAt, DateTime.utc(2026, 8, 19, 10, 30));

      final snap = service.resolveStateFromServerForTest(rpcResult);
      expect(snap.state, CloudEntitlementState.revoked);
      expect(snap.isRevoked, true);
      expect(snap.revokedAt, DateTime.utc(2026, 8, 19, 10, 30));
    });

    test('Scenario 9: max_devices == null → unlimited semantics, no '
        'fabricated numeric max', () {
      final snap = service.resolveStateFromServerForTest(
        result(
          hasLicense: true,
          licenseStatus: 'ACTIVE',
          maxDevices: null,
          deviceSlotAvailable: true,
        ),
      );
      expect(snap.maxDevices, isNull);
      expect(snap.state, CloudEntitlementState.entitled);
      expect(snap.allowsWrites, true);
    });

    test('Scenario 10: malformed/missing security-relevant server fields → '
        'FAIL CLOSED, no fabricated entitlement', () {
      // A license granted with no status and no trial signal is malformed.
      final malformed =
          result(hasLicense: true, licenseStatus: null, isTrial: false);
      expect(service.isMalformedSecurityStateForTest(malformed), true);

      // Missing revocation timestamps do not turn a real revocation into
      // fabricated entitlement.
      final revoked =
          result(hasLicense: false, licenseStatus: 'REVOKED', isRevoked: true);
      expect(service.isMalformedSecurityStateForTest(revoked), false);
      final snap = service.resolveStateFromServerForTest(revoked);
      expect(snap.state, CloudEntitlementState.revoked);
      expect(snap.allowsWrites, false);
    });

    test('Scenario 11: server_time captured as authoritative anchor', () {
      final serverTime = DateTime.utc(2026, 8, 20, 12, 0, 0);
      final snap = service.resolveStateFromServerForTest(
        result(
            hasLicense: true,
            licenseStatus: 'ACTIVE',
            serverTime: serverTime),
      );
      expect(snap.serverTime, serverTime);
    });

    test('Scenario 12: subscription_expires_at consumed without fabricating '
        'entitlement', () {
      // Paid active with a future subscription expiry → entitled (server
      // status already authoritative).
      final active = service.resolveStateFromServerForTest(
        result(
          hasLicense: true,
          licenseStatus: 'ACTIVE',
          subscriptionExpiresAt: DateTime.utc(2026, 12, 31),
          deviceSlotAvailable: true,
        ),
      );
      expect(active.state, CloudEntitlementState.entitled);

      // Server-authoritative EXPIRED → blocked regardless of any expiry field.
      final expired = service.resolveStateFromServerForTest(
        result(
          hasLicense: true,
          licenseStatus: 'EXPIRED',
          subscriptionExpiresAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect(expired.state, CloudEntitlementState.expired);
      expect(expired.allowsWrites, false);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // B. Cache contract (Scenarios 13-18)
  // ────────────────────────────────────────────────────────────────────────
  group('B. Cache contract', () {
    late EntitlementCache cache;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      cache = EntitlementCache();
    });

    EntitlementSnapshot snapshot({
      String shopId = 'shop-a',
      bool hasLicense = true,
      String? licenseStatus = 'ACTIVE',
      bool isTrial = false,
      bool trialActive = false,
      bool isRevoked = false,
      DateTime? revokedAt,
      int schemaVersion = kEntitlementCacheSchemaVersion,
      DateTime? verifiedAt,
    }) {
      final now = verifiedAt ?? DateTime.now().toUtc();
      return EntitlementSnapshot(
        shopId: shopId,
        hasLicense: hasLicense,
        licenseStatus: licenseStatus,
        isTrial: isTrial,
        trialActive: trialActive,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification: now,
        localWallClockAtVerification: now,
        lastSuccessfulVerificationAt: now,
        isRevoked: isRevoked,
        revokedAt: revokedAt,
        schemaVersion: schemaVersion,
      );
    }

    test('Scenario 13: save/load round trip preserves revocation + schema/'
        'version metadata', () async {
      final revokedAt = DateTime.utc(2026, 8, 19, 10, 30, 0);
      final s = snapshot(
        shopId: 'shop-a',
        hasLicense: false,
        licenseStatus: 'REVOKED',
        isRevoked: true,
        revokedAt: revokedAt,
      );
      await cache.save(s);

      final loaded = await cache.load('shop-a');
      expect(loaded, isNotNull);
      expect(loaded!.isRevoked, true);
      expect(loaded.revokedAt, revokedAt);
      expect(loaded.schemaVersion, kEntitlementCacheSchemaVersion);
      expect(loaded.isCompatibleSchema(), true);
      await cache.clear('shop-a');
    });

    test('Scenario 14: corrupt/malformed cached JSON → fail safe → treated as '
        'no trustworthy cache', () async {
      await AppSettings.setValue('cloud.license.shop-corrupt',
          '{ not valid json }');
      final loaded = await cache.load('shop-corrupt');
      expect(loaded, isNull);
      await AppSettings.setValue('cloud.license.shop-corrupt', '');
    });

    test('Scenario 15: absent/empty/corrupt cache never yields entitled or '
        'entitledCached', () async {
      final empty = await cache.load('shop-missing');
      expect(empty, isNull);

      await AppSettings.setValue('cloud.license.shop-corrupt2', 'garbage');
      final corrupt = await cache.load('shop-corrupt2');
      expect(corrupt, isNull);

      // A null/absent cache resolved offline must not produce entitlement.
      final service = CloudLicensingService();
      final resolved = service.resolveStateFromCacheForTest(
        EntitlementSnapshot(
          shopId: 'shop-x',
          hasLicense: false,
          isTrial: false,
          trialActive: false,
          currentDevices: 0,
          deviceSlotAvailable: false,
          serverTimeAtVerification: DateTime.now().toUtc(),
          localWallClockAtVerification: DateTime.now(),
          lastSuccessfulVerificationAt: DateTime.now(),
        ),
      );
      expect(resolved.allowsWrites, false);
    });

    test('Scenario 16: cached REVOKED/non-entitled blocks writes offline '
        'regardless of grace', () {
      final service = CloudLicensingService();
      final revokedSnap = snapshot(
        shopId: 'shop-a',
        hasLicense: false,
        licenseStatus: 'REVOKED',
        isRevoked: true,
      );
      final resolved = service.resolveStateFromCacheForTest(revokedSnap);
      expect(resolved.state, CloudEntitlementState.revoked);
      expect(resolved.allowsWrites, false);
    });

    test('Scenario 17: Shop A snapshot never consumed for Shop B', () async {
      final sA = snapshot(shopId: 'shop-A', hasLicense: true,
          licenseStatus: 'ACTIVE');
      await cache.save(sA);

      // Load for shop B must not see shop A's entitlement.
      final loadedB = await cache.load('shop-B');
      expect(loadedB, isNull);

      // A cached non-entitled state for shop B stays blocked.
      final nonEntitledB =
          snapshot(shopId: 'shop-B', hasLicense: false, licenseStatus: null);
      await cache.save(nonEntitledB);
      final service = CloudLicensingService();
      final b = await cache.load('shop-B');
      final resolvedB = service.resolveStateFromCacheForTest(b!);
      expect(resolvedB.allowsWrites, false);

      await cache.clear('shop-A');
      await cache.clear('shop-B');
    });

    test('Scenario 18: unknown/incompatible cache version → non-authoritative '
        '→ blocked pending revalidation', () {
      final service = CloudLicensingService();
      final futureSchema = snapshot(
        shopId: 'shop-a',
        hasLicense: true,
        licenseStatus: 'ACTIVE',
        schemaVersion: kEntitlementCacheSchemaVersion + 100,
      );
      expect(futureSchema.isCompatibleSchema(), false);
      final resolved = service.resolveStateFromCacheForTest(futureSchema);
      // An unknown schema must never grant entitledCached.
      expect(resolved.state, isNot(CloudEntitlementState.entitledCached));
      expect(resolved.allowsWrites, false);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // C. Offline grace (Scenarios 19-22)
  // ────────────────────────────────────────────────────────────────────────
  group('C. Offline grace', () {
    final service = CloudLicensingService();
    final grace = OfflineGracePolicy();

    EntitlementSnapshot cached({
      String? licenseStatus,
      bool isTrial = false,
      bool trialActive = false,
      bool isRevoked = false,
      int daysAgo = 0,
    }) {
      final now = DateTime.now().toUtc();
      final sync = now.subtract(Duration(days: daysAgo));
      return EntitlementSnapshot(
        shopId: 'shop-g',
        hasLicense: true,
        licenseStatus: licenseStatus,
        isTrial: isTrial,
        trialActive: trialActive,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification: sync,
        localWallClockAtVerification: sync,
        lastSuccessfulVerificationAt: sync,
        isRevoked: isRevoked,
      );
    }

    test('Scenario 19: TRIAL offline = zero grace → blocked', () {
      // Even a freshly-synced active trial gets no offline runway.
      final trial = cached(
          licenseStatus: 'TRIAL', isTrial: true, trialActive: true);
      expect(grace.isWithinGraceWindow(trial), false);
      final resolved = service.resolveStateFromCacheForTest(trial);
      expect(resolved.state, isNot(CloudEntitlementState.entitledCached));
      expect(resolved.allowsWrites, false);
    });

    test('Scenario 20: ACTIVE paid — inside 7 days → entitledCached; outside '
        '→ staleOffline blocked', () {
      final inside = cached(licenseStatus: 'ACTIVE', daysAgo: 3);
      expect(grace.isWithinGraceWindow(inside), true);
      final resolvedIn = service.resolveStateFromCacheForTest(inside);
      expect(resolvedIn.state, CloudEntitlementState.entitledCached);
      expect(resolvedIn.allowsWrites, true);

      final outside = cached(licenseStatus: 'ACTIVE', daysAgo: 8);
      expect(grace.isWithinGraceWindow(outside), false);
      final resolvedOut = service.resolveStateFromCacheForTest(outside);
      expect(resolvedOut.state, CloudEntitlementState.staleOffline);
      expect(resolvedOut.allowsWrites, false);
    });

    test('Scenario 21: PERPETUAL compatibility — inside 14 days → entitled'
        'Cached; outside → blocked', () {
      final inside = cached(licenseStatus: 'PERPETUAL', daysAgo: 10);
      expect(grace.isWithinGraceWindow(inside), true);
      final resolvedIn = service.resolveStateFromCacheForTest(inside);
      expect(resolvedIn.state, CloudEntitlementState.entitledCached);

      final outside = cached(licenseStatus: 'PERPETUAL', daysAgo: 15);
      expect(grace.isWithinGraceWindow(outside), false);
      final resolvedOut = service.resolveStateFromCacheForTest(outside);
      expect(resolvedOut.allowsWrites, false);
    });

    test('Scenario 22: cached REVOKED/EXPIRED/SUSPENDED — grace MUST NOT '
        'override blocked state', () {
      // Even a freshly synced non-entitled cached state remains blocked.
      final revoked =
          cached(licenseStatus: 'REVOKED', isRevoked: true, daysAgo: 0);
      expect(grace.isCachedNonEntitled(revoked), true);
      final resolvedR = service.resolveStateFromCacheForTest(revoked);
      expect(resolvedR.allowsWrites, false);
      expect(resolvedR.state, CloudEntitlementState.revoked);

      final suspended = cached(licenseStatus: 'SUSPENDED', daysAgo: 0);
      final resolvedS = service.resolveStateFromCacheForTest(suspended);
      expect(resolvedS.state, CloudEntitlementState.suspended);
      expect(resolvedS.allowsWrites, false);

      final expiredSnap = cached(licenseStatus: 'EXPIRED', daysAgo: 0);
      final resolvedE = service.resolveStateFromCacheForTest(expiredSnap);
      expect(resolvedE.allowsWrites, false);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // D. Convergence / revalidation (Scenarios 23-24)
  // ────────────────────────────────────────────────────────────────────────
  group('D. Convergence / reconnect', () {
    final service = CloudLicensingService();

    test('Scenario 23: fresh server revalidation replaces stale cache with '
        'authoritative truth', () {
      // Simulate an offline stale cache that previously had entitlement.
      final stale = EntitlementSnapshot(
        shopId: 'shop-c',
        hasLicense: true,
        licenseStatus: 'ACTIVE',
        isTrial: false,
        trialActive: false,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt:
            DateTime.now().toUtc().subtract(const Duration(days: 10)),
      );
      final staleResolved = service.resolveStateFromCacheForTest(stale);
      expect(staleResolved.state, CloudEntitlementState.staleOffline);

      // Fresh server result says entitled → converge to entitled.
      final fresh = EntitlementResult(
        hasLicense: true,
        licenseStatus: 'ACTIVE',
        isTrial: false,
        trialActive: false,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTime: DateTime.now().toUtc(),
      );
      expect(service.resolveStateFromServerForTest(fresh).state,
          CloudEntitlementState.entitled);
    });

    test('Scenario 24: revoked while offline → revalidate → revoked + blocked; '
        'legitimate re-entitlement → allowed only when server says entitled',
        () {
      // Server now says REVOKED → converge to revoked + blocked.
      final revokedServer = EntitlementResult(
        hasLicense: false,
        licenseStatus: 'REVOKED',
        isTrial: false,
        trialActive: false,
        currentDevices: 0,
        deviceSlotAvailable: false,
        serverTime: DateTime.now().toUtc(),
        isRevoked: true,
        revokedAt: DateTime.now().toUtc(),
      );
      final revoked = service.resolveStateFromServerForTest(revokedServer);
      expect(revoked.state, CloudEntitlementState.revoked);
      expect(revoked.allowsWrites, false);

      // Server legitimately returns entitled → allowed only then.
      final entitledServer = EntitlementResult(
        hasLicense: true,
        licenseStatus: 'ACTIVE',
        isTrial: false,
        trialActive: false,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTime: DateTime.now().toUtc(),
      );
      final entitled = service.resolveStateFromServerForTest(entitledServer);
      expect(entitled.state, CloudEntitlementState.entitled);
      expect(entitled.allowsWrites, true);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // E. Backward compatibility (Scenario 25)
  // ────────────────────────────────────────────────────────────────────────
  group('E. Backward compatibility', () {
    final service = CloudLicensingService();

    test('Scenario 25: pre-S3 payload missing revocation signal must still '
        'fail closed, never fabricate entitlement', () {
      // A pre-S3 ACTIVE payload without is_revoked/revoked_at fields parses
      // with isRevoked=false and remains entitled (backward compatible).
      final preS3Active = EntitlementResult.fromRpc({
        'has_license': true,
        'license_status': 'ACTIVE',
        'is_trial': false,
        'trial_active': false,
        'trial_started_at': null,
        'trial_expires_at': null,
        'days_remaining': 30,
        'hours_remaining': 12,
        'activated_at': null,
        'subscription_expires_at': '2026-12-31T00:00:00Z',
        'max_devices': 3,
        'current_devices': 1,
        'device_slot_available': true,
        'server_time': '2026-08-20T00:00:00Z',
      });
      expect(preS3Active.isRevoked, false);
      expect(preS3Active.revokedAt, isNull);
      expect(service.resolveStateFromServerForTest(preS3Active).allowsWrites,
          true);

      // A pre-S3 payload with no license and status REVOKED (without the S3
      // boolean) still maps to revoked, not fabricated entitlement.
      final preS3Revoked = EntitlementResult.fromRpc({
        'has_license': false,
        'license_status': 'REVOKED',
        'is_trial': false,
        'trial_active': false,
        'days_remaining': null,
        'hours_remaining': null,
        'max_devices': null,
        'current_devices': 0,
        'device_slot_available': false,
        'server_time': '2026-08-20T00:00:00Z',
      });
      expect(service.resolveStateFromServerForTest(preS3Revoked).state,
          CloudEntitlementState.revoked);
      expect(service.resolveStateFromServerForTest(preS3Revoked).allowsWrites,
          false);
    });
  });
}
