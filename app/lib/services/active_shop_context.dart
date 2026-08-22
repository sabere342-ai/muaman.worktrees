import 'package:flutter/foundation.dart';

/// Thrown when a shop-context operation fails validation (plan §L). The
/// context never falls back to an unvalidated shop id — every failure is
/// explicit and leaves the previous state intact.
class TenantContextException implements Exception {
  final String message;
  const TenantContextException(this.message);

  @override
  String toString() => 'TenantContextException: $message';
}

/// Single authoritative in-process tenant context (Phase J WS1).
///
/// Holds the cloud shop id under which all tenant-scoped data-layer
/// operations execute. Every bind/switch is validated against the signed-in
/// user's ACTIVE memberships through [configure]'d validator, so a stale or
/// foreign shop id can never become the operating tenant.
///
/// Lifecycle (plan §L):
///   login + cloud-link → ShopResolver resolves → bind(shopId)
///   shop switch        → switchShop(newId) after validation
///   logout/cloud-unlink→ unbind()
///
/// `shopId == null` means "no authorized cloud tenant". While strict tenant
/// isolation is armed (see TenantIsolationGate), a null context makes reads
/// fail closed to empty and writes throw — never silent unscoped access.
class ActiveShopContext extends ChangeNotifier {
  static final ActiveShopContext instance = ActiveShopContext._();

  ActiveShopContext._();

  /// Returns true when [shopId] is an ACTIVE membership of the currently
  /// authenticated user. Wired during app startup; when not configured the
  /// context rejects every bind attempt (fail-closed default).
  Future<bool> Function(String shopId)? _membershipValidator;

  String? _shopId;

  /// The bound active shop id, or null when no authorized tenant is active.
  String? get shopId => _shopId;

  bool get isBound => _shopId != null;

  /// Wires the membership validator used to authorize bind/switch attempts.
  void configure({
    required Future<bool> Function(String shopId) membershipValidator,
  }) {
    _membershipValidator = membershipValidator;
  }

  Future<void> _validate(String shopId) async {
    final validator = _membershipValidator;
    if (validator == null) {
      throw const TenantContextException('سياق المتجر غير مهيأ بعد');
    }
    if (shopId.trim().isEmpty) {
      throw const TenantContextException('معرّف المتجر غير صالح');
    }
    final authorized = await validator(shopId);
    if (!authorized) {
      throw TenantContextException('المتجر غير مصرح به لهذا الحساب: $shopId');
    }
  }

  /// Binds the context to [shopId] after membership validation. A repeated
  /// bind of the already-bound shop is a no-op and does not re-notify.
  Future<void> bind(String shopId) async {
    await _validate(shopId);
    if (_shopId == shopId) return;
    _shopId = shopId;
    notifyListeners();
  }

  /// Switches the active shop atomically: the NEW shop is validated BEFORE
  /// the old binding is released, so an invalid switch leaves the current
  /// tenant context untouched. Mid-flight sync cycles remain safe because
  /// queue entries execute strictly under their persisted entry.shop_id,
  /// never under this ambient value (plan §L/§O).
  Future<void> switchShop(String newShopId) async {
    await _validate(newShopId);
    if (_shopId == newShopId) return;
    _shopId = newShopId;
    notifyListeners();
  }

  /// Clears the tenant context (logout / cloud unlink).
  void unbind() {
    if (_shopId == null) return;
    _shopId = null;
    notifyListeners();
  }

  /// Test seam: fully resets the singleton between tests.
  @visibleForTesting
  void resetForTest() {
    _membershipValidator = null;
    _shopId = null;
  }
}
