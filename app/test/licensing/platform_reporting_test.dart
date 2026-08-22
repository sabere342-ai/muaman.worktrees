import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/licensing/cloud_licensing_service.dart';

/// Phase K (D6) — truthful platform reporting.
///
/// The server contract (`devices.platform` CHECK) accepts only 'windows' |
/// 'android'. Android clients must report 'android'; Windows behavior is
/// unchanged.
void main() {
  group('platform label mapping', () {
    test('Android reports android', () {
      expect(detectPlatformLabelFor(isAndroidPlatform: true), 'android');
    });

    test('Windows reports windows (unchanged)', () {
      expect(detectPlatformLabelFor(isAndroidPlatform: false), 'windows');
    });
  });

  group('device name mapping', () {
    test('Android devices are no longer reported as Desktop', () {
      expect(detectDeviceNameFor(isAndroidPlatform: true), 'Android');
    });

    test('Desktop name preserved for Windows', () {
      expect(detectDeviceNameFor(isAndroidPlatform: false), 'Desktop');
    });
  });

  group('server contract compliance', () {
    test('every emitted platform label satisfies the server CHECK', () {
      final labels = [
        detectPlatformLabelFor(isAndroidPlatform: true),
        detectPlatformLabelFor(isAndroidPlatform: false),
      ];
      for (final label in labels) {
        expect(label, anyOf('windows', 'android'),
            reason: 'devices.platform CHECK accepts only windows|android');
      }
    });
  });
}
