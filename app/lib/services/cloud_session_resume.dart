import '../database/database_helper.dart';
import '../licensing/cloud_licensing_service.dart';
import '../rbac/permission_sync_service.dart';
import 'active_shop_context.dart';
import 'shop_resolver.dart';
import 'tenant_isolation_gate.dart';

/// Resolves the active shop for a restored session (injectable for tests).
typedef ActiveShopResolverFn = Future<ShopMembership> Function();

/// Licensing resume steps executed after tenant binding (injectable so
/// tests never touch cloud services).
typedef LicensingResumeSteps = Future<void> Function(String shopId);

/// Permission synchronization step (injectable for tests).
typedef PermissionSyncStep = Future<void> Function(String shopId);

/// Phase K D4 — cold-start cloud-session resume.
///
/// When the app starts with a valid persisted Supabase session (the COMMON
/// case on Android after process death), the tenant runtime MUST be fully
/// re-armed before any tenant-owned data renders — the same sequence the
/// LoginScreen executes after an interactive cloud login:
///
///   resolveActiveShop → ActiveShopContext.bind(shopId)
///                     → TenantIsolationGate.restoreAtStartup
///                     → licensing initialize/register/activate
///                     → PermissionSyncService.syncPermissions
///
/// Safety properties:
/// - Fail-closed: if shop resolution fails, membership validation rejects
///   the bind, or any binding error occurs, NO shop is bound and the caller
///   receives null. Data access follows unbound fail-closed semantics.
/// - No shop id is ever guessed or hard-coded; resolution goes through the
///   Phase J ShopResolver rules (single/last-used/first-ACTIVE) and every
///   bind is validated against ACTIVE memberships by the configured
///   validator.
/// - Licensing and permission-sync failures degrade silently to the same
///   offline behavior as LoginScreen; they can never bypass isolation.
///
/// Returns the bound shop id, or null when no authorized shop could be
/// bound. The sync runtime is intentionally NOT touched here or anywhere
/// else in Phase K (plan D9).
Future<String?> resumeCloudSessionAtStartup({
  required ActiveShopResolverFn resolveActiveShop,
  LicensingResumeSteps? licensingSteps,
  PermissionSyncStep? syncPermissions,
}) async {
  String membershipShopId;
  try {
    final membership = await resolveActiveShop();
    membershipShopId = membership.shopId;
  } catch (_) {
    // No resolvable shop (no memberships / resolver failure): fail closed.
    return null;
  }

  try {
    await ActiveShopContext.instance.bind(membershipShopId);
  } catch (_) {
    // Membership validator rejected the shop: fail closed, nothing bound.
    return null;
  }

  try {
    await TenantIsolationGate().restoreAtStartup(
      db: await DatabaseHelper.instance.database,
      shopId: membershipShopId,
    );
  } catch (_) {
    // Gate restoration must never block the startup flow.
  }

  try {
    if (licensingSteps != null) {
      await licensingSteps(membershipShopId);
    } else {
      final service = CloudLicensingService.instance;
      await service.initialize(shopId: membershipShopId, isCloudLinked: true);
      await service.registerDevice(membershipShopId);
      await service.activateDevice(membershipShopId);
    }
  } catch (_) {
    // Offline / cloud unavailable — existing degrade-silently pattern.
  }

  try {
    if (syncPermissions != null) {
      await syncPermissions(membershipShopId);
    } else {
      await PermissionSyncService.instance.syncPermissions(membershipShopId);
    }
  } catch (_) {
    // Permission sync failure — continue with local defaults.
  }

  return membershipShopId;
}
