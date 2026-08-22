import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/services/active_shop_context.dart';

/// Shared fixture wiring for the Phase J tenant-isolation suite: binds a
/// permissive test context so data-layer scoping can be exercised without
/// cloud infrastructure.
Future<void> bindTestShop(String shopId) async {
  final context = ActiveShopContext.instance;
  context.resetForTest();
  context.configure(membershipValidator: (_) async => true);
  await context.bind(shopId);
}

void resetTestContext() {
  ActiveShopContext.instance.resetForTest();
}
