import '../database/database_helper.dart';
import '../database/user_repository.dart';
import '../models/user.dart';
import '../services/app_settings.dart';
import 'cloud_auth_service.dart';

/// Result of an identity linking attempt.
enum LinkResultType {
  success,
  localUserNotFound,
  cloudAccountExists,
  invalidCredentials,
  emailNotConfirmed,
  ownershipConflict,
  networkUnavailable,
  unknownError,
}

class LinkResult {
  LinkResult._({
    required this.type,
    this.cloudUserId,
    this.shopId,
    this.errorMessage,
  });

  factory LinkResult.success({
    required String cloudUserId,
    required String shopId,
  }) =>
      LinkResult._(
        type: LinkResultType.success,
        cloudUserId: cloudUserId,
        shopId: shopId,
      );

  factory LinkResult.localUserNotFound() =>
      LinkResult._(type: LinkResultType.localUserNotFound);

  factory LinkResult.cloudAccountExists() =>
      LinkResult._(type: LinkResultType.cloudAccountExists);

  factory LinkResult.invalidCredentials() =>
      LinkResult._(type: LinkResultType.invalidCredentials);

  factory LinkResult.emailNotConfirmed() =>
      LinkResult._(type: LinkResultType.emailNotConfirmed);

  factory LinkResult.ownershipConflict(String message) => LinkResult._(
        type: LinkResultType.ownershipConflict,
        errorMessage: message,
      );

  factory LinkResult.networkUnavailable() =>
      LinkResult._(type: LinkResultType.networkUnavailable);

  factory LinkResult.unknownError(String message) =>
      LinkResult._(type: LinkResultType.unknownError, errorMessage: message);

  final LinkResultType type;
  final String? cloudUserId;
  final String? shopId;
  final String? errorMessage;

  bool get isSuccess => type == LinkResultType.success;
}

/// Bridges the local user domain with the cloud Supabase Auth domain.
///
/// Identity linking establishes three connections:
/// 1. `users.cloud_uuid` ↔ `auth.uid()` (local user → cloud identity)
/// 2. `ShopProfile.cloudUuid` ↔ `shops.id` (shop → cloud shop)
/// 3. `app_settings['cloud.auth.email']` ↔ `auth.users.email`
///
/// This class handles both fresh owner onboarding (new cloud account)
/// and existing owner linking (existing local user + new cloud account).
class IdentityLinker {
  IdentityLinker({
    CloudAuthService? cloudAuthService,
    UserRepository? userRepository,
    DatabaseHelper? dbHelper,
  })  : _cloudAuth = cloudAuthService ?? CloudAuthService(),
        _userRepo = userRepository ?? UserRepository(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final CloudAuthService _cloudAuth;
  final UserRepository _userRepo;
  final DatabaseHelper _dbHelper;

  /// Link an existing local user to an existing cloud identity via sign-in.
  ///
  /// Flow:
  /// 1. Verify local user has no existing cloud_uuid (already linked = success).
  /// 2. Authenticate the cloud identity using the existing sign-in path.
  /// 3. Resolve or create the owner shop via the idempotent RPC.
  /// 4. Persist cloud_uuid, shop_id, cloud.auth.email, shopProfile.cloudUuid.
  ///
  /// This is the sign-in-first path for an existing confirmed Supabase Auth
  /// identity. It does NOT call signUp — the identity already exists and must
  /// be authenticated, not created.
  Future<LinkResult> linkExistingUser({
    required User localUser,
    required String email,
    required String password,
    required String shopName,
  }) async {
    // Step 1: If local user already has a cloud link, the linkage is complete.
    if (localUser.id != null) {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'users',
        columns: ['cloud_uuid'],
        where: 'id = ?',
        whereArgs: [localUser.id],
      );
      if (rows.isNotEmpty &&
          (rows.first['cloud_uuid'] as String?)?.isNotEmpty == true) {
        final existingShopId =
            await AppSettings.getValue(AppSettings.keyShopProfileCloudUuid);
        return LinkResult.success(
          cloudUserId: rows.first['cloud_uuid'] as String,
          shopId: existingShopId,
        );
      }
    }

    // Step 2: Authenticate the existing cloud identity via sign-in.
    final signInResult = await _cloudAuth.signInWithEmail(
      email: email,
      password: password,
    );

    if (signInResult.type == CloudAuthResultType.invalidCredentials) {
      return LinkResult.invalidCredentials();
    }
    if (signInResult.type == CloudAuthResultType.emailNotConfirmed) {
      return LinkResult.emailNotConfirmed();
    }
    if (signInResult.type == CloudAuthResultType.networkUnavailable) {
      return LinkResult.networkUnavailable();
    }
    if (!signInResult.isSuccess || signInResult.session == null) {
      return LinkResult.unknownError(
        signInResult.errorMessage ?? 'فشل تسجيل الدخول إلى الحساب السحابي',
      );
    }

    final cloudUserId = signInResult.session!.user.id;

    // Step 3: Resolve or create the owner shop via the idempotent RPC.
    //
    // resolve_owner_shop uses advisory locking + transaction to guarantee
    // at most one owner shop per authenticated identity (defense-in-depth
    // Layer 2). The RPC returns the existing owner shop if one exists,
    // creates a new one if none exists, or raises if multiple exist.
    try {
      final shopId = await _cloudAuth.resolveOwnerShop(shopName);

      // Step 4: Persist the three identity linkage points locally.
      await _persistIdentity(
        localUserId: localUser.id!,
        cloudUserId: cloudUserId,
        shopId: shopId,
        email: email,
      );
      return LinkResult.success(
        cloudUserId: cloudUserId,
        shopId: shopId,
      );
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('multiple owner shops') ||
          msg.contains('reconciliation required')) {
        return LinkResult.ownershipConflict(
          'تعذر الربط: الحساب السحابي يحتوي على أكثر من متجر مالك واحد. '
          'يرجى التواصل مع الدعم الفني.',
        );
      }
      if (msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('connection')) {
        return LinkResult.networkUnavailable();
      }
      return LinkResult.unknownError(
        'تم تسجيل الدخول بنجاح لكن فشل ربط المتجر: $e',
      );
    }
  }

  /// Onboard a fresh owner (no existing local users).
  ///
  /// Flow:
  /// 1. Create local user with PBKDF2 hash
  /// 2. Create cloud account via sign-up
  /// 3. Create shop via create_shop_with_owner RPC
  /// 4. Persist cloud_uuid in local users table
  /// 5. Persist shopProfile.cloudUuid
  /// 6. Persist cloud.auth.email
  Future<LinkResult> onboardFreshOwner({
    required String displayName,
    required String username,
    required String password,
    required String email,
    required String shopName,
  }) async {
    // 1. Create local user (fail-closed first-owner bootstrap path only)
    final localUserId = await _userRepo.createFirstOwner(
      displayName: displayName,
      username: username,
      password: password,
    );

    // 2. Create cloud account
    final signUpResult = await _cloudAuth.signUp(
      email: email,
      password: password,
    );

    if (signUpResult.type == CloudSignUpResultType.emailAlreadyRegistered) {
      // Local user was created but cloud account already exists.
      // Local user still works for offline mode.
      return LinkResult.cloudAccountExists();
    }
    if (signUpResult.type == CloudSignUpResultType.networkUnavailable) {
      // Local user created, cloud linking deferred.
      return LinkResult.networkUnavailable();
    }
    if (!signUpResult.isSuccess || signUpResult.session == null) {
      // Local user created, cloud linking deferred.
      return LinkResult.networkUnavailable();
    }

    final cloudUserId = signUpResult.session!.user.id;

    // 3. Create shop
    try {
      final shopId = await _cloudAuth.createShopWithOwner(shopName);
      await _persistIdentity(
        localUserId: localUserId,
        cloudUserId: cloudUserId,
        shopId: shopId,
        email: email,
      );
      return LinkResult.success(
        cloudUserId: cloudUserId,
        shopId: shopId,
      );
    } catch (e) {
      // Local user exists, cloud account exists, shop creation failed.
      // Will be resolved on next launch via recovery logic.
      return LinkResult.unknownError(
        'تم الإنشاء المحلي والسحابي لكن فشل إنشاء المتجر: $e',
      );
    }
  }

  /// Persist the three identity linkage points to local storage.
  Future<void> _persistIdentity({
    required int localUserId,
    required String cloudUserId,
    required String shopId,
    required String email,
  }) async {
    final db = await _dbHelper.database;

    // 1. users.cloud_uuid = auth.uid(), users.shop_id = resolved shop id
    await db.update(
      'users',
      {
        'cloud_uuid': cloudUserId,
        'shop_id': shopId,
      },
      where: 'id = ?',
      whereArgs: [localUserId],
    );

    // 2. ShopProfile.cloudUuid
    await AppSettings.setValue(AppSettings.keyShopProfileCloudUuid, shopId);

    // 3. cloud.auth.email
    await AppSettings.setValue('cloud.auth.email', email.trim());
  }

  /// Attempt to recover an interrupted onboarding.
  ///
  /// Checks cloud state and re-persists local mappings if needed.
  Future<LinkResult> recoverOnboarding() async {
    try {
      final shops = await _cloudAuth.getUserShops();
      if (shops.isEmpty) {
        return LinkResult.unknownError('لا توجد متاجر مرتبطة بالحساب');
      }

      final shop = shops.first;
      final shopId = shop['shop_id'].toString();
      final cloudUserId = _cloudAuth.currentUser?.id;

      if (cloudUserId == null) {
        return LinkResult.networkUnavailable();
      }

      // Find local user with this cloud_uuid or no cloud_uuid
      final db = await _dbHelper.database;
      final localUsers = await db
          .query('users', where: 'cloud_uuid = ?', whereArgs: [cloudUserId]);
      if (localUsers.isNotEmpty) {
        final localUserId = localUsers.first['id'] as int;
        await _persistIdentity(
          localUserId: localUserId,
          cloudUserId: cloudUserId,
          shopId: shopId,
          email: _cloudAuth.currentUser?.email ?? '',
        );
        return LinkResult.success(
          cloudUserId: cloudUserId,
          shopId: shopId,
        );
      }

      return LinkResult.unknownError('لم يتم العثور على مستخدم محلي مطابق');
    } catch (e) {
      if (e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        return LinkResult.networkUnavailable();
      }
      return LinkResult.unknownError(e.toString());
    }
  }
}
