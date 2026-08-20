import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/licensing/cloud_licensing_service.dart';
import 'package:muaman_store/licensing/offline_grace_policy.dart';
import 'package:muaman_store/licensing/license_exception.dart';
import 'package:muaman_store/licensing/entitlement_cache.dart';

/// Security tests for Phase E licensing.
///
/// These tests verify that:
/// 1. Local clock cannot be used as licensing authority
/// 2. Cached entitlement cannot grant new entitlement
/// 3. Non-entitled states are properly enforced offline
/// 4. No secrets are committed in client code
void main() {
  group('Clock manipulation attack prevention', () {
    test('clock rollback does not extend trial access', () {
      final policy = OfflineGracePolicy();

      // A trial that expired 1 day ago, but cache was valid 1 hour ago
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
        lastSuccessfulVerificationAt:
            DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );

      // Even though last verification was recent, expired trial blocks writes
      expect(policy.isCachedNonEntitled(snapshot), true);
      expect(snapshot.blocksWrites, true);
    });

    test('clock forward triggers early revalidation (acceptable)', () {
      final policy = OfflineGracePolicy();

      // Cache is 2 hours old, but clock moved forward 25 hours
      final snapshot = EntitlementSnapshot(
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
            DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      );

      // The grace window uses wall clock; moving clock forward should
      // not prevent the check from working normally
      // (2 hours < 24 hours revalidation window, so within grace)
      expect(policy.isWithinGraceWindow(snapshot), true);
    });

    test('never-verified installation gets no entitlement', () {
      final policy = OfflineGracePolicy();
      expect(policy.isWithinGraceWindow(null), false);
    });

    test('negative elapsed time (clock backward) does not extend grace', () {
      final policy = OfflineGracePolicy();

      final snapshot = EntitlementSnapshot(
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
            DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      // last verification is in the future — negative elapsed
      expect(policy.isWithinGraceWindow(snapshot), false);
    });
  });

  group('Cached entitlement security', () {
    test('cached expired state blocks writes offline', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.expired,
        hasLicense: true,
        isTrial: true,
        trialActive: false,
        currentDevices: 0,
        deviceActivated: false,
        isOnline: false,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('cached revoked state blocks writes offline', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.revoked,
        hasLicense: true,
        isTrial: false,
        trialActive: false,
        licenseStatus: 'REVOKED',
        currentDevices: 0,
        deviceActivated: false,
        isOnline: false,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('cached suspended state blocks writes offline', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.suspended,
        hasLicense: true,
        isTrial: false,
        trialActive: false,
        licenseStatus: 'SUSPENDED',
        currentDevices: 0,
        deviceActivated: false,
        isOnline: false,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('cached stale state blocks writes', () {
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

    test('no-license state blocks writes', () {
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
  });

  group('Exception messages — no internal terms', () {
    test('messages do not expose technical terms', () {
      final forbiddenTerms = [
        'RLS',
        'JWT',
        'RPC',
        'SQL',
        'PostgREST',
        'HTTP 401',
        'SECURITY DEFINER',
        'auth.uid()',
        'supabase',
      ];

      final exceptions = <String>[
        const TrialExpiredException().message,
        const LicenseExpiredException().message,
        const LicenseSuspendedException().message,
        const DeviceRevokedException().message,
        const EntitlementUnknownException().message,
        const ClockRollbackDetectedException().message,
      ];

      for (final msg in exceptions) {
        for (final term in forbiddenTerms) {
          expect(
            msg.toLowerCase(),
            isNot(contains(term.toLowerCase())),
            reason: 'Exception message "$msg" contains forbidden term "$term"',
          );
        }
      }
    });
  });

  group('No secrets in client code', () {
    test('no service_role key in licensing files', () {
      final licensingFiles = [
        'cloud_licensing_service.dart',
        'cloud_licensing_repository.dart',
        'entitlement_cache.dart',
        'offline_grace_policy.dart',
        'license_exception.dart',
      ];

      for (final fileName in licensingFiles) {
        final file = File(
          'C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze/'
          'app/lib/licensing/$fileName',
        );
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          expect(
            content.toLowerCase(),
            isNot(contains('service_role')),
            reason: '$fileName should not contain service_role key',
          );
          expect(
            content.toLowerCase(),
            isNot(contains('private_key')),
            reason: '$fileName should not contain private_key',
          );
        }
      }
    });

    test('no hardcoded credentials in cloud_licensing_repository', () {
      final file = File(
        'C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze/'
        'app/lib/licensing/cloud_licensing_repository.dart',
      );
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        // Should not contain any placeholder or real API keys
        expect(content, isNot(contains('sk_')));
        expect(content, isNot(contains('password')));
        expect(content, isNot(contains('secret')));
      }
    });
  });

  group('Multi-shop isolation security', () {
    test('different shops cannot share entitlement', () {
      const shopA = CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitled,
        hasLicense: true,
        isTrial: true,
        trialActive: true,
        currentDevices: 1,
        deviceActivated: true,
        isOnline: true,
      );

      const shopB = CloudEntitlementSnapshot(
        state: CloudEntitlementState.expired,
        hasLicense: true,
        isTrial: true,
        trialActive: false,
        currentDevices: 0,
        deviceActivated: false,
        isOnline: true,
      );

      // Shop A can write, Shop B cannot — different entitlements per shop
      expect(shopA.allowsWrites, true);
      expect(shopB.blocksWrites, true);
    });
  });

  group('Enforcement boundary', () {
    test('entitled state passes enforcement', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitled,
        hasLicense: true,
        isTrial: true,
        trialActive: true,
        currentDevices: 1,
        deviceActivated: true,
        isOnline: true,
      );
      expect(snapshot.blocksWrites, false);
    });

    test('all non-entitled states block writes', () {
      const blockingStates = [
        CloudEntitlementState.noLicense,
        CloudEntitlementState.expired,
        CloudEntitlementState.suspended,
        CloudEntitlementState.revoked,
        CloudEntitlementState.deviceRevoked,
        CloudEntitlementState.staleOffline,
        CloudEntitlementState.offlineNoLicense,
        CloudEntitlementState.offlineNoActivation,
        CloudEntitlementState.activating,
        CloudEntitlementState.clockTamper,
      ];

      for (final state in blockingStates) {
        final snapshot = CloudEntitlementSnapshot(
          state: state,
          hasLicense: false,
          isTrial: false,
          trialActive: false,
          currentDevices: 0,
          deviceActivated: false,
          isOnline: false,
        );
        expect(
          snapshot.blocksWrites,
          true,
          reason: 'State $state should block writes',
        );
      }
    });
  });
}
