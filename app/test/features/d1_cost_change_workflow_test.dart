import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/inventory/inventory_screen.dart';
import 'package:muaman_store/services/session_state.dart';
import 'package:muaman_store/models/user.dart';

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

  Future<void> seedProduct({
    required String name,
    required String barcode,
    required double cost,
    int quantity = 5,
  }) async {
    await testDb.insert('products', {
      'name': name,
      'barcode': barcode,
      'openingQuantity': quantity,
      'soldQuantity': 0,
      'returnedQuantity': 0,
      'currentQuantity': quantity,
      'costPrice': cost,
      'totalInventoryCost': quantity * cost,
      'inventoryAdjustment': 0,
    });
  }

  group('D1 three-path cost-change workflow', () {
    testWidgets('Update current product: cost changes, one history entry, no new product',
        (WidgetTester tester) async {
      await seedProduct(name: 'صنف أ', barcode: 'UPD-001', cost: 100);

      await tester.pumpWidget(
        MaterialApp(home: InventoryScreen(sessionState: ownerSession())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();

      await tester.enterText(dialogFieldAt(1), '150');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('تحذير تغيير سعر التكلفة'), findsOneWidget);
      await tester.tap(find.text('تحديث السعر'));
      await tester.pumpAndSettle();

      expect(find.text('تعديل الصنف'), findsNothing);

      final products = await testDb.query('products');
      expect(products.length, 1);
      expect(products.first['costPrice'], 150.0);
      expect(products.first['barcode'], 'UPD-001');
    });

    testWidgets('Create new product: original untouched, new distinct product created',
        (WidgetTester tester) async {
      await seedProduct(name: 'صنف أ', barcode: 'NEW-001', cost: 100);

      await tester.pumpWidget(
        MaterialApp(home: InventoryScreen(sessionState: ownerSession())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();

      await tester.enterText(dialogFieldAt(1), '200');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('تحذير تغيير سعر التكلفة'), findsOneWidget);
      await tester.tap(find.text('إنشاء صنف جديد'));
      await tester.pumpAndSettle();

      expect(find.text('اسم الصنف الجديد'), findsOneWidget);
      expect(find.text('صنف أ'), findsWidgets);
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      final products = await testDb.query('products');
      expect(products.length, 2);

      final original = products.firstWhere((p) => p['barcode'] == 'NEW-001');
      expect(original['costPrice'], 100.0,
          reason: 'original product cost must NOT change');

      final newProduct = products.firstWhere((p) => p['barcode'] != 'NEW-001');
      expect(newProduct['costPrice'], 200.0);
      expect(newProduct['currentQuantity'], 0);
      expect(newProduct['openingQuantity'], 0);
      expect(newProduct['barcode'] != 'NEW-001', isTrue,
          reason: 'new product must have a distinct barcode');
    });

    testWidgets('Cancel: no changes to original product, no new product',
        (WidgetTester tester) async {
      await seedProduct(name: 'صنف أ', barcode: 'CAN-001', cost: 100);

      await tester.pumpWidget(
        MaterialApp(home: InventoryScreen(sessionState: ownerSession())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();

      await tester.enterText(dialogFieldAt(1), '999');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('تحذير تغيير سعر التكلفة'), findsOneWidget);
      await tester.tap(find.text('إلغاء').last);
      await tester.pumpAndSettle();

      expect(find.text('تعديل الصنف'), findsOneWidget,
          reason: 'edit dialog should remain open');

      final products = await testDb.query('products');
      expect(products.length, 1);
      expect(products.first['costPrice'], 100.0,
          reason: 'cost must NOT change on cancel');
    });

    testWidgets('Enter key on cost field reaches three-option dialog',
        (WidgetTester tester) async {
      await seedProduct(name: 'صنف أ', barcode: 'EK-001', cost: 10);

      await tester.pumpWidget(
        MaterialApp(home: InventoryScreen(sessionState: ownerSession())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();

      await tester.enterText(dialogFieldAt(1), '50');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('تحذير تغيير سعر التكلفة'), findsOneWidget);
      expect(find.text('إلغاء'), findsWidgets);
      expect(find.text('تحديث السعر'), findsOneWidget);
      expect(find.text('إنشاء صنف جديد'), findsOneWidget);
    });
  });
}
