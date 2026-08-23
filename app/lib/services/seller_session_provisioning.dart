import '../database/database_helper.dart';
import '../database/user_repository.dart';
import '../licensing/cloud_licensing_service.dart';
import '../models/user.dart';
import '../rbac/permission_sync_service.dart';
import 'active_shop_context.dart';
import 'cloud_auth_service.dart';
import 'shop_resolver.dart';
import 'tenant_isolation_gate.dart';

/// Outcome of the cloud sign-in step (injectable for tests).
class SellerSignInOutcome {
  const SellerSignInOutcome({required this.userId, this.displayName});

  /// The Supabase `auth.uid()` for the authenticated cloud identity.
  final String userId;

  /// Display name from cloud user metadata, when present.
  final String? displayName;
}

/// Failure signal raised by the sign-in step with its mapped status.
class SellerSignInFailure implements Exception {
  const SellerSignInFailure(this.status, [this.message]);

  final SellerSessionStatus status;
  final String? message;
}

typedef SellerSignInStep = Future<SellerSignInOutcome> Function(
    String email, String password);
typedef SellerMembershipsStep = Future<List<ShopMembership>> Function();
typedef SellerResolveShopStep = Future<ShopMembership> Function();
typedef SellerBindStep = Future<void> Function(String shopId);
typedef SellerArmGateStep = Future<void> Function(String shopId);
typedef SellerLicensingStep = Future<void> Function(String shopId);
typedef SellerPermissionSyncStep = Future<void> Function(String shopId);
typedef SellerUpsertUserStep = Future<User> Function({
  required String cloudUuid,
  String? displayName,
  required String membershipRole,
});

/// Possible outcomes of the seller cloud-login provisioning sequence.
enum SellerSessionStatus {
  success,
  invalidCredentials,
  noActiveMembership,
  ownerRejected,
  bindRejected,
  networkUnavailable,
  unknownError,
}

/// Result of [provisionSellerSession].
///
/// On success it carries the resolved ACTIVE membership, the provisioned
/// local cache user, and the cloud user id so the caller can establish
/// SessionState + CloudSession. On failure it carries ONLY the mapped
/// status — no partial tenant state survives (fail-closed).
class SellerSessionResult {
  const SellerSessionResult._({
    required this.status,
    this.membership,
    this.user,
    this.cloudUserId,
    this.errorMessage,
  });

  const SellerSessionResult._failure(this.status, [this.errorMessage])
      : membership = null,
        user = null,
        cloudUserId = null;

  const SellerSessionResult.success({
    required ShopMembership membership,
    required User user,
    required String cloudUserId,
  }) : this._(
          status: SellerSessionStatus.success,
          membership: membership,
          user: user,
          cloudUserId: cloudUserId,
        );

  static const SellerSessionResult invalidCredentials =
      SellerSessionResult._failure(SellerSessionStatus.invalidCredentials);
  static const SellerSessionResult noActiveMembership =
      SellerSessionResult._failure(SellerSessionStatus.noActiveMembership);
  static const SellerSessionResult ownerRejected =
      SellerSessionResult._failure(SellerSessionStatus.ownerRejected);
  static const SellerSessionResult bindRejected =
      SellerSessionResult._failure(SellerSessionStatus.bindRejected);
  static const SellerSessionResult networkUnavailable =
      SellerSessionResult._failure(SellerSessionStatus.networkUnavailable);

  factory SellerSessionResult.unknownError([String? message]) =>
      SellerSessionResult._failure(SellerSessionStatus.unknownError, message);

  final SellerSessionStatus status;
  final ShopMembership? membership;
  final User? user;
  final String? cloudUserId;
  final String? errorMessage;

  bool get isSuccess => status == SellerSessionStatus.success;
}

/// Phase L (D-L1): cloud-first seller session provisioning.
///
/// Executes the canonical authentication/tenant sequence on EVERY new
/// seller authentication path — identical primitives to Phase K D4 cold
/// start and the Phase J interactive login — with NO shortcut paths:
///
///   signInWithEmail -> get_user_shops (require >= 1 ACTIVE)
///                   -> resolveActiveShop (ACTIVE chain only)
///                   -> ActiveShopContext.bind (validator-validated)
///                   -> TenantIsolationGate.restoreAtStartup (arm)
///                   -> licensing initialize/register/activate
///                   -> PermissionSyncService.syncPermissions
///                   -> local users row upsert keyed by cloud_uuid (D-L4)
///
/// Safety properties:
/// - Fail-closed: zero-ACTIVE-membership accounts bind NOTHING, read
///   NOTHING and write NOTHING; a rejected bind leaves the context
///   unbound.
/// - Ownership hijack prevention (D-L3): an owner-role membership is
///   rejected BEFORE any mutation so the seller path can never create or
///   elevate an owner locally; owners keep their dedicated FirstOwnerSetup
///   linking flow.
/// - No shop id is ever guessed; resolution goes through the ShopResolver
///   rules and every bind is validated against ACTIVE memberships by the
///   configured validator.
/// - Licensing and permission-sync failures degrade silently to offline
///   behavior exactly like LoginScreen/cold-start resume.
/// - The sync runtime is intentionally NOT touched here or anywhere else
///   in Phase L (D-L7): SyncEngine/SyncWorker/HydrationService remain
///   unconstructed.
Future<SellerSessionResult> provisionSellerSession({
  required String email,
  required String password,
  SellerSignInStep? signIn,
  SellerMembershipsStep? getMemberships,
  SellerResolveShopStep? resolveActiveShop,
  SellerBindStep? bindShop,
  SellerArmGateStep? armTenantIsolationGate,
  SellerLicensingStep? licensingSteps,
  SellerPermissionSyncStep? syncPermissions,
  SellerUpsertUserStep? upsertLocalCloudUser,
}) async {
  late final SellerSignInOutcome auth;
  try {
    auth = await (signIn ?? _defaultSignIn)(email.trim(), password);
  } on SellerSignInFailure catch (f) {
    return f.status == SellerSessionStatus.unknownError
        ? SellerSessionResult.unknownError(f.message)
        : SellerSessionResult._failure(f.status, f.message);
  } catch (_) {
    return const SellerSessionResult._failure(SellerSessionStatus.unknownError);
  }

  // Membership gate: require at least one ACTIVE membership BEFORE any
  // tenant binding. Resolver errors map to the same fail-closed outcome.
  List<ShopMembership>? memberships;
  try {
    memberships = await (getMemberships ?? ShopResolver().getAllMemberships)();
  } catch (_) {}
  if (memberships == null || !memberships.any((m) => m.isActive)) {
    return SellerSessionResult.noActiveMembership;
  }

  ShopMembership resolved;
  try {
    resolved = await (resolveActiveShop ?? ShopResolver().resolveActiveShop)();
  } catch (_) {
    return SellerSessionResult.noActiveMembership;
  }
  if (!resolved.isActive) {
    return SellerSessionResult.noActiveMembership;
  }

  // D-L3: the seller path NEVER provisions ownership. Reject before any
  // mutation so a fresh device cannot be claimed via crafted cloud state.
  if (resolved.isOwner || resolved.membershipRole == 'owner') {
    return SellerSessionResult.ownerRejected;
  }

  bool bound = false;
  try {
    await (bindShop ??
        (shopId) => ActiveShopContext.instance.bind(shopId))(resolved.shopId);
    bound = true;
  } catch (_) {
    // Membership validator rejected the shop: fail closed, nothing bound.
    return SellerSessionResult.bindRejected;
  }

  try {
    await (armTenantIsolationGate ?? _defaultArmGate)(resolved.shopId);
  } catch (_) {
    // Gate restoration must never block the login flow (same as resume).
  }

  try {
    await (licensingSteps ?? _defaultLicensing)(resolved.shopId);
  } catch (_) {
    // Offline / cloud unavailable — existing degrade-silently pattern.
  }

  try {
    await (syncPermissions ??
            (shopId) => PermissionSyncService.instance.syncPermissions(shopId))(
        resolved.shopId);
  } catch (_) {
    // Permission sync failure — continue with cached/local defaults.
  }

  try {
    final user = await (upsertLocalCloudUser ?? _defaultUpsertUser)(
      cloudUuid: auth.userId,
      displayName: auth.displayName ?? email,
      membershipRole: resolved.membershipRole,
    );
    return SellerSessionResult.success(
      membership: resolved,
      user: user,
      cloudUserId: auth.userId,
    );
  } on CloudIdentityRoleConflictException {
    await _unbindQuietly(bound);
    return SellerSessionResult.ownerRejected;
  } catch (e) {
    // Never leave a bound tenant context behind a failed provisioning.
    await _unbindQuietly(bound);
    return SellerSessionResult.unknownError(e.toString());
  }
}

/// D-L3: whether AuthGate should offer the fresh-device bootstrap options
/// (Owner Setup / Cloud Login / Accept Invitation). Only when Supabase is
/// configured AND no local users exist; otherwise the historical behavior
/// stands unchanged.
bool offersFreshDeviceCloudBootstrap({
  required bool hasLocalUsers,
  required bool supabaseConfigured,
}) {
  return !hasLocalUsers && supabaseConfigured;
}

Future<void> _unbindQuietly(bool bound) async {
  if (!bound) return;
  try {
    ActiveShopContext.instance.unbind();
  } catch (_) {
    // Best-effort cleanup; unbound-context fail-closed semantics apply.
  }
}

Future<SellerSignInOutcome> _defaultSignIn(
    String email, String password) async {
  final result = await CloudAuthService()
      .signInWithEmail(email: email, password: password);
  switch (result.type) {
    case CloudAuthResultType.success:
      String? displayName;
      final meta = result.session?.user.userMetadata;
      if (meta != null) {
        final value = meta['display_name'] ?? meta['name'];
        if (value is String && value.trim().isNotEmpty) {
          displayName = value.trim();
        }
      }
      return SellerSignInOutcome(
        userId: result.session!.user.id,
        displayName: displayName,
      );
    case CloudAuthResultType.invalidCredentials:
      throw const SellerSignInFailure(SellerSessionStatus.invalidCredentials);
    case CloudAuthResultType.networkUnavailable:
      throw const SellerSignInFailure(SellerSessionStatus.networkUnavailable);
    case CloudAuthResultType.emailNotConfirmed:
      throw const SellerSignInFailure(
        SellerSessionStatus.unknownError,
        'يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول',
      );
    case CloudAuthResultType.emailAlreadyRegistered:
    case CloudAuthResultType.unknownError:
      throw SellerSignInFailure(
        SellerSessionStatus.unknownError,
        result.errorMessage,
      );
  }
}

Future<void> _defaultArmGate(String shopId) async {
  await TenantIsolationGate().restoreAtStartup(
    db: await DatabaseHelper.instance.database,
    shopId: shopId,
  );
}

Future<void> _defaultLicensing(String shopId) async {
  final service = CloudLicensingService.instance;
  await service.initialize(shopId: shopId, isCloudLinked: true);
  await service.registerDevice(shopId);
  await service.activateDevice(shopId);
}

Future<User> _defaultUpsertUser({
  required String cloudUuid,
  String? displayName,
  required String membershipRole,
}) {
  return UserRepository().upsertCloudUser(
    cloudUuid: cloudUuid,
    displayName: displayName,
    membershipRole: membershipRole,
  );
}
