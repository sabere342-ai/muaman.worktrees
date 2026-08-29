import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/admin/conflict_review_screen.dart';
import 'package:muaman_store/sync/conflict_audit_record.dart';
import 'package:muaman_store/sync/conflict_audit_repository.dart';
import 'package:muaman_store/sync/sync_status.dart';

/// Phase M M-I08 acceptance suite (plan §22, §28 M-I08, §29-J).
///
/// Proves:
///   - owner-only resolution: employee/salesOnly get read-only view
///     (fail closed on null role too),
///   - server-side permission re-check gates every resolution action,
///   - resolution notes/audit trail: RESOLVED carries method OWNER + note,
///   - failed re-check/apply returns the record to REVIEW_REQUIRED
///     (never stuck in RESOLUTION_PENDING),
///   - Arabic RTL rendering.
void main() {
  sqfliteFfiInit();

  late Database db;
  late ConflictAuditRepository auditRepo;

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE conflict_audit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        entity_uuid TEXT,
        product_name TEXT,
        product_barcode TEXT,
        operation TEXT NOT NULL,
        local_before TEXT,
        local_after TEXT,
        server_before TEXT,
        server_after TEXT,
        related_event_ids TEXT,
        local_version INTEGER,
        server_version INTEGER,
        idempotency_key TEXT,
        detected_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'REVIEW_REQUIRED',
        resolution_method TEXT,
        resolved_by_user TEXT,
        resolved_at TEXT,
        resolution_note TEXT,
        resulting_adjustment_id INTEGER
      )
    ''');
    auditRepo = ConflictAuditRepository(db);
    await auditRepo.recordConflict(
      shopId: 'shop-1',
      entityType: 'product',
      entityId: 7,
      operation: 'UPDATE',
      productBarcode: 'REV-1',
      localBefore: {'name': 'محلي'},
      serverBefore: {'name': 'خادم'},
      idempotencyKey: 'review-key-1',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    UserRole? role,
    Future<bool> Function({required String action})? serverRecheck,
    Future<bool> Function(ConflictAuditRecord record, String note)? onResolve,
  }) async {
    final effectiveRecheck = role == UserRole.owner
        ? (serverRecheck ?? ({required String action}) async => true)
        : null;
    await tester.pumpWidget(MaterialApp(
      home: ConflictReviewScreen(
        auditRepository: auditRepo,
        currentRole: role,
        serverPermissionRecheck: effectiveRecheck,
        onResolve: onResolve ?? (record, note) async => true,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('renders open conflicts RTL with review banner (owner view)',
      (tester) async {
    await pumpScreen(tester, role: UserRole.owner);

    expect(find.text('مراجعة تعارضات المزامنة'), findsOneWidget);
    // The screen's own Directionality wrapper forces RTL regardless of the
    // ambient app locale.
    final dir = tester.widget<Directionality>(
      find.byType(Directionality).last,
    );
    expect(dir.textDirection, TextDirection.rtl);
    expect(find.textContaining('product #7'), findsOneWidget);
    expect(find.text('حل'), findsOneWidget);
  });

  testWidgets('employee is read-only: no resolve button, banner shown',
      (tester) async {
    var resolveCalled = false;
    await pumpScreen(
      tester,
      role: UserRole.employee,
      onResolve: (record, note) async {
        resolveCalled = true;
        return true;
      },
    );

    expect(find.text('وضع العرض فقط — حل التعارضات متاح للمالك فقط'),
        findsOneWidget);
    expect(find.text('حل'), findsNothing);
    expect(resolveCalled, isFalse);
  });

  testWidgets('salesOnly is read-only (fail closed)', (tester) async {
    await pumpScreen(tester, role: UserRole.salesOnly);

    expect(find.text('حل'), findsNothing);
  });

  testWidgets('null session role fails closed', (tester) async {
    await pumpScreen(tester, role: null);

    expect(find.text('وضع العرض فقط — حل التعارضات متاح للمالك فقط'),
        findsOneWidget);
    expect(find.text('حل'), findsNothing);
  });

  testWidgets(
      'owner resolution: server re-check passes → onResolve runs → '
      'audit RESOLVED with OWNER method and note', (tester) async {
    var recheckActions = <String>[];
    var resolvedNote = '';
    await pumpScreen(
      tester,
      role: UserRole.owner,
      serverRecheck: ({required action}) async {
        recheckActions.add(action);
        return true;
      },
      onResolve: (record, note) async {
        resolvedNote = note;
        return true;
      },
    );

    await tester.tap(find.text('حل'));
    await tester.pumpAndSettle();

    // Evidence sheet visible; enter a resolution note and apply.
    expect(find.textContaining('حل التعارض'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'اعتماد قيمة الخادم');
    await tester.tap(find.text('تطبيق القرار'));
    await tester.pumpAndSettle();

    expect(recheckActions, ['apply_resolved'],
        reason: 'server-side permission re-check must run before applying');
    expect(resolvedNote, 'اعتماد قيمة الخادم');

    final open = await auditRepo.getOpenConflicts();
    expect(open, isEmpty, reason: 'conflict must be terminally resolved');

    final all = await auditRepo.getByShop('shop-1');
    expect(all.first.status, ConflictLifecycleStatus.RESOLVED);
    expect(all.first.resolutionMethod, ConflictResolutionMethod.OWNER);
    expect(all.first.resolutionNote, 'اعتماد قيمة الخادم');
    expect(all.first.resolvedByUser, 'owner');
  });

  testWidgets(
      'server re-check DENIAL fails closed: onResolve never runs, '
      'record returns to REVIEW_REQUIRED', (tester) async {
    var applyCalled = false;
    await pumpScreen(
      tester,
      role: UserRole.owner,
      serverRecheck: ({required action}) async => false,
      onResolve: (record, note) async {
        applyCalled = true;
        return true;
      },
    );

    await tester.tap(find.text('حل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق القرار'));
    await tester.pumpAndSettle();

    expect(applyCalled, isFalse,
        reason: 'denied permission must prevent any local apply');
    expect(find.text('فشل التحقق من الصلاحية على الخادم'), findsOneWidget);

    final open = await auditRepo.getOpenConflicts();
    expect(open, hasLength(1));
    expect(open.first.status, ConflictLifecycleStatus.REVIEW_REQUIRED,
        reason: 'failed attempt stays restartable, not stuck PENDING');
  });

  testWidgets(
      'missing cloud connection (no re-check seam) fails closed even '
      'for the owner', (tester) async {
    var applyCalled = false;
    await tester.pumpWidget(MaterialApp(
      home: ConflictReviewScreen(
        auditRepository: auditRepo,
        currentRole: UserRole.owner,
        serverPermissionRecheck: null,
        onResolve: (record, note) async {
          applyCalled = true;
          return true;
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق القرار'));
    await tester.pumpAndSettle();

    expect(applyCalled, isFalse);
    final open = await auditRepo.getOpenConflicts();
    expect(open.first.status, ConflictLifecycleStatus.REVIEW_REQUIRED);
  });
}
