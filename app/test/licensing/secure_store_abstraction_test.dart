import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/invoices/invoice_delivery.dart';
import 'package:muaman_store/licensing/secure_store.dart';
import 'package:muaman_store/licensing/secure_store_android.dart';
import 'package:muaman_store/platform/platform_capabilities.dart';
import 'package:muaman_store/platform/secure_secret_store.dart';

/// Phase K (D7/D8) — secure-storage abstraction and scoped-storage
/// delivery-mode contracts.
///
/// The Keystore-backed activation store is exercised against an in-memory
/// fake [SecureSecretStore] (test profile only); no secret material is ever
/// printed. Production Android wiring delegates to the Keystore-backed
/// `itech.app/secure_storage` method channel.
void main() {
  group('SecureSecretStore contract (InMemory fake — test profile)', () {
    test('read/write/delete roundtrip', () async {
      final store = InMemorySecureSecretStore();
      expect(await store.read('k'), isNull);

      await store.write('k', 'v');
      expect(await store.read('k'), 'v');
      expect(await store.containsKey('k'), isTrue);

      await store.delete('k');
      expect(await store.read('k'), isNull);
      expect(await store.containsKey('k'), isFalse);
    });
  });

  group('KeystoreActivationStore', () {
    late InMemorySecureSecretStore backing;
    late KeystoreActivationStore store;

    setUp(() {
      backing = InMemorySecureSecretStore();
      store = KeystoreActivationStore(backing);
    });

    test('absent state reads as null', () async {
      expect(await store.read(), isNull);
    });

    test('write → read preserves the full activation state', () async {
      final state = SecureActivationState(
        businessId: '0123456789abcdef-0123-4567-89ab-cdef',
        deviceHash: Uint8List.fromList([1, 2, 3, 4, 5]),
        tokenBytes: Uint8List.fromList([9, 8, 7]),
        activationGeneration: 42,
        createdAt: 1700000000000,
      );

      await store.write(state);
      final restored = await store.read();

      expect(restored, isNotNull);
      expect(restored!.businessId, state.businessId);
      expect(restored.deviceHash, state.deviceHash);
      expect(restored.tokenBytes, state.tokenBytes);
      expect(restored.activationGeneration, state.activationGeneration);
      expect(restored.createdAt, state.createdAt);
    });

    test('delete removes the persisted state', () async {
      await store.write(SecureActivationState(
        businessId: 'biz',
        deviceHash: Uint8List.fromList([1]),
        tokenBytes: Uint8List.fromList([2]),
        activationGeneration: 1,
        createdAt: 1,
      ));
      await store.delete();
      expect(await store.read(), isNull);
    });

    test('corrupted backing payload raises CorruptStateException', () async {
      await backing.write('itech.licensing.activation.state', '{not-json');
      expect(() => store.read(), throwsA(isA<CorruptStateException>()));
    });
  });

  group('scoped-storage PDF delivery mode (D8)', () {
    test('Android resolves to system share (no arbitrary writes)', () {
      expect(pdfDeliveryModeFor(isAndroidPlatform: true),
          PdfDeliveryMode.systemShare);
    });

    test('Windows keeps the native save dialog (unchanged)', () {
      expect(pdfDeliveryModeFor(isAndroidPlatform: false),
          PdfDeliveryMode.nativeSaveDialog);
    });
  });

  group('platform capability truthfulness (D6 seam)', () {
    test('desktop filesystem semantics flag is boolean-stable', () {
      // Structural assertion: the centralized seam exposes a stable value
      // on every host so callers never scatter Platform checks.
      expect(PlatformCapabilities.supportsDesktopFilesystem, isA<bool>());
      expect(PlatformCapabilities.isAndroid, isA<bool>());
      expect(PlatformCapabilities.isWindows, isA<bool>());
    });
  });
}
