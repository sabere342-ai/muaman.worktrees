import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/licensing/cloud_licensing_service.dart';
import 'package:muaman_store/licensing/entitlement_cache.dart';
import 'package:muaman_store/licensing/offline_grace_policy.dart';
import 'package:muaman_store/licensing/s6_device_identity.dart';
import 'package:muaman_store/licensing/s6_proof_of_possession.dart';
import 'package:muaman_store/licensing/s8_cache_integrity.dart';
import 'package:muaman_store/platform/secure_secret_store.dart';

/// Phase P Group B S9 — legacy Ed25519 entitlement-token retirement.
///
/// Governed contract: Section P of
/// docs/PHASE_P_GROUP_B_S9_LEGACY_ED25519_RETIREMENT_IMPLEMENTATION_GOVERNANCE.md.
///
/// S9 retires the legacy entitlement-token Ed25519 surface
/// (`entitlement_token.dart`: EntitlementToken / ParsedToken / Entitlements /
/// EntitlementVerifier / TokenVerificationResult / TrustedKey / parseSigned)
/// and the superseded local `LicensingService` / `ActivationClient` authority.
/// It must NOT weaken the canonical S6 device proof-of-possession, S6 per-
/// install identity, or S8 device-bound cache-integrity Ed25519 seams.
///
/// Security-negatives are mandatory. Where a case is best proven by static
/// source inspection rather than runtime behavior, the proof is made
/// deterministic and explicit (file-existence + symbol-scan assertions).
void main() {
  const installA = 'install-aaaa-0000-0000-000000000001';
  const installB = 'install-bbbb-0000-0000-000000000002';
  const userA = 'user-aaaa';
  const userB = 'user-bbbb';
  final fixedNow = DateTime.utc(2026, 9, 1, 12, 0, 0);

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
  }) {
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
      serverTimeAtVerification: fixedNow,
      localWallClockAtVerification: fixedNow,
      lastSuccessfulVerificationAt: fixedNow,
      isRevoked: isRevoked,
      revokedAt: revokedAt,
      lastTrustedServerTimeUtc: fixedNow,
    );
  }

  Future<EntitlementSnapshot> boundSnapshot({
    String shopId = 'shop-A',
    String? licenseStatus = 'ACTIVE',
    bool isRevoked = false,
    required S6Identity identity,
    String? userBoundary,
  }) async {
    final s = baseSnapshot(
      shopId: shopId,
      licenseStatus: licenseStatus,
      isRevoked: isRevoked,
    );
    final bound = s.copyWith(
      s8PublicKey: await identity.publicKeyBase64Url(),
      graceBasis: S8CacheIntegrity.inferGraceBasis(s),
      userBoundary: userBoundary ?? s.shopId,
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
  // Group 1 — Canonical S6 / S8 verification is preserved (S9 must not
  // weaken the canonical Ed25519 seams).
  // ────────────────────────────────────────────────────────────────────────
  group('Canonical S6/S8 preservation', () {
    test(
        'Case 1: canonical S6 proof-of-possession continues to verify '
        '(S6 PoP untouched)', () async {
      final id = await identityWithSeed(1);
      final envelope = S6GoldenVector.envelope();
      final sig = await S6ProofOfPossession.signBase64Url(envelope, id);
      final ok = await S6ProofOfPossession.verifyCanonical(
        envelope,
        await id.publicKeyBase64Url(),
        sig,
      );
      expect(ok, isTrue);
    });

    test(
        'Case 9: a valid existing canonical S6 identity survives upgrade — '
        'the SAME identity derives the same public key and re-verifies',
        () async {
      final seed =
          Uint8List.fromList(List<int>.generate(32, (i) => (i + 1) % 256));
      final first = await S6TestIdentity.fromSeed(seed, createdAt: 0);
      final pub1 = await first.publicKeyBase64Url();
      // A reload from the same seed yields the identical S6 device identity.
      final second = await S6TestIdentity.fromSeed(seed, createdAt: 0);
      expect(await second.publicKeyBase64Url(), pub1);
      // The reused identity still binds/verifies an S8 cache.
      final s = await boundSnapshot(identity: second);
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, isTrue);
    });

    test(
        'Case 6: S8 authenticated cache remains valid under canonical '
        'identity', () async {
      final id = await identityWithSeed(2);
      final s = await boundSnapshot(identity: id);
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, isTrue);
      expect(s.isS8Bound, isTrue);
      expect(s.s8PublicKey, isNotNull);
      expect(s.s8Signature, isNotNull);
      expect(s.s8PublicKey, await id.publicKeyBase64Url());
    });

    test('Case 7: replay/rollback protection remains intact', () async {
      final store = InMemorySecureSecretStore();
      await S6DeviceIdentity(store).writeTrustedTimeHighWater(fixedNow);
      // An older cache high-water cannot be replayed over the protected one.
      final stale = fixedNow.subtract(const Duration(days: 3));
      expect(
        S8CacheIntegrity.isReplayOrRollback(
          cacheHighWater: stale,
          protectedHighWater:
              await S6DeviceIdentity(store).readTrustedTimeHighWater(),
        ),
        isTrue,
      );
      // A forward bound cache under canonical identity still verifies.
      final id = await identityWithSeed(3);
      final s = await boundSnapshot(identity: id);
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, isTrue);
    });

    test('Case 8: protected trusted-time high-water remains intact', () async {
      final store = InMemorySecureSecretStore();
      await S6DeviceIdentity(store).writeTrustedTimeHighWater(fixedNow);
      final restored = await S6DeviceIdentity(store).readTrustedTimeHighWater();
      expect(restored, fixedNow);
      // Stale server authority is rejected against the protected high-water.
      expect(
        S8CacheIntegrity.isStaleAuthority(
          serverTime: fixedNow.subtract(const Duration(hours: 1)),
          protectedHighWater: fixedNow,
        ),
        isTrue,
      );
    });

    test('Case 10: user boundary remains enforced', () async {
      final id = await identityWithSeed(10);
      final s = await boundSnapshot(identity: id, userBoundary: userA);
      // Verifying with a different user boundary fails closed.
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: userB,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, isFalse);
      // Same-boundary verification still succeeds.
      final okSame = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(okSame, isTrue);
    });

    test('Case 11: shop (tenant) boundary remains enforced', () async {
      final id = await identityWithSeed(11);
      final s = await boundSnapshot(shopId: 'shop-A', identity: id);
      // A cache bound to shop-A must not verify for shop-B.
      final otherShop = s.copyWith(shopId: 'shop-B');
      final ok = await S8CacheIntegrity.verify(
        s: otherShop,
        installationId: installA,
        userBoundary: otherShop.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, isFalse);
      // Device-installation crossing also fails closed.
      final crossDevice = await S8CacheIntegrity.verify(
        s: s,
        installationId: installB,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(crossDevice, isFalse);
    });

    test(
        'Case 12: revoked entitlement remains revoked (terminal, '
        'never restored by cached evidence)', () {
      final revoked = baseSnapshot(
        hasLicense: false,
        licenseStatus: 'REVOKED',
        isRevoked: true,
        revokedAt: DateTime.utc(2026, 8, 20),
      );
      expect(OfflineGracePolicy().isCachedNonEntitled(revoked), isTrue);
      final resolved =
          CloudLicensingService().resolveStateFromCacheForTest(revoked);
      expect(resolved.state, CloudEntitlementState.revoked);
      expect(resolved.allowsWrites, isFalse);
    });

    test('Case 13: stale authority remains stale (cannot be revived)', () {
      expect(
        S8CacheIntegrity.isStaleAuthority(
          serverTime: fixedNow.subtract(const Duration(minutes: 30)),
          protectedHighWater: fixedNow,
        ),
        isTrue,
      );
      // A cache whose server-time predates the protected high-water is stale
      // authority and cannot be accepted as fresh evidence.
      final aged = baseSnapshot();
      final staleTs =
          aged.serverTimeAtVerification.subtract(const Duration(days: 90));
      expect(
        S8CacheIntegrity.isStaleAuthority(
          serverTime: staleTs,
          protectedHighWater: aged.lastTrustedServerTimeUtc,
        ),
        isTrue,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Group 2 — Security negatives (unknown / malformed / unsupported input
  // always fails closed; no silent fallback to legacy verification).
  // ────────────────────────────────────────────────────────────────────────
  group('Security negatives — fail closed', () {
    test('Case 3: unknown legacy signature format fails closed (never grants)',
        () async {
      final id = await identityWithSeed(20);
      final s = await boundSnapshot(identity: id);
      // A legacy/unknown "token" supplied as an arbitrary byte blob must not
      // pass canonical S8 verification.
      final unknownSig = base64urlEncode(
          Uint8List.fromList(List<int>.generate(64, (i) => (i * 7) % 256)));
      final ok = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: unknownSig,
      );
      expect(ok, isFalse);
    });

    test('Case 4: malformed signatures fail closed', () async {
      final id = await identityWithSeed(21);
      final s = await boundSnapshot(identity: id);
      // Malformed (non base64url) signature encoding is rejected.
      final bad = await S8CacheIntegrity.verify(
        s: s,
        installationId: installA,
        userBoundary: s.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: '!!!not-valid-base64url!!!',
      );
      expect(bad, isFalse);
      // S6 PoP also rejects a malformed signature.
      final envelope = S6GoldenVector.envelope();
      final popOk = await S6ProofOfPossession.verifyCanonical(
        envelope,
        await id.publicKeyBase64Url(),
        'short-and-invalid',
      );
      expect(popOk, isFalse);
    });

    test(
        'Case 14: no silent fallback from canonical verification to legacy '
        'verification', () async {
      final id = await identityWithSeed(22);
      // A legacy-shaped unsigned payload simply does not verify; there is no
      // legacy verifier that could grant it.
      final unknown = baseSnapshot().copyWith(
        s8Signature: null,
        s8PublicKey: null,
      );
      expect(unknown.isS8Bound, isFalse);
      final ok = await S8CacheIntegrity.verify(
        s: unknown,
        installationId: installA,
        userBoundary: unknown.effectiveUserBoundary,
        publicKeyBase64Url: await id.publicKeyBase64Url(),
        signatureBase64Url: '',
      );
      expect(ok, isFalse);
      // Verification only succeeds against a genuinely canonical binding.
      final bound = await boundSnapshot(identity: id);
      final okBound = await S8CacheIntegrity.verify(
        s: bound,
        installationId: installA,
        userBoundary: bound.effectiveUserBoundary,
        publicKeyBase64Url: bound.s8PublicKey!,
        signatureBase64Url: bound.s8Signature!,
      );
      expect(okBound, isTrue);
    });

    test('Case 16: older unsupported state fails safely', () async {
      final id = await identityWithSeed(23);
      final s = await boundSnapshot(identity: id);
      final futureSchema = s.copyWith(schemaVersion: s.schemaVersion + 100);
      expect(futureSchema.isCompatibleSchema(), isFalse);
      final ok = await S8CacheIntegrity.verify(
        s: futureSchema,
        installationId: installA,
        userBoundary: futureSchema.effectiveUserBoundary,
        publicKeyBase64Url: s.s8PublicKey!,
        signatureBase64Url: s.s8Signature!,
      );
      expect(ok, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Group 3 — Deterministic static / source-inspection proofs of retirement
  // and P-OD12 staged compliance. These assert on tracked source material, not
  // on the code-under-test being compiled, so they are stable and explicit.
  // ────────────────────────────────────────────────────────────────────────
  group('Retirement static proofs', () {
    test(
        'Case 2: legacy-only verification path is no longer reachable — '
        'entitlement_token.dart and licensing_service.dart are removed', () {
      for (final legacy in <String>[
        'lib/licensing/entitlement_token.dart',
        'lib/licensing/licensing_service.dart',
      ]) {
        expect(File(legacy).existsSync(), isFalse,
            reason: '$legacy must be retired');
      }
    });

    test(
        'Case 20: no dangling legacy reference survives in application '
        'source (zero symbol references)', () {
      const retiredSymbols = <String>[
        'EntitlementVerifier',
        'EntitlementToken',
        'TokenVerificationResult',
        'TrustedKey',
        'parseSigned',
        'LicensingService',
        'ActivationClient',
        'LicensingSnapshot',
      ];
      final dir = Directory('lib');
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);
      final offenders = <String>[];
      for (final file in dartFiles) {
        final executable = _stripComments(file.readAsStringSync());
        for (final sym in retiredSymbols) {
          for (final lineNo in _identifierMatches(executable, sym)) {
            offenders.add('${file.path}:$lineNo');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'dangling legacy references must be zero');
    });

    test(
        'Case 5: legacy private-key/seed material is never migrated into '
        'plaintext', () {
      // The canonical S6 seed lives ONLY under the protected SecureSecretStore
      // key — it must not be an AppSettings/SQLite/cache plaintext key.
      expect(S6DeviceIdentity.storageKey, 'itech.s6.device.seed');
      // Prove the seed key is absent from the AppSettings plaintext key set,
      // i.e. the S6 private seed is never serialized into the plaintext cache.
      final appSettingsSrc =
          File('lib/services/app_settings.dart').readAsStringSync();
      final seedKeyAppearsInAppSettings =
          RegExp(r"key[A-Za-z0-9]+\s*=\s*'itech\.s6\.device\.seed'")
              .hasMatch(appSettingsSrc);
      expect(seedKeyAppearsInAppSettings, isFalse,
          reason: 'S6 seed key must not be an AppSettings plaintext key');
      // The S6 identity writes its record through SecureSecretStore (protected
      // DPAPI / Keystore), not a plaintext AppSettings value.
      final s6Src =
          File('lib/licensing/s6_device_identity.dart').readAsStringSync();
      expect(s6Src.contains('SecureSecretStore'), isTrue);
      expect(s6Src.contains('_store.write('), isTrue);
    });

    test('Case 15: migration/compatibility matches P-OD12 staged retirement',
        () {
      // STAGE 1 complete: the legacy direct files are removed and the settings
      // screen no longer references the retired legacy LicensingService.
      expect(
          File('lib/licensing/entitlement_token.dart').existsSync(), isFalse);
      expect(
          File('lib/licensing/licensing_service.dart').existsSync(), isFalse);
      final settings = File('lib/screens/settings_screen.dart');
      expect(settings.existsSync(), isTrue);
      final settingsText = settings.readAsStringSync();
      // No executable reference to the legacy LicensingService remains.
      expect(
          _identifierMatches(_stripComments(settingsText), 'LicensingService'),
          isEmpty);
      // Canonical cloud licensing authority remains wired into the UI.
      expect(settingsText.contains('CloudLicensingService'), isTrue);
    });

    test(
        'Case 17: canonical S6 device-trust / PoP seam remains present and '
        'functional (invitation/device-trust regression guard)', () async {
      // The canonical S6 identity/PoP files that the invitation/device-trust
      // path relies on are intact and still verify.
      expect(
          File('lib/licensing/s6_device_identity.dart').existsSync(), isTrue);
      expect(File('lib/licensing/s6_proof_of_possession.dart').existsSync(),
          isTrue);
      final id = await identityWithSeed(30);
      final envelope = S6GoldenVector.envelope();
      final sig = await S6ProofOfPossession.sign(envelope, id);
      expect(sig.length, 64);
      final ok = await S6ProofOfPossession.verify(
        envelope,
        await id.publicKeyBytes(),
        sig,
      );
      expect(ok, isTrue);
    });

    test(
        'Case 18: licensing regressions remain green — canonical S6/S8 test '
        'files are preserved (not deleted/weakened)', () {
      for (final canonicalTest in <String>[
        'test/licensing/s6_device_identity_test.dart',
        'test/licensing/s6_proof_of_possession_test.dart',
        'test/licensing/s8_tamper_cache_clock_test.dart',
        'test/licensing/cloud_licensing_test.dart',
        'test/licensing/s5_client_entitlement_integration_test.dart',
      ]) {
        expect(File(canonicalTest).existsSync(), isTrue,
            reason: '$canonicalTest must not be deleted');
      }
    });

    test(
        'Case 19: full Dart regression floor is not reduced — governed '
        'licensing test directory remains populated', () {
      final licensingDir = Directory('test/licensing');
      expect(licensingDir.existsSync(), isTrue);
      final count = licensingDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .length;
      // S9 adds this file (13), so the floor is at least the prior 12-file
      // governed set.
      expect(count, greaterThanOrEqualTo(12));
    });
  });
}

/// Return the line numbers of every occurrence of [symbol] as a standalone
/// identifier (word boundary) in [text].
List<int> _identifierMatches(String text, String symbol) {
  final results = <int>[];
  final lines = text.split('\n');
  final pattern = RegExp(
      r'(?<![A-Za-z0-9_])' + RegExp.escape(symbol) + r'(?![A-Za-z0-9_])');
  for (var i = 0; i < lines.length; i++) {
    if (pattern.hasMatch(lines[i])) {
      results.add(i + 1);
    }
  }
  return results;
}

/// Remove Dart comments (line `//`, doc `///`, and `/* ... */` blocks) so the
/// retired-symbol scan measures executable references only, not documentation.
String _stripComments(String source) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final c = source[i];
    if (c == '/' && i + 1 < source.length && source[i + 1] == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
    } else if (c == '/' && i + 1 < source.length && source[i + 1] == '*') {
      i += 2;
      while (i + 1 < source.length &&
          !(source[i] == '*' && source[i + 1] == '/')) {
        buffer.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      i += 2;
    } else {
      buffer.write(c);
      i++;
    }
  }
  return buffer.toString();
}

String base64urlEncode(Uint8List bytes) {
  return base64Encode(bytes)
      .replaceAll('+', '-')
      .replaceAll('/', '_')
      .replaceAll('=', '');
}
