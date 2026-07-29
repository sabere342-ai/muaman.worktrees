import '../models/user_role.dart';

enum AppPermission {
  canAccessDashboard,
  canAccessInventory,
  canAccessSales,
  canAccessReturns,
  canAccessExpenses,
  canAccessAnalytics,
  canAccessStocktake,
  canManageUsers,
}

class Permissions {
  static bool hasPermission(UserRole role, AppPermission permission) {
    return _permissionMap[role]?.contains(permission) ?? false;
  }

  static Set<AppPermission> permissionsForRole(UserRole role) {
    return _permissionMap[role] ?? {};
  }

  static const Map<UserRole, Set<AppPermission>> _permissionMap = {
    UserRole.owner: {
      AppPermission.canAccessDashboard,
      AppPermission.canAccessInventory,
      AppPermission.canAccessSales,
      AppPermission.canAccessReturns,
      AppPermission.canAccessExpenses,
      AppPermission.canAccessAnalytics,
      AppPermission.canAccessStocktake,
      AppPermission.canManageUsers,
    },
    UserRole.employee: {
      AppPermission.canAccessDashboard,
      AppPermission.canAccessInventory,
      AppPermission.canAccessSales,
      AppPermission.canAccessReturns,
      AppPermission.canAccessExpenses,
      AppPermission.canAccessAnalytics,
      AppPermission.canAccessStocktake,
    },
    UserRole.salesOnly: {
      AppPermission.canAccessSales,
    },
  };
}
