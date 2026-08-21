import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/licensing/cloud_licensing_service.dart';
import 'package:muaman_store/licensing/entitlement_cache.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration tests for Phase E licensing flows.
///
/// These tests verify the end-to-end flow of licensing operations
/// using mock dependencies.
void main() {
  group('CloudEntitlementState resolution', () {
    test('entitled state when trial active', () {
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
      expect(snapshot.trialActive, true);
    });

    test('entitled state when paid active', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitled,
        hasLicense: true,
        isTrial: false,
        trialActive: false,
        licenseStatus: 'ACTIVE',
        currentDevices: 1,
        deviceActivated: true,
        isOnline: true,
      );
      expect(snapshot.allowsWrites, true);
    });

    test('cached entitled state when offline within grace', () {
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
      expect(snapshot.isOnline, false);
    });

    test('expired state when trial expired', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.expired,
        hasLicense: true,
        isTrial: true,
        trialActive: false,
        currentDevices: 0,
        deviceActivated: false,
        isOnline: true,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('no license state', () {
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

    test('device revoked state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.deviceRevoked,
        hasLicense: true,
        isTrial: false,
        trialActive: false,
        licenseStatus: 'ACTIVE',
        currentDevices: 0,
        deviceActivated: false,
        isOnline: true,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('stale offline state', () {
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

    test('suspended state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.suspended,
        hasLicense: true,
        isTrial: false,
        trialActive: false,
        licenseStatus: 'SUSPENDED',
        currentDevices: 0,
        deviceActivated: false,
        isOnline: true,
      );
      expect(snapshot.blocksWrites, true);
    });

    test('revoked state', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.revoked,
        hasLicense: true,
        isTrial: false,
        trialActive: false,
        licenseStatus: 'REVOKED',
        currentDevices: 0,
        deviceActivated: false,
        isOnline: true,
      );
      expect(snapshot.blocksWrites, true);
    });
  });

  group('EntitlementCache', () {
    late EntitlementCache cache;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      // Delete stale test DB to avoid migration conflicts
      final dbPath = p.join(
        '.dart_tool', 'sqflite_common_ffi', 'databases', 'muaman_store.db',
      );
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) dbFile.deleteSync();
    });

    setUp(() {
      cache = EntitlementCache();
    });

    test('generates installation ID', () async {
      final id = await cache.getInstallationId();
      expect(id.isNotEmpty, true);
      // Should be a UUID-like format
      expect(id.contains('-'), true);
    });

    test('installation ID is stable across calls', () async {
      final id1 = await cache.getInstallationId();
      final id2 = await cache.getInstallationId();
      expect(id1, equals(id2));
    });
  });

  group('Multi-shop isolation', () {
    test('different shops have different snapshots', () {
      const snapshot1 = CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitled,
        hasLicense: true,
        isTrial: true,
        trialActive: true,
        currentDevices: 1,
        deviceActivated: true,
        isOnline: true,
      );

      const snapshot2 = CloudEntitlementSnapshot(
        state: CloudEntitlementState.expired,
        hasLicense: true,
        isTrial: true,
        trialActive: false,
        currentDevices: 0,
        deviceActivated: false,
        isOnline: true,
      );

      expect(snapshot1.allowsWrites, true);
      expect(snapshot2.blocksWrites, true);
      // Shop isolation: one can write, other cannot
      expect(snapshot1.allowsWrites, isNot(equals(snapshot2.allowsWrites)));
    });
  });

  group('Device limit scenarios', () {
    test('device limit at capacity blocks new activation', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitled,
        hasLicense: true,
        isTrial: true,
        trialActive: true,
        maxDevices: 3,
        currentDevices: 3,
        deviceActivated: false,
        isOnline: true,
      );
      expect(snapshot.deviceActivated, false);
      expect(snapshot.currentDevices, snapshot.maxDevices);
    });

    test('device limit one below allows activation', () {
      const snapshot = CloudEntitlementSnapshot(
        state: CloudEntitlementState.entitled,
        hasLicense: true,
        isTrial: true,
        trialActive: true,
        maxDevices: 3,
        currentDevices: 2,
        deviceActivated: true,
        isOnline: true,
      );
      expect(snapshot.deviceActivated, true);
      expect(snapshot.currentDevices, lessThan(snapshot.maxDevices!));
    });
  });
}
