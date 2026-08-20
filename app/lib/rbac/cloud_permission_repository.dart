import 'package:supabase_flutter/supabase_flutter.dart';

import 'effective_permission_model.dart';
import 'permission_exception.dart';

/// Supabase RPC calls for permission operations.
///
/// This repository is the ONLY place that calls permission-related RPCs.
/// All other services go through this class.
class CloudPermissionRepository {
  CloudPermissionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch the full permission snapshot for the caller in a shop.
  ///
  /// Returns a [CloudPermissionSnapshot] with resolved effective permissions,
  /// overrides, and metadata. Throws [CloudPermissionException] on failure.
  Future<CloudPermissionSnapshot> syncUserPermissions(String shopId) async {
    try {
      final response = await _client.rpc(
        'sync_user_permissions',
        params: {'p_shop_id': shopId},
      );
      return CloudPermissionSnapshot.fromRpc(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      throw CloudPermissionException.fromRpcError(e.toString());
    }
  }

  /// Assert the caller has a specific permission in a shop.
  ///
  /// Returns the member's role on success. Throws on failure.
  Future<String> requireShopPermission(
      String shopId, String permissionId) async {
    try {
      final response = await _client.rpc(
        'require_shop_permission',
        params: {
          'p_shop_id': shopId,
          'p_permission_id': permissionId,
        },
      );
      return response as String;
    } catch (e) {
      throw CloudPermissionException.fromRpcError(e.toString());
    }
  }

  /// Get all overrides for a shop (owner-only).
  Future<List<Map<String, dynamic>>> getShopPermissionOverrides(
      String shopId) async {
    try {
      final response = await _client.rpc(
        'get_shop_permission_overrides',
        params: {'p_shop_id': shopId},
      );
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw CloudPermissionException.fromRpcError(e.toString());
    }
  }

  /// Set a permission override (owner-only).
  Future<bool> setShopPermissionOverride({
    required String shopId,
    required String role,
    required String permissionId,
    required String effect,
  }) async {
    try {
      final response = await _client.rpc(
        'set_shop_permission_override',
        params: {
          'p_shop_id': shopId,
          'p_role': role,
          'p_permission_id': permissionId,
          'p_effect': effect,
        },
      );
      return response == true;
    } catch (e) {
      throw CloudPermissionException.fromRpcError(e.toString());
    }
  }

  /// Delete a permission override (owner-only).
  Future<bool> deleteShopPermissionOverride({
    required String shopId,
    required String role,
    required String permissionId,
  }) async {
    try {
      final response = await _client.rpc(
        'delete_shop_permission_override',
        params: {
          'p_shop_id': shopId,
          'p_role': role,
          'p_permission_id': permissionId,
        },
      );
      return response == true;
    } catch (e) {
      throw CloudPermissionException.fromRpcError(e.toString());
    }
  }
}
