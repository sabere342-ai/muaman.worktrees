import 'package:flutter/foundation.dart';

/// In-memory representation of an active cloud session.
///
/// A [CloudSession] is created after a successful Supabase Auth sign-in and
/// carries the cloud user identity, active shop, and membership information.
/// It does NOT persist tokens — the Supabase SDK handles token persistence
/// and refresh internally.
@immutable
class CloudSession {
  const CloudSession({
    required this.userId,
    required this.activeShopId,
    required this.membershipRole,
    required this.membershipStatus,
  });

  /// The Supabase `auth.uid()` for the authenticated cloud user.
  final String userId;

  /// The currently selected shop UUID (from `get_user_shops()`).
  final String activeShopId;

  /// The membership role for the active shop (owner, employee, salesOnly).
  final String membershipRole;

  /// The membership status (ACTIVE, SUSPENDED, REVOKED).
  final String membershipStatus;

  bool get isActive => membershipStatus == 'ACTIVE';
  bool get isOwner => membershipRole == 'owner';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CloudSession &&
        other.userId == userId &&
        other.activeShopId == activeShopId &&
        other.membershipRole == membershipRole &&
        other.membershipStatus == membershipStatus;
  }

  @override
  int get hashCode =>
      Object.hash(userId, activeShopId, membershipRole, membershipStatus);

  @override
  String toString() => 'CloudSession(userId: $userId, shop: $activeShopId, '
      'role: $membershipRole, status: $membershipStatus)';
}
