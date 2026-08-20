import '../database/database_helper.dart';
import '../database/user_repository.dart';
import '../models/user.dart';
import '../models/user_role.dart' as model;
import '../services/app_settings.dart';
import 'cloud_auth_service.dart';

/// Result of an identity linking attempt.
enum LinkResultType {
  success,
  localUserNotFound,
  cloudAccountExists,
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

  /// Link an existing local user to a new cloud account.
  ///
  /// Flow:
  /// 1. Verify local user has no existing cloud_uuid
  /// 2. Create cloud account via sign-up
  /// 3. Create shop via create_shop_with_owner RPC
  /// 4. Persist cloud_uuid in local users table
  /// 5. Persist shopProfile.cloudUuid
  /// 6. Persist cloud.auth.email
  Future<LinkResult> linkExistingUser({
    required User localUser,
    required String email,
    required String password,
    required String shopName,
  }) async {
    // Check if local user already has a cloud link
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
        return LinkResult.success(
          cloudUserId: rows.first['cloud_uuid'] as String,
          shopId:
              await AppSettings.getValue(AppSettings.keyShopProfileCloudUuid),
        );
      }
    }

    // Create cloud account
    final signUpResult = await _cloudAuth.signUp(
      email: email,
      password: password,
    );

    if (signUpResult.type == CloudSignUpResultType.emailAlreadyRegistered) {
      return LinkResult.cloudAccountExists();
    }
    if (signUpResult.type == CloudSignUpResultType.networkUnavailable) {
      return LinkResult.networkUnavailable();
    }
    if (!signUpResult.isSuccess || signUpResult.session == null) {
      return LinkResult.unknownError(
        signUpResult.errorMessage ?? 'فشل إنشاء الحساب السحابي',
      );
    }

    final cloudUserId = signUpResult.session!.user.id;

    // Create shop
    try {
      final shopId = await _cloudAuth.createShopWithOwner(shopName);
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
    } catch (e) {
      // Shop creation failed — but the cloud account exists.
      // The user can retry linking on next launch.
      return LinkResult.unknownError(
        'تم إنشاء الحساب السحابي لكن فشل إنشاء المتجر: $e',
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
    // 1. Create local user
    final localUserId = await _userRepo.createUser(
      displayName: displayName,
      username: username,
      password: password,
      role: model.UserRole.owner,
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

    // 1. users.cloud_uuid = auth.uid()
    await db.update(
      'users',
      {'cloud_uuid': cloudUserId},
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
