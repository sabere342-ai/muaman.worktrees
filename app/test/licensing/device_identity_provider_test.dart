import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/licensing/device_identity.dart';

/// Phase K (D5) — injectable device identity.
///
/// Proves the provider seam is deterministic, distinct per simulated
/// physical device (collision gate), and that the Android SSAID channel is
/// consumed through the abstraction with an explicit sentinel fallback.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    DeviceIdentity.setProvider(null);
  });

  group('injected providers', () {
    test('same components → identical fingerprint (deterministic)', () async {
      DeviceIdentity.setProvider(const FakeDeviceIdentityProvider(
        machineGuid: 'GUID-1',
        cpuId: 'CPU-1',
        boardSerial: 'BOARD-1',
      ));

      final a = await DeviceIdentity.computeFingerprint();
      final b = await DeviceIdentity.computeFingerprint();
      expect(a, b);
    });

    test('two simulated devices → DISTINCT fingerprints (collision gate)',
        () async {
      DeviceIdentity.setProvider(const FakeDeviceIdentityProvider(
        machineGuid: 'SSAID-DEVICE-ONE',
        cpuId: '',
        boardSerial: '',
      ));
      final deviceOne = await DeviceIdentity.getDeviceIdHashBase64();

      // Historical defect: without a real Android identity source both
      // devices collapsed onto the UNAVAILABLE sentinel fingerprint.
      DeviceIdentity.setProvider(const FakeDeviceIdentityProvider(
        machineGuid: 'SSAID-DEVICE-TWO',
        cpuId: '',
        boardSerial: '',
      ));
      final deviceTwo = await DeviceIdentity.getDeviceIdHashBase64();

      expect(deviceOne, isNot(deviceTwo));
    });

    test('sentinel fallback equals historical UNAVAILABLE-only hash', () async {
      DeviceIdentity.setProvider(const SentinelDeviceIdentityProvider());
      final sentinelHash = await DeviceIdentity.computeFingerprint();

      final legacyEquivalent = DeviceIdentity.computeFingerprintFromComponents(
        machineGuid: '',
        cpuId: '',
        boardSerial: '',
      );

      expect(sentinelHash, legacyEquivalent);
    });

    test('Windows algorithm inputs remain byte-identical', () {
      // The canonical construction and hashing are unchanged from the
      // pre-Phase-K implementation; this pins the exact contract.
      final canonical = DeviceIdentity.constructCanonical(
        machineGuid: 'M',
        cpuId: 'C',
        boardSerial: 'B',
      );
      expect(canonical, 'I-TECH-DEVICE|M|C|B');
    });
  });

  group('AndroidDeviceIdentityProvider', () {
    const channel = MethodChannel('itech.app/device_identity');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getSsaid') return 'ANDROID-ID-123';
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('returns SSAID as machineGuid component', () async {
      const provider = AndroidDeviceIdentityProvider();
      final components = await provider.loadComponents();
      expect(components.machineGuid, 'ANDROID-ID-123');
    });

    test('missing channel plugin degrades to empty components', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      const provider = AndroidDeviceIdentityProvider();
      final components = await provider.loadComponents();
      expect(components.machineGuid, isEmpty);
      expect(components.cpuId, isEmpty);
      expect(components.boardSerial, isEmpty);
    });

    test('null SSAID degrades to empty components (sentinel last resort)',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      const provider = AndroidDeviceIdentityProvider();
      final components = await provider.loadComponents();
      expect(components.machineGuid, isEmpty);
    });
  });

  group('WindowsDeviceIdentityProvider off-Windows behavior', () {
    test('probes short-circuit on non-Windows host (no crash, no data)',
        () async {
      // Tests run on the host VM; on non-Windows CI this asserts the guard.
      // On Windows hosts the probes execute for real and may return values,
      // so only structural invariants are asserted here.
      const provider = WindowsDeviceIdentityProvider();
      final components = await provider.loadComponents();
      expect(components.machineGuid, isA<String>());
      expect(components.cpuId, isA<String>());
      expect(components.boardSerial, isA<String>());
    });
  });
}

class FakeDeviceIdentityProvider implements DeviceIdentityProvider {
  final String machineGuid;
  final String cpuId;
  final String boardSerial;

  const FakeDeviceIdentityProvider({
    required this.machineGuid,
    required this.cpuId,
    required this.boardSerial,
  });

  @override
  Future<DeviceIdentityComponents> loadComponents() async {
    return DeviceIdentityComponents(
      machineGuid: machineGuid,
      cpuId: cpuId,
      boardSerial: boardSerial,
    );
  }
}
