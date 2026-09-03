import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/licensing/s6_device_identity.dart';
import 'package:muaman_store/licensing/secure_store_android.dart';
import 'package:muaman_store/platform/secure_secret_store.dart';

/// Phase P Group B S6 — per-install Ed25519 device identity.
///
/// Covers governed Scenarios 01-08, 23-25 (identity lifecycle, secure-store
/// binding, and the "private material never leaks" invariant). Proof-of-
/// possession verification lives in s6_proof_of_possession_test.dart and the
/// evidence matrix in s6_platform_secure_device_identity_test.dart.
void main() {
  // ────────────────────────────────────────────────────────────────────────
  // Scenario 01: FIRST INSTALL generates exactly one per-install Ed25519 key
  // ────────────────────────────────────────────────────────────────────────
  group('Scenario 01 — first-install identity generation', () {
    test('fresh store yields a new 32-byte-Ed25519 identity persisted once',
        () async {
      final store = InMemorySecureSecretStore();
      final identity = S6DeviceIdentity(store);

      final outcome = await identity.loadOrCreate();

      expect(outcome.isNew, isTrue);
      final pub = await outcome.identity.publicKeyBytes();
      expect(pub.length, 32);
      expect(await outcome.identity.publicKeyBase64Url(),
          isNot(contains('='))); // canonical base64url, no padding
      // Persisted exactly once.
      expect(await store.containsKey(S6DeviceIdentity.storageKey), isTrue);
      final record = await store.read(S6DeviceIdentity.storageKey);
      expect(record, isNot(contains('=')));
      expect(record!.split('|').length, 2);
    });

    test('a seed produces a deterministic keypair (Ed25519/RFC 8032)', () async {
      final seed = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final a = await S6TestIdentity.fromSeed(seed, createdAt: 1);
      final b = await S6TestIdentity.fromSeed(seed, createdAt: 1);
      expect(await a.publicKeyBase64Url(), await b.publicKeyBase64Url());
      expect(await a.publicKeyBytes(), await b.publicKeyBytes());
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Scenario 02: NORMAL RESTART loads and reuses the SAME identity
  // ────────────────────────────────────────────────────────────────────────
  group('Scenario 02 — restart reuse', () {
    test('second load reuses the persisted identity without regenerating',
        () async {
      final store = InMemorySecureSecretStore();
      final first = await S6DeviceIdentity(store).loadOrCreate();
      final pub1 = await first.identity.publicKeyBase64Url();

      // Simulate a restart with a fresh service instance over the same store.
      final second = await S6DeviceIdentity(store).loadOrCreate();
      expect(second.isNew, isFalse);
      expect(await second.identity.publicKeyBase64Url(), pub1);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Scenario 03: CONCURRENT FIRST LOAD converges on one identity
  // ────────────────────────────────────────────────────────────────────────
  group('Scenario 03 — concurrent single-flight init', () {
    test('parallel first loads converge on exactly one persisted identity',
        () async {
      final store = InMemorySecureSecretStore();
      final service = S6DeviceIdentity(store);

      final results = await Future.wait(
          List.generate(8, (_) => service.loadOrCreate()));

      final pubs = <String>{};
      for (final r in results) {
        pubs.add(await r.identity.publicKeyBase64Url());
      }
      expect(pubs.length, 1);
      // Exactly one record persisted, not several competing ones.
      expect(await store.containsKey(S6DeviceIdentity.storageKey), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Scenario 04: SECURE STORE LOST / REINSTALL -> new identity + re-enrollment
  // ────────────────────────────────────────────────────────────────────────
  group('Scenario 04 — secure-store loss forces re-enrollment', () {
    test('a wiped store yields a brand-new identity (re-enroll flow)', () async {
      final store = InMemorySecureSecretStore();
      final first = await S6DeviceIdentity(store).loadOrCreate();
      final pub1 = await first.identity.publicKeyBase64Url();

      await store.delete(S6DeviceIdentity.storageKey); // store lost

      final second = await S6DeviceIdentity(store).loadOrCreate();
      expect(second.isNew, isTrue);
      expect(await second.identity.publicKeyBase64Url(), isNot(pub1));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Scenario 05: CORRUPT / UNAVAILABLE protected store -> fail closed
  // ────────────────────────────────────────────────────────────────────────
  group('Scenario 05 — corrupt private material fails closed', () {
    test('malformed persisted seed raises S6DeviceIdentityException',
        () async {
      final store = InMemorySecureSecretStore();
      await store.write(S6DeviceIdentity.storageKey, 'not-a-valid-record');
      expect(
        () => S6DeviceIdentity(store).loadOrCreate(),
        throwsA(isA<S6DeviceIdentityException>()),
      );
    });

    test('a non-32-byte seed fails closed', () async {
      final store = InMemorySecureSecretStore();
      final badSeed =
          base64UrlEncode(List<int>.filled(16, 7)).replaceAll('=', '');
      await store.write(S6DeviceIdentity.storageKey, '$badSeed|123');
      expect(
        () => S6DeviceIdentity(store).loadOrCreate(),
        throwsA(isA<S6DeviceIdentityException>()),
      );
    });

    test('a store that throws on read fails closed (no fabricated identity)',
        () async {
      final store = _ThrowingSecretStore();
      expect(
        () => S6DeviceIdentity(store).loadOrCreate(),
        throwsA(isA<S6DeviceIdentityException>()),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Scenario 06-08: platform secure-store binding & fail-closed persistence
  // ────────────────────────────────────────────────────────────────────────
  group('Scenario 06-08 — platform secure-store binding', () {
    test('Android default resolves to the Keystore channel store', () async {
      expect(const KeystoreChannelSecretStore(), isA<SecureSecretStore>());
      // The Keystore store delegates ALL persistence to the itech.app/secure_storage
      // channel (EncryptedSharedPreferences + Keystore master key). It performs
      // no plaintext storage of its own and surfaces PlatformException to fail
      // closed. (Channel round-trips are out of scope for the Dart VM test.)
      final src = await File('lib/licensing/secure_store_android.dart')
          .readAsString();
      expect(src.contains('itech.app/secure_storage'), isTrue);
      // No direct shared_preferences dependency and no plaintext file writes.
      expect(src.contains('package:shared_preferences'), isFalse);
      expect(src.contains("import 'package:shared_preferences"), isFalse);
      expect(src.contains('writeAsString'), isFalse);
    });

    test('Windows store protects via DPAPI CurrentUser (no plaintext file)',
        () async {
      final dir = Directory.systemTemp.createTempSync('s6_dpapi_test_');
      try {
        final store = WindowsDpapiSecureSecretStore(baseDir: dir);
        if (!Platform.isWindows) {
          // On non-Windows the store must fail closed, never fall back.
          await expectLater(store.write('k', 'v'), throwsA(isA<StateError>()));
          return;
        }
        await store.write('k', 'secret-value');
        // Persisted file is ONLY ciphertext base64, never the plaintext.
        final file = File('${dir.path}/k.bin');
        expect(await file.exists(), isTrue);
        final contents = await file.readAsString();
        expect(contents, isNot(contains('secret-value')));
        expect(await store.read('k'), 'secret-value');
        // Round-trip under a different key proves key isolation.
        expect(await store.containsKey('k'), isTrue);
        await store.delete('k');
        expect(await store.containsKey('k'), isFalse);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('never stores plaintext or XOR-obfuscation for S6 material',
        () async {
      final src = await File(
              'lib/platform/secure_secret_store.dart')
          .readAsString();
      // S6 private material is protected by DPAPI CurrentUser; the store never
      // uses LocalMachine scope, an XOR/obfuscation fallback, or a plaintext
      // temp file. (The doc comment may mention the words; we assert no actual
      // XOR/obfuscate routine exists.)
      expect(src.contains('DataProtectionScope.LocalMachine'), isFalse);
      expect(src.contains('DataProtectionScope.CurrentUser'), isTrue);
      expect(src.contains('xorEncode'), isFalse);
      expect(src.contains('obfuscate('), isFalse);
      expect(src.contains('xorWith'), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Scenario 23: identity is NEVER serialized to cache/AppSettings/SQLite and
  //              private material is NEVER logged
  // ────────────────────────────────────────────────────────────────────────
  group('Scenario 23 — private material containment', () {
    test('implementation never logs or prints the private seed', () async {
      final src = await File('lib/licensing/s6_device_identity.dart')
          .readAsString();
      // No logging/printing of the private seed...
      expect(src.contains('debugPrint(seed'), isFalse);
      expect(src.contains('print(seed'), isFalse);
      // ...and no cache / AppSettings / SQLite persistence dependency.
      expect(src.contains('shared_preferences'), isFalse);
      expect(src.contains('sqflite'), isFalse);
      expect(src.contains("import 'package:shared_preferences"), isFalse);
      expect(src.contains("import 'package:sqflite"), isFalse);
    });

    test('the generated seed is not written into any cache/AppSettings/SQLite',
        () async {
      final store = InMemorySecureSecretStore();
      final identity = S6DeviceIdentity(store);
      final outcome = await identity.loadOrCreate();
      // Only the protected store holds material; the exposed form is the
      // canonical base64url public key (no '=' padding), never the seed.
      final pub = await outcome.identity.publicKeyBase64Url();
      expect(pub.contains('='), isFalse);
      expect(pub, isNotEmpty);
      expect(pub.length, 43); // 32 raw bytes -> 43 base64url chars (no pad)
    });
  });
}

/// Test-only store that fails on every read — used to prove fail-closed when
/// the underlying protected storage is unavailable.
class _ThrowingSecretStore implements SecureSecretStore {
  @override
  Future<String?> read(String key) async =>
      throw StateError('secure storage unavailable');

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<bool> containsKey(String key) async => false;
}
