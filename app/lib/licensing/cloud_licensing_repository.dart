import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side entitlement resolution result.
class EntitlementResult {
  final bool hasLicense;
  final String? licenseStatus;
  final bool isTrial;
  final bool trialActive;
  final DateTime? trialStartedAt;
  final DateTime? trialExpiresAt;
  final int? daysRemaining;
  final int? hoursRemaining;
  final DateTime? activatedAt;
  final DateTime? subscriptionExpiresAt;
  final int? maxDevices;
  final int currentDevices;
  final bool deviceSlotAvailable;
  final DateTime serverTime;
  final bool isRevoked;
  final DateTime? revokedAt;

  const EntitlementResult({
    required this.hasLicense,
    this.licenseStatus,
    required this.isTrial,
    required this.trialActive,
    this.trialStartedAt,
    this.trialExpiresAt,
    this.daysRemaining,
    this.hoursRemaining,
    this.activatedAt,
    this.subscriptionExpiresAt,
    this.maxDevices,
    required this.currentDevices,
    required this.deviceSlotAvailable,
    required this.serverTime,
    this.isRevoked = false,
    this.revokedAt,
  });

  factory EntitlementResult.fromRpc(Map<String, dynamic> data) {
    return EntitlementResult(
      hasLicense: data['has_license'] as bool? ?? false,
      licenseStatus: data['license_status'] as String?,
      isTrial: data['is_trial'] as bool? ?? false,
      trialActive: data['trial_active'] as bool? ?? false,
      trialStartedAt: data['trial_started_at'] != null
          ? DateTime.parse(data['trial_started_at'] as String)
          : null,
      trialExpiresAt: data['trial_expires_at'] != null
          ? DateTime.parse(data['trial_expires_at'] as String)
          : null,
      daysRemaining: data['days_remaining'] as int?,
      hoursRemaining: data['hours_remaining'] as int?,
      activatedAt: data['activated_at'] != null
          ? DateTime.parse(data['activated_at'] as String)
          : null,
      subscriptionExpiresAt: data['subscription_expires_at'] != null
          ? DateTime.parse(data['subscription_expires_at'] as String)
          : null,
      maxDevices: data['max_devices'] as int?,
      currentDevices: data['current_devices'] as int? ?? 0,
      deviceSlotAvailable: data['device_slot_available'] as bool? ?? false,
      serverTime: data['server_time'] != null
          ? DateTime.parse(data['server_time'] as String)
          : DateTime.now().toUtc(),
      isRevoked: data['is_revoked'] as bool? ?? false,
      revokedAt: data['revoked_at'] != null
          ? DateTime.parse(data['revoked_at'] as String)
          : null,
    );
  }
}

/// Result of device activation.
class DeviceActivationResult {
  final bool success;
  final String? activationId;
  final int? devicesRemaining;
  final String? error;

  const DeviceActivationResult({
    required this.success,
    this.activationId,
    this.devicesRemaining,
    this.error,
  });

  factory DeviceActivationResult.fromRpc(Map<String, dynamic> data) {
    return DeviceActivationResult(
      success: data['success'] as bool? ?? false,
      activationId: data['activation_id'] as String?,
      devicesRemaining: data['devices_remaining'] as int?,
      error: data['error'] as String?,
    );
  }
}

/// Result of device registration.
class DeviceRegistrationResult {
  final bool success;
  final String? deviceId;
  final String? error;

  const DeviceRegistrationResult({
    required this.success,
    this.deviceId,
    this.error,
  });
}

/// Supabase RPC calls for cloud licensing operations.
///
/// This repository is the ONLY place that calls licensing-related RPCs.
/// All other services go through this class.
class CloudLicensingRepository {
  CloudLicensingRepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;

  SupabaseClient get _client {
    return _injectedClient ?? Supabase.instance.client;
  }

  /// Verify the current licensing entitlement for a shop.
  Future<EntitlementResult> verifyLicenseEntitlement(String shopId) async {
    final response = await _client.rpc(
      'verify_license_entitlement',
      params: {'p_shop_id': shopId},
    );
    return EntitlementResult.fromRpc(
        Map<String, dynamic>.from(response as Map));
  }

  /// Start a 14-day trial for a shop.
  Future<String> startTrial(String shopId) async {
    final response = await _client.rpc(
      'start_trial',
      params: {'p_shop_id': shopId},
    );
    return response as String;
  }

  /// Register a device installation for a shop.
  Future<DeviceRegistrationResult> registerDevice({
    required String shopId,
    required String installationId,
    required String platform,
    String? deviceName,
  }) async {
    try {
      final response = await _client.rpc(
        'register_device',
        params: {
          'p_shop_id': shopId,
          'p_installation_id': installationId,
          'p_platform': platform,
          'p_device_name': deviceName,
        },
      );
      return DeviceRegistrationResult(
        success: true,
        deviceId: response as String?,
      );
    } catch (e) {
      return DeviceRegistrationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Activate a device under the shop license.
  Future<DeviceActivationResult> activateDevice({
    required String shopId,
    required String installationId,
  }) async {
    try {
      final response = await _client.rpc(
        'activate_device',
        params: {
          'p_shop_id': shopId,
          'p_installation_id': installationId,
        },
      );
      return DeviceActivationResult.fromRpc(
          Map<String, dynamic>.from(response as Map));
    } catch (e) {
      return DeviceActivationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Owner deactivates a device activation.
  Future<bool> deactivateDevice(String activationId) async {
    try {
      final response = await _client.rpc(
        'deactivate_device',
        params: {'p_activation_id': activationId},
      );
      return response == true;
    } catch (_) {
      return false;
    }
  }

  /// Get the list of devices for a shop (owner-only).
  Future<List<Map<String, dynamic>>> getDeviceList(String shopId) async {
    final response = await _client.rpc(
      'get_device_list',
      params: {'p_shop_id': shopId},
    );
    return List<Map<String, dynamic>>.from(response as List);
  }
}
