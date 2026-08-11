import 'package:sqflite/sqflite.dart';
import '../models/user_role.dart';
import 'permissions.dart';
import '../database/database_helper.dart';

/// Persists the per-role permission configuration in the local database.
///
/// Storage is a dedicated `role_permissions` table (created by the database
/// migration). A missing row means "use the built-in default", so upgrading an
/// existing MUAMAN-14 database produces identical effective permissions with
/// no migration-time writes.
///
/// Writes are restricted to the owner and can never target the owner role.
class RolePermissionRepository {
  RolePermissionRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper;

  static final RolePermissionRepository instance = RolePermissionRepository();

  /// Resolved lazily to avoid a constructor-time cycle with the
  /// [DatabaseHelper] singleton (which itself holds a [PermissionResolver]).
  final DatabaseHelper? _dbHelper;

  DatabaseHelper get _helper => _dbHelper ?? DatabaseHelper.instance;

  /// Loads every role's effective configuration. Roles without a stored row
  /// fall back to the built-in defaults.
  Future<Map<UserRole, Set<AppPermission>>> loadAllOrDefaults() async {
    final db = await _helper.database;
    final List<Map<String, Object?>> rows;
    try {
      rows = await db.query('role_permissions');
    } on DatabaseException catch (e) {
      if (e.isNoSuchTableError()) {
        // A database without the role_permissions table has no persisted
        // configuration. Safe fallback = built-in defaults (never allow-all).
        return {
          for (final role in UserRole.values)
            role: PermissionCatalog.defaultPermissionsForRole(role),
        };
      }
      rethrow;
    }
    final stored = <UserRole, Set<AppPermission>>{};
    for (final row in rows) {
      final roleId = row['role'] as String?;
      final encoded = row['permissions'] as String? ?? '';
      final role = UserRole.fromStringOrNull(roleId);
      if (role == null) continue;
      stored[role] = PermissionCatalog.decodeSet(encoded);
    }

    return {
      for (final role in UserRole.values)
        role: stored[role] ?? PermissionCatalog.defaultPermissionsForRole(role),
    };
  }

  /// Stores a role's permission set. Throws [PermissionDeniedException] unless
  /// the actor is the owner, the target is not the owner, and no
  /// owner-exclusive permission is granted to a non-owner role.
  Future<void> saveRolePermissions({
    required UserRole role,
    required Set<AppPermission> permissions,
    required UserRole? actorRole,
  }) async {
    _authorizeWrite(actorRole, role: role, permissions: permissions);

    final db = await _helper.database;
    await db.insert(
      'role_permissions',
      {
        'role': role.value,
        'permissions': PermissionCatalog.encodeSet(permissions),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes a role's stored row so it falls back to the built-in defaults.
  Future<void> resetRoleToDefaults({
    required UserRole role,
    required UserRole? actorRole,
  }) async {
    _authorizeWrite(actorRole, role: role, permissions: null);

    final db = await _helper.database;
    await db
        .delete('role_permissions', where: 'role = ?', whereArgs: [role.value]);
  }

  void _authorizeWrite(
    UserRole? actorRole, {
    required UserRole role,
    required Set<AppPermission>? permissions,
  }) {
    if (actorRole != UserRole.owner) {
      throw const PermissionDeniedException(
          'غير مصرح بتعديل الصلاحيات. هذه الخاصية متاحة للمالك فقط.');
    }
    if (role == UserRole.owner) {
      throw const PermissionDeniedException(
          'لا يمكن تعديل صلاحيات المالك. المالك يتمتع بجميع الصلاحيات دائمًا.');
    }
    if (permissions != null) {
      final exclusive =
          permissions.intersection(PermissionCatalog.ownerExclusive);
      if (exclusive.isNotEmpty) {
        throw PermissionDeniedException(
            'لا يمكن منح دور غير المالك صلاحية محصورة بالمالك: '
            '${exclusive.map((p) => p.displayName).join('، ')}');
      }
    }
  }
}
