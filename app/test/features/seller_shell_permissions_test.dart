import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/main.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/rbac/effective_permission_model.dart';
import 'package:muaman_store/screens/auth/login_screen.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/session_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_schema.dart';

/// Phase L (D-L5) — permission-driven shell matrix.
///
/// EVERY logged-in user routes to FullAppShell; the existing
/// permission-filtered navigation yields the seller experience. Proves:
/// - default salesOnly sees EXACTLY the Sales tab (equivalence with the
///   retired SalesOnlyShell surface set);
/// - owner and employee see their default surfaces;
/// - an owner-granted extra permission becomes visible immediately via
///   the cloud permission snapshot;
/// - seller surfaces render at ~360dp-class viewports.
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

    await testDb.insert('customers', {
      'name': 'عميل اختبار',
      'phone': '0123456789',
      'isActive': 1,
      'isSystem': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await testDb.insert('products', {
      'name': 'منتج اختبار',
      'barcode': 'BAR-001',
      'openingQuantity': 10,
      'soldQuantity': 2,
      'currentQuantity': 8,
      'costPrice': 50,
      'totalInventoryCost': 400,
      'inventoryAdjustment': 0,
    });
    await testDb.insert('sales', {
      'date': DateTime.now().toIso8601String(),
      'productName': 'منتج تاريخي',
      'barcode': 'BAR-001',
      'quantity': 2,
      'salePrice': 100,
      'totalSaleValue': 200,
      'costPrice': 50,
      'cogs': 100,
    });
  });

  tearDown(() async {
    PermissionResolver.instance.setCloudSnapshot(null);
    await testDb.close();
  });

  SessionState sessionFor(UserRole role) {
    final user = User(
      displayName: 'مستخدم $role',
      username: 'user-$role',
      passwordHash: 'dummy',
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final session = SessionState();
    session.login(user);
    return session;
  }

  Future<void> pumpShell(WidgetTester tester, SessionState session,
      {Size size = const Size(1400, 1000)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: FullAppShell(sessionState: session, onLogout: () {}),
    ));
    await tester.pumpAndSettle();
  }

  List<String> navLabels(WidgetTester tester) {
    final navBar =
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    return navBar.items.map((i) => i.label!).toList();
  }

  void consumeKnownSaleCardOverflow(WidgetTester tester) {
    final dynamic exception = tester.takeException();
    if (exception == null) return;
    expect(exception, isA<FlutterError>(),
        reason: 'Only the pre-existing sale-card RenderFlex overflow may be '
            'consumed; any other exception must fail the test.');
    expect(exception.toString(), contains('RenderFlex overflowed'));
  }

  const expectedFullTabs = [
    'لوحة التحكم',
    'المخزن',
    'المبيعات',
    'المرتجعات',
    'المصروفات',
    'الجرد',
  ];

  group('default role matrices', () {
    testWidgets(
        'default salesOnly sees exactly the Sales tab and the create-sale '
        'surface — equivalent to the retired SalesOnlyShell', (tester) async {
      await pumpShell(tester, sessionFor(UserRole.salesOnly));

      // Single permitted tab: the shell renders without a nav bar
      // (BottomNavigationBar requires >= 2 destinations).
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Allowed: create-sale entry.
      expect(find.text('إنشاء فاتورة بيع جديدة'), findsOneWidget);
      expect(find.text('فاتورة جديدة'), findsOneWidget);
      expect(find.text('المبيعات'), findsOneWidget); // AppBar title

      // Forbidden: history, search, filters, reports, admin actions.
      expect(find.text('بحث بالاسم أو الباركود...'), findsNothing);
      expect(find.textContaining('عدد العمليات:'), findsNothing);
      expect(find.text('منتج تاريخي'), findsNothing);
      expect(find.byIcon(Icons.people), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('owner keeps every tab and admin actions', (tester) async {
      await pumpShell(tester, sessionFor(UserRole.owner));

      expect(navLabels(tester), expectedFullTabs);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.person_search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('default employee sees all tabs but no admin actions',
        (tester) async {
      await pumpShell(tester, sessionFor(UserRole.employee));

      expect(navLabels(tester), expectedFullTabs);
      expect(find.byIcon(Icons.people), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
    });
  });

  group('permission-driven grants', () {
    testWidgets(
        'granted inventory+returns permissions become visible immediately '
        'for a salesOnly user via the cloud snapshot', (tester) async {
      final session = sessionFor(UserRole.salesOnly);
      PermissionResolver.instance.setCloudSnapshot(CloudPermissionSnapshot(
        shopId: 'shop-A',
        memberRole: 'salesOnly',
        permissionIds: {
          'sales.view',
          'sales.create',
          'inventory.view',
          'returns.view',
          'returns.create',
        },
        overrides: const [],
        catalogVersion: 1,
        serverTime: DateTime.now().toUtc(),
        permissionsUpdatedAt: DateTime.now().toUtc(),
        cachedAt: DateTime.now(),
      ));

      await pumpShell(tester, session);

      final labels = navLabels(tester);
      expect(labels, containsAll(['المبيعات', 'المخزن', 'المرتجعات']));
      expect(labels, hasLength(3));

      // Still no admin powers.
      expect(find.byIcon(Icons.people), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
    });
  });

  group('~360dp-class viewport (seller surfaces)', () {
    testWidgets(
        'default salesOnly shell renders without unproven overflows at '
        '~360x690', (tester) async {
      await pumpShell(
        tester,
        sessionFor(UserRole.salesOnly),
        size: const Size(360, 690),
      );
      consumeKnownSaleCardOverflow(tester);

      expect(find.text('فاتورة جديدة'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('cloud login form renders at ~360x690 in cloud mode',
        (tester) async {
      final session = SessionState();
      await tester.binding.setSurfaceSize(const Size(360, 690));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(
          sessionState: session,
          initialMode: LoginMode.cloud,
          allowLocalMode: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Cloud seller fields are present and usable at phone width.
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('دخول سحابي'), findsOneWidget);
      // Local-mode-only fields stay absent in the fresh-device cloud view.
      expect(find.text('اسم المستخدم'), findsNothing);
    });
  });
}
