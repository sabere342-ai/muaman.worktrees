import 'package:flutter/foundation.dart';

/// The authoritative, server-derived device lifecycle used by S7 (S4/S6 model).
///
/// These are EXACTLY the committed canonical states (governance G.3):
/// `PENDING_APPROVAL`, `ACTIVE`, `REJECTED`, `REVOKED`, `LOST`. S7 MUST NOT
/// introduce or display invented states (e.g. PENDING/APPROVED/DISABLED).
@immutable
enum DeviceTrustStatus {
  pendingApproval,
  active,
  rejected,
  revoked,
  lost;

  /// Canonical server string for this state.
  String get serverValue {
    switch (this) {
      case DeviceTrustStatus.pendingApproval:
        return 'PENDING_APPROVAL';
      case DeviceTrustStatus.active:
        return 'ACTIVE';
      case DeviceTrustStatus.rejected:
        return 'REJECTED';
      case DeviceTrustStatus.revoked:
        return 'REVOKED';
      case DeviceTrustStatus.lost:
        return 'LOST';
    }
  }

  /// Arabic presentational label for the Owner-facing UI.
  String get labelAr {
    switch (this) {
      case DeviceTrustStatus.pendingApproval:
        return 'قيد الموافقة';
      case DeviceTrustStatus.active:
        return 'نشط (موثوق)';
      case DeviceTrustStatus.rejected:
        return 'مرفوض';
      case DeviceTrustStatus.revoked:
        return 'ملغى';
      case DeviceTrustStatus.lost:
        return 'مفقود';
    }
  }

  bool get isTerminal {
    switch (this) {
      case DeviceTrustStatus.pendingApproval:
      case DeviceTrustStatus.active:
        return false;
      case DeviceTrustStatus.rejected:
      case DeviceTrustStatus.revoked:
      case DeviceTrustStatus.lost:
        return true;
    }
  }

  /// Parses a server lifecycle value. Returns `null` for unknown values so the
  /// UI can FAIL CLOSED rather than infer a state (never assume ACTIVE from a
  /// missing/null status).
  static DeviceTrustStatus? fromServer(String? value) {
    if (value == null) return null;
    for (final status in DeviceTrustStatus.values) {
      if (status.serverValue == value) return status;
    }
    return null;
  }
}

/// A typed, server-authoritative device as returned by `s4_list_devices`.
///
/// Maps the exact `s4_list_devices` output columns:
/// `device_id, installation_id, platform, device_name, user_id, status,
/// public_key, approved_at, revoked_at, first_seen_at, last_seen_at`.
@immutable
class CloudDevice {
  const CloudDevice({
    required this.deviceId,
    required this.installationId,
    required this.platform,
    required this.deviceName,
    required this.userId,
    required this.status,
    this.publicKey,
    this.approvedAt,
    this.revokedAt,
    this.firstSeenAt,
    this.lastSeenAt,
  });

  final String deviceId;
  final String installationId;
  final String? platform;
  final String? deviceName;

  /// The last user associated with the device (`devices.user_id`). May be
  /// needed internally for tenant/member presentation; never a raw secret.
  final String? userId;

  /// The authoritative lifecycle state. Fail-closed resolution lives here.
  final DeviceTrustStatus status;

  /// The S6 Ed25519 public-key identity (public metadata only). Never a
  /// private key or seed.
  final String? publicKey;

  final DateTime? approvedAt;
  final DateTime? revokedAt;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;

  factory CloudDevice.fromRpc(Map<String, dynamic> data) {
    final status = DeviceTrustStatus.fromServer(data['status'] as String?);
    if (status == null) {
      throw const FormatException('Unknown device lifecycle status');
    }
    return CloudDevice(
      deviceId: data['device_id'].toString(),
      installationId: data['installation_id'].toString(),
      platform: data['platform'] as String?,
      deviceName: data['device_name'] as String?,
      userId: data['user_id']?.toString(),
      status: status,
      publicKey: data['public_key'] as String?,
      approvedAt: _parseNullableTime(data['approved_at']),
      revokedAt: _parseNullableTime(data['revoked_at']),
      firstSeenAt: _parseNullableTime(data['first_seen_at']),
      lastSeenAt: _parseNullableTime(data['last_seen_at']),
    );
  }

  static DateTime? _parseNullableTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value.toString());
  }
}
