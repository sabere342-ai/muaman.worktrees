import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/services/app_settings.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:muaman_store/services/tenant_isolation_gate.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixture.dart';

/// J-WS6 arming-gate matrix (plan §N): no path may arm strict filtering over
/// unattributed migrated data. Completed migration + full attribution arms;
/// partial migration, foreign-attributed migrated rows, or an unmigrated
/// legacy database all block. Restore semantics (§P) clear the marker.
void main() {
  sqfliteFfiInit();

  late Database testDb;
  final gate = TenantIsolationGate();

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.runCreateDbForTest(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
    await bindTestShop('shop-a');
  });

  tearDown(() async {
    resetTestContext();
    DatabaseHelper.setTenantIsolationArmed(false);
    DatabaseHelper.resetForTest();
    await testDb.close();
  });

  Future<void> seedProduct({String? shopId, String? cloudUuid}) =>
      testDb.insert('products', {
        'name': 'صنف',
        'barcode':
            'BC-${cloudUuid ?? shopId ?? 'x'}-${testDb.hashCode.abs() % 99999}',
        'costPrice': 5.0,
        if (shopId != null) 'shop_id': shopId,
        if (cloudUuid != null) 'cloud_uuid': cloudUuid,
      });

  Future<void> completeMigration(String shopId) async {
    await testDb.insert('legacy_migration_progress', {
      'batch_id': 'batch-$shopId',
      'shop_id': shopId,
      'phase': 'DONE',
      'status': 'COMPLETED',
      'started_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  test('J-G01: fresh install (no rows, no history) can arm', () async {
    final report = await gate.evaluate(db: testDb, shopId: 'shop-a');
    expect(report.canArm, isTrue, reason: report.blockers.join('; '));
    expect(report.totalInvisibleMigrated, 0);
    expect(report.totalResidualUnattributed, 0);
  });

  test('J-G02: unmigrated legacy data blocks arming', () async {
    // Local-only legacy rows with no completed migration pass.
    await seedProduct(shopId: null, cloudUuid: null);
    final report = await gate.evaluate(db: testDb, shopId: 'shop-a');
    expect(report.canArm, isFalse);
    expect(report.blockers.join(), contains('غير منسوب'));
    expect(DatabaseHelper.tenantIsolationArmed, isFalse);
  });

  test('J-G03: partial (non-terminal) migration blocks arming', () async {
    await testDb.insert('legacy_migration_progress', {
      'batch_id': 'batch-running',
      'shop_id': 'shop-a',
      'phase': 'COPY',
      'status': 'RUNNING',
      'started_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    final report = await gate.evaluate(db: testDb, shopId: 'shop-a');
    expect(report.canArm, isFalse);
    expect(report.blockers.join(), contains('غير مكتمل'));
  });

  test('J-G04: completed migration with fully attributed data arms', () async {
    await completeMigration('shop-a');
    await seedProduct(shopId: 'shop-a', cloudUuid: 'uuid-1');
    // Residual unattributed leftovers are allowed once adoption ran — but
    // they are counted in the arming report and never silently discarded.
    await seedProduct(shopId: null, cloudUuid: null);

    final report = await gate.arm(db: testDb, shopId: 'shop-a');
    expect(report.canArm, isTrue, reason: report.blockers.join('; '));
    expect(report.totalResidualUnattributed, greaterThan(0),
        reason: 'residual NULL-shop rows must be surfaced, never hidden');
    expect(DatabaseHelper.tenantIsolationArmed, isTrue);
    expect(
        await AppSettings.getValue(TenantIsolationGate.armedMarkerKey), 'true');
  });

  test('J-G05: invisible migrated rows block arming even after completion',
      () async {
    await completeMigration('shop-a');
    // A migrated row attributed to ANOTHER shop would vanish for shop-a.
    await seedProduct(shopId: 'shop-b', cloudUuid: 'uuid-foreign');

    final report = await gate.arm(db: testDb, shopId: 'shop-a');
    expect(report.canArm, isFalse);
    expect(report.blockers.join(), contains('غير مرئي'));
    expect(DatabaseHelper.tenantIsolationArmed, isFalse);
  });

  test('J-G06: disarm clears both the runtime flag and the marker', () async {
    await completeMigration('shop-a');
    await gate.arm(db: testDb, shopId: 'shop-a');
    expect(DatabaseHelper.tenantIsolationArmed, isTrue);

    await gate.disarm();
    expect(DatabaseHelper.tenantIsolationArmed, isFalse);
    expect(await AppSettings.getValue(TenantIsolationGate.armedMarkerKey),
        'false');
  });

  test('J-G07: restoreAtStartup re-arms only when preconditions still hold',
      () async {
    await completeMigration('shop-a');
    await seedProduct(shopId: 'shop-a', cloudUuid: 'uuid-ok');
    await AppSettings.setValue(TenantIsolationGate.armedMarkerKey, 'true');

    final armed = await gate.restoreAtStartup(
        db: testDb, shopId: ActiveShopContext.instance.shopId);
    expect(armed, isTrue);
    expect(DatabaseHelper.tenantIsolationArmed, isTrue);
  });

  test('J-G08: restoreAtStartup stays unarmed when the DB regressed', () async {
    // Post-restore state (plan §P): the marker may still say 'true', but the
    // restored database holds unattributed rows and NO completed migration
    // pass — arming must stay off until migration/attribution re-runs.
    await AppSettings.setValue(TenantIsolationGate.armedMarkerKey, 'true');
    await seedProduct(shopId: null, cloudUuid: null);

    final armed = await gate.restoreAtStartup(
        db: testDb, shopId: ActiveShopContext.instance.shopId);
    expect(armed, isFalse,
        reason: 'never half-arm over unattributed data (plan §P)');
    expect(DatabaseHelper.tenantIsolationArmed, isFalse);
  });

  test('J-G09: restoreAtStartup without a bound shop stays disarmed', () async {
    await AppSettings.setValue(TenantIsolationGate.armedMarkerKey, 'true');
    final armed = await gate.restoreAtStartup(db: testDb, shopId: null);
    expect(armed, isFalse);
    expect(DatabaseHelper.tenantIsolationArmed, isFalse);
  });
}
