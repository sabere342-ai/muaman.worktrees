import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/customer.dart';
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

  group('T4-1: Customer CRUD', () {
    test('TC-CUST-01: owner can insert a customer', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(
          name: 'عميل تجريبي',
          phone: '0123456789',
          address: 'شارع التحرير',
          notes: 'ملاحظات',
        ),
        currentRole: UserRole.owner,
      );

      expect(id, greaterThan(0));

      final customers = await DatabaseHelper.instance.getAllCustomers();
      expect(customers, hasLength(1));
      expect(customers.first.name, 'عميل تجريبي');
      expect(customers.first.phone, '0123456789');
      expect(customers.first.address, 'شارع التحرير');
      expect(customers.first.notes, 'ملاحظات');
      expect(customers.first.isActive, isTrue);
      expect(customers.first.isSystem, isFalse);
    });

    test('TC-CUST-02: salesOnly can insert a customer', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل مبيعات', phone: '0555123456'),
        currentRole: UserRole.salesOnly,
      );

      expect(id, greaterThan(0));
      final customers = await DatabaseHelper.instance.getAllCustomers();
      expect(customers, hasLength(1));
      expect(customers.first.name, 'عميل مبيعات');
    });

    test('TC-CUST-03: insertCustomer requires currentRole (null throws)',
        () async {
      expect(
        () => DatabaseHelper.instance.insertCustomer(
          Customer(name: 'عميل بدون دور'),
          currentRole: null,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('TC-CUST-04: empty name throws ArgumentError', () async {
      expect(
        () => DatabaseHelper.instance.insertCustomer(
          Customer(name: ''),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CUST-05: whitespace-only name throws ArgumentError', () async {
      expect(
        () => DatabaseHelper.instance.insertCustomer(
          Customer(name: '   '),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'TC-CUST-06: getAllCustomers returns sorted by system first, then name',
        () async {
      await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'زبون'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'أحمد'),
        currentRole: UserRole.owner,
      );

      final customers = await DatabaseHelper.instance.getAllCustomers();
      expect(customers, hasLength(2));
      expect(customers.first.name, 'أحمد');
      expect(customers.last.name, 'زبون');
    });

    test('TC-CUST-07: getActiveCustomers excludes archived', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل نشط'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل أرشيف'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance
          .archiveCustomer(id, currentRole: UserRole.owner);

      final active = await DatabaseHelper.instance.getActiveCustomers();
      expect(active, hasLength(1));
      expect(active.first.name, 'عميل أرشيف');
    });

    test('TC-CUST-08: getCustomerById returns correct customer', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل محدد', phone: '0500111222'),
        currentRole: UserRole.owner,
      );

      final customer = await DatabaseHelper.instance.getCustomerById(id);
      expect(customer, isNotNull);
      expect(customer!.name, 'عميل محدد');
      expect(customer.phone, '0500111222');
    });

    test('TC-CUST-09: getCustomerById returns null for nonexistent id',
        () async {
      final customer = await DatabaseHelper.instance.getCustomerById(9999);
      expect(customer, isNull);
    });

    test('TC-CUST-10: searchCustomers finds by name', () async {
      await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'محمد علي'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'أحمد حسن'),
        currentRole: UserRole.owner,
      );

      final results = await DatabaseHelper.instance.searchCustomers('محمد');
      expect(results, hasLength(1));
      expect(results.first.name, 'محمد علي');
    });

    test('TC-CUST-11: searchCustomers finds by phone', () async {
      await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل', phone: '0555987654'),
        currentRole: UserRole.owner,
      );

      final results = await DatabaseHelper.instance.searchCustomers('0555987');
      expect(results, hasLength(1));
      expect(results.first.phone, '0555987654');
    });

    test('TC-CUST-12: searchCustomers excludes archived', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'محذوف'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance
          .archiveCustomer(id, currentRole: UserRole.owner);

      final results = await DatabaseHelper.instance.searchCustomers('محذوف');
      expect(results, isEmpty);
    });

    test('TC-CUST-13: updateCustomer modifies fields', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'اسم قديم'),
        currentRole: UserRole.owner,
      );

      final original = await DatabaseHelper.instance.getCustomerById(id);
      await DatabaseHelper.instance.updateCustomer(
        original!.copyWith(name: 'اسم جديد', phone: '0500123456'),
        currentRole: UserRole.owner,
      );

      final updated = await DatabaseHelper.instance.getCustomerById(id);
      expect(updated!.name, 'اسم جديد');
      expect(updated.phone, '0500123456');
    });

    test('TC-CUST-14: updateCustomer with empty name throws', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل'),
        currentRole: UserRole.owner,
      );
      final original = await DatabaseHelper.instance.getCustomerById(id);

      expect(
        () => DatabaseHelper.instance.updateCustomer(
          original!.copyWith(name: ''),
          currentRole: UserRole.owner,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TC-CUST-15: archiveCustomer sets isActive to false', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'للأرشفة'),
        currentRole: UserRole.owner,
      );

      await DatabaseHelper.instance
          .archiveCustomer(id, currentRole: UserRole.owner);

      final customer = await DatabaseHelper.instance.getCustomerById(id);
      expect(customer!.isActive, isFalse);
    });

    test('TC-CUST-16: archiveCustomer throws for system customer', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل نقدي', isSystem: true),
        currentRole: UserRole.owner,
      );

      expect(
        () => DatabaseHelper.instance
            .archiveCustomer(id, currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );
    });

    test('TC-CUST-17: archiveCustomer throws for nonexistent id', () async {
      expect(
        () => DatabaseHelper.instance
            .archiveCustomer(9999, currentRole: UserRole.owner),
        throwsA(isA<StateError>()),
      );
    });

    test('TC-CUST-18: reactivateCustomer sets isActive to true', () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'معاد'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance
          .archiveCustomer(id, currentRole: UserRole.owner);

      await DatabaseHelper.instance
          .reactivateCustomer(id, currentRole: UserRole.owner);

      final customer = await DatabaseHelper.instance.getCustomerById(id);
      expect(customer!.isActive, isTrue);
    });

    test('TC-CUST-19: inactive customer excluded from getActiveCustomers',
        () async {
      final id = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'غير نشط'),
        currentRole: UserRole.owner,
      );
      await DatabaseHelper.instance
          .archiveCustomer(id, currentRole: UserRole.owner);

      final active = await DatabaseHelper.instance.getActiveCustomers();
      expect(active, isEmpty);
    });
  });

  group('T4-1: Invoice-Customer linkage', () {
    test('TC-INV-CUST-01: invoice with customerId links correctly', () async {
      final customerId = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل فاتورة'),
        currentRole: UserRole.owner,
      );

      final invoiceId = await testDb.insert('invoices', {
        'invoiceNumber': 'INV-T41-001',
        'date': DateTime.now().toIso8601String(),
        'customerName': 'عميل فاتورة',
        'paymentMethod': 'cash',
        'totalAmount': 250.0,
        'totalItems': 2,
        'createdAt': DateTime.now().toIso8601String(),
        'customerId': customerId,
      });

      expect(invoiceId, greaterThan(0));

      final invoices = await testDb
          .query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
      expect(invoices, hasLength(1));
      expect(invoices.first['customerId'], customerId);
      expect(invoices.first['customerName'], 'عميل فاتورة');
    });

    test('TC-INV-CUST-02: invoice without customerId still works', () async {
      final invoiceId = await testDb.insert('invoices', {
        'invoiceNumber': 'INV-T41-002',
        'date': DateTime.now().toIso8601String(),
        'customerName': 'عميل نقدي',
        'paymentMethod': 'cash',
        'totalAmount': 100.0,
        'totalItems': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'customerId': null,
      });

      expect(invoiceId, greaterThan(0));

      final invoices = await testDb
          .query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
      expect(invoices.first['customerId'], isNull);
    });

    test('TC-INV-CUST-03: archived customer still referenced on old invoices',
        () async {
      final customerId = await DatabaseHelper.instance.insertCustomer(
        Customer(name: 'عميل قديم'),
        currentRole: UserRole.owner,
      );

      await testDb.insert('invoices', {
        'invoiceNumber': 'INV-T41-003',
        'date': DateTime.now().toIso8601String(),
        'customerName': 'عميل قديم',
        'paymentMethod': 'cash',
        'totalAmount': 300.0,
        'totalItems': 3,
        'createdAt': DateTime.now().toIso8601String(),
        'customerId': customerId,
      });

      await DatabaseHelper.instance
          .archiveCustomer(customerId, currentRole: UserRole.owner);

      final invoices = await testDb
          .query('invoices', where: 'customerId = ?', whereArgs: [customerId]);
      expect(invoices, hasLength(1));
      expect(invoices.first['customerName'], 'عميل قديم');
    });
  });

  group('T4-1: Licensing gate on customer writes', () {
    test('TC-LIC-CUST-01: insertCustomer respects licensing enforcement',
        () async {
      bool licensingCalled = false;
      DatabaseHelper.setLicensingEnforcer(() async {
        licensingCalled = true;
      });

      try {
        await DatabaseHelper.instance.insertCustomer(
          Customer(name: 'عميل ترخيص'),
          currentRole: UserRole.owner,
        );
        expect(licensingCalled, isTrue);
      } finally {
        DatabaseHelper.clearLicensingEnforcer();
      }
    });

    test('TC-LIC-CUST-02: updateCustomer respects licensing enforcement',
        () async {
      bool licensingCalled = false;
      DatabaseHelper.setLicensingEnforcer(() async {
        licensingCalled = true;
      });

      try {
        final id = await DatabaseHelper.instance.insertCustomer(
          Customer(name: 'للتحديث'),
          currentRole: UserRole.owner,
        );
        licensingCalled = false;

        final customer = await DatabaseHelper.instance.getCustomerById(id);
        await DatabaseHelper.instance.updateCustomer(
          customer!.copyWith(name: 'محدث'),
          currentRole: UserRole.owner,
        );
        expect(licensingCalled, isTrue);
      } finally {
        DatabaseHelper.clearLicensingEnforcer();
      }
    });

    test('TC-LIC-CUST-03: archiveCustomer respects licensing enforcement',
        () async {
      bool licensingCalled = false;
      DatabaseHelper.setLicensingEnforcer(() async {
        licensingCalled = true;
      });

      try {
        final id = await DatabaseHelper.instance.insertCustomer(
          Customer(name: 'للأرشفة'),
          currentRole: UserRole.owner,
        );
        licensingCalled = false;

        await DatabaseHelper.instance
            .archiveCustomer(id, currentRole: UserRole.owner);
        expect(licensingCalled, isTrue);
      } finally {
        DatabaseHelper.clearLicensingEnforcer();
      }
    });

    test('TC-LIC-CUST-04: reactivateCustomer respects licensing enforcement',
        () async {
      bool licensingCalled = false;
      DatabaseHelper.setLicensingEnforcer(() async {
        licensingCalled = true;
      });

      try {
        final id = await DatabaseHelper.instance.insertCustomer(
          Customer(name: 'معاد'),
          currentRole: UserRole.owner,
        );
        await DatabaseHelper.instance
            .archiveCustomer(id, currentRole: UserRole.owner);
        licensingCalled = false;

        await DatabaseHelper.instance
            .reactivateCustomer(id, currentRole: UserRole.owner);
        expect(licensingCalled, isTrue);
      } finally {
        DatabaseHelper.clearLicensingEnforcer();
      }
    });
  });
}
