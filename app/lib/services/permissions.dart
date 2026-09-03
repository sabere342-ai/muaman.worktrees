import '../models/user_role.dart';

/// Thrown when an unauthorized actor attempts to change permission settings,
/// or when a change would grant owner-equivalent powers to a non-owner role.
class PermissionDeniedException implements Exception {
  final String message;

  const PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

/// Groupings used to present permissions in the settings UI.
enum PermissionCategory {
  dashboard('لوحة التحكم'),
  inventory('المخزون'),
  sales('المبيعات'),
  returns('المرتجعات'),
  expenses('المصروفات'),
  stocktake('الجرد'),
  admin('الإدارة');

  const PermissionCategory(this.displayName);

  final String displayName;
}

/// Central catalog of every permission in the application.
///
/// Each entry carries a stable storage [id] (never change it once released),
/// an Arabic [displayName] and [description] for the settings UI, and a
/// [category] used for grouping. No permission may exist here without a real
/// consumer in the application.
enum AppPermission {
  // ==================== لوحة التحكم ====================
  canAccessDashboard(
    'dashboard.view',
    'مشاهدة لوحة التحكم',
    PermissionCategory.dashboard,
    'الوصول إلى لوحة التحكم والإحصائيات الرئيسية',
  ),

  // ==================== المخزون ====================
  canAccessInventory(
    'inventory.view',
    'مشاهدة المخزون',
    PermissionCategory.inventory,
    'الوصول إلى شاشة المخزون وعرض الأصناف',
  ),
  canEditProducts(
    'inventory.edit',
    'إضافة / تعديل الأصناف',
    PermissionCategory.inventory,
    'إضافة أصناف جديدة وتعديل بياناتها',
  ),
  canDeleteProducts(
    'inventory.delete',
    'حذف الأصناف',
    PermissionCategory.inventory,
    'حذف الأصناف من المخزون',
  ),

  // ==================== المبيعات ====================
  canAccessSales(
    'sales.view',
    'مشاهدة المبيعات',
    PermissionCategory.sales,
    'الوصول إلى شاشة المبيعات',
  ),
  canCreateSales(
    'sales.create',
    'إنشاء فاتورة بيع',
    PermissionCategory.sales,
    'تسجيل فواتير بيع جديدة',
  ),
  canViewSalesHistory(
    'sales.history.view',
    'سجل المبيعات',
    PermissionCategory.sales,
    'عرض سجل المبيعات السابقة والتقارير',
  ),
  canDeleteSales(
    'sales.delete',
    'حذف عمليات البيع',
    PermissionCategory.sales,
    'حذف عمليات البيع',
  ),

  // ==================== المرتجعات ====================
  canAccessReturns(
    'returns.view',
    'مشاهدة المرتجعات',
    PermissionCategory.returns,
    'الوصول إلى شاشة المرتجعات',
  ),
  canCreateReturns(
    'returns.create',
    'تسجيل مرتجع',
    PermissionCategory.returns,
    'تسجيل مرتجعات جديدة',
  ),
  canDeleteReturns(
    'returns.delete',
    'حذف المرتجعات',
    PermissionCategory.returns,
    'حذف سجلات المرتجعات',
  ),

  // ==================== المصروفات ====================
  canAccessExpenses(
    'expenses.view',
    'مشاهدة المصروفات',
    PermissionCategory.expenses,
    'الوصول إلى شاشة المصروفات',
  ),
  canCreateExpenses(
    'expenses.create',
    'تسجيل مصروف',
    PermissionCategory.expenses,
    'تسجيل مصروفات جديدة',
  ),
  canDeleteExpenses(
    'expenses.delete',
    'حذف المصروفات',
    PermissionCategory.expenses,
    'حذف سجلات المصروفات',
  ),

  // ==================== الجرد ====================
  canAccessStocktake(
    'stocktake.view',
    'شاشة الجرد',
    PermissionCategory.stocktake,
    'الوصول إلى شاشة الجرد',
  ),

  // ==================== الإدارة ====================
  canManageUsers(
    'admin.users.manage',
    'إدارة المستخدمين',
    PermissionCategory.admin,
    'إنشاء وتعديل حسابات المستخدمين',
  ),
  canManagePermissions(
    'admin.permissions.manage',
    'إدارة الصلاحيات',
    PermissionCategory.admin,
    'تعديل صلاحيات الأدوار',
  ),
  canManageDevices(
    'admin.devices.manage',
    'إدارة الأجهزة',
    PermissionCategory.admin,
    'عرض وإدارة أجهزة المتجر (الموافقة/الرفض/الإلغاء/الفقدان)',
  ),
  canAccessSettings(
    'admin.settings.access',
    'الإعدادات',
    PermissionCategory.admin,
    'الوصول إلى إعدادات التطبيق',
  );

  const AppPermission(
    this.id,
    this.displayName,
    this.category,
    this.description,
  );

  /// Stable identifier used for persistence. Never change a released value.
  final String id;

  final String displayName;

  final PermissionCategory category;

  final String description;

  static AppPermission fromId(String id) {
    return AppPermission.values.firstWhere(
      (p) => p.id == id,
      orElse: () => throw ArgumentError('صلاحية غير معروفة: $id'),
    );
  }
}

/// Static definition of the permission catalog and the built-in (MUAMAN-14)
/// default configuration for every role.
class PermissionCatalog {
  PermissionCatalog._();

  /// Every permission in the application.
  static Set<AppPermission> get allPermissions => AppPermission.values.toSet();

  /// Permissions that can never be granted to a non-owner role. They are the
  /// powers that would otherwise make a non-owner equivalent to the owner.
  static const Set<AppPermission> ownerExclusive = {
    AppPermission.canManageUsers,
    AppPermission.canManagePermissions,
    AppPermission.canManageDevices,
  };

  /// Default (baseline) configuration for every role. This exactly matches the
  /// behavior of MUAMAN-14: owner = everything, employee = everything except
  /// user management and admin powers, salesOnly = sales creation only.
  static final Map<UserRole, Set<AppPermission>> defaultPermissions = {
    UserRole.owner: allPermissions,
    UserRole.employee: allPermissions.difference({
      AppPermission.canDeleteProducts,
      AppPermission.canDeleteSales,
      AppPermission.canDeleteReturns,
      AppPermission.canDeleteExpenses,
      AppPermission.canManageUsers,
      AppPermission.canManagePermissions,
      AppPermission.canManageDevices,
      AppPermission.canAccessSettings,
    }),
    UserRole.salesOnly: {
      AppPermission.canAccessSales,
      AppPermission.canCreateSales,
    },
  };

  static Set<AppPermission> defaultPermissionsForRole(UserRole role) {
    return defaultPermissions[role] ?? {};
  }

  /// Default-configured access (only meaningful when no persisted override
  /// exists). The live check must go through [services/permission_resolver.dart].
  static bool hasDefaultPermission(UserRole role, AppPermission permission) {
    return defaultPermissions[role]?.contains(permission) ?? false;
  }

  static Set<AppPermission> permissionsForRoleDefault(UserRole role) {
    return defaultPermissions[role] ?? {};
  }

  /// Encodes a permission set to a stable, order-independent string.
  static String encodeSet(Set<AppPermission> permissions) {
    final ids = permissions.map((p) => p.id).toList()..sort();
    return ids.join(',');
  }

  /// Decodes the string produced by [encodeSet]. Unknown ids are ignored so a
  /// corrupt/foreign value can never disable a real permission.
  static Set<AppPermission> decodeSet(String encoded) {
    final trimmed = encoded.trim();
    if (trimmed.isEmpty) return {};
    final result = <AppPermission>{};
    for (final part in trimmed.split(',')) {
      final id = part.trim();
      if (id.isEmpty) continue;
      for (final p in AppPermission.values) {
        if (p.id == id) {
          result.add(p);
          break;
        }
      }
    }
    return result;
  }

  /// Permissions grouped by category, preserving catalog order.
  static Map<PermissionCategory, List<AppPermission>> grouped() {
    final groups = <PermissionCategory, List<AppPermission>>{};
    for (final p in AppPermission.values) {
      groups.putIfAbsent(p.category, () => []).add(p);
    }
    return groups;
  }
}
