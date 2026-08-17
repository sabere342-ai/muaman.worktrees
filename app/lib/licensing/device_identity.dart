import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Application salt for device fingerprint hashing.
/// Fixed per-app constant per T3-2 §13.
const String _deviceFingerprintSalt = 'I-TECH-LICENSING-DEVICE-FINGERPRINT-v1';

/// Sentinel value for unavailable hardware identifiers.
const String _unavailableSentinel = 'UNAVAILABLE';

/// Provides Windows device identity for licensing device binding.
///
/// Computes a stable device fingerprint from:
/// - Windows MachineGuid (registry)
/// - CPU ProcessorId (WMI)
/// - Baseboard SerialNumber (WMI)
///
/// The raw identifiers are never sent to the server — only the
/// SHA-256 derived hash is transmitted.
class DeviceIdentity {
  /// Compute the device fingerprint hash as specified in T3-2 §13.
  ///
  /// Returns a 32-byte SHA-256 digest.
  /// Deterministic: same inputs always produce the same hash.
  static Future<Uint8List> computeFingerprint() async {
    final machineGuid = await _getMachineGuid();
    final cpuId = await _getCpuId();
    final boardSerial = await _getBoardSerial();

    return _hashFingerprint(
      machineGuid: machineGuid,
      cpuId: cpuId,
      boardSerial: boardSerial,
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

  // --- Windows-specific hardware identification ---

  /// Read MachineGuid from Windows registry.
  /// Survives OS reinstall, app reinstall, disk changes.
  static Future<String> _getMachineGuid() async {
    if (!Platform.isWindows) return _unavailableSentinel;
    try {
      final result = await Process.run('reg', [
        'query',
        r'HKLM\SOFTWARE\Microsoft\Cryptography',
        '/v',
        'MachineGuid',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match =
            RegExp(r'MachineGuid\s+REG_SZ\s+(\S+)').firstMatch(output);
        if (match != null) {
          return match.group(1)!;
        }
      }
    } catch (_) {}
    return _unavailableSentinel;
  }

  /// Read CPU ProcessorId via WMI.
  /// Survives OS reinstall, app reinstall, disk changes.
  static Future<String> _getCpuId() async {
    if (!Platform.isWindows) return _unavailableSentinel;
    try {
      final result = await Process.run('wmic', [
        'cpu',
        'get',
        'ProcessorId',
        '/value',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'ProcessorId=(\S+)').firstMatch(output);
        if (match != null) {
          return match.group(1)!;
        }
      }
    } catch (_) {}
    return _unavailableSentinel;
  }

  /// Read Baseboard SerialNumber via WMI.
  /// Survives OS reinstall, app reinstall.
  static Future<String> _getBoardSerial() async {
    if (!Platform.isWindows) return _unavailableSentinel;
    try {
      final result = await Process.run('wmic', [
        'baseboard',
        'get',
        'SerialNumber',
        '/value',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'SerialNumber=(\S+)').firstMatch(output);
        if (match != null) {
          return match.group(1)!;
        }
      }
    } catch (_) {}
    return _unavailableSentinel;
  }
}
