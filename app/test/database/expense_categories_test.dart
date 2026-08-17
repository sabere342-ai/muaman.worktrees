import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/expense.dart';
import 'package:muaman_store/models/expense_category.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/services/permissions.dart';

import '../helpers/test_schema.dart';

void main() {
  sqfliteFfiInit();

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

  group('T2-2: Expense Category CRUD', () {
    test('TC-CAT-01: owner can create a category', () async {
      final id = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      expect(id, greaterThan(0));

      final categories = await DatabaseHelper.instance.getAllExpenseCategories();
      expect(categories, hasLength(1));
      expect(categories.first.name, 'نقل');
    });

    test('TC-CAT-02: default employee cannot create category (owner-only)', () async {
      expect(
        () => DatabaseHelper.instance.insertExpenseCategory(
          ExpenseCategory(name: 'رواتب'),
          currentRole: UserRole.employee,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('TC-CAT-03: category name is trimmed on insert', () async {
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: '  طعام  '),
        currentRole: UserRole.owner,
      );
      final categories = await DatabaseHelper.instance.getAllExpenseCategories();
      expect(categories.first.name, 'طعام');
    });

    test('TC-CAT-04: blank name is rejected', () async {
      expect(
        () => DatabaseHelper.instance.insertExpenseCategory(
          ExpenseCategory(name: '   '),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CAT-05: empty name is rejected', () async {
      expect(
        () => DatabaseHelper.instance.insertExpenseCategory(
          ExpenseCategory(name: ''),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CAT-06: duplicate category name is rejected (case-insensitive)', () async {
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      expect(
        () => DatabaseHelper.instance.insertExpenseCategory(
          ExpenseCategory(name: 'نقل'),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CAT-07: duplicate with different case is rejected', () async {
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      expect(
        () => DatabaseHelper.instance.insertExpenseCategory(
          ExpenseCategory(name: 'نقل'),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CAT-08: duplicate with leading/trailing spaces is rejected', () async {
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      expect(
        () => DatabaseHelper.instance.insertExpenseCategory(
          ExpenseCategory(name: ' نقل '),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CAT-09: multiple distinct categories can be created', () async {
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'رواتب'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: ' طعام'),
        currentRole: UserRole.owner,
      );

      final categories = await DatabaseHelper.instance.getAllExpenseCategories();
      expect(categories, hasLength(3));
      expect(categories.map((c) => c.name), containsAll(['نقل', 'رواتب', 'طعام']));
    });

    test('TC-CAT-10: category can be renamed', () async {
      final id = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.renameExpenseCategory(id, 'مواصلات',
          currentRole: UserRole.owner);

      final categories = await DatabaseHelper.instance.getAllExpenseCategories();
      expect(categories.first.name, 'مواصلات');
    });

    test('TC-CAT-11: rename to blank is rejected', () async {
      final id = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      expect(
        () => DatabaseHelper.instance.renameExpenseCategory(id, '   ',
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CAT-12: rename to duplicate is rejected', () async {
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      final id2 = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'رواتب'),
        currentRole: UserRole.owner,
      );
      expect(
        () => DatabaseHelper.instance.renameExpenseCategory(id2, 'نقل',
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CAT-13: rename to same name (self) is allowed', () async {
      final id = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.renameExpenseCategory(id, 'نقل',
          currentRole: UserRole.owner);

      final categories = await DatabaseHelper.instance.getAllExpenseCategories();
      expect(categories, hasLength(1));
      expect(categories.first.name, 'نقل');
    });

    test('TC-CAT-14: unused category can be deleted', () async {
      final id = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      final deleted = await DatabaseHelper.instance.deleteExpenseCategory(id,
          currentRole: UserRole.owner);
      expect(deleted, 1);

      final categories = await DatabaseHelper.instance.getAllExpenseCategories();
      expect(categories, isEmpty);
    });

    test('TC-CAT-15: category in use cannot be deleted', () async {
      final id = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertExpense(
        Expense(
          date: DateTime.now(),
          description: 'أجرة تاكسي',
          amount: 50,
          category: 'نقل',
        ),
        currentRole: UserRole.owner,
      );

      expect(
        () => DatabaseHelper.instance.deleteExpenseCategory(id,
            currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );
    });

    test('TC-CAT-16: delete nonexistent category throws', () async {
      expect(
        () => DatabaseHelper.instance.deleteExpenseCategory(9999,
            currentRole: UserRole.owner),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CAT-17: categories are ordered by id ASC', () async {
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'رواتب'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'نقل'),
        currentRole: UserRole.owner,
      );

      final categories = await DatabaseHelper.instance.getAllExpenseCategories();
      expect(categories.first.name, 'رواتب');
      expect(categories.last.name, 'نقل');
    });
  });

  group('T2-2: Expense Model with Category', () {
    test('TC-EXP-01: expense with null category roundtrips correctly', () async {
      final expense = Expense(
        date: DateTime(2026, 8, 15),
        description: 'مصروف عام',
        amount: 100,
      );
      final id = await DatabaseHelper.instance.insertExpense(expense,
          currentRole: UserRole.owner);

      final all = await DatabaseHelper.instance.getAllExpenses();
      final loaded = all.firstWhere((e) => e.id == id);
      expect(loaded.category, isNull);
      expect(loaded.description, 'مصروف عام');
      expect(loaded.amount, 100);
    });

    test('TC-EXP-02: expense with category roundtrips correctly', () async {
      final expense = Expense(
        date: DateTime(2026, 8, 15),
        description: 'أجرة تاكسي',
        amount: 50,
        category: 'نقل',
      );
      final id = await DatabaseHelper.instance.insertExpense(expense,
          currentRole: UserRole.owner);

      final all = await DatabaseHelper.instance.getAllExpenses();
      final loaded = all.firstWhere((e) => e.id == id);
      expect(loaded.category, 'نقل');
      expect(loaded.amount, 50);
    });

    test('TC-EXP-03: category persists after reload', () async {
      await DatabaseHelper.instance.insertExpense(
        Expense(
          date: DateTime.now(),
          description: 'مصاريف متنوعة',
          amount: 200,
          category: 'متنوع',
        ),
        currentRole: UserRole.owner,
      );

      final expenses = await DatabaseHelper.instance.getAllExpenses();
      expect(expenses.first.category, 'متنوع');
    });

    test('TC-EXP-04: category does not alter expense amount', () async {
      final withCategory = Expense(
        date: DateTime.now(),
        description: 'مصروف 1',
        amount: 150,
        category: 'نقل',
      );
      final withoutCategory = Expense(
        date: DateTime.now(),
        description: 'مصروف 2',
        amount: 150,
      );

      await DatabaseHelper.instance.insertExpense(withCategory,
          currentRole: UserRole.owner);
      await DatabaseHelper.instance.insertExpense(withoutCategory,
          currentRole: UserRole.owner);

      final total = await DatabaseHelper.instance.getTotalExpenses();
      expect(total, 300);
    });

    test('TC-EXP-05: category does not affect total expenses calculation', () async {
      await DatabaseHelper.instance.insertExpense(
        Expense(
            date: DateTime.now(),
            description: 'مصروف بتصنيف',
            amount: 100,
            category: 'نقل'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertExpense(
        Expense(
            date: DateTime.now(),
            description: 'مصروف بدون تصنيف',
            amount: 200,
        ),
        currentRole: UserRole.owner,
      );

      final total = await DatabaseHelper.instance.getTotalExpenses();
      expect(total, 300);
    });

    test('TC-EXP-06: getDistinctExpenseCategories returns unique categories', () async {
      await DatabaseHelper.instance.insertExpense(
        Expense(
            date: DateTime.now(),
            description: 'تاكسي',
            amount: 30,
            category: 'نقل'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertExpense(
        Expense(
            date: DateTime.now(),
            description: 'أتوبيس',
            amount: 10,
            category: 'نقل'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertExpense(
        Expense(
            date: DateTime.now(),
            description: 'وجبة',
            amount: 25,
            category: 'طعام'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertExpense(
        Expense(
            date: DateTime.now(),
            description: 'مصروف عام',
            amount: 50,
        ),
        currentRole: UserRole.owner,
      );

      final distinct = await DatabaseHelper.instance.getDistinctExpenseCategories();
      expect(distinct, hasLength(2));
      expect(distinct, containsAll(['نقل', 'طعام']));
    });

    test('TC-EXP-07: updating expense category works', () async {
      final id = await DatabaseHelper.instance.insertExpense(
        Expense(
          date: DateTime.now(),
          description: 'مصروف',
          amount: 100,
          category: 'عام',
        ),
        currentRole: UserRole.owner,
      );

      final updated = Expense(
        id: id,
        date: DateTime.now(),
        description: 'مصروف',
        amount: 100,
        category: 'متنوع',
      );
      await DatabaseHelper.instance.updateExpense(updated);

      final all = await DatabaseHelper.instance.getAllExpenses();
      final loaded = all.firstWhere((e) => e.id == id);
      expect(loaded.category, 'متنوع');
    });
  });

  group('T2-2: Historical Data Compatibility', () {
    test('TC-HIST-01: legacy expense without category remains readable', () async {
      // Simulate a legacy expense row (no category column value)
      await testDb.rawInsert(
          'INSERT INTO expenses (date, description, amount) VALUES (?, ?, ?)',
          ['2026-01-01T00:00:00.000', 'مصروف قديم', 500]);

      final expenses = await DatabaseHelper.instance.getAllExpenses();
      expect(expenses, hasLength(1));
      expect(expenses.first.description, 'مصروف قديم');
      expect(expenses.first.amount, 500);
      expect(expenses.first.category, isNull);
    });

    test('TC-HIST-02: expense totals remain unchanged for legacy data', () async {
      await testDb.rawInsert(
          'INSERT INTO expenses (date, description, amount) VALUES (?, ?, ?)',
          ['2026-01-01T00:00:00.000', 'مصروف قديم 1', 100]);
      await testDb.rawInsert(
          'INSERT INTO expenses (date, description, amount) VALUES (?, ?, ?)',
          ['2026-02-01T00:00:00.000', 'مصروف قديم 2', 200]);

      final total = await DatabaseHelper.instance.getTotalExpenses();
      expect(total, 300);
    });

    test('TC-HIST-03: expense model fromMap handles null category', () {
      final map = {
        'id': 1,
        'date': '2026-01-01T00:00:00.000',
        'description': 'test',
        'amount': 100,
      };
      final expense = Expense.fromMap(map);
      expect(expense.category, isNull);
    });

    test('TC-HIST-04: expense model toMap includes null category', () {
      final expense = Expense(
        date: DateTime(2026, 1, 1),
        description: 'test',
        amount: 100,
      );
      final map = expense.toMap();
      expect(map['category'], isNull);
    });
  });

  group('T2-2: ExpenseCategory Model', () {
    test('TC-MOD-01: toMap/fromMap roundtrip', () {
      const category = ExpenseCategory(id: 1, name: 'نقل');
      final map = category.toMap();
      final fromMap = ExpenseCategory.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.name, 'نقل');
    });

    test('TC-MOD-02: copyWith works', () {
      const category = ExpenseCategory(id: 1, name: 'نقل');
      final renamed = category.copyWith(name: 'مواصلات');
      expect(renamed.id, 1);
      expect(renamed.name, 'مواصلات');
    });

    test('TC-MOD-03: normalize trims whitespace', () {
      expect(ExpenseCategory.normalize('  نقل  '), 'نقل');
      expect(ExpenseCategory.normalize('نقل'), 'نقل');
    });

    test('TC-MOD-04: isBlankName detects blank strings', () {
      expect(ExpenseCategory.isBlankName(''), true);
      expect(ExpenseCategory.isBlankName('   '), true);
      expect(ExpenseCategory.isBlankName('نقل'), false);
    });
  });

  group('T2-2: Backup/Restore with Categories', () {
    test('TC-BR-01: expense categories table exists in schema', () async {
      final tables = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'expense_categories'");
      expect(tables, hasLength(1));
    });

    test('TC-BR-02: expenses table has category column', () async {
      final columns = await testDb.rawQuery('PRAGMA table_info(expenses)');
      final categoryCol = columns.firstWhere((col) => col['name'] == 'category');
      expect(categoryCol['type'], 'TEXT');
    });

    test('TC-BR-03: expenses table has all v7 columns', () async {
      final columns = await testDb.rawQuery('PRAGMA table_info(expenses)');
      final names = columns.map((col) => col['name'] as String).toList();
      expect(names, containsAll(['id', 'date', 'description', 'amount', 'category']));
    });
  });

  group('T2-2: Expense Permissions', () {
    test('TC-PERM-01: unauthorized user cannot create category', () async {
      expect(
        () => DatabaseHelper.instance.insertExpenseCategory(
          ExpenseCategory(name: 'اختبار'),
          currentRole: UserRole.salesOnly,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('TC-PERM-02: unauthorized user cannot rename category', () async {
      final id = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'اختبار'),
        currentRole: UserRole.owner,
      );
      expect(
        () => DatabaseHelper.instance.renameExpenseCategory(id, 'جديد',
            currentRole: UserRole.salesOnly),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('TC-PERM-03: unauthorized user cannot delete category', () async {
      final id = await DatabaseHelper.instance.insertExpenseCategory(
        ExpenseCategory(name: 'اختبار'),
        currentRole: UserRole.owner,
      );
      expect(
        () => DatabaseHelper.instance.deleteExpenseCategory(id,
            currentRole: UserRole.salesOnly),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });
}
