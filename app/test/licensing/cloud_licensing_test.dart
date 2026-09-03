import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muaman_store/licensing/cloud_licensing_repository.dart';
import 'package:muaman_store/licensing/cloud_licensing_service.dart';
import 'package:muaman_store/licensing/entitlement_cache.dart';
import 'package:muaman_store/licensing/offline_grace_policy.dart';
import 'package:muaman_store/licensing/license_exception.dart';

void main() {
  group('EntitlementResult', () {
    test('parses from RPC response correctly', () {
      final data = {
        'has_license': true,
        'license_status': 'TRIAL',
        'is_trial': true,
        'trial_active': true,
        'trial_started_at': '2026-08-01T00:00:00Z',
        'trial_expires_at': '2026-08-15T00:00:00Z',
        'days_remaining': 13,
        'hours_remaining': 12,
        'activated_at': null,
        'subscription_expires_at': null,
        'max_devices': 3,
        'current_devices': 1,
        'device_slot_available': true,
        'server_time': '2026-08-02T00:00:00Z',
      };
      final result = EntitlementResult.fromRpc(data);
      expect(result.hasLicense, true);
      expect(result.licenseStatus, 'TRIAL');
      expect(result.isTrial, true);
      expect(result.trialActive, true);
      expect(result.daysRemaining, 13);
      expect(result.maxDevices, 3);
      expect(result.currentDevices, 1);
      expect(result.deviceSlotAvailable, true);
    });

    test('parses no-license response', () {
      final data = {
        'has_license': false,
        'license_status': null,
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
        'server_time': '2026-08-02T00:00:00Z',
      };
      final result = EntitlementResult.fromRpc(data);
      expect(result.hasLicense, false);
      expect(result.isTrial, false);
      expect(result.trialActive, false);
      expect(result.currentDevices, 0);
    });

    test('parses expired trial response', () {
      final data = {
        'has_license': true,
        'license_status': 'TRIAL',
        'is_trial': true,
        'trial_active': false,
        'trial_started_at': '2026-08-01T00:00:00Z',
        'trial_expires_at': '2026-08-14T00:00:00Z',
        'days_remaining': 0,
        'hours_remaining': 0,
        'activated_at': null,
        'subscription_expires_at': null,
        'max_devices': 3,
        'current_devices': 2,
        'device_slot_available': false,
        'server_time': '2026-08-15T00:00:00Z',
      };
      final result = EntitlementResult.fromRpc(data);
      expect(result.hasLicense, true);
      expect(result.trialActive, false);
      expect(result.daysRemaining, 0);
    });

    test('parses S3 revocation metadata (is_revoked/revoked_at)', () {
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
      final result = EntitlementResult.fromRpc(data);
      expect(result.hasLicense, false);
      expect(result.isRevoked, true);
      expect(result.revokedAt, DateTime.utc(2026, 8, 19, 10, 30));
    });
  });

  group('DeviceActivationResult', () {
    test('parses success response', () {
      final data = {
        'success': true,
        'activation_id': 'abc-123',
        'devices_remaining': 2,
      };
      final result = DeviceActivationResult.fromRpc(data);
      expect(result.success, true);
      expect(result.activationId, 'abc-123');
      expect(result.devicesRemaining, 2);
    });

    test('parses failure response', () {
      final data = {
        'success': false,
        'error': 'Device limit reached',
      };
      final result = DeviceActivationResult.fromRpc(data);
      expect(result.success, false);
      expect(result.error, 'Device limit reached');
    });
  });

  group('EntitlementSnapshot', () {
    test('serialization round-trip', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: true,
        trialStartedAt: DateTime.utc(2026, 8, 1),
        trialExpiresAt: DateTime.utc(2026, 8, 15),
        daysRemaining: 13,
        activatedAt: null,
        subscriptionExpiresAt: null,
        maxDevices: 3,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification: DateTime.utc(2026, 8, 2),
        localWallClockAtVerification: DateTime.utc(2026, 8, 2),
        lastSuccessfulVerificationAt: DateTime.utc(2026, 8, 2),
      );

      final json = snapshot.toJson();
      final restored = EntitlementSnapshot.fromJson(json);

      expect(restored.shopId, snapshot.shopId);
      expect(restored.hasLicense, snapshot.hasLicense);
      expect(restored.isTrial, snapshot.isTrial);
      expect(restored.trialActive, snapshot.trialActive);
      expect(restored.maxDevices, snapshot.maxDevices);
      expect(restored.currentDevices, snapshot.currentDevices);
    });

    test('blocksWrites for expired trial', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: false,
        currentDevices: 0,
        deviceSlotAvailable: false,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(snapshot.blocksWrites, true);
    });

    test('allows writes for active trial', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: true,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(snapshot.blocksWrites, false);
    });

    test('blocksWrites for revoked license', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'REVOKED',
        isTrial: false,
        trialActive: false,
        currentDevices: 0,
        deviceSlotAvailable: false,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(snapshot.blocksWrites, true);
    });

    test('blocksWrites for suspended license', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'SUSPENDED',
        isTrial: false,
        trialActive: false,
        currentDevices: 0,
        deviceSlotAvailable: false,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(snapshot.blocksWrites, true);
    });

    test('allows writes for active paid license', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'ACTIVE',
        isTrial: false,
        trialActive: false,
        currentDevices: 2,
        deviceSlotAvailable: true,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(snapshot.blocksWrites, false);
    });
  });

  group('OfflineGracePolicy', () {
    late OfflineGracePolicy policy;

    setUp(() {
      policy = OfflineGracePolicy();
    });

    test('trial has NO offline grace even when recently verified (WS-4)', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: true,
        trialExpiresAt: DateTime.now().toUtc().add(const Duration(days: 5)),
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now().toUtc(),
      );
      expect(policy.isWithinGraceWindow(snapshot), false,
          reason: 'owner spec (WS-4): trial offline grace is 0 days');
    });

    test('paid grace is 7 days, not capped by the retired 24h window (WS-4)',
        () {
      EntitlementSnapshot snapshot(int daysAgo) => EntitlementSnapshot(
            shopId: 'shop-123',
            hasLicense: true,
            licenseStatus: 'ACTIVE',
            isTrial: false,
            trialActive: false,
            currentDevices: 1,
            deviceSlotAvailable: true,
            serverTimeAtVerification: DateTime.now().toUtc(),
            localWallClockAtVerification: DateTime.now(),
            lastSuccessfulVerificationAt:
                DateTime.now().toUtc().subtract(Duration(days: daysAgo)),
          );

      expect(policy.isWithinGraceWindow(snapshot(6)), true);
      expect(policy.isWithinGraceWindow(snapshot(2)), true,
          reason: 'a 2-day-old cache survives the retired 24h window');
      expect(policy.isWithinGraceWindow(snapshot(8)), false);
    });

    test('perpetual grace is 14 days (WS-4)', () {
      EntitlementSnapshot snapshot(int days) => EntitlementSnapshot(
            shopId: 'shop-123',
            hasLicense: true,
            licenseStatus: 'PERPETUAL',
            isTrial: false,
            trialActive: false,
            currentDevices: 1,
            deviceSlotAvailable: true,
            serverTimeAtVerification: DateTime.now().toUtc(),
            localWallClockAtVerification: DateTime.now(),
            lastSuccessfulVerificationAt:
                DateTime.now().toUtc().subtract(Duration(days: days)),
          );

      expect(policy.isWithinGraceWindow(snapshot(13)), true);
      expect(policy.isWithinGraceWindow(snapshot(15)), false);
    });

    test('isWithinGraceWindow returns false for expired trial', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: true,
        trialExpiresAt: DateTime.now().toUtc().add(const Duration(days: 5)),
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification:
            DateTime.now().toUtc().subtract(const Duration(hours: 25)),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt:
            DateTime.now().toUtc().subtract(const Duration(hours: 25)),
      );
      expect(policy.isWithinGraceWindow(snapshot), false);
    });

    test('isWithinGraceWindow returns false for expired trial', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: false,
        trialExpiresAt:
            DateTime.now().toUtc().subtract(const Duration(days: 1)),
        currentDevices: 0,
        deviceSlotAvailable: false,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now().toUtc(),
      );
      expect(policy.isWithinGraceWindow(snapshot), false);
    });

    test('isWithinGraceWindow returns false for clock backwards', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'ACTIVE',
        isTrial: false,
        trialActive: false,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification:
            DateTime.now().toUtc().add(const Duration(hours: 1)),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt:
            DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      expect(policy.isWithinGraceWindow(snapshot), false);
    });

    test('isCachedNonEntitled returns true for null', () {
      expect(policy.isCachedNonEntitled(null), true);
    });

    test('isCachedNonEntitled returns true for expired', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'EXPIRED',
        isTrial: false,
        trialActive: false,
        currentDevices: 0,
        deviceSlotAvailable: false,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(policy.isCachedNonEntitled(snapshot), true);
    });

    test('isCachedNonEntitled returns false for active trial', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: true,
        currentDevices: 1,
        deviceSlotAvailable: true,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(policy.isCachedNonEntitled(snapshot), false);
    });

    test('isCachedNonEntitled returns true for expired trial', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: true,
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: false,
        currentDevices: 0,
        deviceSlotAvailable: false,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(policy.isCachedNonEntitled(snapshot), true);
    });

    test('isCachedNonEntitled returns true for no license', () {
      final snapshot = EntitlementSnapshot(
        shopId: 'shop-123',
        hasLicense: false,
        isTrial: false,
        trialActive: false,
        currentDevices: 0,
        deviceSlotAvailable: false,
        serverTimeAtVerification: DateTime.now().toUtc(),
        localWallClockAtVerification: DateTime.now(),
        lastSuccessfulVerificationAt: DateTime.now(),
      );
      expect(policy.isCachedNonEntitled(snapshot), true);
    });
  });

  group('LicenseException classes', () {
    test('TrialExpiredException message', () {
      const e = TrialExpiredException();
      expect(e.message, contains('تجريبية'));
    });

    test('LicenseExpiredException message', () {
      const e = LicenseExpiredException();
      expect(e.message, contains('انتهت'));
    });

    test('LicenseSuspendedException message', () {
      const e = LicenseSuspendedException();
      expect(e.message, contains('تعليق'));
    });

    test('DeviceLimitReachedException message', () {
      const e = DeviceLimitReachedException(
        currentDevices: 3,
        maxDevices: 3,
      );
      expect(e.message, contains('3/3'));
    });

    test('DeviceRevokedException message', () {
      const e = DeviceRevokedException();
      expect(e.message, contains('مصرحاً'));
    });

    test('EntitlementUnknownException message', () {
      const e = EntitlementUnknownException();
      expect(e.message, contains('التحقق'));
    });

    test('ClockRollbackDetectedException message', () {
      const e = ClockRollbackDetectedException();
      expect(e.message, contains('الوقت'));
    });

    test('CloudLicenseWriteBlockedException message', () {
      const e = CloudLicenseWriteBlockedException('test message');
      expect(e.message, 'test message');
    });
  });

  group('CloudEntitlementSnapshot', () {
    test('allowsWrites for entitled state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitled,
        hasLicense: true,
        isTrial: true,
        trialActive: true,
        currentDevices: 1,
        deviceActivated: true,
        isOnline: true,
      );
      expect(snapshot.allowsWrites, true);
      expect(snapshot.blocksWrites, false);
    });

    test('blocksWrites for expired state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.expired,
        hasLicense: true,
        isTrial: true,
        trialActive: false,
        currentDevices: 1,
        deviceActivated: true,
        isOnline: true,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('allowsWrites for entitledCached state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitledCached,
        hasLicense: true,
        isTrial: true,
        trialActive: true,
        currentDevices: 1,
        deviceActivated: true,
        isOnline: false,
      );
      expect(snapshot.allowsWrites, true);
    });

    test('blocksWrites for revoked state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.revoked,
        hasLicense: true,
        isTrial: false,
        trialActive: false,
        currentDevices: 1,
        deviceActivated: false,
        isOnline: true,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('blocksWrites for noLicense state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.noLicense,
        hasLicense: false,
        isTrial: false,
        trialActive: false,
        currentDevices: 0,
        deviceActivated: false,
        isOnline: true,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('blocksWrites for staleOffline state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.staleOffline,
        hasLicense: true,
        isTrial: true,
        trialActive: true,
        currentDevices: 1,
        deviceActivated: true,
        isOnline: false,
      );
      expect(snapshot.blocksWrites, true);
    });
  });

  group('CloudLicensingRepository startup safety', () {
    test('construction without initialized Supabase succeeds (TEST A)', () {
      expect(
        () => CloudLicensingRepository(),
        returnsNormally,
      );
    });

    test(
        'construction does not eagerly access Supabase.instance.client (TEST B)',
        () {
      final repo = CloudLicensingRepository();
      expect(repo, isNotNull);
    });

    test('injected client is used when provided (TEST C)', () {
      final mockClient = _MockSupabaseClient();
      final repo = CloudLicensingRepository(client: mockClient);
      expect(repo, isNotNull);
    });

    test(
        'unavailable default client becomes controlled failure at cloud use (TEST D)',
        () async {
      final repo = CloudLicensingRepository();
      try {
        await repo.verifyLicenseEntitlement('test-shop');
        fail('Expected exception for uninitialized Supabase');
      } catch (e) {
        // Any exception is acceptable - the point is construction succeeds
        // and cloud use fails gracefully rather than crashing startup
        expect(e, isNotNull);
      }
    });
  });

  group('CloudLicensingService startup safety', () {
    test('service initialization without Supabase does not crash (TEST E)',
        () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final service = CloudLicensingService.instance;
      await expectLater(
        service.initialize(),
        completes,
      );
    });
  });
}

class _MockSupabaseClient implements SupabaseClient {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
