import 'package:flutter/foundation.dart';

/// Central business identity of the shop.
///
/// This is the single source of truth for the identity that is rendered in
/// user-visible places (app title, login screen, dashboard header) and edited
/// from Settings. The value of [shopName] must come from this profile, never
/// from scattered constants.
@immutable
class ShopProfile {
  const ShopProfile({
    required this.shopName,
    this.ownerOrManagerName = '',
    this.phone = '',
    this.address = '',
    this.logoPath = '',
    this.cloudUuid,
  });

  /// Migration default. This is the ONLY production place that defines the
  /// identity of the current client. It preserves the existing experience on
  /// first launch after upgrade and can be changed by an authorized user from
  /// Settings without touching source code.
  static const String defaultShopName = 'المحل';

  /// Neutral fallback shown by consumers when [shopName] is blank.
  static const String neutralShopName = 'المتجر';

  final String shopName;
  final String ownerOrManagerName;
  final String phone;
  final String address;

  /// Path to a managed copy of the shop logo stored next to the application
  /// database. Empty when no logo has been set.
  final String logoPath;

  /// Cloud UUID for multi-tenant identity mapping. Null until the shop is
  /// linked to a cloud identity (Phase C+).
  final String? cloudUuid;

  bool get hasLogo => logoPath.isNotEmpty;

  static ShopProfile defaultProfile() =>
      const ShopProfile(shopName: defaultShopName);

  ShopProfile copyWith({
    String? shopName,
    String? ownerOrManagerName,
    String? phone,
    String? address,
    String? logoPath,
    String? cloudUuid,
  }) {
    return ShopProfile(
      shopName: shopName ?? this.shopName,
      ownerOrManagerName: ownerOrManagerName ?? this.ownerOrManagerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
      cloudUuid: cloudUuid ?? this.cloudUuid,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShopProfile) return false;
    return shopName == other.shopName &&
        ownerOrManagerName == other.ownerOrManagerName &&
        phone == other.phone &&
        address == other.address &&
        logoPath == other.logoPath &&
        cloudUuid == other.cloudUuid;
  }

  @override
  int get hashCode => Object.hash(
      shopName, ownerOrManagerName, phone, address, logoPath, cloudUuid);

  @override
  String toString() =>
      'ShopProfile(shopName: $shopName, ownerOrManagerName: $ownerOrManagerName, '
      'phone: $phone, address: $address, logoPath: $logoPath, '
      'cloudUuid: $cloudUuid)';
}
