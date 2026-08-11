import 'package:flutter_test/flutter_test.dart';

import 'package:muaman_store/models/shop_profile.dart';

void main() {
  group('ShopProfile model', () {
    test('defaultProfile uses the safe migration default identity', () {
      final profile = ShopProfile.defaultProfile();
      expect(profile.shopName, 'محل مؤمن');
      expect(profile.ownerOrManagerName, '');
      expect(profile.phone, '');
      expect(profile.address, '');
      expect(profile.logoPath, '');
      expect(profile.hasLogo, false);
    });

    test('copyWith updates only the provided fields', () {
      const base = ShopProfile(shopName: 'محل أ', phone: '0111');
      final updated = base.copyWith(shopName: 'محل ب', address: 'شارع 1');
      expect(updated.shopName, 'محل ب');
      expect(updated.phone, '0111');
      expect(updated.address, 'شارع 1');
      expect(updated.ownerOrManagerName, '');
      expect(base.shopName, 'محل أ');
    });

    test('value equality compares every identity field', () {
      const a = ShopProfile(shopName: 'محل أ', phone: '1', logoPath: 'x');
      const b = ShopProfile(shopName: 'محل أ', phone: '1', logoPath: 'x');
      const c = ShopProfile(shopName: 'محل ج');
      expect(a, b);
      expect(a == c, false);
      expect(a.hashCode, b.hashCode);
    });

    test('hasLogo reflects a set logo path', () {
      const withLogo = ShopProfile(shopName: 'محل أ', logoPath: 'logo.png');
      const without = ShopProfile(shopName: 'محل أ');
      expect(withLogo.hasLogo, true);
      expect(without.hasLogo, false);
    });

    test('neutralShopName is used as a generic fallback, not the client name',
        () {
      expect(ShopProfile.neutralShopName, 'المتجر');
      expect(ShopProfile.defaultShopName, 'محل مؤمن');
    });
  });
}
