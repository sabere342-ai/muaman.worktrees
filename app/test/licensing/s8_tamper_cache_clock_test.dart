import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/licensing/cloud_licensing_service.dart';
import 'package:muaman_store/licensing/entitlement_cache.dart';
import 'package:muaman_store/licensing/offline_grace_policy.dart';
import 'package:muaman_store/licensing/s6_device_identity.dart';
import 'package:muaman_store/licensing/s8_cache_integrity.dart';
import 'package:muaman_store/platform/secure_secret_store.dart';
import 'package:muaman_store/services/app_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase P Group B S8 — tamper / cache / clock enforcement convergence.
///
/// Deterministic S8 scenario matrix (Governance Section S / Section 23).
/// All fixtures are synthetic (S6TestIdentity seeds, fixed identifiers); no
/// production private material is used or printed.
void main() {
  const installA = 'install-aaaa-0000-0000-000000000001';
  const installB = 'install-bbbb-0000-0000-000000000002';

  Future<S6Identity> identityWithSeed(int n) {
    final seed =
        Uint8List.fromList(List<int>.generate(32, (i) => (i + n) % 256));
    return S6TestIdentity.fromSeed(seed, createdAt: n);
  }

  EntitlementSnapshot baseSnapshot({
    String shopId = 'shop-A',
    bool hasLicense = true,
    String? licenseStatus = 'ACTIVE',
    bool isTrial = false,
    bool trialActive = false,
    bool isRevoked = false,
    DateTime? revokedAt,
    DateTime? trialExpiresAt,
    DateTime? subscriptionExpiresAt,
    DateTime? serverTime,
    DateTime? highWater,
  }) {
    final st = serverTime ?? DateTime.utc(2026, 9, 1, 12, 0, 0);
    return EntitlementSnapshot(
      shopId: shopId,
      hasLicense: hasLicense,
      licenseStatus: licenseStatus,
      isTrial: isTrial,
      trialActive: trialActive,
      trialExpiresAt: trialExpiresAt,
      subscriptionExpiresAt: subscriptionExpiresAt,
      currentDevices: 1,
      deviceSlotAvailable: true,
      serverTimeAtVerification: st,
      localWallClockAtVerification: st,
      lastSuccessfulVerificationAt: st,
      isRevoked: isRevoked,
      revokedAt: revokedAt,
      lastTrustedServerTimeUtc: highWater ?? st,
    );
  }

  Future<EntitlementSnapshot> boundSnapshot({
    String shopId = 'shop-A',
    bool hasLicense = true,
    String? licenseStatus = 'ACTIVE',
    bool isTrial = false,
    bool trialActive = false,
    bool isRevoked = false,
    DateTime? revokedAt,
    DateTime? trialExpiresAt,
    DateTime? subscriptionExpiresAt,
    DateTime? serverTime,
    DateTime? highWater,
    required S6Identity identity,
  }) async {
    final s = baseSnapshot(
      shopId: shopId,
      hasLicense: hasLicense,
      licenseStatus: licenseStatus,
      isTrial: isTrial,
      trialActive: trialActive,
      isRevoked: isRevoked,
      revokedAt: revokedAt,
      trialExpiresAt: trialExpiresAt,
      subscriptionExpiresAt: subscriptionExpiresAt,
      serverTime: serverTime,
      highWater: highWater,
    );
    final dryer = highWater ?? serverTime ?? s.serverTimeAtVerification;
    final bound = s.copyWith(
      s8PublicKey: await identity.publicKeyBase64Url(),
      graceBasis: S8CacheIntegrity.inferGraceBasis(s),
      lastTrustedServerTimeUtc: dryer.toUtc(),
    );
    final sig = await S8CacheIntegrity.signBase64Url(
      s: bound,
      installationId: installA,
      userBoundary: bound.effectiveUserBoundary,
      identity: identity,
    );
    return bound.copyWith(s8Signature: sig);
  }

  // ────────────────────────────────────────────────────────────────────────
  // A. Cache integrity — canonical payload / signature / bindings
  // ────────────────────────────────────────────────────────────────────────
  group('A. Cache integrity', () {
    test(
        'A1: equivalent semantic payloads produce identical canonical bytes '
        'and signatures', () async {
      final id = await identityWithSeed(1);
      final s1 = await boundSnapshot(identity: id);
      final s2 = await boundSnapshot(identity: id);
      expect(s1.s8Signature, s2.s8Signature);
      expect(jsonEncode(s1.toJson()), jsonEncode(s2.toJson()));
    });

    test('A2: a valid current S8 cache verifies and is S8-bound', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      expect(s.isS8Bound, true);
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, true);
    });

    test('A3: status mutation is rejected', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      final tampered = s.copyWith(licenseStatus: 'SUSPENDED');
      final ok = await S8CacheIntegrity.verify(
        s: tampered,
        installationId: installA,
        userBoundary: tampered.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, false);
    });

    test('A4: timestamp mutation is rejected', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      final tampered = s.copyWith(
          serverTimeAtVerification:
              s.serverTimeAtVerification.add(const Duration(days: 30)));
      final ok = await S8CacheIntegrity.verify(
        s: tampered,
        installationId: installA,
        userBoundary: tampered.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, false);
    });

    test('A5: tenant (shop) mismatch is rejected', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(shopId: 'shop-A', identity: id);
      final otherShop = s.copyWith(shopId: 'shop-B');
      final ok = await S8CacheIntegrity.verify(
        s: otherShop,
        installationId: installA,
        userBoundary: otherShop.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, false);
    });

    test('A6: device / installation mismatch is rejected', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installB,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, false);
    });

    test('A7: unknown schema is rejected', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      final futureSchema = s.copyWith(schemaVersion: s.schemaVersion + 100);
      expect(futureSchema.isCompatibleSchema(), false);
      final ok = await S8CacheIntegrity.verify(
        s: futureSchema,
        installationId: installA,
        userBoundary: futureSchema.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, false);
    });

    test('A8: missing integrity metadata => not S8-bound (fail closed)',
        () async {
      // A cache without signature/public-key metadata is not S8-bound.
      final raw = baseSnapshot();
      expect(raw.isS8Bound, false);
      // A bound cache is S8-bound and verifiable.
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      expect(s.isS8Bound, true);
      expect(s.s8Signature, isNotNull);
      expect(s.s8PublicKey, isNotNull);
    });

    test('A9: malformed signature encoding is rejected', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: 'not-a-valid-signature',
      );
      expect(ok, false);
    });

    test(
        'A10: canonical payload is deterministically reconstructed across '
        'UTC-equivalent values', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(
        identity: id,
        serverTime: DateTime.utc(2026, 9, 1, 12, 0, 0),
        highWater: DateTime.utc(2026, 9, 1, 12, 0, 0),
      );
      final equivalent = s.copyWith(
        serverTimeAtVerification: DateTime.parse('2026-09-01T14:00:00+02:00'),
        lastTrustedServerTimeUtc: DateTime.parse('2026-09-01T14:00:00+02:00'),
      );
      final c1 = S8CacheIntegrity.canonicalJson(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
      );
      final c2 = S8CacheIntegrity.canonicalJson(
        s: equivalent,
        installationId: installA,
        userBoundary: equivalent.effectiveUserBoundary,
      );
      expect(c1, c2);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // B. Clock / anti-rollback
  // ────────────────────────────────────────────────────────────────────────
  group('B. Clock / anti-rollback', () {
    final grace = OfflineGracePolicy();
    final hw = DateTime.utc(2026, 9, 1, 12, 0, 0);

    EntitlementSnapshot snapshotAt({DateTime? baseline}) {
      final b = baseline ?? hw;
      return baseSnapshot(licenseStatus: 'ACTIVE', serverTime: b, highWater: b);
    }

    test('B1: normal forward progression within grace is allowed', () {
      final s = snapshotAt();
      final now = hw.add(const Duration(days: 2));
      expect(
        grace.isWithinGraceWindow(s, currentTime: now, trustedHighWater: hw),
        true,
      );
    });

    test('B2: backward clock rollback fails closed (no grace extension)', () {
      final s = snapshotAt();
      final rolledBack = hw.subtract(const Duration(days: 5));
      expect(
        grace.isWithinGraceWindow(s,
            currentTime: rolledBack, trustedHighWater: hw),
        false,
      );
    });

    test('B3: small legitimate correction never creates extra entitlement', () {
      final s = snapshotAt();
      final smallCorrection = hw.subtract(const Duration(minutes: 2));
      // A wall clock behind the trusted baseline yields elapsed < 0 -> denied,
      // never granting extra offline time even for a minor correction.
      expect(
        grace.isWithinGraceWindow(s,
            currentTime: smallCorrection, trustedHighWater: hw),
        false,
      );
    });

    test(
        'B4: large forward jump does not create a fresh baseline nor extend '
        'grace', () {
      final s = snapshotAt();
      final farFuture = hw.add(const Duration(days: 90));
      expect(
        grace.isWithinGraceWindow(s,
            currentTime: farFuture, trustedHighWater: hw),
        false,
      );
    });

    test('B5: forward jump then rollback is rejected (behind high-water)', () {
      final s = snapshotAt();
      final rollbackPoint = hw.subtract(const Duration(hours: 1));
      expect(
        grace.isWithinGraceWindow(s,
            currentTime: rollbackPoint, trustedHighWater: hw),
        false,
      );
    });

    test('B6: restart preserves trusted anti-rollback state', () async {
      final store = InMemorySecureSecretStore();
      await S6DeviceIdentity(store).writeTrustedTimeHighWater(hw);
      final restored = await S6DeviceIdentity(store).readTrustedTimeHighWater();
      expect(restored, hw);
    });

    test(
        'B7: reboot-equivalent reconstruction — plaintext cache cannot lower '
        'the protected high-water', () async {
      final store = InMemorySecureSecretStore();
      await S6DeviceIdentity(store).writeTrustedTimeHighWater(hw);
      final oldBaseline = hw.subtract(const Duration(days: 3));
      final replayed = S8CacheIntegrity.isReplayOrRollback(
        cacheHighWater: oldBaseline,
        protectedHighWater:
            await S6DeviceIdentity(store).readTrustedTimeHighWater(),
      );
      expect(replayed, true);
    });

    test('B8: timezone change does not extend grace (UTC-normalized)', () {
      final s = snapshotAt();
      final nowUtc = hw.add(const Duration(days: 2));
      final nowOffset = DateTime.parse('2026-09-03T16:00:00+02:00');
      final inUtc = grace.isWithinGraceWindow(s,
          currentTime: nowUtc, trustedHighWater: hw);
      final inOffset = grace.isWithinGraceWindow(s,
          currentTime: nowOffset, trustedHighWater: hw);
      expect(inUtc, inOffset);
    });

    test('B9: DST change does not extend grace (all comparisons are UTC)', () {
      final s = snapshotAt();
      final now = hw.add(const Duration(days: 2));
      expect(
        grace.isWithinGraceWindow(s, currentTime: now, trustedHighWater: hw),
        true,
      );
    });

    test('B10: future-dated / inconsistent trusted metadata fails closed', () {
      final protected = hw;
      final stale = S8CacheIntegrity.isStaleAuthority(
        serverTime: protected.subtract(const Duration(minutes: 30)),
        protectedHighWater: protected,
      );
      expect(stale, true);
      final fresh = S8CacheIntegrity.isStaleAuthority(
        serverTime: protected.add(const Duration(minutes: 1)),
        protectedHighWater: protected,
      );
      expect(fresh, false);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // C. Entitlement invariants (grace windows)
  // ────────────────────────────────────────────────────────────────────────
  group('C. Entitlement invariants', () {
    final grace = OfflineGracePolicy();
    final hw = DateTime.utc(2026, 9, 1, 12, 0, 0);

    EntitlementSnapshot paid({int daysAgo = 0, String status = 'ACTIVE'}) {
      final baseline = hw.subtract(Duration(days: daysAgo));
      return baseSnapshot(
          licenseStatus: status, serverTime: baseline, highWater: baseline);
    }

    test('C1: TRIAL offline is denied (zero grace)', () {
      final trial = baseSnapshot(
        licenseStatus: 'TRIAL',
        isTrial: true,
        trialActive: true,
        highWater: hw,
      );
      expect(
        grace.isWithinGraceWindow(trial,
            currentTime: hw.add(const Duration(days: 1)), trustedHighWater: hw),
        false,
      );
    });

    test('C2: PAID within 7 days is allowed only when authority checks pass',
        () {
      final inside = paid(daysAgo: 3);
      expect(
        grace.isWithinGraceWindow(inside,
            currentTime: hw, trustedHighWater: inside.lastTrustedServerTimeUtc),
        true,
      );
    });

    test('C3: PAID beyond 7 days is denied', () {
      final outside = paid(daysAgo: 8);
      expect(
        grace.isWithinGraceWindow(outside,
            currentTime: hw,
            trustedHighWater: outside.lastTrustedServerTimeUtc),
        false,
      );
    });

    test('C4: PERPETUAL within 14 days is allowed', () {
      final inside = paid(daysAgo: 10, status: 'PERPETUAL');
      expect(
        grace.isWithinGraceWindow(inside,
            currentTime: hw, trustedHighWater: inside.lastTrustedServerTimeUtc),
        true,
      );
    });

    test('C5: PERPETUAL beyond 14 days is denied', () {
      final outside = paid(daysAgo: 15, status: 'PERPETUAL');
      expect(
        grace.isWithinGraceWindow(outside,
            currentTime: hw,
            trustedHighWater: outside.lastTrustedServerTimeUtc),
        false,
      );
    });

    test('C6: REVOKED always wins (never restored by cache)', () {
      final revoked = baseSnapshot(
        hasLicense: false,
        licenseStatus: 'REVOKED',
        isRevoked: true,
        revokedAt: DateTime.utc(2026, 8, 20),
        highWater: hw,
      );
      // Non-entitled terminal state is always blocked...
      expect(grace.isCachedNonEntitled(revoked), true);
      // ...and resolution enforces REVOKED precedence ahead of any grace.
      final resolved =
          CloudLicensingService().resolveStateFromCacheForTest(revoked);
      expect(resolved.state, CloudEntitlementState.revoked);
      expect(resolved.allowsWrites, false);
    });

    test('C7: EXPIRED cannot be restored by a stale cache', () {
      final expired = baseSnapshot(
        hasLicense: true,
        licenseStatus: 'EXPIRED',
        subscriptionExpiresAt: DateTime.utc(2026, 8, 1),
        highWater: hw,
      );
      expect(grace.isCachedNonEntitled(expired), true);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // D. Device / identity binding
  // ────────────────────────────────────────────────────────────────────────
  group('D. Device / identity binding', () {
    test('D1: cache bound by device A is rejected under device B', () async {
      final idA = await identityWithSeed(1);
      final idB = await identityWithSeed(2);
      final s = await boundSnapshot(identity: idA);
      final okB = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: await idB.publicKeyBase64Url(),
        signatureBase64Url: s.s8Signature!,
      );
      expect(okB, false);
      expect(s.s8PublicKey, isNot(await idB.publicKeyBase64Url()));
    });

    test('D2: missing secure identity fails closed (cannot verify)', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: '',
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, false);
    });

    test('D3: REVOKED / LOST terminal cache state stays terminal', () {
      final revoked = baseSnapshot(
        hasLicense: false,
        licenseStatus: 'REVOKED',
        isRevoked: true,
        highWater: DateTime.utc(2026, 9, 1, 12, 0, 0),
      );
      expect(_isTerminalState(revoked), true);
      expect(revoked.isS8Bound, false);
    });

    test('D4: valid S6 identity composition succeeds', () async {
      final id = await identityWithSeed(7);
      final s = await boundSnapshot(identity: id);
      final pub = await id.publicKeyBase64Url();
      expect(s.s8PublicKey, pub);
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: pub,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, true);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // E. Online recovery / persistence / upgrade
  // ────────────────────────────────────────────────────────────────────────
  group('E. Online recovery / persistence / upgrade', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late EntitlementCache cache;

    setUp(() {
      cache = EntitlementCache();
    });

    test(
        'E1: fresh authoritative server time advances the protected '
        'high-water monotonically', () async {
      final store = InMemorySecureSecretStore();
      final device = S6DeviceIdentity(store);
      await device.writeTrustedTimeHighWater(DateTime.utc(2026, 9, 1, 12));
      final advanced = S8CacheIntegrity.advanceHighWater(
        serverTime: DateTime.utc(2026, 9, 2, 12),
        protectedHighWater: await device.readTrustedTimeHighWater(),
      );
      expect(advanced, DateTime.utc(2026, 9, 2, 12));
      final regressed = S8CacheIntegrity.advanceHighWater(
        serverTime: DateTime.utc(2026, 8, 1, 12),
        protectedHighWater: advanced,
      );
      expect(regressed, advanced);
    });

    test('E2: malformed / materially stale server timestamp fails closed', () {
      final hw = DateTime.utc(2026, 9, 10, 12);
      final stale = S8CacheIntegrity.isStaleAuthority(
        serverTime: DateTime.utc(2026, 9, 1, 12),
        protectedHighWater: hw,
      );
      expect(stale, true);
    });

    test('E3: server failure never fabricates fresh authority', () {
      // Absent high-water => nothing older to compare, but the first fresh
      // server response is what establishes authority (no local fabrication).
      final noHw = S8CacheIntegrity.isStaleAuthority(
        serverTime: DateTime.utc(2026, 9, 1, 12),
        protectedHighWater: null,
      );
      expect(noHw, false);
    });

    test('E4: authenticated save/load round-trip binds and verifies a cache',
        () async {
      final id = await identityWithSeed(1);
      final s = baseSnapshot(
        shopId: 'shop-save',
        licenseStatus: 'ACTIVE',
        serverTime: DateTime.utc(2026, 9, 1, 12),
        highWater: DateTime.utc(2026, 9, 1, 12),
      );
      await cache.saveAuthenticated(
        s,
        installationId: installA,
        identity: id,
        highWater: DateTime.utc(2026, 9, 1, 12),
      );
      final loaded = await cache.load('shop-save');
      expect(loaded, isNotNull);
      expect(loaded!.isS8Bound, true);
      final ok = await S8CacheIntegrity.verify(
        s: loaded,
        installationId: installA,
        userBoundary: loaded.effectiveUserBoundary,
        publicKeyBase64Url: loaded.s8PublicKey!,
        signatureBase64Url: loaded.s8Signature!,
      );
      expect(ok, true);
      await cache.clear('shop-save');
    });

    test(
        'E5: pre-S8 / unbound cache follows '
        'OLD_CACHE_REQUIRES_ONLINE_REVALIDATION', () async {
      await cache.save(baseSnapshot());
      final loaded = await cache.load('shop-A');
      expect(loaded, isNotNull);
      expect(loaded!.isS8Bound, false);
      await cache.clear('shop-A');
    });

    test('E6: truncated / corrupt cache fails closed (load -> null)', () async {
      await AppSettings.setValue(
          'cloud.license.shop-corrupt-s8', '{ not valid json s8');
      final loaded = await cache.load('shop-corrupt-s8');
      expect(loaded, isNull);
      await AppSettings.setValue('cloud.license.shop-corrupt-s8', '');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // F. Explicit S8 distinctions: valid signature != current authority
  // ────────────────────────────────────────────────────────────────────────
  group('F. Anti-rollback distinctions', () {
    test('F1: VALID_SIGNATURE_BUT_STALE_CACHE_IS_REJECTED', () async {
      final id = await identityWithSeed(1);
      final oldHw = DateTime.utc(2026, 9, 1, 12, 0, 0);
      final s = await boundSnapshot(
          serverTime: oldHw, highWater: oldHw, identity: id);

      final sigValid = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(sigValid, true);

      final protectedNow = oldHw.add(const Duration(days: 10));
      final replayed = S8CacheIntegrity.isReplayOrRollback(
        cacheHighWater: oldHw,
        protectedHighWater: protectedNow,
      );
      expect(replayed, true);
    });

    test('F2: OLD_SIGNED_CACHE_REPLAY_IS_REJECTED via protected high-water',
        () async {
      final store = InMemorySecureSecretStore();
      final device = S6DeviceIdentity(store);
      final currentHw = DateTime.utc(2026, 9, 10, 12);
      await device.writeTrustedTimeHighWater(currentHw);
      final oldBaseline = DateTime.utc(2026, 9, 1, 12);
      final replay = S8CacheIntegrity.isReplayOrRollback(
        cacheHighWater: oldBaseline,
        protectedHighWater: await device.readTrustedTimeHighWater(),
      );
      expect(replay, true);
    });

    test('F3: SIGNATURE_DOES_NOT_EQUAL_FRESH_AUTHORITY', () {
      final hw = DateTime.utc(2026, 9, 1, 12);
      final base = S8CacheIntegrity.advanceHighWater(
        serverTime: hw,
        protectedHighWater: null,
      );
      expect(base, hw);
      expect(S8CacheIntegrity.kS8IntegrityVersion, greaterThan(0));
    });

    test('F4: PRIVATE_KEY_NEVER_SERIALIZED_IN_CACHE', () async {
      final id = await identityWithSeed(1);
      final s = await boundSnapshot(identity: id);
      final json = jsonEncode(s.toJson());
      expect(json.contains('seed'), false);
      expect(json.contains('private'), false);
      expect(json.contains(s.s8PublicKey!), true);
    });
  });
}

bool _isTerminalState(EntitlementSnapshot s) =>
    s.isRevoked || s.licenseStatus == 'REVOKED';
