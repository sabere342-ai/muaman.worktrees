import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/cloud_session.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/settings_screen.dart';
import 'package:muaman_store/services/cloud_auth_service.dart';
import 'package:muaman_store/services/identity_linker.dart';
import 'package:muaman_store/services/permission_resolver.dart';
import 'package:muaman_store/services/session_state.dart';
import 'package:muaman_store/services/shop_profile_service.dart';

import '../helpers/test_schema.dart';

const _cloudLinkButtonKey = ValueKey('cloud-link-button');
const _cloudLinkEmailKey = ValueKey('cloud-link-email');
const _cloudLinkPasswordKey = ValueKey('cloud-link-password');
const _cloudLinkShopNameKey = ValueKey('cloud-link-shop-name');
const _cloudLinkSubmitKey = ValueKey('cloud-link-submit');

const _cloudIdentityKeys = ['shopProfile.cloudUuid', 'cloud.auth.email'];

void main() {
  sqfliteFfiInit();

  late Database testDb;
  late SessionState ownerSession;
  late SessionState salesOnlySession;

  setUp(() async {
    testDb =
        await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await createTestSchema(testDb);
    DatabaseHelper.setTestDatabase(testDb);
    ShopProfileService.instance.invalidate();
    PermissionResolver.instance.invalidate();

    final now = DateTime.now().toIso8601String();
    await testDb.insert('users', {
      'displayName': 'المالك',
      'username': 'owner',
      'passwordHash': 'x',
      'role': 'owner',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    ownerSession = SessionState()
      ..login(User(
        id: 1,
        displayName: 'المالك',
        username: 'owner',
        passwordHash: 'x',
        role: UserRole.owner,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    salesOnlySession = SessionState()
      ..login(User(
        id: 2,
        displayName: 'موظف',
        username: 'sales',
        passwordHash: 'x',
        role: UserRole.salesOnly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
  });

  tearDown(() async {
    await testDb.close();
  });

  Future<void> pumpSettings(
    WidgetTester tester,
    SessionState session,
    IdentityLinker linker,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SettingsScreen(sessionState: session, identityLinker: linker),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> revealCloudLinkButton(WidgetTester tester) async {
    final finder = find.byKey(_cloudLinkButtonKey);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openCloudLinkDialog(WidgetTester tester) async {
    await revealCloudLinkButton(tester);
    await tester.tap(find.byKey(_cloudLinkButtonKey));
    await tester.pumpAndSettle();
  }

  Future<void> submitValidLinkDialog(WidgetTester tester) async {
    await tester.enterText(
        find.byKey(_cloudLinkEmailKey), 'owner@example.com');
    await tester.enterText(
        find.byKey(_cloudLinkPasswordKey), 'password123');
    await tester.enterText(
        find.byKey(_cloudLinkShopNameKey), 'متجر النور');
    await tester.tap(find.byKey(_cloudLinkSubmitKey));
    await tester.pumpAndSettle();
  }

  Future<void> expectNoCloudIdentityPersisted() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [1]);
    expect(rows, hasLength(1));
    expect(rows.single['cloud_uuid'], isNull);
    for (final key in _cloudIdentityKeys) {
      final settingRows =
          await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
      expect(settingRows, isEmpty, reason: 'value must not be persisted: $key');
    }
  }

  group('Existing owner cloud-link settings entry', () {
    testWidgets(
        'an unlinked owner can reach the flow but nothing auto-runs',
        (tester) async {
      final fake = _FakeIdentityLinker(null);
      await pumpSettings(tester, ownerSession, fake);

      await revealCloudLinkButton(tester);

      expect(find.byKey(_cloudLinkButtonKey), findsOneWidget);
      expect(find.text('ربط الحساب السحابي'), findsOneWidget);
      expect(fake.linkCalls, 0);
      expect(ownerSession.isCloudLinked, false);
    });

    testWidgets('a non-owner role cannot see the cloud-link entry',
        (tester) async {
      final fake = _FakeIdentityLinker(null);
      await pumpSettings(tester, salesOnlySession, fake);

      expect(find.byKey(_cloudLinkButtonKey), findsNothing);
      expect(fake.linkCalls, 0);
    });

    testWidgets('an already cloud-linked owner sees no cloud-link entry',
        (tester) async {
      final linkedOwner = SessionState()
        ..login(User(
          id: 1,
          displayName: 'المالك',
          username: 'owner',
          passwordHash: 'x',
          role: UserRole.owner,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ))
        ..setCloudSession(const CloudSession(
          userId: 'cu-1',
          activeShopId: 'sp-1',
          membershipRole: 'owner',
          membershipStatus: 'ACTIVE',
        ));
      final fake = _FakeIdentityLinker(null);
      await pumpSettings(tester, linkedOwner, fake);

      expect(find.byKey(_cloudLinkButtonKey), findsNothing);
      expect(fake.linkCalls, 0);
    });

    testWidgets('cancelling the dialog runs nothing and keeps local state',
        (tester) async {
      final fake = _FakeIdentityLinker(null);
      await pumpSettings(tester, ownerSession, fake);

      await openCloudLinkDialog(tester);
      expect(find.byKey(_cloudLinkEmailKey), findsOneWidget);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(fake.linkCalls, 0);
      await expectNoCloudIdentityPersisted();
      expect(ownerSession.isCloudLinked, false);
    });

    testWidgets('an invalid email is rejected before any linker call',
        (tester) async {
      final fake = _FakeIdentityLinker(null);
      await pumpSettings(tester, ownerSession, fake);

      await openCloudLinkDialog(tester);
      await tester.enterText(
          find.byKey(_cloudLinkEmailKey), 'not-an-email');
      await tester.enterText(
          find.byKey(_cloudLinkPasswordKey), 'password123');
      await tester.enterText(
          find.byKey(_cloudLinkShopNameKey), 'متجر النور');
      await tester.tap(find.byKey(_cloudLinkSubmitKey));
      await tester.pumpAndSettle();

      expect(find.text('أدخل بريدًا إلكترونيًا صحيحًا'), findsOneWidget);
      expect(fake.linkCalls, 0);
    });

    testWidgets(
        'an already-registered email fails closed with no local mutation',
        (tester) async {
      final fake = _FakeIdentityLinker(
          (user, email, password, shopName) async =>
              LinkResult.cloudAccountExists());
      await pumpSettings(tester, ownerSession, fake);

      await openCloudLinkDialog(tester);
      await submitValidLinkDialog(tester);

      expect(fake.linkCalls, 1);
      expect(find.text('هذا البريد الإلكتروني مسجل مسبقًا في حساب سحابي'),
          findsOneWidget);
      await expectNoCloudIdentityPersisted();
      expect(ownerSession.isCloudLinked, false);
    });

    testWidgets('a network failure shows an error and mutates nothing',
        (tester) async {
      final fake = _FakeIdentityLinker(
          (user, email, password, shopName) async =>
              LinkResult.networkUnavailable());
      await pumpSettings(tester, ownerSession, fake);

      await openCloudLinkDialog(tester);
      await submitValidLinkDialog(tester);

      expect(fake.linkCalls, 1);
      expect(
          find.text('لا يوجد اتصال بالإنترنت — أعد المحاولة لاحقًا'),
          findsOneWidget);
      await expectNoCloudIdentityPersisted();
    });

    testWidgets('a successful link reports success and opens no cloud session',
        (tester) async {
      final fake = _FakeIdentityLinker(
          (user, email, password, shopName) async => LinkResult.success(
                cloudUserId: 'cu-1',
                shopId: 'sp-1',
              ));
      await pumpSettings(tester, ownerSession, fake);

      await openCloudLinkDialog(tester);
      await submitValidLinkDialog(tester);

      expect(fake.linkCalls, 1);
      expect(
          find.text(
              'تم ربط الحساب السحابي بنجاح. أعد تسجيل الدخول لتفعيل المزامنة.'),
          findsOneWidget);
      // The canonical flow persists local linkage but the runtime cloud
      // session is only established on the next login — never here.
      expect(ownerSession.isCloudLinked, false);
    });
  });

  group('Real IdentityLinker fail-closed guards', () {
    test('an already-registered email stops before any local persistence',
        () async {
      final auth = _FakeCloudAuthService(
          CloudSignUpResult.emailAlreadyRegistered());
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: User(
          id: 1,
          displayName: 'المالك',
          username: 'owner',
          passwordHash: 'x',
          role: UserRole.owner,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.cloudAccountExists);
      expect(result.isSuccess, false);
      expect(auth.signUpCalls, 1);
      expect(auth.createShopCalls, 0);
      await expectNoCloudIdentityPersisted();
    });

    test('a network failure stops before any local persistence', () async {
      final auth =
          _FakeCloudAuthService(CloudSignUpResult.networkUnavailable());
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: User(
          id: 1,
          displayName: 'المالك',
          username: 'owner',
          passwordHash: 'x',
          role: UserRole.owner,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.networkUnavailable);
      expect(result.isSuccess, false);
      expect(auth.signUpCalls, 1);
      expect(auth.createShopCalls, 0);
      await expectNoCloudIdentityPersisted();
    });
  });
}

/// Driver for the real [IdentityLinker.linkExistingUser] flow. The sign-up and
/// shop-creation steps are fake so the fail-closed behavior can be proven
/// without any network or an initialized Supabase client.
class _FakeCloudAuthService extends CloudAuthService {
  _FakeCloudAuthService(this._signUpResult)
      : super(authClient: _dummyClient.auth, client: _dummyClient);

  static final SupabaseClient _dummyClient =
      SupabaseClient('http://dummy', 'dummy');

  final CloudSignUpResult _signUpResult;
  int signUpCalls = 0;
  int createShopCalls = 0;

  @override
  Future<CloudSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    return _signUpResult;
  }

  @override
  Future<String> createShopWithOwner(String shopName) async {
    createShopCalls++;
    return 'sp-1';
  }
}

/// Injectable [IdentityLinker] representative for widget tests. It never
/// touches Supabase and records whether the canonical entry point was invoked.
class _FakeIdentityLinker implements IdentityLinker {
  _FakeIdentityLinker(this.onLink);

  final Future<LinkResult> Function(
    User localUser,
    String email,
    String password,
    String shopName,
  )? onLink;

  int linkCalls = 0;

  @override
  Future<LinkResult> linkExistingUser({
    required User localUser,
    required String email,
    required String password,
    required String shopName,
  }) async {
    linkCalls++;
    final handler = onLink;
    if (handler == null) {
      return LinkResult.unknownError('no handler provided');
    }
    return handler(localUser, email, password, shopName);
  }

  @override
  Future<LinkResult> onboardFreshOwner({
    required String displayName,
    required String username,
    required String password,
    required String email,
    required String shopName,
  }) async =>
      LinkResult.unknownError('not used in these tests');

  @override
  Future<LinkResult> recoverOnboarding() async =>
      LinkResult.unknownError('not used in these tests');
}