import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/user_repository.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/admin/user_management_screen.dart';
import 'package:muaman_store/screens/auth/login_screen.dart';
import 'package:muaman_store/screens/inventory/inventory_screen.dart';
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

  Finder dialogFieldAt(int index) => find
      .descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      )
      .at(index);

  SessionState ownerSession() {
    final session = SessionState();
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

  group('Login screen Enter key', () {
    testWidgets('Enter on password field performs login',
        (WidgetTester tester) async {
      await UserRepository().createUser(
        displayName: 'المالك',
        username: 'owner',
        password: 'secret123',
        role: UserRole.owner,
      );

      final session = SessionState();
      var loginCount = 0;
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(
          sessionState: session,
          onLoginSuccess: () => loginCount++,
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'owner');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Let the real async login (PBKDF2 + sqflite isolate) complete. The
      // login screen keeps a spinner visible after success, so pumpAndSettle
      // would time out; wait on real time instead.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 800)),
      );
      await tester.pump();

      expect(loginCount, 1);
      expect(session.isLoggedIn, true);
    });

    testWidgets('Enter does not submit login twice',
        (WidgetTester tester) async {
      await UserRepository().createUser(
        displayName: 'المالك',
        username: 'owner',
        password: 'secret123',
        role: UserRole.owner,
      );

      final session = SessionState();
      var loginCount = 0;
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(
          sessionState: session,
          onLoginSuccess: () => loginCount++,
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'owner');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 800)),
      );
      await tester.pump();

      expect(loginCount, 1);
    });
  });

  group('Create user dialog Enter key', () {
    Future<void> openCreateDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UserManagementScreen(sessionState: SessionState()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('مستخدم جديد'));
      await tester.pumpAndSettle();
      expect(find.text('إنشاء مستخدم جديد'), findsOneWidget);
    }

    testWidgets('Enter on confirm field creates exactly one user',
        (WidgetTester tester) async {
      await openCreateDialog(tester);

      await tester.enterText(dialogFieldAt(0), 'أحمد');
      await tester.enterText(dialogFieldAt(1), 'ahmed');
      await tester.enterText(dialogFieldAt(2), 'secret123');
      await tester.enterText(dialogFieldAt(3), 'secret123');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pumpAndSettle();

      expect(find.text('إنشاء مستخدم جديد'), findsNothing);
      final users = await testDb.query('users');
      expect(users.length, 1);
      expect(users.first['username'], 'ahmed');
    });

    testWidgets('Enter with invalid data shows error and creates no user',
        (WidgetTester tester) async {
      await openCreateDialog(tester);

      await tester.enterText(dialogFieldAt(0), 'أحمد');
      await tester.enterText(dialogFieldAt(1), 'ahmed');
      await tester.enterText(dialogFieldAt(2), '123');
      await tester.enterText(dialogFieldAt(3), '123');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pumpAndSettle();

      expect(find.textContaining('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
          findsOneWidget);
      final users = await testDb.query('users');
      expect(users, isEmpty);
    });
  });

  group('Inventory add/edit dialog Enter key', () {
    testWidgets('Enter on quantity field adds the product',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: InventoryScreen(sessionState: ownerSession())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة صنف'));
      await tester.pumpAndSettle();
      expect(find.text('إضافة صنف جديد'), findsOneWidget);

      await tester.enterText(dialogFieldAt(0), 'صنف جديد');
      await tester.enterText(dialogFieldAt(1), '25');
      await tester.enterText(dialogFieldAt(2), '4');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pumpAndSettle();

      expect(find.text('إضافة صنف جديد'), findsNothing);
      final products = await testDb.query('products');
      expect(products.length, 1);
      expect(products.first['name'], 'صنف جديد');
      expect(products.first['currentQuantity'], 4);
      expect(products.first['costPrice'], 25.0);
    });

    testWidgets('Enter on cost field saves edits', (WidgetTester tester) async {
      await testDb.insert('products', {
        'name': 'صنف قديم',
        'barcode': 'OLD-001',
        'openingQuantity': 5,
        'soldQuantity': 0,
        'returnedQuantity': 0,
        'currentQuantity': 5,
        'costPrice': 10,
        'totalInventoryCost': 50,
        'inventoryAdjustment': 0,
      });

      await tester.pumpWidget(
        MaterialApp(home: InventoryScreen(sessionState: ownerSession())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();
      expect(find.text('تعديل الصنف'), findsOneWidget);

      await tester.enterText(dialogFieldAt(1), '30');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pumpAndSettle();

      expect(find.text('تعديل الصنف'), findsNothing);
      final products = await testDb.query('products');
      expect(products.length, 1);
      expect(products.first['costPrice'], 30.0);
    });
  });
}
