import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/user_repository.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/rbac/effective_permission_model.dart';
import 'package:muaman_store/rbac/permission_cache.dart';
import 'package:muaman_store/screens/auth/accept_invitation_screen.dart';
import 'package:muaman_store/services/invitation_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_schema.dart';

/// Phase L (D-L2/D-L4) — invitation acceptance flow.
///
/// Covers the acceptance result mapping, the local CACHE row provisioning
/// keyed by cloud_uuid exactly as the accept screen performs it, the
/// permission-refresh degrade path after acceptance, and the screen's
/// client-side validation guards (no cloud calls required).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database testDb;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
    DatabaseHelper.resetForTest();
  });

  group('AcceptInvitationResult mapping', () {
    test('success maps to isSuccess', () {
      expect(AcceptInvitationResult.success().isSuccess, isTrue);
    });

    test('no pending invitation maps to failure', () {
      final result = AcceptInvitationResult.noPendingInvitation();
      expect(result.isSuccess, isFalse);
      expect(result.type, AcceptInvitationResultType.noPendingInvitation);
    });

    test('network failure maps to a retryable class', () {
      final result = AcceptInvitationResult.networkUnavailable();
      expect(result.isSuccess, isFalse);
      expect(result.type, AcceptInvitationResultType.networkUnavailable);
    });

    test('unknown error carries its message', () {
      final result = AcceptInvitationResult.unknownError('boom');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'boom');
    });
  });

  group('post-acceptance local provisioning (D-L4)', () {
    test(
        'membership row provisions a cloud_uuid-keyed cache row with '
        'membership-derived role', () async {
      // Mirrors accept_invitation_screen.dart: role comes ONLY from the
      // accepted membership row returned by get_user_shops.
      const membership = <String, dynamic>{
        'shop_id': 'shop-A',
        'membership_role': 'employee',
        'membership_status': 'ACTIVE',
      };
      final repo = UserRepository();
      final user = await repo.upsertCloudUser(
        cloudUuid: 'accepted-user-uuid',
        displayName: 'موظف جديد',
        membershipRole: membership['membership_role']?.toString() ?? 'employee',
      );

      expect(user.role, UserRole.employee);
      expect(user.id, isNotNull);

      final byCloud = await repo.getUserByCloudUuid('accepted-user-uuid');
      expect(byCloud!.id, user.id);
    });

    test('salesOnly invitation maps to the salesOnly local role', () async {
      final repo = UserRepository();
      final user = await repo.upsertCloudUser(
        cloudUuid: 'sales-invitee-uuid',
        displayName: 'بائع',
        membershipRole: 'salesOnly',
      );
      expect(user.role, UserRole.salesOnly);
    });

    test('repeat login after acceptance reuses the SAME row (idempotent)',
        () async {
      final repo = UserRepository();
      final first = await repo.upsertCloudUser(
        cloudUuid: 'repeat-uuid',
        displayName: 'موظف',
        membershipRole: 'employee',
      );
      final second = await repo.upsertCloudUser(
        cloudUuid: 'repeat-uuid',
        displayName: 'موظف',
        membershipRole: 'employee',
      );
      expect(second.id, first.id);
      expect(await testDb.query('users'), hasLength(1));
    });
  });

  group('permission refresh after acceptance', () {
    test(
        'offline cache lookup degrades safely (null, no throw) so the '
        'post-acceptance refresh never blocks landing', () async {
      // This is exactly the path PermissionSyncService.syncPermissions
      // takes for an unconfigured/offline cloud: PermissionCache.load
      // returns null, no snapshot is applied, built-in role defaults
      // govern local UI while the server stays authoritative per RPC.
      final cache = PermissionCache();
      final cached = await cache.load('shop-A');
      expect(cached, isNull);
    });

    test('a cached snapshot round-trips and applies to the resolver', () async {
      final now = DateTime.now();
      final snapshot = CloudPermissionSnapshot(
        shopId: 'shop-A',
        memberRole: 'salesOnly',
        permissionIds: {'sales.view', 'sales.create'},
        overrides: const [],
        catalogVersion: 1,
        serverTime: now.toUtc(),
        permissionsUpdatedAt: now.toUtc(),
        cachedAt: now,
      );
      final cache = PermissionCache();
      await cache.save(snapshot);

      final loaded = await cache.load('shop-A');
      expect(loaded, isNotNull);
      expect(loaded!.permissionIds, {'sales.view', 'sales.create'});
    });
  });

  group('acceptance screen validation guards (no cloud touched)', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester
          .pumpWidget(const MaterialApp(home: AcceptInvitationScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('empty email shows validation error and stays on screen',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
      expect(find.byType(AcceptInvitationScreen), findsOneWidget);
    });

    testWidgets('short password shows validation error', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
          find.byType(TextField).first, 'seller@example.com');
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(2), '123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
          findsOneWidget);
    });

    testWidgets('mismatched confirmation shows validation error',
        (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
          find.byType(TextField).first, 'seller@example.com');
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(2), 'secret123');
      await tester.enterText(passwordFields.at(3), 'other123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('كلمة المرور وتأكيدها غير متطابقين'), findsOneWidget);
    });
  });
}
