import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/models/cloud/cloud_device.dart';
import 'package:muaman_store/services/cloud_device_management_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// S7 Owner device-management repository tests.
///
/// These prove the client wiring calls ONLY the committed server-authoritative
/// RPCs with the correct tenant-scoped parameters, and that lifecycle parsing
/// is fail-closed (never infers a state from an unknown/missing value).
///
/// RPCs are exercised through an injected seam so the assertions observe the
/// exact function name and tenant-scoped parameters.
void main() {
  group('CloudDeviceManagementRepository', () {
    test('listDevices invokes s4_list_devices with the bound shop id',
        () async {
      final mock = _RpcRecorder((fn, params) {
        expect(fn, 's4_list_devices');
        return [
          {
            'device_id': 'dev-1',
            'installation_id': 'inst-1',
            'platform': 'android',
            'device_name': 'جهاز 1',
            'user_id': 'u-1',
            'status': 'PENDING_APPROVAL',
            'public_key': 'pubkey',
            'approved_at': null,
            'revoked_at': null,
            'first_seen_at': '2026-08-01T10:00:00Z',
            'last_seen_at': '2026-09-01T10:00:00Z',
          },
        ];
      });
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      final devices = await repo.listDevices('shop-A');

      expect(mock.calls, hasLength(1));
      final call = mock.calls.single;
      expect(call.fn, 's4_list_devices');
      expect(call.params['p_shop_id'], 'shop-A');
      expect(devices, hasLength(1));
      expect(devices.first.deviceName, 'جهاز 1');
      expect(devices.first.status, DeviceTrustStatus.pendingApproval);
    });

    test('listDevices parses all five canonical lifecycle states', () async {
      final mock = _RpcRecorder((fn, params) {
        return [
          for (final s in [
            'PENDING_APPROVAL',
            'ACTIVE',
            'REJECTED',
            'REVOKED',
            'LOST',
          ])
            {'device_id': 'd-$s', 'installation_id': 'i', 'status': s},
        ];
      });
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      final devices = await repo.listDevices('shop-A');

      expect(devices.map((d) => d.status).toSet(), {
        DeviceTrustStatus.pendingApproval,
        DeviceTrustStatus.active,
        DeviceTrustStatus.rejected,
        DeviceTrustStatus.revoked,
        DeviceTrustStatus.lost,
      });
    });

    test('listDevices fails closed on an unknown lifecycle value', () async {
      final mock = _RpcRecorder((fn, params) {
        return [
          {'device_id': 'd-1', 'installation_id': 'i', 'status': 'FABRICATED'},
        ];
      });
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      expect(
        () => repo.listDevices('shop-A'),
        throwsA(isA<FormatException>()),
      );
    });

    test('listDevices fails closed on a missing/null status (no ACTIVE infer)',
        () async {
      final mock = _RpcRecorder((fn, params) {
        return [
          {'device_id': 'd-1', 'installation_id': 'i'},
        ];
      });
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      expect(
        () => repo.listDevices('shop-A'),
        throwsA(isA<FormatException>()),
      );
    });

    test('approveDevice invokes s4_approve_device with shop, device, reason',
        () async {
      final mock = _RpcRecorder((fn, params) => true);
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      final ok = await repo.approveDevice('shop-A', 'dev-1', reason: 'ok');

      expect(ok, isTrue);
      expect(mock.calls.single.fn, 's4_approve_device');
      expect(mock.calls.single.params['p_shop_id'], 'shop-A');
      expect(mock.calls.single.params['p_device_id'], 'dev-1');
      expect(mock.calls.single.params['p_reason'], 'ok');
    });

    test('rejectDevice invokes s4_reject_device', () async {
      final mock = _RpcRecorder((fn, params) => true);
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      final ok = await repo.rejectDevice('shop-A', 'dev-1');

      expect(ok, isTrue);
      expect(mock.calls.single.fn, 's4_reject_device');
      expect(mock.calls.single.params['p_device_id'], 'dev-1');
    });

    test('markDeviceLost invokes s4_mark_device_lost', () async {
      final mock = _RpcRecorder((fn, params) => true);
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      final ok = await repo.markDeviceLost('shop-A', 'dev-1');

      expect(ok, isTrue);
      expect(mock.calls.single.fn, 's4_mark_device_lost');
    });

    test('revokeDevice uses the canonical s3_revoke_device (NOT an S7 RPC)',
        () async {
      final mock = _RpcRecorder((fn, params) => true);
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      final ok = await repo.revokeDevice('shop-A', 'dev-1');

      expect(ok, isTrue);
      expect(mock.calls.single.fn, 's3_revoke_device');
      expect(mock.calls.single.params['p_device_id'], 'dev-1');
    });

    test(
        'a failed mutation surfaces the client-visible failure (no fabrication)',
        () async {
      final mock = _RpcRecorder((fn, params) {
        throw PostgrestException(
          message: 'S4_REJECT_DENIED: active device must be revoked',
          code: 'check_violation',
          details: '',
          hint: '',
        );
      });
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      await expectLater(
        repo.rejectDevice('shop-A', 'dev-1'),
        throwsA(isA<PostgrestException>()),
      );
    });

    test(
        'terminal-state result values map truthfully to booleans (false stays '
        'false, never treated as success)', () async {
      final mock = _RpcRecorder((fn, params) => false);
      final repo = CloudDeviceManagementRepository(rpc: mock.rpc);

      expect(await repo.approveDevice('shop-A', 'dev-1'), isFalse);
      expect(await repo.revokeDevice('shop-A', 'dev-1'), isFalse);
      expect(await repo.markDeviceLost('shop-A', 'dev-1'), isFalse);
      expect(await repo.rejectDevice('shop-A', 'dev-1'), isFalse);
    });
  });

  group('CloudDevice model', () {
    test('Server value mapping stays canonical (no invented states)', () {
      expect(DeviceTrustStatus.active.serverValue, 'ACTIVE');
      expect(DeviceTrustStatus.pendingApproval.serverValue, 'PENDING_APPROVAL');
      expect(DeviceTrustStatus.rejected.serverValue, 'REJECTED');
      expect(DeviceTrustStatus.revoked.serverValue, 'REVOKED');
      expect(DeviceTrustStatus.lost.serverValue, 'LOST');
    });

    test('fromServer rejects invented states and null (fail closed)', () {
      expect(DeviceTrustStatus.fromServer(null), isNull);
      expect(DeviceTrustStatus.fromServer('PENDING'), isNull);
      expect(DeviceTrustStatus.fromServer('APPROVED'), isNull);
      expect(DeviceTrustStatus.fromServer('DISABLED'), isNull);
      expect(DeviceTrustStatus.fromServer('BLOCKED'), isNull);
    });

    test('only the three trust failures are terminal', () {
      expect(DeviceTrustStatus.rejected.isTerminal, isTrue);
      expect(DeviceTrustStatus.revoked.isTerminal, isTrue);
      expect(DeviceTrustStatus.lost.isTerminal, isTrue);
      expect(DeviceTrustStatus.active.isTerminal, isFalse);
      expect(DeviceTrustStatus.pendingApproval.isTerminal, isFalse);
    });
  });
}

/// Records every RPC invocation and returns the configured result. Replaces
/// the (impractical) task of mocking `SupabaseClient.rpc`, whose static return
/// type is a `PostgrestFilterBuilder`.
class _RpcRecorder {
  _RpcRecorder(this.handler);

  final Object? Function(String fn, Map<String, dynamic> params) handler;
  final List<({String fn, Map<String, dynamic> params})> calls = [];

  Future<Object?> rpc(String fn, Map<String, dynamic> params) async {
    calls.add((fn: fn, params: params));
    return handler(fn, params);
  }
}
