import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muaman_store/database/user_repository.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permissions.dart';
import 'package:muaman_store/services/permission_resolver.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await createTestTables(testDb);
    await DatabaseHelper.setTestDatabase(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  UserRepository createRepo() => UserRepository();

  group('UserRepository - Database Operations', () {
    test('1. Create users table in new database', () async {
      final tables = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='users'");
      expect(tables.length, 1);
    });

    test('2. Create first owner', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'المالك',
        username: 'owner',
        password: 'password123',
        role: UserRole.owner,
      );
      expect(id, greaterThan(0));

      final user = await repo.getUserById(id);
      expect(user, isNotNull);
      expect(user!.displayName, 'المالك');
      expect(user.username, 'owner');
      expect(user.role, UserRole.owner);
      expect(user.isActive, true);
    });

    test('3. Prevent duplicate username', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'User1',
        username: 'testuser',
        password: 'password123',
        role: UserRole.owner,
      );
      expect(
        () => repo.createUser(
          displayName: 'User2',
          username: 'testuser',
          password: 'password456',
          role: UserRole.employee,
        ),
        throwsA(isA<DuplicateUsernameException>()),
      );
    });

    test('4. Prevent duplicate with case-insensitive match', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'User1',
        username: 'TestUser',
        password: 'password123',
        role: UserRole.owner,
      );
      expect(
        () => repo.createUser(
          displayName: 'User2',
          username: 'testuser',
          password: 'password456',
          role: UserRole.employee,
        ),
        throwsA(isA<DuplicateUsernameException>()),
      );
    });

    test('5. Reject empty username', () async {
      final repo = createRepo();
      expect(
        () => repo.createUser(
          displayName: 'User',
          username: '  ',
          password: 'password123',
          role: UserRole.owner,
        ),
        throwsArgumentError,
      );
    });

    test('6. Reject empty display name', () async {
      final repo = createRepo();
      expect(
        () => repo.createUser(
          displayName: '  ',
          username: 'user1',
          password: 'password123',
          role: UserRole.owner,
        ),
        throwsArgumentError,
      );
    });

    test('7. Reject invalid password (too short)', () async {
      final repo = createRepo();
      expect(
        () => repo.createUser(
          displayName: 'User',
          username: 'user1',
          password: '12',
          role: UserRole.owner,
        ),
        throwsA(isA<WeakPasswordException>()),
      );
    });

    test('8. Reject unknown role', () async {
      expect(
        () => UserRole.fromString('superadmin'),
        throwsA(isA<InvalidUserRoleException>()),
      );
    });

    test('9. Create employee successfully', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'موظف',
        username: 'employee1',
        password: 'password123',
        role: UserRole.employee,
      );
      final user = await repo.getUserById(id);
      expect(user!.role, UserRole.employee);
      expect(user.isActive, true);
    });

    test('10. Create salesOnly successfully', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'كاشير',
        username: 'cashier1',
        password: 'password123',
        role: UserRole.salesOnly,
      );
      final user = await repo.getUserById(id);
      expect(user!.role, UserRole.salesOnly);
      expect(user.isActive, true);
    });

    test('11. Update display name', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'Old Name',
        username: 'user1',
        password: 'password123',
        role: UserRole.employee,
      );
      await repo.updateUser(id: id, displayName: 'New Name');
      final user = await repo.getUserById(id);
      expect(user!.displayName, 'New Name');
    });

    test('12. Update username', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'User',
        username: 'olduser',
        password: 'password123',
        role: UserRole.employee,
      );
      await repo.updateUser(id: id, username: 'newuser');
      final user = await repo.getUserById(id);
      expect(user!.username, 'newuser');
    });

    test('13. Change role', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'password123',
        role: UserRole.employee,
      );
      await repo.updateUser(id: id, role: UserRole.salesOnly);
      final user = await repo.getUserById(id);
      expect(user!.role, UserRole.salesOnly);
    });

    test('14. Disable user', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'Owner',
        username: 'owner',
        password: 'password123',
        role: UserRole.owner,
      );
      final id = await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'password123',
        role: UserRole.employee,
      );
      await repo.setUserActiveStatus(id: id, isActive: false);
      final user = await repo.getUserById(id);
      expect(user!.isActive, false);
    });

    test('15. Reactivate user', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'Owner',
        username: 'owner',
        password: 'password123',
        role: UserRole.owner,
      );
      final id = await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'password123',
        role: UserRole.employee,
      );
      await repo.setUserActiveStatus(id: id, isActive: false);
      await repo.setUserActiveStatus(id: id, isActive: true);
      final user = await repo.getUserById(id);
      expect(user!.isActive, true);
    });

    test('16. Reset password', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'oldpassword',
        role: UserRole.employee,
      );
      await repo.resetPassword(id: id, newPassword: 'newpassword123');
      final user = await repo.getUserById(id);
      expect(user!.passwordHash, isNot('oldpassword'));
      expect(user.passwordHash.contains(':'), true);
    });

    test('17. Password not stored as plain text', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'mySecretPassword',
        role: UserRole.employee,
      );
      final rows =
          await testDb.query('users', where: 'id = ?', whereArgs: [id]);
      final hash = rows.first['passwordHash'] as String;
      expect(hash.contains('mySecretPassword'), false);
      expect(hash.contains(':'), true);
      expect(hash.length, greaterThan(20));
    });

    test('18. Old password invalid after reset', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'oldpassword',
        role: UserRole.employee,
      );
      await repo.resetPassword(id: id, newPassword: 'newpassword123');

      final authOld = await repo.authenticate('user1', 'oldpassword');
      expect(authOld, isNull);

      final authNew = await repo.authenticate('user1', 'newpassword123');
      expect(authNew, isNotNull);
    });

    test('19. Cannot disable last active owner', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'Owner',
        username: 'owner',
        password: 'password123',
        role: UserRole.owner,
      );

      expect(
        () => repo.setUserActiveStatus(id: 1, isActive: false),
        throwsA(isA<LastActiveOwnerException>()),
      );
    });

    test('20. Cannot downgrade last active owner role', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'Owner',
        username: 'owner',
        password: 'password123',
        role: UserRole.owner,
      );

      expect(
        () => repo.updateUser(id: 1, role: UserRole.employee),
        throwsA(isA<LastActiveOwnerException>()),
      );
    });

    test('21. Can disable owner when another active owner exists', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'Owner1',
        username: 'owner1',
        password: 'password123',
        role: UserRole.owner,
      );
      final id2 = await repo.createUser(
        displayName: 'Owner2',
        username: 'owner2',
        password: 'password123',
        role: UserRole.owner,
      );

      await repo.setUserActiveStatus(
          id: id2, isActive: false, currentUserId: 1);
      final user2 = await repo.getUserById(id2);
      expect(user2!.isActive, false);
    });

    test('22. Cannot disable self', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'Owner',
        username: 'owner',
        password: 'password123',
        role: UserRole.owner,
      );
      await repo.createUser(
        displayName: 'Owner2',
        username: 'owner2',
        password: 'password123',
        role: UserRole.owner,
      );

      expect(
        () => repo.setUserActiveStatus(
            id: id, isActive: false, currentUserId: id),
        throwsA(isA<CannotDisableCurrentUserException>()),
      );
    });

    test('23. Reject update of non-existent user', () async {
      final repo = createRepo();
      expect(
        () => repo.updateUser(id: 999, displayName: 'Ghost'),
        throwsA(isA<UserNotFoundException>()),
      );
    });

    test('24. Reject password reset for non-existent user', () async {
      final repo = createRepo();
      expect(
        () => repo.resetPassword(id: 999, newPassword: 'password123'),
        throwsA(isA<UserNotFoundException>()),
      );
    });

    test('25. Verify affected row count on update', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'password123',
        role: UserRole.employee,
      );
      final affected = await repo.updateUser(id: id, displayName: 'Updated');
      expect(affected, 1);
    });
  });

  group('Authentication', () {
    test('26. Owner login succeeds', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'Owner',
        username: 'owner',
        password: 'password123',
        role: UserRole.owner,
      );
      final user = await repo.authenticate('owner', 'password123');
      expect(user, isNotNull);
      expect(user!.role, UserRole.owner);
    });

    test('27. Employee login succeeds', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'Employee',
        username: 'employee',
        password: 'password123',
        role: UserRole.employee,
      );
      final user = await repo.authenticate('employee', 'password123');
      expect(user, isNotNull);
      expect(user!.role, UserRole.employee);
    });

    test('28. SalesOnly login succeeds', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'Cashier',
        username: 'cashier',
        password: 'password123',
        role: UserRole.salesOnly,
      );
      final user = await repo.authenticate('cashier', 'password123');
      expect(user, isNotNull);
      expect(user!.role, UserRole.salesOnly);
    });

    test('29. Reject non-existent username', () async {
      final repo = createRepo();
      final user = await repo.authenticate('nonexistent', 'password123');
      expect(user, isNull);
    });

    test('30. Reject wrong password', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'correctpassword',
        role: UserRole.employee,
      );
      final user = await repo.authenticate('user1', 'wrongpassword');
      expect(user, isNull);
    });

    test('31. Reject disabled account', () async {
      final repo = createRepo();
      final id = await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'password123',
        role: UserRole.employee,
      );
      await repo.setUserActiveStatus(id: id, isActive: false);
      final user = await repo.authenticate('user1', 'password123');
      expect(user, isNull);
    });

    test('32. Update lastLoginAt on success', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'password123',
        role: UserRole.employee,
      );
      final user = await repo.authenticate('user1', 'password123');
      expect(user, isNotNull);

      await repo.updateLastLogin(user!.id!);
      final updated = await repo.getUserById(user.id!);
      expect(updated!.lastLoginAt, isNotNull);
    });

    test('33. lastLoginAt remains null on failed auth', () async {
      final repo = createRepo();
      await repo.createUser(
        displayName: 'User',
        username: 'user1',
        password: 'password123',
        role: UserRole.employee,
      );

      await repo.authenticate('user1', 'wrongpassword');
      final rows = await testDb.rawQuery(
          'SELECT lastLoginAt FROM users WHERE username = ?', ['user1']);
      expect(rows.first['lastLoginAt'], isNull);
    });
  });

  group('Permissions', () {
    // A resolver with no persisted configuration must reproduce the MUAMAN-14
    // baseline defaults exactly (fail-safe fallback).
    final resolver = PermissionResolver();

    test('36. Owner has all permissions', () {
      for (final permission in AppPermission.values) {
        expect(resolver.can(UserRole.owner, permission), true,
            reason: 'Owner should always hold ${permission.id}');
      }
    });

    test('36b. Owner is never reduced by a persisted configuration', () async {
      final fresh = PermissionResolver();
      await fresh.refresh();
      for (final permission in AppPermission.values) {
        expect(fresh.can(UserRole.owner, permission), true,
            reason: 'Owner should always hold ${permission.id}');
      }
    });

    test('37. Employee cannot manage users or permissions or settings', () {
      expect(
          resolver.can(UserRole.employee, AppPermission.canManageUsers), false);
      expect(
          resolver.can(UserRole.employee, AppPermission.canManagePermissions),
          false);
      expect(resolver.can(UserRole.employee, AppPermission.canAccessSettings),
          false);
    });

    test('38. Employee can access operational screens and create/edit', () {
      for (final permission in {
        AppPermission.canAccessDashboard,
        AppPermission.canAccessInventory,
        AppPermission.canEditProducts,
        AppPermission.canAccessSales,
        AppPermission.canCreateSales,
        AppPermission.canViewSalesHistory,
        AppPermission.canAccessReturns,
        AppPermission.canCreateReturns,
        AppPermission.canAccessExpenses,
        AppPermission.canCreateExpenses,
        AppPermission.canAccessStocktake,
      }) {
        expect(resolver.can(UserRole.employee, permission), true,
            reason: 'Employee should hold ${permission.id}');
      }
    });

    test('38b. Employee cannot delete (owner-only in baseline)', () {
      for (final permission in {
        AppPermission.canDeleteProducts,
        AppPermission.canDeleteSales,
        AppPermission.canDeleteReturns,
        AppPermission.canDeleteExpenses,
      }) {
        expect(resolver.can(UserRole.employee, permission), false,
            reason: 'Employee should not hold ${permission.id}');
      }
    });

    test('39. SalesOnly can access and create sales', () {
      expect(
          resolver.can(UserRole.salesOnly, AppPermission.canAccessSales), true);
      expect(
          resolver.can(UserRole.salesOnly, AppPermission.canCreateSales), true);
    });

    test('39c. SalesOnly cannot view sales history', () {
      expect(
          resolver.can(UserRole.salesOnly, AppPermission.canViewSalesHistory),
          false);
    });

    test('39d. SalesOnly cannot delete sales', () {
      expect(resolver.can(UserRole.salesOnly, AppPermission.canDeleteSales),
          false);
    });

    test('40-45. SalesOnly cannot access other screens or admin powers', () {
      for (final permission in {
        AppPermission.canAccessDashboard,
        AppPermission.canAccessInventory,
        AppPermission.canAccessReturns,
        AppPermission.canAccessExpenses,
        AppPermission.canAccessStocktake,
        AppPermission.canManageUsers,
        AppPermission.canManagePermissions,
        AppPermission.canAccessSettings,
      }) {
        expect(resolver.can(UserRole.salesOnly, permission), false,
            reason: 'SalesOnly should not hold ${permission.id}');
      }
    });
  });
}

Future<void> createTestTables(Database db) async {
  await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      barcode TEXT UNIQUE NOT NULL,
      openingQuantity INTEGER DEFAULT 0,
      soldQuantity INTEGER DEFAULT 0,
      returnedQuantity INTEGER DEFAULT 0,
      currentQuantity INTEGER DEFAULT 0,
      costPrice REAL DEFAULT 0,
      totalInventoryCost REAL DEFAULT 0,
      inventoryAdjustment INTEGER DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoiceId INTEGER,
      date TEXT NOT NULL,
      productName TEXT NOT NULL,
      barcode TEXT NOT NULL,
      quantity INTEGER DEFAULT 0,
      salePrice REAL DEFAULT 0,
      totalSaleValue REAL DEFAULT 0,
      costPrice REAL DEFAULT 0,
      cogs REAL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE returns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      productName TEXT NOT NULL,
      barcode TEXT NOT NULL,
      quantity INTEGER DEFAULT 0,
      salePrice REAL DEFAULT 0,
      totalReturnValue REAL DEFAULT 0,
      costPrice REAL DEFAULT 0,
      returnedCogs REAL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE inventory_count (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productId INTEGER NOT NULL,
      actualQuantity INTEGER DEFAULT 0,
      notes TEXT DEFAULT '',
      countDate TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      displayName TEXT NOT NULL,
      username TEXT NOT NULL UNIQUE,
      passwordHash TEXT NOT NULL,
      role TEXT NOT NULL,
      isActive INTEGER NOT NULL DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      lastLoginAt TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS import_batches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_sha256 TEXT NOT NULL UNIQUE,
      file_name TEXT NOT NULL,
      imported_at TEXT NOT NULL,
      products_count INTEGER DEFAULT 0,
      sales_count INTEGER DEFAULT 0,
      returns_count INTEGER DEFAULT 0,
      expenses_count INTEGER DEFAULT 0,
      adjustments_count INTEGER DEFAULT 0,
      total_quantity INTEGER DEFAULT 0,
      total_inventory_value REAL DEFAULT 0,
      total_sales REAL DEFAULT 0,
      total_returns REAL DEFAULT 0,
      net_sales REAL DEFAULT 0,
      total_cogs REAL DEFAULT 0,
      returned_cogs REAL DEFAULT 0,
      net_cogs REAL DEFAULT 0,
      gross_profit REAL DEFAULT 0,
      total_expenses REAL DEFAULT 0,
      net_profit REAL DEFAULT 0,
      reconciliation_json TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE role_permissions (
      role TEXT PRIMARY KEY,
      permissions TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
}
