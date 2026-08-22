import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:muaman_store/services/app_settings.dart';
import 'package:muaman_store/services/cloud_session_resume.dart';
import 'package:muaman_store/services/shop_resolver.dart';
import 'package:muaman_store/services/tenant_isolation_gate.dart';

/// Phase K (D4) — cold-start cloud-session resume binding.
///
/// Proves that a restored session re-binds ActiveShopContext, arms
/// TenantIsolationGate and refreshes permissions BEFORE any tenant data
/// renders, with strict fail-closed behavior on missing/foreign shops.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('muaman_resume_test');
    final db = await databaseFactoryFfiNoIsolate.openDatabase(p.join(
        tempDir.path, 'resume_${DateTime.now().microsecondsSinceEpoch}.db'));
    DatabaseHelper.setTestDatabase(db);
    await DatabaseHelper.runCreateDbForTest(
        await DatabaseHelper.instance.database);
    DatabaseHelper.setTenantIsolationArmed(false);
    ActiveShopContext.instance.resetForTest();
    ActiveShopContext.instance.configure(
      membershipValidator: (shopId) async => shopId == 'shop-A',
    );
    await AppSettings.setValue(TenantIsolationGate.armedMarkerKey, '');
  });

  tearDown(() {
    DatabaseHelper.resetForTest();
    DatabaseHelper.setTenantIsolationArmed(false);
    ActiveShopContext.instance.resetForTest();
  });

  ShopMembership member(String id, {String status = 'ACTIVE'}) =>
      ShopMembership(
          shopId: id,
          shopName: 'متجر $id',
          membershipRole: 'owner',
          membershipStatus: status);

  test('valid restored session binds shop, arms gate, syncs permissions',
      () async {
    // Fresh install with nothing to attribute: gate arms freely once the
    // persistence marker is present.
    await AppSettings.setValue(TenantIsolationGate.armedMarkerKey, 'true');

    final licensingShops = <String>[];
    final syncedShops = <String>[];

    final bound = await resumeCloudSessionAtStartup(
      resolveActiveShop: () async => member('shop-A'),
      licensingSteps: (shopId) async => licensingShops.add(shopId),
      syncPermissions: (shopId) async => syncedShops.add(shopId),
    );

    expect(bound, 'shop-A');
    expect(ActiveShopContext.instance.isBound, isTrue);
    expect(ActiveShopContext.instance.shopId, 'shop-A');
    expect(licensingShops, ['shop-A']);
    expect(syncedShops, ['shop-A']);
    expect(DatabaseHelper.tenantIsolationArmed, isTrue,
        reason: 'TenantIsolationGate must be armed after cold-start resume');
  });

  test('gate stays disarmed when arming marker absent (conservative default)',
      () async {
    final bound = await resumeCloudSessionAtStartup(
      resolveActiveShop: () async => member('shop-A'),
      licensingSteps: (_) async {},
      syncPermissions: (_) async {},
    );

    expect(bound, 'shop-A');
    expect(ActiveShopContext.instance.isBound, isTrue);
    expect(DatabaseHelper.tenantIsolationArmed, isFalse,
        reason: 'restoreAtStartup must never half-arm without its marker');
  });

  test('resolver failure binds NOTHING (fail-closed)', () async {
    final bound = await resumeCloudSessionAtStartup(
      resolveActiveShop: () async => throw StateError('no memberships'),
      licensingSteps: (_) async {},
      syncPermissions: (_) async {},
    );

    expect(bound, isNull);
    expect(ActiveShopContext.instance.isBound, isFalse);
  });

  test('foreign/unauthorized shop is rejected by membership validator',
      () async {
    final bound = await resumeCloudSessionAtStartup(
      resolveActiveShop: () async => member('shop-FOREIGN'),
      licensingSteps: (_) async {
        fail('licensing must never run for an unauthorized shop');
      },
      syncPermissions: (_) async {
        fail('permission sync must never run for an unauthorized shop');
      },
    );

    expect(bound, isNull);
    expect(ActiveShopContext.instance.isBound, isFalse,
        reason: 'cross-tenant context must never bind');
  });

  test('unvalidated shop context (configure missing) binds NOTHING', () async {
    ActiveShopContext.instance.resetForTest();
    final bound = await resumeCloudSessionAtStartup(
      resolveActiveShop: () async => member('shop-A'),
      licensingSteps: (_) async {},
      syncPermissions: (_) async {},
    );

    expect(bound, isNull);
    expect(ActiveShopContext.instance.isBound, isFalse);
  });
}
