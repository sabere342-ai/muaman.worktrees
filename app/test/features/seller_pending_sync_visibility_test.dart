import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/cloud_session.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/sales/sales_screen.dart';
import 'package:muaman_store/services/session_state.dart';

import '../helpers/test_schema.dart';

/// Phase P (plan §F.6 / WS-5): pending-sync status is VISIBLE to the seller.
///
/// A salesOnly seller is exactly the offline-sales user: their screen never
/// reaches settings (owner/employee only), so WS-5 wires the live sync
/// indicator (counters published by the WS-1 runtime) into the seller app
/// bar. It appears only when the device is linked to a cloud tenant; a purely
/// local seller sees nothing.
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

  SessionState sellerSession({CloudSession? cloudSession}) {
    final user = User(
      displayName: 'بائع',
      username: 'seller',
      passwordHash: 'dummy',
      role: UserRole.salesOnly,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final session = SessionState();
    session.login(user);
    if (cloudSession != null) {
      session.setCloudSession(cloudSession);
    }
    return session;
  }

  CloudSession activeCloud() => const CloudSession(
        userId: 'cloud-user-1',
        activeShopId: 'shop-1',
        membershipRole: 'salesOnly',
        membershipStatus: 'ACTIVE',
      );

  Future<void> setSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('cloud-linked seller sees the pending count badge',
      (tester) async {
    await setSurface(tester);
    final session = sellerSession(cloudSession: activeCloud());
    session.updateSyncStatus(pendingCount: 3);

    await tester.pumpWidget(
      MaterialApp(
        home:
            SalesScreen(showAppBar: true, showFab: true, sessionState: session),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إنشاء فاتورة بيع جديدة'), findsOneWidget);
    expect(find.text('3'), findsOneWidget,
        reason: 'pending count must be visible to the offline seller');
  });

  testWidgets('local-only seller sees no sync indicator', (tester) async {
    await setSurface(tester);
    final session = sellerSession();
    session.updateSyncStatus(pendingCount: 3);

    await tester.pumpWidget(
      MaterialApp(
        home:
            SalesScreen(showAppBar: true, showFab: true, sessionState: session),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إنشاء فاتورة بيع جديدة'), findsOneWidget);
    expect(find.text('3'), findsNothing,
        reason: 'no cloud tenant → no pending-sync indicator');
  });

  testWidgets('indicator re-renders when the runtime publishes new counters',
      (tester) async {
    await setSurface(tester);
    final session = sellerSession(cloudSession: activeCloud());
    await tester.pumpWidget(
      MaterialApp(
        home:
            SalesScreen(showAppBar: true, showFab: true, sessionState: session),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);

    session.updateSyncStatus(pendingCount: 2);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });
}
