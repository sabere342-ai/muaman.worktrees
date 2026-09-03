import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cloud/cloud_device.dart';

/// Owner device-management repository (S7).
///
/// Wraps ONLY the committed, server-authoritative device lifecycle authority:
///   - list  : `s4_list_devices`
///   - approve: `s4_approve_device`
///   - reject : `s4_reject_device`
///   - lost   : `s4_mark_device_lost`
///   - revoke : canonical `s3_revoke_device`
///
/// These are SECURITY DEFINER, owner-only, tenant-scoped functions granted to
/// `authenticated`. This client layer never mutates tables directly and never
/// fabricates lifecycle state — the server is the final authority.
class CloudDeviceManagementRepository {
  CloudDeviceManagementRepository({
    SupabaseClient? client,
    Future<Object?> Function(
      String function,
      Map<String, dynamic> params,
    )? rpc,
  })  : _injectedClient = client,
        _injectedRpc = rpc;

  final SupabaseClient? _injectedClient;
  final Future<Object?> Function(String function, Map<String, dynamic> params)?
      _injectedRpc;

  SupabaseClient get _client {
    return _injectedClient ?? Supabase.instance.client;
  }

  /// Invokes an RPC, using the injected seam if provided (tests) or the
  /// configured `SupabaseClient` otherwise.
  Future<Object?> _rpc(String function, Map<String, dynamic> params) {
    final injected = _injectedRpc;
    if (injected != null) {
      return injected(function, params);
    }
    return _client.rpc(function, params: params);
  }

  /// Lists the current shop's devices from the server-authoritative,
  /// owner-scoped `s4_list_devices`. Fail-closed: any unknown lifecycle value
  /// throws rather than silently defaulting.
  Future<List<CloudDevice>> listDevices(String shopId) async {
    final response = await _rpc(
      's4_list_devices',
      {'p_shop_id': shopId},
    );
    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(CloudDevice.fromRpc).toList();
  }

  /// Approves a pending device via `s4_approve_device` (PENDING_APPROVAL →
  /// ACTIVE). Returns the authoritative server boolean.
  Future<bool> approveDevice(
    String shopId,
    String deviceId, {
    String? reason,
  }) async {
    final response = await _rpc(
      's4_approve_device',
      {
        'p_shop_id': shopId,
        'p_device_id': deviceId,
        'p_reason': reason,
      },
    );
    return response == true;
  }

  /// Rejects a pending device via `s4_reject_device` (→ REJECTED, terminal).
  Future<bool> rejectDevice(
    String shopId,
    String deviceId, {
    String? reason,
  }) async {
    final response = await _rpc(
      's4_reject_device',
      {
        'p_shop_id': shopId,
        'p_device_id': deviceId,
        'p_reason': reason,
      },
    );
    return response == true;
  }

  /// Marks a device lost via `s4_mark_device_lost` (→ LOST, terminal).
  Future<bool> markDeviceLost(
    String shopId,
    String deviceId, {
    String? reason,
  }) async {
    final response = await _rpc(
      's4_mark_device_lost',
      {
        'p_shop_id': shopId,
        'p_device_id': deviceId,
        'p_reason': reason,
      },
    );
    return response == true;
  }

  /// Revokes a device via the canonical `s3_revoke_device` path (→ REVOKED,
  /// terminal). S7 does NOT create an S7-specific revocation path.
  Future<bool> revokeDevice(
    String shopId,
    String deviceId, {
    String? reason,
  }) async {
    final response = await _rpc(
      's3_revoke_device',
      {
        'p_shop_id': shopId,
        'p_device_id': deviceId,
        'p_reason': reason,
      },
    );
    return response == true;
  }
}
