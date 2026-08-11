import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/admin/roles_permissions_screen.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/permissions.dart';
import 'package:muaman_store/services/session_state.dart';

import '../helpers/test_schema.dart';

void main() {
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
  });

  SessionState ownerSession() {
    final session = SessionState(resolver: PermissionResolver());
    session.login(User(
      displayName: 'المالك',
      username: 'owner',
      passwordHash: 'dummy',
      role: UserRole.owner,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return session;
  }

  SessionState employeeSession() {
    final session = SessionState(resolver: PermissionResolver());
    session.login(User(
      displayName: 'موظف',
      username: 'employee',
      passwordHash: 'dummy',
      role: UserRole.employee,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return session;
  }

  Future<void> pumpScreen(WidgetTester tester, SessionState session) async {
    // The permission groups render in a lazy ListView; enlarge the surface so
    // every category (including the admin group) is built without scrolling.
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: RolesPermissionsScreen(sessionState: session)),
    );
    await tester.pumpAndSettle();
  }

  group('RolesPermissionsScreen', () {
    testWidgets('A non-owner is denied access (no bypass)', (tester) async {
      await pumpScreen(tester, employeeSession());

      expect(
        find.text('غير مصرح بالوصول إلى إدارة الصلاحيات'),
        findsOneWidget,
      );
      expect(find.text('حفظ التغييرات'), findsNothing);
      expect(find.text('استعادة الافتراضي'), findsNothing);
    });

    testWidgets('Owner sees the employee switches and reset button by default',
        (tester) async {
      await pumpScreen(tester, ownerSession());

      expect(find.text('موظف'), findsWidgets);
      expect(find.text('مشاهدة المخزون'), findsOneWidget);
      expect(find.text('استعادة الافتراضي'), findsOneWidget);
    });

    testWidgets('Owner role is shown read-only and cannot be edited',
        (tester) async {
      await pumpScreen(tester, ownerSession());

      await tester.tap(find.text('مالك'));
      await tester.pumpAndSettle();

      expect(
        find.text('المالك يتمتع بجميع الصلاحيات دائمًا ولا يمكن تقييده.'),
        findsOneWidget,
      );
      expect(find.text('✓ يُسمح دائمًا'), findsOneWidget);
      expect(find.text('استعادة الافتراضي'), findsNothing);
      expect(find.text('مشاهدة المخزون'), findsNothing);
    });

    testWidgets('Owner-exclusive switches are disabled for non-owner roles',
        (tester) async {
      await pumpScreen(tester, ownerSession());

      final exclusiveTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'إدارة المستخدمين'));
      expect(exclusiveTile.onChanged, isNull);

      final normalTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'مشاهدة المخزون'));
      expect(normalTile.onChanged, isNotNull);
    });

    testWidgets('Saving a change persists to role_permissions and confirms',
        (tester) async {
      await pumpScreen(tester, ownerSession());

      // Toggle OFF the sales history permission for the employee role.
      await tester.tap(find.widgetWithText(SwitchListTile, 'سجل المبيعات'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();

      // Confirmation dialog is shown; confirm with the dialog button.
      expect(find.text('حفظ التغييرات'), findsWidgets);
      await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(find.text('تم حفظ الصلاحيات بنجاح'), findsOneWidget);

      final rows = await testDb.query('role_permissions');
      expect(rows, hasLength(1));
      expect(rows.first['role'], 'employee');
      final stored =
          PermissionCatalog.decodeSet(rows.first['permissions'] as String);
      expect(stored.contains(AppPermission.canViewSalesHistory), false);
      expect(stored.contains(AppPermission.canCreateSales), true);
    });

    testWidgets('An owner-exclusive permission cannot be persisted to a role',
        (tester) async {
      await pumpScreen(tester, ownerSession());

      // canManageUsers is disabled for non-owner roles, so there must be no
      // path to persist it: verify no stored row exists and the switch is off.
      final rows = await testDb.query('role_permissions');
      expect(rows, isEmpty);
      final tile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'إدارة المستخدمين'));
      expect(tile.value, false);
      expect(tile.onChanged, isNull);
    });

    testWidgets('Reset restores built-in defaults', (tester) async {
      await pumpScreen(tester, ownerSession());

      // Persist a reduced configuration first.
      await tester.tap(find.widgetWithText(SwitchListTile, 'سجل المبيعات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
      await tester.pumpAndSettle();

      var rows = await testDb.query('role_permissions');
      expect(rows, hasLength(1));

      // Let the save-success SnackBar expire so the reset SnackBar is not
      // queued behind it.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Reset the employee role to defaults.
      await tester.tap(find.text('استعادة الافتراضي'));
      await tester.pumpAndSettle();
      expect(find.text('استعادة الصلاحيات الافتراضية'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'استعادة'));
      await tester.pumpAndSettle();

      expect(find.text('تم استعادة الصلاحيات الافتراضية'), findsOneWidget);

      rows = await testDb.query('role_permissions',
          where: 'role = ?', whereArgs: ['employee']);
      expect(rows, isEmpty);
    });
  });
}
