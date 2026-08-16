# Permission Hardening Report

## Summary

Enforced data-layer permission guards on all sensitive mutation operations at the service/database boundary for the I-TECH application. All mutations now check `AppPermission` via `PermissionResolver` BEFORE executing within a transaction, rejecting unauthorized access with `PermissionDeniedException` deterministically.

## Baseline

- Commit: `e345e95` (T3 Brand Color final commit)
- Branch: `codex/i-tech-permission-hardening`
- Schema changes: 0
- Migration count: 0
- New dependencies: 0

## Permission Model

17 `AppPermission` enum values resolved per role via `PermissionResolver` singleton. Owner has implicit full access (never reduced).

### Default Employee Permissions (operational)

- `canEditProducts`
- `canCreateSales`
- `canCreateReturns`
- `canCreateExpenses`
- `canAccessStocktake`
- `canViewSalesHistory`
- `canExportData`
- `canViewReports`

### Owner-Exclusive Permissions

- `canDeleteProducts`, `canDeleteSales`, `canDeleteReturns`, `canDeleteExpenses`
- `canManageUsers`
- `canManagePermissions`
- `canAccessSettings`

## Guarded Methods

### DatabaseHelper (Core Mutations)

| Method | Permission Required | Fail-Closed |
|--------|-------------------|-------------|
| `insertProduct` | `canEditProducts` | Yes |
| `updateProduct` | `canEditProducts` | Yes |
| `insertSale` | `canCreateSales` | Yes |
| `insertSaleAndDecrementStock` | `canCreateSales` | Yes |
| `insertInvoiceWithItems` | `canCreateSales` | Yes |
| `insertReturn` | `canCreateReturns` | Yes |
| `insertExpense` | `canCreateExpenses` | Yes |
| `saveInventoryCount` | `canAccessStocktake` | Yes |

### UserRepository (User Management)

| Method | Permission Required | Fail-Closed |
|--------|-------------------|-------------|
| `createUser` | `canManageUsers` | Yes |
| `updateUser` | `canManageUsers` | Yes |
| `resetPassword` | `canManageUsers` | Yes |
| `setUserActiveStatus` | `canManageUsers` | Yes |

### Screen-Level UI Gates

- `InventoryCountScreen`: UI-level check via `canAccessStocktake` + data-layer guard
- All screens pass `currentRole: widget.sessionState?.currentRole` to mutation methods

## Guard Pattern

All guarded methods accept optional `{UserRole? currentRole}` parameter. When null or missing permission, `PermissionDeniedException` is thrown before any transaction begins. This is fail-closed: no role context = no mutation.

```dart
void _requirePermission(UserRole? role, AppPermission permission) {
  if (role == null || !_permissions.can(role, permission)) {
    throw PermissionDeniedException(
      'Permission denied: ${permission.id}',
    );
  }
}
```

## Test Coverage

### Permission Hardening Tests (33 tests)

File: `test/database/permission_hardening_test.dart`

- **NC01-NC02**: Product create/update authorization (owner, authorized employee, unauthorized employee, no-role)
- **NC03-NC04**: Sale/Invoice creation authorization (owner, authorized employee, unauthorized employee)
- **NC05**: Return creation authorization
- **NC06**: Expense creation authorization
- **NC07**: Inventory count authorization
- **NC08**: User management authorization (owner, employee, unauthorized)
- **NC09**: Owner remains allowed for all mutations
- **NC10**: Existing delete guard preserved

### Existing Test Compatibility

All 550 tests pass (up from 517 baseline + 33 new permission tests). Test files updated to provide `currentRole: UserRole.owner` authorization context where testing business logic (not permission logic).

## Files Modified

### Source Files (8)

- `app/lib/database/database_helper.dart` — Core mutation guards
- `app/lib/database/user_repository.dart` — User management guards
- `app/lib/main.dart` — InventoryCountScreen sessionState pass-through
- `app/lib/screens/admin/user_management_screen.dart` — currentRole pass-through
- `app/lib/screens/expenses/expenses_screen.dart` — currentRole + error handling
- `app/lib/screens/inventory/inventory_screen.dart` — currentRole pass-through
- `app/lib/screens/inventory_count/inventory_count_screen.dart` — SessionState + UI gate
- `app/lib/screens/returns/returns_screen.dart` — currentRole + error handling
- `app/lib/screens/sales/invoice_screen.dart` — currentRole pass-through

### Test Files (11)

- `app/test/database/permission_hardening_test.dart` (NEW)
- `app/test/database/inventory_count_transaction_test.dart`
- `app/test/database/product_normalization_test.dart`
- `app/test/database/product_reference_integrity_test.dart`
- `app/test/database/product_validation_test.dart`
- `app/test/database/sale_return_update_consistency_test.dart`
- `app/test/database/sale_transaction_test.dart`
- `app/test/database/user_repository_test.dart`
- `app/test/exploratory/barcode_and_deletion_test.dart`
- `app/test/features/enter_key_behavior_test.dart`
- `app/test/features/invoice_pdf_delivery_test.dart`
- `app/test/features/sales_invoice_behavior_test.dart`

### Formatting-Only Changes (4)

- `app/lib/screens/admin/roles_permissions_screen.dart`
- `app/lib/screens/sales/sales_report_screen.dart`
- `app/lib/screens/settings_screen.dart`
- `app/test/database/app_settings_brand_color_test.dart`

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze` | 0 issues |
| `flutter test` | 550/550 PASS (0 failures) |
| `flutter build windows --release` | Success |
| Schema changes | 0 |
| Migration count | 0 |
| New dependencies | 0 |
| Commit count above e345e95 | 1 |
| Merge commits | 0 |
