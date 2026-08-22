import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../platform/device_identity_provider.dart';

export '../platform/device_identity_provider.dart'
    show
        AndroidDeviceIdentityProvider,
        DeviceIdentityComponents,
        DeviceIdentityProvider,
        SentinelDeviceIdentityProvider,
        WindowsDeviceIdentityProvider;

/// Application salt for device fingerprint hashing.
/// Fixed per-app constant per T3-2 §13.
const String _deviceFingerprintSalt = 'I-TECH-LICENSING-DEVICE-FINGERPRINT-v1';

/// Sentinel value for unavailable hardware identifiers.
const String _unavailableSentinel = 'UNAVAILABLE';

/// Provides device identity for licensing device binding.
///
/// Computes a stable device fingerprint from platform-sourced components
/// through the injectable [DeviceIdentityProvider] seam (Phase K D5):
/// - Windows: MachineGuid (registry), CPU ProcessorId (WMI), Baseboard
///   SerialNumber (WMI) — historical pipeline, byte-identical inputs.
/// - Android: SSAID fingerprint via platform channel.
///
/// The raw identifiers are never sent to the server — only the
/// SHA-256 derived hash is transmitted. Tests inject deterministic
/// providers via [setProvider].
class DeviceIdentity {
  static DeviceIdentityProvider? _providerOverride;

  /// Injects a custom identity source (tests / fakes). Pass null to restore
  /// the platform default resolution.
  static void setProvider(DeviceIdentityProvider? provider) {
    _providerOverride = provider;
  }

  static DeviceIdentityProvider get _provider =>
      _providerOverride ?? resolveDefaultDeviceIdentityProvider();

  /// Compute the device fingerprint hash as specified in T3-2 §13.
  ///
  /// Returns a 32-byte SHA-256 digest.
  /// Deterministic: same inputs always produce the same hash.
  static Future<Uint8List> computeFingerprint() async {
    final components = await _provider.loadComponents();
    return computeFingerprintFromComponents(
      machineGuid: components.machineGuid,
      cpuId: components.cpuId,
      boardSerial: components.boardSerial,
    );
  }

  /// Compute fingerprint hash from provided components (for testing).
  static Uint8List computeFingerprintFromComponents({
    required String machineGuid,
    required String cpuId,
    required String boardSerial,
  }) {
    return _hashFingerprint(
      machineGuid: machineGuid,
      cpuId: cpuId,
      boardSerial: boardSerial,
    );
  }

  /// Get the device_id_hash as a base64 string (for API transmission).
  static Future<String> getDeviceIdHashBase64() async {
    final fingerprint = await computeFingerprint();
    return base64Encode(fingerprint);
  }

  /// Normalize a hardware identifier value.
  /// Strips whitespace, falls back to sentinel if empty.
  static String normalize(String? raw) {
    if (raw == null) return _unavailableSentinel;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? _unavailableSentinel : trimmed;
  }

  /// Construct the canonical input string per T3-2 §13.
  static String constructCanonical({
    required String machineGuid,
    required String cpuId,
    required String boardSerial,
  }) {
    return 'I-TECH-DEVICE|$machineGuid|$cpuId|$boardSerial';
  }

  /// Hash the fingerprint with application salt per T3-2 §13.
  static Uint8List _hashFingerprint({
    required String machineGuid,
    required String cpuId,
    required String boardSerial,
  }) {
    final canonical = constructCanonical(
      machineGuid: normalize(machineGuid),
      cpuId: normalize(cpuId),
      boardSerial: normalize(boardSerial),
    );
    final input = '$_deviceFingerprintSalt|$canonical';
    final bytes = utf8.encode(input);
    return Uint8List.fromList(sha256.convert(bytes).bytes);
  }
}
