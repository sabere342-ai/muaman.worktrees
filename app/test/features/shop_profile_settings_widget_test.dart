import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/settings_screen.dart';
import 'package:muaman_store/services/app_settings.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/session_state.dart';
import 'package:muaman_store/services/shop_profile_service.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late SessionState ownerSession;
  late SessionState salesOnlySession;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
    ShopProfileService.instance.invalidate();
    PermissionResolver.instance.invalidate();

    ownerSession = SessionState()
      ..login(User(
        id: 1,
        displayName: 'المالك',
        username: 'owner',
        passwordHash: 'x',
        role: UserRole.owner,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    salesOnlySession = SessionState()
      ..login(User(
        id: 2,
        displayName: 'موظف',
        username: 'sales',
        passwordHash: 'x',
        role: UserRole.salesOnly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
  });

  tearDown(() async {
    await testDb.close();
  });

  Future<void> pumpSettings(WidgetTester tester, SessionState session) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SettingsScreen(sessionState: session),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('authorized owner sees the editable shop profile section',
      (WidgetTester tester) async {
    await pumpSettings(tester, ownerSession);

    expect(find.text('هوية المتجر'), findsOneWidget);
    expect(find.text('اسم المتجر'), findsOneWidget);
    expect(find.text('اسم المالك / المسؤول'), findsOneWidget);
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('العنوان'), findsOneWidget);
    expect(find.text('حفظ بيانات المتجر'), findsOneWidget);
    expect(find.byTooltip('اختيار الشعار'), findsOneWidget);
  });

  testWidgets('owner can save the shop profile from the UI and it persists',
      (WidgetTester tester) async {
    await pumpSettings(tester, ownerSession);

    await tester.enterText(
        find.widgetWithText(TextField, 'اسم المتجر'), 'متجر النور');
    await tester.enterText(
        find.widgetWithText(TextField, 'رقم الهاتف'), '01112345678');
    await tester.enterText(
        find.widgetWithText(TextField, 'العنوان'), 'شارع التحلية');

    await tester.tap(find.text('حفظ بيانات المتجر'));
    await tester.pumpAndSettle();

    expect(find.text('تم حفظ بيانات المحل بنجاح'), findsOneWidget);
    expect(ShopProfileService.instance.current.shopName, 'متجر النور');

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings',
        where: 'key = ?', whereArgs: ['shopProfile.shopName']);
    expect(rows, hasLength(1));
    expect(rows.single['value'], 'متجر النور');
  });

  testWidgets('blank shop name shows a validation message and nothing saves',
      (WidgetTester tester) async {
    await pumpSettings(tester, ownerSession);

    await tester.enterText(find.widgetWithText(TextField, 'اسم المتجر'), '   ');
    await tester.tap(find.text('حفظ بيانات المتجر'));
    await tester.pumpAndSettle();

    expect(find.text('اسم المحل مطلوب'), findsOneWidget);

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings',
        where: 'key = ?', whereArgs: ['shopProfile.shopName']);
    expect(rows, isEmpty);
  });

  testWidgets(
      'a role without canAccessSettings sees the read-only profile card',
      (WidgetTester tester) async {
    await pumpSettings(tester, salesOnlySession);

    expect(find.text('غير مصرح لك بتعديل بيانات المتجر'), findsOneWidget);
    expect(find.text('اسم المتجر'), findsNothing);
    expect(find.text('حفظ بيانات المتجر'), findsNothing);
    expect(find.byTooltip('اختيار الشعار'), findsNothing);
  });

  testWidgets(
      'owner sees I Tech attribution in shop profile section (OD5 fixed)',
      (WidgetTester tester) async {
    await pumpSettings(tester, ownerSession);

    expect(find.text('نسب التطوير'), findsOneWidget);
    expect(find.text(AppSettings.defaultItechAttributionText), findsOneWidget);
  });

  testWidgets(
      'sales-only role sees I Tech attribution in read-only shop profile section (OD5 fixed)',
      (WidgetTester tester) async {
    await pumpSettings(tester, salesOnlySession);

    expect(find.text('نسب التطوير'), findsOneWidget);
    expect(find.text(AppSettings.defaultItechAttributionText), findsOneWidget);
  });
}
