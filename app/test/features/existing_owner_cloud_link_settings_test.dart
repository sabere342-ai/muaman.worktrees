import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:muaman_store/database/database_helper.dart';
import 'package:muaman_store/models/cloud_session.dart';
import 'package:muaman_store/models/user.dart';
import 'package:muaman_store/models/user_role.dart';
import 'package:muaman_store/screens/settings_screen.dart';
import 'package:muaman_store/services/cloud_auth_service.dart';
import 'package:muaman_store/services/identity_linker.dart';
import 'package:muaman_store/services/app_settings.dart';
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
    await tester.enterText(find.byKey(_cloudLinkEmailKey), 'owner@example.com');
    await tester.enterText(find.byKey(_cloudLinkPasswordKey), 'password123');
    await tester.enterText(find.byKey(_cloudLinkShopNameKey), 'متجر النور');
    await tester.tap(find.byKey(_cloudLinkSubmitKey));
    await tester.pumpAndSettle();
  }

  Future<void> expectNoCloudIdentityPersisted() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [1]);
    expect(rows, hasLength(1));
    expect(rows.single['cloud_uuid'], isNull);
    expect(rows.single['shop_id'], isNull);
    for (final key in _cloudIdentityKeys) {
      final settingRows =
          await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
      expect(settingRows, isEmpty, reason: 'value must not be persisted: $key');
    }
  }

  User existingOwnerUser() => User(
        id: 1,
        displayName: 'المالك',
        username: 'owner',
        passwordHash: 'x',
        role: UserRole.owner,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  group('Existing owner cloud-link settings entry', () {
    testWidgets('an unlinked owner can reach the flow but nothing auto-runs',
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
      await tester.enterText(find.byKey(_cloudLinkEmailKey), 'not-an-email');
      await tester.enterText(find.byKey(_cloudLinkPasswordKey), 'password123');
      await tester.enterText(find.byKey(_cloudLinkShopNameKey), 'متجر النور');
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
      expect(find.text('لا يوجد اتصال بالإنترنت — أعد المحاولة لاحقًا'),
          findsOneWidget);
      await expectNoCloudIdentityPersisted();
    });

    testWidgets('invalid credentials shows a clean error and mutates nothing',
        (tester) async {
      final fake = _FakeIdentityLinker(
          (user, email, password, shopName) async =>
              LinkResult.invalidCredentials());
      await pumpSettings(tester, ownerSession, fake);

      await openCloudLinkDialog(tester);
      await submitValidLinkDialog(tester);

      expect(fake.linkCalls, 1);
      expect(find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
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

    testWidgets('multiple-owner-shop conflict shows a distinguishable error',
        (tester) async {
      final fake = _FakeIdentityLinker(
          (user, email, password, shopName) async =>
              LinkResult.ownershipConflict(
                  'تعذر الربط: توجد مشكلة في ملكية المتجر'));
      await pumpSettings(tester, ownerSession, fake);

      await openCloudLinkDialog(tester);
      await submitValidLinkDialog(tester);

      expect(fake.linkCalls, 1);
      expect(
          find.text('تعذر الربط: توجد مشكلة في ملكية المتجر'), findsOneWidget);
      await expectNoCloudIdentityPersisted();
    });
  });

  group('Real IdentityLinker sign-in-first fail-closed guards', () {
    test('an existing confirmed identity uses sign-in, never sign-up',
        () async {
      final auth = _FakeCloudAuthService(
          signInResult: CloudAuthResult.success(_testSession()),
          resolveShopResult: 'sp-1');
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.success);
      expect(result.isSuccess, true);
      expect(result.cloudUserId, 'cu-1');
      expect(result.shopId, 'sp-1');
      expect(auth.signInCalls, 1);
      expect(auth.signUpCalls, 0);
      expect(auth.resolveShopCalls, 1);
      expect(auth.createShopCalls, 0);
    });

    test('an existing confirmed identity reuses its single owner shop',
        () async {
      final auth = _FakeCloudAuthService(
        signInResult: CloudAuthResult.success(_testSession()),
        resolveShopResult: 'sp-1',
      );
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.isSuccess, true);
      expect(result.shopId, 'sp-1');
      expect(auth.resolveShopCalls, 1);
      // Reuse means no shop was created through the older RPC.
      expect(auth.createShopCalls, 0);

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('users', where: 'id = ?', whereArgs: [1]);
      expect(rows, hasLength(1));
      expect(rows.single['cloud_uuid'], 'cu-1');
      expect(rows.single['shop_id'], 'sp-1');
      expect(rows.single['displayName'], 'المالك');
      expect(rows.single['username'], 'owner');
    });

    test('repeats of the linker converge to the same shop (no second shop)',
        () async {
      final auth = _FakeCloudAuthService(
        signInResult: CloudAuthResult.success(_testSession()),
        resolveShopResult: 'sp-1',
      );
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      final db = await DatabaseHelper.instance.database;
      final users =
          await db.query('users', where: 'cloud_uuid = ?', whereArgs: ['cu-1']);
      expect(users, hasLength(1));
      expect(users.single['shop_id'], 'sp-1');
    });

    test('invalid credentials fail cleanly with no local persistence',
        () async {
      final auth = _FakeCloudAuthService(
          signInResult: CloudAuthResult.invalidCredentials());
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'wrong-password',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.invalidCredentials);
      expect(result.isSuccess, false);
      expect(auth.signInCalls, 1);
      expect(auth.signUpCalls, 0);
      expect(auth.resolveShopCalls, 0);
      await expectNoCloudIdentityPersisted();
    });

    test('email-not-confirmed fails cleanly with no local persistence',
        () async {
      final auth = _FakeCloudAuthService(
          signInResult: CloudAuthResult.emailNotConfirmed());
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.emailNotConfirmed);
      expect(result.isSuccess, false);
      expect(auth.resolveShopCalls, 0);
      await expectNoCloudIdentityPersisted();
    });

    test('a network failure stops before any local persistence', () async {
      final auth = _FakeCloudAuthService(
          signInResult: CloudAuthResult.networkUnavailable());
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.networkUnavailable);
      expect(result.isSuccess, false);
      expect(auth.signInCalls, 1);
      expect(auth.signUpCalls, 0);
      expect(auth.createShopCalls, 0);
      await expectNoCloudIdentityPersisted();
    });

    test('multiple existing owner shops fail closed (ownership conflict)',
        () async {
      final auth = _FakeCloudAuthService(
        signInResult: CloudAuthResult.success(_testSession()),
        resolveShopError:
            Exception('Multiple owner shops already exist for this account '
                '(count: 2). Reconciliation required.'),
      );
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.ownershipConflict);
      expect(result.isSuccess, false);
      expect(auth.resolveShopCalls, 1);
      await expectNoCloudIdentityPersisted();
    });

    test('non-ownership shop-resolution errors map to unknownError', () async {
      final auth = _FakeCloudAuthService(
        signInResult: CloudAuthResult.success(_testSession()),
        resolveShopError: Exception('shop name cannot be empty'),
      );
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.unknownError);
      expect(result.isSuccess, false);
      await expectNoCloudIdentityPersisted();
    });

    test('a local row that already links returns success without sign-in',
        () async {
      final db = await DatabaseHelper.instance.database;
      await db.update('users', {'cloud_uuid': 'already-linked'},
          where: 'id = ?', whereArgs: [1]);
      await AppSettings.setValue(AppSettings.keyShopProfileCloudUuid, 'sp-9');

      final auth = _FakeCloudAuthService(
          signInResult: CloudAuthResult.success(_testSession()));
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      final result = await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'password123',
        shopName: 'متجر النور',
      );

      expect(result.type, LinkResultType.success);
      expect(result.cloudUserId, 'already-linked');
      expect(auth.signInCalls, 0);
      expect(auth.resolveShopCalls, 0);

      final users = await db.query('users', where: 'id = ?', whereArgs: [1]);
      expect(users.single['cloud_uuid'], 'already-linked');
    });
  });

  group('Real IdentityLinker no trusted cloud_uuid before authentication', () {
    test('authentication failure never writes the supplied cloud identity',
        () async {
      final auth = _FakeCloudAuthService(
          signInResult: CloudAuthResult.invalidCredentials());
      final linker = IdentityLinker(
        cloudAuthService: auth,
        dbHelper: DatabaseHelper.instance,
      );

      await linker.linkExistingUser(
        localUser: existingOwnerUser(),
        email: 'owner@example.com',
        password: 'wrong',
        shopName: 'متجر النور',
      );

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('users', where: 'id = ?', whereArgs: [1]);
      expect(rows.single['cloud_uuid'], isNull);
      expect(rows.single['shop_id'], isNull);
      final settings = await db.query('app_settings',
          where: 'key = ?', whereArgs: ['cloud.auth.email']);
      expect(settings, isEmpty);
    });
  });
}

/// Builds a real (non-network) Session for the fake sign-in result.
supabase.Session _testSession() => supabase.Session(
      accessToken: 'dummy-token',
      tokenType: 'bearer',
      user: const supabase.User(
        id: 'cu-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'owner@example.com',
      ),
    );

/// Driver for the real [IdentityLinker.linkExistingUser] flow. The sign-in and
/// shop-resolution steps are fake so the fail-closed behavior can be proven
/// without any network or an initialized Supabase client.
class _FakeCloudAuthService extends CloudAuthService {
  _FakeCloudAuthService({
    CloudAuthResult? signInResult,
    this.resolveShopResult,
    this.resolveShopError,
  })  : _signInResult = signInResult,
        super(authClient: _dummyClient.auth, client: _dummyClient);

  static final supabase.SupabaseClient _dummyClient =
      supabase.SupabaseClient('http://dummy', 'dummy');

  final CloudAuthResult? _signInResult;
  final String? resolveShopResult;
  final Exception? resolveShopError;

  int signInCalls = 0;
  int signUpCalls = 0;
  int createShopCalls = 0;
  int resolveShopCalls = 0;

  @override
  Future<CloudAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    return _signInResult ?? CloudAuthResult.success(_testSession());
  }

  @override
  Future<CloudSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    return CloudSignUpResult.unknownError(
        'sign-up is never used by the linker');
  }

  @override
  Future<String> createShopWithOwner(String shopName) async {
    createShopCalls++;
    return 'sp-1';
  }

  @override
  Future<String> resolveOwnerShop(String shopName) async {
    resolveShopCalls++;
    if (resolveShopError != null) throw resolveShopError!;
    return resolveShopResult ?? 'sp-1';
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
