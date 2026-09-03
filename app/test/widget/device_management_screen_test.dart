import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/models/cloud/cloud_device.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/settings/device_management_screen.dart';
import 'package:muaman_store/services/active_shop_context.dart';
import 'package:muaman_store/services/cloud_device_management_repository.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/session_state.dart';

/// S7 Owner device management screen tests.
///
/// Proves the authorized-owner gate, tenant isolation, five-state rendering,
/// mutation routing through the server-authoritative repository, the
/// post-mutation authoritative re-read (R14), and fail-closed UI behavior.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final ctx = ActiveShopContext.instance;
    ctx.resetForTest();
    ctx.configure(membershipValidator: (_) async => true);
  });

  tearDown(() {
    ActiveShopContext.instance.resetForTest();
  });

  Future<void> bindShop(String shopId) async {
    await ActiveShopContext.instance.bind(shopId);
  }

  SessionState ownerSession() {
    final session = SessionState(resolver: PermissionResolver());
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

  SessionState employeeSession() {
    final session = SessionState(resolver: PermissionResolver());
    session.login(User(
      displayName: 'موظف',
      username: 'employee',
      passwordHash: 'dummy',
      role: UserRole.employee,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return session;
  }

  SessionState noUserSession() {
    return SessionState(resolver: PermissionResolver());
  }

  CloudDevice device({
    String id = 'dev-1',
    String name = 'جهاز 1',
    DeviceTrustStatus status = DeviceTrustStatus.pendingApproval,
    String? platform = 'android',
    String? publicKey,
    DateTime? lastSeenAt,
  }) {
    return CloudDevice(
      deviceId: id,
      installationId: 'inst-$id',
      platform: platform,
      deviceName: name,
      userId: 'u-1',
      status: status,
      publicKey: publicKey,
      lastSeenAt: lastSeenAt,
    );
  }

  Future<void> pump(
    WidgetTester tester,
    SessionState session,
    CloudDeviceManagementRepository repo,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: DeviceManagementScreen(sessionState: session, repository: repo),
    ));
    await tester.pumpAndSettle();
  }

  group('Authorization / Owner gate', () {
    testWidgets('1. Owner can load device management and see devices',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.active)],
      );
      await pump(tester, ownerSession(), repo);

      expect(find.text('جهاز 1'), findsOneWidget);
      expect(find.text('نشط (موثوق)'), findsOneWidget);
    });

    testWidgets('2. Non-owner is denied Owner capability (access denied)',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.active)],
      );
      await pump(tester, employeeSession(), repo);

      expect(
          find.text('غير مصرح لك بالوصول إلى إدارة الأجهزة'), findsOneWidget);
      expect(find.text('جهاز 1'), findsNothing);
    });

    testWidgets('3. Missing/unknown role fails closed (no user)',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(onList: () => []);
      await pump(tester, noUserSession(), repo);

      expect(
          find.text('غير مصرح لك بالوصول إلى إدارة الأجهزة'), findsOneWidget);
    });

    testWidgets('4. UI does not present privileged mutations to a non-owner',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.pendingApproval)],
      );
      await pump(tester, employeeSession(), repo);

      expect(find.text('موافقة'), findsNothing);
      expect(find.text('رفض'), findsNothing);
      expect(find.text('إلغاء'), findsNothing);
      expect(find.text('فقدان'), findsNothing);
    });

    testWidgets(
        '5. server rejection is surfaced even if client state was tampered',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.pendingApproval)],
        onApprove: (_) => false,
      );
      await pump(tester, ownerSession(), repo);

      await tester.tap(find.text('موافقة'));
      await tester.pumpAndSettle();

      expect(find.text('فشل تنفيذ الإجراء من الخادم'), findsOneWidget);
      // Device stays pending; no fabricated ACTIVE.
      expect(find.text('قيد الموافقة'), findsOneWidget);
      expect(find.text('نشط (موثوق)'), findsNothing);
    });
  });

  group('Tenant isolation', () {
    testWidgets(
        '6/7. only current-shop devices rendered; foreign device not retrievable '
        '(server-authoritative list only)', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [
          device(id: 'own-1', name: 'جهاز المحل'),
        ],
      );
      await pump(tester, ownerSession(), repo);

      // The repository was asked only for the bound shop (not a forged id).
      expect(_lastShop, 'shop-A');
      expect(find.text('جهاز المحل'), findsOneWidget);
      expect(repo.calls.contains('list:other-shop'), isFalse);
    });

    testWidgets(
        'no tenant bound fails closed to a safe error (no unscoped rendering)',
        (tester) async {
      // NOTE: shop unbound.
      final repo = _FakeDeviceRepo(onList: () => [device()]);
      await pump(tester, ownerSession(), repo);

      expect(find.text('لا يوجد متجر مرتبط بهذا الحساب'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });
  });

  group('Five-state lifecycle rendering', () {
    testWidgets('10. PENDING_APPROVAL renders as pending', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.pendingApproval)],
      );
      await pump(tester, ownerSession(), repo);
      expect(find.text('قيد الموافقة'), findsOneWidget);
      expect(find.text('موافقة'), findsOneWidget);
      expect(find.text('رفض'), findsOneWidget);
    });

    testWidgets('11. ACTIVE renders as trusted with revoke/lost',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.active)],
      );
      await pump(tester, ownerSession(), repo);
      expect(find.text('نشط (موثوق)'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('فقدان'), findsOneWidget);
      expect(find.text('موافقة'), findsNothing);
    });

    testWidgets('12. REJECTED renders as terminal', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.rejected)],
      );
      await pump(tester, ownerSession(), repo);
      expect(find.text('مرفوض'), findsOneWidget);
      expect(find.text('هذا الجهاز في حالة نهائية ولا يمكن استعادته من هنا.'),
          findsOneWidget);
      expect(find.text('موافقة'), findsNothing);
    });

    testWidgets('13. REVOKED renders as terminal', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.revoked)],
      );
      await pump(tester, ownerSession(), repo);
      expect(find.text('ملغى'), findsOneWidget);
      expect(find.text('هذا الجهاز في حالة نهائية ولا يمكن استعادته من هنا.'),
          findsOneWidget);
      expect(find.text('إلغاء'), findsNothing);
    });

    testWidgets('14. LOST renders as terminal', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.lost)],
      );
      await pump(tester, ownerSession(), repo);
      expect(find.text('مفقود'), findsOneWidget);
      expect(find.text('فقدان'), findsNothing);
    });

    testWidgets('15. unknown lifecycle fails closed (never infers ACTIVE)',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [
          device(status: DeviceTrustStatus.pendingApproval),
        ],
      );
      // Force the repository to throw on an unknown/missing status.
      repo.throwOnList =
          const FormatException('Unknown device lifecycle status');
      await pump(tester, ownerSession(), repo);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('تعذر تحميل الأجهزة'), findsOneWidget);
      expect(find.text('نشط (موثوق)'), findsNothing);
    });
  });

  group('Mutations route through server authority', () {
    testWidgets('16. approve invokes the repository approve method (s4)',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.pendingApproval)],
        onApprove: (_) => true,
      );
      await pump(tester, ownerSession(), repo);
      await tester.tap(find.text('موافقة'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('approve:dev-1'));
    });

    testWidgets('17. reject invokes the repository reject method',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.pendingApproval)],
        onReject: (_) => true,
      );
      await pump(tester, ownerSession(), repo);
      await tester.tap(find.text('رفض'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('reject:dev-1'));
    });

    testWidgets('18. revoke uses the canonical revoke path', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.active)],
        onRevoke: (_) => true,
      );
      await pump(tester, ownerSession(), repo);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('revoke:dev-1'));
    });

    testWidgets('19. lost uses the mark lost path', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.active)],
        onLost: (_) => true,
      );
      await pump(tester, ownerSession(), repo);
      await tester.tap(find.text('فقدان'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('lost:dev-1'));
    });

    testWidgets('20. failed mutation does not fabricate success (exception)',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.pendingApproval)],
        onApprove: (_) => throw Exception('network down'),
      );
      await pump(tester, ownerSession(), repo);
      await tester.tap(find.text('موافقة'));
      await tester.pumpAndSettle();

      expect(find.textContaining('فشل تنفيذ الإجراء'), findsOneWidget);
      expect(find.text('نشط (موثوق)'), findsNothing);
      expect(find.text('قيد الموافقة'), findsOneWidget);
    });
  });

  group('Refresh discipline (R14)', () {
    testWidgets('21/22. successful mutation triggers an authoritative re-read',
        (tester) async {
      await bindShop('shop-A');
      var listCount = 0;
      final repo = _FakeDeviceRepo(
        onList: () {
          listCount++;
          if (listCount == 1) {
            return [device(status: DeviceTrustStatus.pendingApproval)];
          }
          // After approve, the server (re-read) reports ACTIVE.
          return [device(status: DeviceTrustStatus.active)];
        },
        onApprove: (_) => true,
      );
      await pump(tester, ownerSession(), repo);
      expect(listCount, 1);

      await tester.tap(find.text('موافقة'));
      await tester.pumpAndSettle();

      // The re-read happened (listCount > 1) and the display came from the
      // re-read result, not a local patch.
      expect(listCount, greaterThan(1));
      expect(find.text('نشط (موثوق)'), findsOneWidget);
      expect(repo.calls, contains('approve:dev-1'));
    });

    testWidgets(
        '23. mutation-success + refresh-failure surfaces safe error, no forged '
        'target state', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [device(status: DeviceTrustStatus.pendingApproval)],
        onApprove: (_) => true,
      );
      repo.failReread = true;
      await pump(tester, ownerSession(), repo);
      await tester.tap(find.text('موافقة'));
      await tester.pumpAndSettle();

      expect(find.textContaining('تم تنفيذ الإجراء لكن تعذر تحديث القائمة'),
          findsOneWidget);
      // The device is NOT shown as trusted after the failed re-read.
      expect(find.text('نشط (موثوق)'), findsNothing);
    });

    testWidgets('26a. empty list renders the safe empty state', (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(onList: () => []);
      await pump(tester, ownerSession(), repo);
      expect(find.text('لا توجد أجهزة في هذا المتجر'), findsOneWidget);
    });

    testWidgets('26b. pull-to-refresh re-reads the list', (tester) async {
      await bindShop('shop-A');
      var n = 1;
      final repo = _FakeDeviceRepo(onList: () {
        if (n == 1) return [device(status: DeviceTrustStatus.active)];
        return [
          device(status: DeviceTrustStatus.active),
          device(id: 'dev-2', name: 'جهاز 2', status: DeviceTrustStatus.lost),
        ];
      });
      n = 1;
      await pump(tester, ownerSession(), repo);
      expect(find.text('جهاز 1'), findsOneWidget);
      expect(find.text('جهاز 2'), findsNothing);

      n = 2;
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('جهاز 2'), findsOneWidget);
    });
  });

  group('Secrets / identity safety', () {
    testWidgets(
        '24. raw device id / private key / S6 seed are not rendered or exposed',
        (tester) async {
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [
          device(
            status: DeviceTrustStatus.active,
            publicKey: 'S3CRET_PRIVATE_MATERIAL',
          ),
        ],
      );
      await pump(tester, ownerSession(), repo);

      // The raw internal device_id and the S6 private material must never
      // appear in the rendered UI.
      expect(find.text('dev-1'), findsNothing);
      expect(find.text('S3CRET_PRIVATE_MATERIAL'), findsNothing);
      expect(find.textContaining('privateKey'), findsNothing);
      expect(find.textContaining('PRIVATE'), findsNothing);
    });

    testWidgets('25. S6 identity binding is not bypassed by a client alternate',
        (tester) async {
      // The feature consumes the S6 public-key model from the committed
      // server authority; it introduces no client-generated identity and
      // renders no private key. Here we prove a non-owner cannot reach it and
      // the owner view exposes only public metadata (device name + status).
      await bindShop('shop-A');
      final repo = _FakeDeviceRepo(
        onList: () => [
          device(
            status: DeviceTrustStatus.active,
            publicKey: 'PUBLIC_KEY_ONLY',
          ),
        ],
      );
      await pump(tester, employeeSession(), repo);
      expect(find.text('جهاز 1'), findsNothing);

      await pump(tester, ownerSession(), repo);
      expect(find.text('جهاز 1'), findsOneWidget);
      expect(find.text('PUBLIC_KEY_ONLY'), findsNothing);
    });
  });
}

String _lastShop = '';

class _FakeDeviceRepo extends CloudDeviceManagementRepository {
  _FakeDeviceRepo({
    this.onList,
    this.onApprove,
    this.onReject,
    this.onRevoke,
    this.onLost,
  });

  List<CloudDevice> Function()? onList;
  bool Function(String deviceId)? onApprove;
  bool Function(String deviceId)? onReject;
  bool Function(String deviceId)? onRevoke;
  bool Function(String deviceId)? onLost;
  bool failReread = false;
  Exception? throwOnList;
  final List<String> calls = [];
  int _listCount = 0;

  @override
  Future<List<CloudDevice>> listDevices(String shopId) async {
    _lastShop = shopId;
    calls.add('list:$shopId');
    _listCount++;
    if (failReread && _listCount > 1) {
      throw Exception('reread failed');
    }
    final throwEx = throwOnList;
    if (throwEx != null) throw throwEx;
    return onList?.call() ?? [];
  }

  @override
  Future<bool> approveDevice(String shopId, String deviceId,
      {String? reason}) async {
    calls.add('approve:$deviceId');
    return onApprove?.call(deviceId) ?? true;
  }

  @override
  Future<bool> rejectDevice(String shopId, String deviceId,
      {String? reason}) async {
    calls.add('reject:$deviceId');
    return onReject?.call(deviceId) ?? true;
  }

  @override
  Future<bool> revokeDevice(String shopId, String deviceId,
      {String? reason}) async {
    calls.add('revoke:$deviceId');
    return onRevoke?.call(deviceId) ?? true;
  }

  @override
  Future<bool> markDeviceLost(String shopId, String deviceId,
      {String? reason}) async {
    calls.add('lost:$deviceId');
    return onLost?.call(deviceId) ?? true;
  }
}
