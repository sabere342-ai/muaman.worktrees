import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/services/active_shop_context.dart';

void main() {
  late ActiveShopContext context;

  setUp(() {
    context = ActiveShopContext.instance;
    context.resetForTest();
    context.configure(membershipValidator: (_) async => true);
  });

  tearDown(() {
    context.resetForTest();
  });

  group('J-WS1-T01..T07: ActiveShopContext contract', () {
    test('bind succeeds with an authorized membership and notifies', () async {
      var notified = 0;
      context.addListener(() => notified++);

      expect(context.isBound, isFalse);
      await context.bind('shop-a');

      expect(context.isBound, isTrue);
      expect(context.shopId, 'shop-a');
      expect(notified, 1);
    });

    test('bind rejects a foreign/stale shop and stays unbound', () async {
      context.configure(membershipValidator: (_) async => false);

      await expectLater(
        context.bind('shop-b'),
        throwsA(isA<TenantContextException>()),
      );
      expect(context.isBound, isFalse,
          reason: 'failed validation must never bind a tenant');
    });

    test('bind fails closed when the validator was never configured', () async {
      context.resetForTest();

      await expectLater(
        context.bind('shop-a'),
        throwsA(isA<TenantContextException>()),
      );
    });

    test('bind rejects empty/blank shop ids before consulting memberships',
        () async {
      var consulted = false;
      context.configure(
        membershipValidator: (_) async {
          consulted = true;
          return true;
        },
      );

      await expectLater(
        context.bind('   '),
        throwsA(isA<TenantContextException>()),
      );
      expect(consulted, isFalse);
    });

    test('switchShop validates the NEW shop before releasing the OLD one',
        () async {
      await context.bind('shop-a');

      // Invalid switch leaves the current binding untouched.
      context.configure(membershipValidator: (_) async => false);
      await expectLater(
        context.switchShop('shop-x'),
        throwsA(isA<TenantContextException>()),
      );
      expect(context.shopId, 'shop-a');

      // Valid switch moves atomically.
      context.configure(membershipValidator: (_) async => true);
      await context.switchShop('shop-b');
      expect(context.shopId, 'shop-b');
    });

    test('rebinding the same shop does not re-notify', () async {
      await context.bind('shop-a');
      var notified = 0;
      context.addListener(() => notified++);
      await context.bind('shop-a');
      expect(notified, 0);
    });

    test('unbind clears the context and notifies listeners', () async {
      await context.bind('shop-a');
      var notified = 0;
      context.addListener(() => notified++);

      context.unbind();
      expect(context.isBound, isFalse);
      expect(context.shopId, isNull);
      expect(notified, 1);

      // Unbinding again is a no-op.
      context.unbind();
      expect(notified, 1);
    });
  });
}
