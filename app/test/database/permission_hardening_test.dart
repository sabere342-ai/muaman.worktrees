import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/database/user_repository.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/models/product.dart';
import 'package:muaman_store/models/sale.dart';
import 'package:muaman_store/models/return_item.dart';
import 'package:muaman_store/models/expense.dart';
import 'package:muaman_store/models/invoice.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/permissions.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late UserRepository userRepo;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);

    userRepo = UserRepository();
    userRepo.permissionResolver = PermissionResolver.instance;

    await testDb.insert('products', {
      'name': 'منتج اختبار',
      'barcode': 'BAR-PERM-001',
      'openingQuantity': 10,
      'soldQuantity': 0,
      'returnedQuantity': 0,
      'currentQuantity': 10,
      'costPrice': 50,
      'totalInventoryCost': 500,
      'inventoryAdjustment': 0,
    });

    await testDb.insert('products', {
      'name': 'منتج اختبار 2',
      'barcode': 'BAR-PERM-002',
      'openingQuantity': 5,
      'soldQuantity': 0,
      'returnedQuantity': 0,
      'currentQuantity': 5,
      'costPrice': 30,
      'totalInventoryCost': 150,
      'inventoryAdjustment': 0,
    });

    PermissionResolver.instance.invalidate();
  });

  tearDown(() async {
    await testDb.close();
  });

  /// Helper: grant employee only the specified permissions (clears defaults).
  Future<void> grantEmployeeOnly(Set<AppPermission> perms) async {
    await PermissionResolver.instance.saveRolePermissions(
      role: UserRole.employee,
      permissions: perms,
      actorRole: UserRole.owner,
    );
  }

  group('NC01-NC02: Product create/update authorization', () {
    test('Owner can insert product', () async {
      final result = await DatabaseHelper.instance.insertProduct(
        Product(
          name: 'منتج مالك',
          barcode: 'BAR-OWNER-001',
          openingQuantity: 5,
          currentQuantity: 5,
          costPrice: 100,
          totalInventoryCost: 500,
        ),
        currentRole: UserRole.owner,
      );
      expect(result, greaterThan(0));
    });

    test('Owner can update product', () async {
      final products = await DatabaseHelper.instance.getAllProducts();
      final product = products.first;
      final result = await DatabaseHelper.instance.updateProduct(
        product.copyWith(name: 'منتج محدث'),
        currentRole: UserRole.owner,
      );
      expect(result, greaterThan(0));
    });

    test('Employee with canEditProducts can insert product', () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessInventory,
        AppPermission.canEditProducts,
        AppPermission.canAccessSales,
      });
      final result = await DatabaseHelper.instance.insertProduct(
        Product(
          name: 'منتج موظف',
          barcode: 'BAR-EMP-001',
          openingQuantity: 3,
          currentQuantity: 3,
          costPrice: 75,
          totalInventoryCost: 225,
        ),
        currentRole: UserRole.employee,
      );
      expect(result, greaterThan(0));
    });

    test('Unauthorized employee cannot insert product (no-mutation proof)',
        () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
      });

      final countBefore = testDb.rawQuery('SELECT COUNT(*) as c FROM products');
      final rowsBefore = (await countBefore).first['c'] as int;

      expect(
        () => DatabaseHelper.instance.insertProduct(
          Product(
            name: 'منتج مرفوض',
            barcode: 'BAR-REJECT-001',
            openingQuantity: 1,
            currentQuantity: 1,
            costPrice: 10,
            totalInventoryCost: 10,
          ),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final countAfter = testDb.rawQuery('SELECT COUNT(*) as c FROM products');
      final rowsAfter = (await countAfter).first['c'] as int;
      expect(rowsAfter, equals(rowsBefore));
    });

    test('Unauthorized employee cannot update product (no-mutation proof)',
        () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
      });

      final products = await DatabaseHelper.instance.getAllProducts();
      final originalName = products.first.name;

      expect(
        () => DatabaseHelper.instance.updateProduct(
          products.first.copyWith(name: 'محاولة تعديل'),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final refreshed = await DatabaseHelper.instance.getAllProducts();
      expect(refreshed.first.name, equals(originalName));
    });

    test('No-role call is rejected (fail-closed)', () async {
      expect(
        () => DatabaseHelper.instance.insertProduct(
          Product(
            name: 'بدون دور',
            barcode: 'BAR-NOROLE-001',
            openingQuantity: 1,
            currentQuantity: 1,
            costPrice: 10,
            totalInventoryCost: 10,
          ),
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('NC03-NC04: Sale/Invoice creation authorization', () {
    test('Owner can insert sale and decrement stock', () async {
      final result = await DatabaseHelper.instance.insertSaleAndDecrementStock(
        Sale(
          date: DateTime.now(),
          productName: 'منتج اختبار',
          barcode: 'BAR-PERM-001',
          quantity: 1,
          salePrice: 100,
          costPrice: 50,
        ),
        currentRole: UserRole.owner,
      );
      expect(result, greaterThan(0));
    });

    test('Employee with canCreateSales can insert sale', () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessInventory,
        AppPermission.canAccessSales,
        AppPermission.canCreateSales,
      });
      final result = await DatabaseHelper.instance.insertSaleAndDecrementStock(
        Sale(
          date: DateTime.now(),
          productName: 'منتج اختبار',
          barcode: 'BAR-PERM-001',
          quantity: 1,
          salePrice: 100,
          costPrice: 50,
        ),
        currentRole: UserRole.employee,
      );
      expect(result, greaterThan(0));
    });

    test('Unauthorized employee cannot create sale (no-mutation proof)',
        () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
      });

      final salesBefore = testDb.rawQuery('SELECT COUNT(*) as c FROM sales');
      final salesRows = (await salesBefore).first['c'] as int;

      final productsBefore = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BAR-PERM-001']);
      final stockBefore = (productsBefore.first['currentQuantity'] as int);

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
          Sale(
            date: DateTime.now(),
            productName: 'منتج اختبار',
            barcode: 'BAR-PERM-001',
            quantity: 1,
            salePrice: 100,
            costPrice: 50,
          ),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final salesAfter = testDb.rawQuery('SELECT COUNT(*) as c FROM sales');
      final salesRowsAfter = (await salesAfter).first['c'] as int;
      expect(salesRowsAfter, equals(salesRows));

      final productsAfter = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BAR-PERM-001']);
      final stockAfter = (productsAfter.first['currentQuantity'] as int);
      expect(stockAfter, equals(stockBefore));
    });

    test('Owner can insert invoice with items', () async {
      final invoice = Invoice(
        invoiceNumber: 'INV-TEST-001',
        date: DateTime.now(),
        customerName: 'عميل اختبار',
        paymentMethod: 'cash',
        totalAmount: 200,
        totalItems: 2,
      );
      final items = [
        Sale(
          date: DateTime.now(),
          productName: 'منتج اختبار',
          barcode: 'BAR-PERM-001',
          quantity: 2,
          salePrice: 100,
          costPrice: 50,
        ),
      ];
      final result = await DatabaseHelper.instance.insertInvoiceWithItems(
        invoice,
        items,
        currentRole: UserRole.owner,
      );
      expect(result, greaterThan(0));
    });

    test('Unauthorized employee cannot create invoice (no-mutation proof)',
        () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
      });

      final salesBefore = testDb.rawQuery('SELECT COUNT(*) as c FROM sales');
      final salesRows = (await salesBefore).first['c'] as int;

      final invoicesBefore =
          testDb.rawQuery('SELECT COUNT(*) as c FROM invoices');
      final invoiceRows = (await invoicesBefore).first['c'] as int;

      final productsBefore = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BAR-PERM-001']);
      final stockBefore = (productsBefore.first['currentQuantity'] as int);

      expect(
        () => DatabaseHelper.instance.insertInvoiceWithItems(
          Invoice(
            invoiceNumber: 'INV-REJECT-001',
            date: DateTime.now(),
            customerName: 'عميل مرفوض',
            paymentMethod: 'cash',
            totalAmount: 100,
            totalItems: 1,
          ),
          [
            Sale(
              date: DateTime.now(),
              productName: 'منتج اختبار',
              barcode: 'BAR-PERM-001',
              quantity: 1,
              salePrice: 100,
              costPrice: 50,
            ),
          ],
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final salesAfter = testDb.rawQuery('SELECT COUNT(*) as c FROM sales');
      final salesRowsAfter = (await salesAfter).first['c'] as int;
      expect(salesRowsAfter, equals(salesRows));

      final invoicesAfter =
          testDb.rawQuery('SELECT COUNT(*) as c FROM invoices');
      final invoiceRowsAfter = (await invoicesAfter).first['c'] as int;
      expect(invoiceRowsAfter, equals(invoiceRows));

      final productsAfter = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BAR-PERM-001']);
      final stockAfter = (productsAfter.first['currentQuantity'] as int);
      expect(stockAfter, equals(stockBefore));
    });

    test('salesOnly with only sales permissions cannot manage products',
        () async {
      expect(
        () => DatabaseHelper.instance.insertProduct(
          Product(
            name: 'منتج مرفوض',
            barcode: 'BAR-SALESREJECT',
            openingQuantity: 1,
            currentQuantity: 1,
            costPrice: 10,
            totalInventoryCost: 10,
          ),
          currentRole: UserRole.salesOnly,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('NC05: Return creation authorization', () {
    test('Owner can insert return', () async {
      final result = await DatabaseHelper.instance.insertReturn(
        ReturnItem(
          date: DateTime.now(),
          productName: 'منتج اختبار',
          barcode: 'BAR-PERM-001',
          quantity: 1,
          salePrice: 100,
          costPrice: 50,
        ),
        currentRole: UserRole.owner,
      );
      expect(result, greaterThan(0));
    });

    test('Employee with canCreateReturns can insert return', () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessReturns,
        AppPermission.canCreateReturns,
      });
      final result = await DatabaseHelper.instance.insertReturn(
        ReturnItem(
          date: DateTime.now(),
          productName: 'منتج اختبار',
          barcode: 'BAR-PERM-001',
          quantity: 1,
          salePrice: 100,
          costPrice: 50,
        ),
        currentRole: UserRole.employee,
      );
      expect(result, greaterThan(0));
    });

    test('Unauthorized employee cannot create return (no-mutation proof)',
        () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
      });

      final returnsBefore =
          testDb.rawQuery('SELECT COUNT(*) as c FROM returns');
      final returnRows = (await returnsBefore).first['c'] as int;

      final productsBefore = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BAR-PERM-001']);
      final stockBefore = (productsBefore.first['currentQuantity'] as int);

      expect(
        () => DatabaseHelper.instance.insertReturn(
          ReturnItem(
            date: DateTime.now(),
            productName: 'منتج اختبار',
            barcode: 'BAR-PERM-001',
            quantity: 1,
            salePrice: 100,
            costPrice: 50,
          ),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final returnsAfter = testDb.rawQuery('SELECT COUNT(*) as c FROM returns');
      final returnRowsAfter = (await returnsAfter).first['c'] as int;
      expect(returnRowsAfter, equals(returnRows));

      final productsAfter = await testDb
          .query('products', where: 'barcode = ?', whereArgs: ['BAR-PERM-001']);
      final stockAfter = (productsAfter.first['currentQuantity'] as int);
      expect(stockAfter, equals(stockBefore));
    });
  });

  group('NC06: Expense creation authorization', () {
    test('Owner can insert expense', () async {
      final result = await DatabaseHelper.instance.insertExpense(
        Expense(
          date: DateTime.now(),
          description: 'مصروف اختبار',
          amount: 100,
        ),
        currentRole: UserRole.owner,
      );
      expect(result, greaterThan(0));
    });

    test('Employee with canCreateExpenses can insert expense', () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessExpenses,
        AppPermission.canCreateExpenses,
      });
      final result = await DatabaseHelper.instance.insertExpense(
        Expense(
          date: DateTime.now(),
          description: 'مصروف موظف',
          amount: 50,
        ),
        currentRole: UserRole.employee,
      );
      expect(result, greaterThan(0));
    });

    test('Unauthorized employee cannot create expense (no-mutation proof)',
        () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
      });

      final expensesBefore =
          testDb.rawQuery('SELECT COUNT(*) as c FROM expenses');
      final expenseRows = (await expensesBefore).first['c'] as int;

      expect(
        () => DatabaseHelper.instance.insertExpense(
          Expense(
            date: DateTime.now(),
            description: 'مصروف مرفوض',
            amount: 200,
          ),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final expensesAfter =
          testDb.rawQuery('SELECT COUNT(*) as c FROM expenses');
      final expenseRowsAfter = (await expensesAfter).first['c'] as int;
      expect(expenseRowsAfter, equals(expenseRows));
    });
  });

  group('NC07: Inventory count authorization', () {
    test('Owner can save inventory count', () async {
      final result = await DatabaseHelper.instance.saveInventoryCount(
        1,
        8,
        'جرد مالك',
        currentRole: UserRole.owner,
      );
      expect(result, isA<int>());
    });

    test('Employee with canAccessStocktake can save inventory count', () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessStocktake,
      });
      final result = await DatabaseHelper.instance.saveInventoryCount(
        1,
        8,
        'جرد موظف',
        currentRole: UserRole.employee,
      );
      expect(result, isA<int>());
    });

    test(
        'Unauthorized employee cannot save inventory count (no-mutation proof)',
        () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
      });

      final countsBefore =
          testDb.rawQuery('SELECT COUNT(*) as c FROM inventory_count');
      final countRows = (await countsBefore).first['c'] as int;

      final productsBefore =
          await testDb.query('products', where: 'id = ?', whereArgs: [1]);
      final stockBefore = (productsBefore.first['currentQuantity'] as int);
      final adjBefore = (productsBefore.first['inventoryAdjustment'] as int);

      expect(
        () => DatabaseHelper.instance.saveInventoryCount(
          1,
          8,
          'جرد مرفوض',
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      final countsAfter =
          testDb.rawQuery('SELECT COUNT(*) as c FROM inventory_count');
      final countRowsAfter = (await countsAfter).first['c'] as int;
      expect(countRowsAfter, equals(countRows));

      final productsAfter =
          await testDb.query('products', where: 'id = ?', whereArgs: [1]);
      final stockAfter = (productsAfter.first['currentQuantity'] as int);
      final adjAfter = (productsAfter.first['inventoryAdjustment'] as int);
      expect(stockAfter, equals(stockBefore));
      expect(adjAfter, equals(adjBefore));
    });
  });

  group('NC08: User management authorization', () {
    test('Owner can create user', () async {
      final result = await userRepo.createUser(
        displayName: 'مستخدم مالك',
        username: 'owner-created',
        password: 'password123',
        role: UserRole.employee,
        currentRole: UserRole.owner,
      );
      expect(result, greaterThan(0));
    });

    test('Employee cannot create user (lacks canManageUsers)', () async {
      expect(
        () => userRepo.createUser(
          displayName: 'مستخدم مرفوض',
          username: 'rejected-user',
          password: 'password123',
          role: UserRole.employee,
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('Employee cannot update user', () async {
      final owner = await userRepo.createUser(
        displayName: 'مالك',
        username: 'owner-target',
        password: 'password123',
        role: UserRole.owner,
        currentRole: UserRole.owner,
      );

      expect(
        () => userRepo.updateUser(
          id: owner,
          displayName: 'محاولة تعديل',
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('Employee cannot reset password', () async {
      final owner = await userRepo.createUser(
        displayName: 'مالك',
        username: 'owner-pwd',
        password: 'password123',
        role: UserRole.owner,
        currentRole: UserRole.owner,
      );

      expect(
        () => userRepo.resetPassword(
          id: owner,
          newPassword: 'newpass123',
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('Employee cannot toggle active status', () async {
      final owner = await userRepo.createUser(
        displayName: 'مالك',
        username: 'owner-active',
        password: 'password123',
        role: UserRole.owner,
        currentRole: UserRole.owner,
      );

      expect(
        () => userRepo.setUserActiveStatus(
          id: owner,
          isActive: false,
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('NC09: Owner remains allowed', () {
    test('Owner can perform all mutations', () async {
      await DatabaseHelper.instance.insertProduct(
        Product(
          name: 'منتج مالك',
          barcode: 'BAR-NC09-001',
          openingQuantity: 5,
          currentQuantity: 5,
          costPrice: 100,
          totalInventoryCost: 500,
        ),
        currentRole: UserRole.owner,
      );

      await DatabaseHelper.instance.insertSaleAndDecrementStock(
        Sale(
          date: DateTime.now(),
          productName: 'منتج مالك',
          barcode: 'BAR-NC09-001',
          quantity: 1,
          salePrice: 150,
          costPrice: 100,
        ),
        currentRole: UserRole.owner,
      );

      await DatabaseHelper.instance.insertReturn(
        ReturnItem(
          date: DateTime.now(),
          productName: 'منتج مالك',
          barcode: 'BAR-NC09-001',
          quantity: 1,
          salePrice: 150,
          costPrice: 100,
        ),
        currentRole: UserRole.owner,
      );

      await DatabaseHelper.instance.insertExpense(
        Expense(
          date: DateTime.now(),
          description: 'مصروف مالك',
          amount: 50,
        ),
        currentRole: UserRole.owner,
      );

      await DatabaseHelper.instance.saveInventoryCount(
        1,
        4,
        'جرد مالك',
        currentRole: UserRole.owner,
      );

      final users = await userRepo.getAllUsers();
      expect(users.length, greaterThanOrEqualTo(0));
    });
  });

  group('NC10: Role-specific access', () {
    test('Employee with canCreateSales but not canEditProducts', () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessInventory,
        AppPermission.canAccessSales,
        AppPermission.canCreateSales,
        AppPermission.canViewSalesHistory,
      });

      final saleResult =
          await DatabaseHelper.instance.insertSaleAndDecrementStock(
        Sale(
          date: DateTime.now(),
          productName: 'منتج اختبار',
          barcode: 'BAR-PERM-001',
          quantity: 1,
          salePrice: 100,
          costPrice: 50,
        ),
        currentRole: UserRole.employee,
      );
      expect(saleResult, greaterThan(0));

      expect(
        () => DatabaseHelper.instance.insertProduct(
          Product(
            name: 'منتج مرفوض',
            barcode: 'BAR-REJECT-NC10',
            openingQuantity: 1,
            currentQuantity: 1,
            costPrice: 10,
            totalInventoryCost: 10,
          ),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('Employee with canCreateReturns but not canCreateSales', () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessReturns,
        AppPermission.canCreateReturns,
      });

      final returnResult = await DatabaseHelper.instance.insertReturn(
        ReturnItem(
          date: DateTime.now(),
          productName: 'منتج اختبار',
          barcode: 'BAR-PERM-001',
          quantity: 1,
          salePrice: 100,
          costPrice: 50,
        ),
        currentRole: UserRole.employee,
      );
      expect(returnResult, greaterThan(0));

      expect(
        () => DatabaseHelper.instance.insertSaleAndDecrementStock(
          Sale(
            date: DateTime.now(),
            productName: 'منتج اختبار',
            barcode: 'BAR-PERM-001',
            quantity: 1,
            salePrice: 100,
            costPrice: 50,
          ),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('Employee with canCreateExpenses but not canAccessStocktake',
        () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessExpenses,
        AppPermission.canCreateExpenses,
      });

      final expenseResult = await DatabaseHelper.instance.insertExpense(
        Expense(
          date: DateTime.now(),
          description: 'مصروف مسموح',
          amount: 25,
        ),
        currentRole: UserRole.employee,
      );
      expect(expenseResult, greaterThan(0));

      expect(
        () => DatabaseHelper.instance.saveInventoryCount(
          1,
          10,
          'جرد مرفوض',
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('Existing delete guards preserved', () {
    test('Owner can delete product', () async {
      final result = await DatabaseHelper.instance.deleteProduct(
        1,
        currentRole: UserRole.owner,
      );
      expect(result, greaterThan(0));
    });

    test('Employee is denied delete product by default', () async {
      expect(
        () => DatabaseHelper.instance.deleteProduct(
          1,
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('Employee with canDeleteProducts can delete', () async {
      await grantEmployeeOnly({
        AppPermission.canAccessDashboard,
        AppPermission.canAccessInventory,
        AppPermission.canDeleteProducts,
      });
      final result = await DatabaseHelper.instance.deleteProduct(
        1,
        currentRole: UserRole.employee,
      );
      expect(result, greaterThan(0));
    });
  });
}
