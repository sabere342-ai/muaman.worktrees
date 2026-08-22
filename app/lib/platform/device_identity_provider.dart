import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Raw hardware-identity components consumed by the DeviceIdentity hashing
/// pipeline (T3-2 §13 canonical inputs). Empty values normalize to the
/// `UNAVAILABLE` sentinel before hashing — the sentinel remains a last
/// resort only (Phase K D5/R3).
class DeviceIdentityComponents {
  final String machineGuid;
  final String cpuId;
  final String boardSerial;

  const DeviceIdentityComponents({
    this.machineGuid = '',
    this.cpuId = '',
    this.boardSerial = '',
  });
}

/// Injectable source of device identity (Phase K D5).
///
/// Business/licensing code depends on this abstraction instead of calling
/// platform probes directly, so Windows, Android and test fakes plug in
/// without forking the fingerprint algorithm. The raw identifiers never
/// leave the process — only the salted SHA-256 derived hash is transmitted.
abstract class DeviceIdentityProvider {
  const DeviceIdentityProvider();

  Future<DeviceIdentityComponents> loadComponents();
}

/// Sentinel provider: every component is unavailable. Used off-Windows/
/// off-Android as an explicit last resort so behavior degrades to the
/// historical sentinel fingerprint instead of crashing.
class SentinelDeviceIdentityProvider implements DeviceIdentityProvider {
  const SentinelDeviceIdentityProvider();

  @override
  Future<DeviceIdentityComponents> loadComponents() async {
    return const DeviceIdentityComponents();
  }
}

/// Windows provider wrapping the historical reg.exe/wmic probe pipeline
/// (MachineGuid, CPU ProcessorId, Baseboard SerialNumber). The probe inputs
/// are byte-identical to the pre-Phase-K implementation; only their
/// ownership moved behind the abstraction.
class WindowsDeviceIdentityProvider implements DeviceIdentityProvider {
  const WindowsDeviceIdentityProvider();

  @override
  Future<DeviceIdentityComponents> loadComponents() async {
    return DeviceIdentityComponents(
      machineGuid: await _getMachineGuid(),
      cpuId: await _getCpuId(),
      boardSerial: await _getBoardSerial(),
    );
  }

  /// Read MachineGuid from Windows registry.
  /// Survives OS reinstall, app reinstall, disk changes.
  Future<String> _getMachineGuid() async {
    if (!Platform.isWindows) return '';
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
    return '';
  }

  /// Read CPU ProcessorId via WMI.
  /// Survives OS reinstall, app reinstall, disk changes.
  Future<String> _getCpuId() async {
    if (!Platform.isWindows) return '';
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
    return '';
  }

  /// Read Baseboard SerialNumber via WMI.
  /// Survives OS reinstall, app reinstall.
  Future<String> _getBoardSerial() async {
    if (!Platform.isWindows) return '';
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
    return '';
  }
}

/// Android provider resolving SSAID (`Settings.Secure.ANDROID_ID`) through
/// the `itech.app/device_identity` platform channel.
///
/// SSAID is scoped per app-signing key + user + device: stable across
/// restarts and app updates on this install, distinct across different
/// physical devices — which is exactly what licensing device bookkeeping
/// requires (`register_device` upserts on installation identity). It is a
/// fingerprint INPUT only; the raw value is never transmitted or logged.
class AndroidDeviceIdentityProvider implements DeviceIdentityProvider {
  const AndroidDeviceIdentityProvider();

  static const MethodChannel _channel =
      MethodChannel('itech.app/device_identity');

  @override
  Future<DeviceIdentityComponents> loadComponents() async {
    try {
      final ssaid = await _channel.invokeMethod<String>('getSsaid');
      if (ssaid == null || ssaid.trim().isEmpty) {
        return const DeviceIdentityComponents();
      }
      return DeviceIdentityComponents(machineGuid: ssaid.trim());
    } on MissingPluginException {
      // Channel not available (e.g. tests): explicit sentinel fallback.
      return const DeviceIdentityComponents();
    } catch (_) {
      return const DeviceIdentityComponents();
    }
  }
}

/// Resolves the provider matching the CURRENT runtime platform.
/// Windows keeps its historical probes; Android uses the SSAID channel;
/// anything else degrades explicitly to the sentinel provider.
DeviceIdentityProvider resolveDefaultDeviceIdentityProvider() {
  if (Platform.isAndroid) {
    return const AndroidDeviceIdentityProvider();
  }
  if (Platform.isWindows) {
    return const WindowsDeviceIdentityProvider();
  }
  return const SentinelDeviceIdentityProvider();
}
