import 'package:flutter/foundation.dart';
import '../services/app_settings.dart';
import 'cloud_auth_service.dart';

/// Information about a single shop membership.
@immutable
class ShopMembership {
  const ShopMembership({
    required this.shopId,
    required this.shopName,
    required this.membershipRole,
    required this.membershipStatus,
  });

  final String shopId;
  final String shopName;
  final String membershipRole;
  final String membershipStatus;

  bool get isActive => membershipStatus == 'ACTIVE';
  bool get isOwner => membershipRole == 'owner';
}

/// Resolves the active shop for the current user from cloud membership data.
///
/// Algorithm (per plan Section 19):
/// 1. Fetch all active memberships via `get_user_shops()` RPC.
/// 2. If 0 shops → throw (no shop memberships).
/// 3. If 1 shop → auto-select.
/// 4. If 2+ shops → check last-used preference, fall back to selector.
class ShopResolver {
  ShopResolver({
    CloudAuthService? cloudAuthService,
  }) : _cloudAuth = cloudAuthService ?? CloudAuthService();

  final CloudAuthService _cloudAuth;

  static const String _keyLastShopId = 'cloud.lastShopId';

  /// Resolve the active shop for the current session.
  ///
  /// Returns the [ShopMembership] for the resolved shop.
  /// Throws [StateError] if no shop memberships exist.
  Future<ShopMembership> resolveActiveShop() async {
    final shops = await _cloudAuth.getUserShops();

    if (shops.isEmpty) {
      throw StateError('لا توجد متاجر مرتبطة بهذا الحساب');
    }

    if (shops.length == 1) {
      final membership = _parseMembership(shops.first);
      await _saveLastShopId(membership.shopId);
      return membership;
    }

    // Multiple shops — check last-used preference
    final lastShopId = await AppSettings.getValue(_keyLastShopId);
    if (lastShopId.isNotEmpty) {
      final match = shops.where(
        (s) => s['shop_id'].toString() == lastShopId,
      );
      if (match.isNotEmpty) {
        return _parseMembership(match.first);
      }
    }

    // No valid last-used — return first active shop
    final firstActive = shops.firstWhere(
      (s) => s['membership_status'] == 'ACTIVE',
      orElse: () => shops.first,
    );
    final membership = _parseMembership(firstActive);
    await _saveLastShopId(membership.shopId);
    return membership;
  }

  /// Persist the user's shop selection as a local preference.
  Future<void> selectShop(String shopId) async {
    await _saveLastShopId(shopId);
  }

  /// Get all memberships for the current user.
  Future<List<ShopMembership>> getAllMemberships() async {
    final shops = await _cloudAuth.getUserShops();
    return shops.map(_parseMembership).toList();
  }

  Future<void> _saveLastShopId(String shopId) async {
    await AppSettings.setValue(_keyLastShopId, shopId);
  }

  ShopMembership _parseMembership(Map<String, dynamic> data) {
    return ShopMembership(
      shopId: data['shop_id'].toString(),
      shopName: (data['shop_name'] as String?) ?? 'متجر',
      membershipRole: (data['membership_role'] as String?) ?? 'employee',
      membershipStatus: (data['membership_status'] as String?) ?? 'ACTIVE',
    );
  }
}
