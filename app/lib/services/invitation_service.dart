import 'package:flutter/foundation.dart';
import '../services/cloud_auth_service.dart';

/// Information about a single invitation.
@immutable
class InvitationInfo {
  const InvitationInfo({
    required this.id,
    required this.shopId,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.expiresAt,
  });

  final String id;
  final String shopId;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? expiresAt;

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Result of an invitation acceptance attempt.
enum AcceptInvitationResultType {
  success,
  noPendingInvitation,
  networkUnavailable,
  unknownError,
}

class AcceptInvitationResult {
  AcceptInvitationResult._({
    required this.type,
    this.errorMessage,
  });

  factory AcceptInvitationResult.success() =>
      AcceptInvitationResult._(type: AcceptInvitationResultType.success);

  factory AcceptInvitationResult.noPendingInvitation() =>
      AcceptInvitationResult._(
          type: AcceptInvitationResultType.noPendingInvitation);

  factory AcceptInvitationResult.networkUnavailable() =>
      AcceptInvitationResult._(
          type: AcceptInvitationResultType.networkUnavailable);

  factory AcceptInvitationResult.unknownError(String message) =>
      AcceptInvitationResult._(
          type: AcceptInvitationResultType.unknownError, errorMessage: message);

  final AcceptInvitationResultType type;
  final String? errorMessage;

  bool get isSuccess => type == AcceptInvitationResultType.success;
}

/// Handles employee invitation acceptance and listing.
///
/// The actual invitation creation is done server-side by the `invite-employee`
/// Edge Function (which requires the service-role key). This service handles
/// client-side operations: accepting invitations and listing pending ones.
class InvitationService {
  InvitationService({
    CloudAuthService? cloudAuthService,
  }) : _cloudAuth = cloudAuthService ?? CloudAuthService();

  final CloudAuthService _cloudAuth;

  /// Accept a pending invitation for the current user.
  Future<AcceptInvitationResult> acceptInvitation({
    required String shopId,
    required String userId,
  }) async {
    try {
      final success = await _cloudAuth.acceptInvitation(
        shopId: shopId,
        userId: userId,
      );
      if (success) {
        return AcceptInvitationResult.success();
      }
      return AcceptInvitationResult.noPendingInvitation();
    } catch (e) {
      if (_isNetworkError(e)) {
        return AcceptInvitationResult.networkUnavailable();
      }
      return AcceptInvitationResult.unknownError(e.toString());
    }
  }

  /// Get all active shop memberships for the current user.
  ///
  /// This uses `get_user_shops()` which only returns ACTIVE memberships.
  Future<List<Map<String, dynamic>>> getActiveMemberships() async {
    try {
      return await _cloudAuth.getUserShops();
    } catch (e) {
      return [];
    }
  }

  bool _isNetworkError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('connection') ||
        text.contains('network') ||
        text.contains('timeout');
  }
}
