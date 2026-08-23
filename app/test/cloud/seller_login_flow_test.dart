import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:muaman_store/services/seller_session_provisioning.dart';
import 'package:muaman_store/services/shop_resolver.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

/// Phase L â€” seller cloud-login provisioning matrix (D-L1/D-L3/D-L4).
///
/// Proves the canonical sequence sign-in -> ACTIVE membership -> bind ->
/// arm -> license -> permission sync -> local cache row, with strict
/// fail-closed behavior on invalid credentials, zero/revoked memberships,
/// foreign shops, offline sign-in and ownership-hijack attempts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUp(() async {
    final tempDir =
        await Directory.systemTemp.createTemp('muaman_seller_login_test');
    final db = await databaseFactoryFfiNoIsolate.openDatabase(p.join(
        tempDir.path, 'seller_${DateTime.now().microsecondsSinceEpoch}.db'));
    DatabaseHelper.setTestDatabase(db);
    await DatabaseHelper.runCreateDbForTest(
        await DatabaseHelper.instance.database);
    DatabaseHelper.setTenantIsolationArmed(false);
    ActiveShopContext.instance.resetForTest();
    ActiveShopContext.instance.configure(
      membershipValidator: (shopId) async => shopId == 'shop-A',
    );
  });

  tearDown(() {
    DatabaseHelper.resetForTest();
    DatabaseHelper.setTenantIsolationArmed(false);
    ActiveShopContext.instance.resetForTest();
  });

  ShopMembership member(String id,
          {String role = 'employee', String status = 'ACTIVE'}) =>
      ShopMembership(
          shopId: id,
          shopName: 'Ù…ØªØ¬Ø± $id',
          membershipRole: role,
          membershipStatus: status);

  User fakeUser(UserRole role) => User(
        id: 7,
        displayName: 'Ø§Ù„Ø¨Ø§Ø¦Ø¹',
        username: 'cloud.x',
        passwordHash: 'x',
        role: role,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  /// Recording harness for every injectable provisioning step.
  ({List<String> log, List<Map<String, dynamic>> upserts}) recorder() {
    final log = <String>[];
    final upserts = <Map<String, dynamic>>[];
    return (
      log: log,
      upserts: upserts,
    );
  }

  Future<SellerSessionResult> runProvisioning({
    required List<String> log,
    required List<Map<String, dynamic>> upserts,
    SellerSignInStep? signIn,
    SellerMembershipsStep? getMemberships,
    SellerResolveShopStep? resolveActiveShop,
    SellerBindStep? bindShop,
    SellerArmGateStep? armTenantIsolationGate,
    SellerLicensingStep? licensingSteps,
    SellerPermissionSyncStep? syncPermissions,
  }) =>
      provisionSellerSession(
        email: 'seller@example.com',
        password: 'secret123',
        signIn: signIn ??
            (_, __) {
              log.add('signIn');
              return Future.value(const SellerSignInOutcome(
                  userId: 'cloud-uid-1', displayName: 'Ø§Ù„Ø¨Ø§Ø¦Ø¹'));
            },
        getMemberships: getMemberships ??
            () {
              log.add('memberships');
              return Future.value([member('shop-A')]);
            },
        resolveActiveShop: resolveActiveShop ??
            () {
              log.add('resolve');
              return Future.value(member('shop-A'));
            },
        bindShop: bindShop ??
            (shopId) {
              log.add('bind:$shopId');
              return Future.value();
            },
        armTenantIsolationGate: armTenantIsolationGate ??
            (shopId) {
              log.add('arm:$shopId');
              return Future.value();
            },
        licensingSteps: licensingSteps ??
            (shopId) {
              log.add('license:$shopId');
              return Future.value();
            },
        syncPermissions: syncPermissions ??
            (shopId) {
              log.add('perms:$shopId');
              return Future.value();
            },
        upsertLocalCloudUser: (
            {required cloudUuid, displayName, required membershipRole}) {
          log.add('upsert');
          upserts.add(
              {'uuid': cloudUuid, 'name': displayName, 'role': membershipRole});
          return Future.value(fakeUser(membershipRole == 'salesOnly'
              ? UserRole.salesOnly
              : UserRole.employee));
        },
      );

  test('success: canonical sequence runs in order against the ACTIVE shop',
      () async {
    final rec = recorder();
    final result = await runProvisioning(log: rec.log, upserts: rec.upserts);

    expect(result.isSuccess, isTrue);
    expect(result.cloudUserId, 'cloud-uid-1');
    expect(result.membership!.shopId, 'shop-A');
    expect(result.user!.role, UserRole.employee);

    // Exact sequence, exactly once each, targeting only shop-A.
    expect(rec.log, [
      'signIn',
      'memberships',
      'resolve',
      'bind:shop-A',
      'arm:shop-A',
      'license:shop-A',
      'perms:shop-A',
      'upsert',
    ]);

    // D-L4: cache row keyed by cloud_uuid with membership-derived role.
    expect(rec.upserts.single['uuid'], 'cloud-uid-1');
    expect(rec.upserts.single['role'], 'employee');
    expect(rec.upserts.single['name'], 'Ø§Ù„Ø¨Ø§Ø¦Ø¹');
  });

  test('invalid credentials fail BEFORE any binding or provisioning', () async {
    final rec = recorder();
    final result = await runProvisioning(
      log: rec.log,
      upserts: rec.upserts,
      signIn: (_, __) {
        rec.log.add('signIn');
        throw const SellerSignInFailure(SellerSessionStatus.invalidCredentials);
      },
    );

    expect(result.status, SellerSessionStatus.invalidCredentials);
    expect(rec.log, ['signIn']);
    expect(ActiveShopContext.instance.isBound, isFalse);
  });

  test('offline sign-in maps to networkUnavailable and touches NOTHING else',
      () async {
    final rec = recorder();
    final result = await runProvisioning(
      log: rec.log,
      upserts: rec.upserts,
      signIn: (_, __) {
        rec.log.add('signIn');
        throw const SellerSignInFailure(SellerSessionStatus.networkUnavailable);
      },
    );

    expect(result.status, SellerSessionStatus.networkUnavailable);
    expect(rec.log, ['signIn']);
    expect(ActiveShopContext.instance.isBound, isFalse);
  });

  test('zero memberships fail closed: no bind, no arm, no provisioning',
      () async {
    final rec = recorder();
    final result = await runProvisioning(
      log: rec.log,
      upserts: rec.upserts,
      getMemberships: () {
        rec.log.add('memberships');
        return Future.value(<ShopMembership>[]);
      },
    );

    expect(result.status, SellerSessionStatus.noActiveMembership);
    expect(rec.log, ['signIn', 'memberships']);
    expect(ActiveShopContext.instance.isBound, isFalse);
  });

  test('REVOKED-only membership fails closed', () async {
    final rec = recorder();
    final result = await runProvisioning(
      log: rec.log,
      upserts: rec.upserts,
      getMemberships: () {
        rec.log.add('memberships');
        return Future.value([
          member('shop-A', status: 'REVOKED'),
          member('shop-B', role: 'employee', status: 'SUSPENDED'),
        ]);
      },
    );

    expect(result.status, SellerSessionStatus.noActiveMembership);
    expect(ActiveShopContext.instance.isBound, isFalse);
  });

  test(
      'owner-role membership is REJECTED before any mutation (D-L3 hijack '
      'prevention)', () async {
    final rec = recorder();
    final result = await runProvisioning(
      log: rec.log,
      upserts: rec.upserts,
      resolveActiveShop: () {
        rec.log.add('resolve');
        return Future.value(member('shop-A', role: 'owner'));
      },
    );

    expect(result.status, SellerSessionStatus.ownerRejected);
    expect(rec.log, ['signIn', 'memberships', 'resolve']);
    expect(rec.upserts, isEmpty);
    expect(ActiveShopContext.instance.isBound, isFalse);
  });

  test('foreign-shop bind rejection fails closed with nothing provisioned',
      () async {
    final rec = recorder();
    var licensed = false;
    final result = await runProvisioning(
      log: rec.log,
      upserts: rec.upserts,
      resolveActiveShop: () {
        rec.log.add('resolve');
        return Future.value(member('shop-FOREIGN'));
      },
      bindShop: (_) async {
        // Mirror the real validator behavior for an unauthorized shop.
        throw StateError('membership validator rejected the shop');
      },
      licensingSteps: (_) async {
        licensed = true;
      },
    );

    expect(result.status, SellerSessionStatus.bindRejected);
    expect(licensed, isFalse,
        reason: 'licensing must never run for an unauthorized shop');
    expect(rec.upserts, isEmpty);
  });

  test(
      'non-ACTIVE resolved membership fails closed even if resolver returns it',
      () async {
    final rec = recorder();
    final result = await runProvisioning(
      log: rec.log,
      upserts: rec.upserts,
      getMemberships: () {
        rec.log.add('memberships');
        return Future.value([member('shop-A')]);
      },
      resolveActiveShop: () =>
          Future.value(member('shop-A', status: 'SUSPENDED')),
    );

    expect(result.status, SellerSessionStatus.noActiveMembership);
    expect(ActiveShopContext.instance.isBound, isFalse);
  });
}
