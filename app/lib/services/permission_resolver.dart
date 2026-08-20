import '../models/user.dart';
import '../models/user_role.dart';
import '../rbac/effective_permission_model.dart';
import 'permissions.dart';
import 'role_permission_repository.dart';

/// Central permission resolver: the single source of truth for whether a role
/// can perform a given action.
///
/// Source of truth chain:
///   Current Session → Role → Persisted Role Permission Configuration →
///   this resolver → UI / navigation / services / database guards.
///
/// Behavior contract:
///  - The owner role is always granted every permission and can never be
///    reduced (prevents owner lockout).
///  - Before the configuration has been loaded (or when no configuration
///    exists), the built-in MUAMAN-14 defaults apply. Those defaults are the
///    safe, fail-closed configuration — never an allow-all.
///  - Cloud permissions take precedence over local config when available
///    (Phase F: server-authoritative permission source).
///  - Changes are applied on the next session for the affected role.
class PermissionResolver {
  PermissionResolver({RolePermissionRepository? repository})
      : _repository = repository ?? RolePermissionRepository.instance;

  static final PermissionResolver instance = PermissionResolver();

  final RolePermissionRepository _repository;

  Map<UserRole, Set<AppPermission>>? _config;

  /// Cloud permission snapshot (Phase F). When set, cloud permissions take
  /// precedence over local config for non-owner roles.
  CloudPermissionSnapshot? _cloudSnapshot;

  /// Loads and caches the persisted configuration. Call once at startup and
  /// after every settings change.
  Future<void> refresh() async {
    _config = await _repository.loadAllOrDefaults();
  }

  /// Clears the cache so the next check falls back to built-in defaults until
  /// [refresh] is called again.
  void invalidate() {
    _config = null;
  }

  /// Set or clear the cloud permission snapshot.
  ///
  /// When set, cloud permissions take precedence over local config for
  /// non-owner roles. Owner always gets all permissions regardless.
  void setCloudSnapshot(CloudPermissionSnapshot? snapshot) {
    _cloudSnapshot = snapshot;
  }

  /// Current cloud permission snapshot (if synced).
  CloudPermissionSnapshot? get cloudSnapshot => _cloudSnapshot;

  bool get isLoaded => _config != null;

  /// Effective permission set for a role. The owner always receives every
  /// permission; a missing configuration falls back to built-in defaults.
  ///
  /// Phase F: When a cloud snapshot is available and fresh, it takes precedence
  /// over local config for non-owner roles. This is the cloud-first resolution.
  Set<AppPermission> effectivePermissions(UserRole role) {
    if (role == UserRole.owner) return PermissionCatalog.allPermissions;

    // Cloud permissions take precedence when available and fresh
    final cloud = _cloudSnapshot;
    if (cloud != null && cloud.isFresh) {
      return cloud.toPermissionSet();
    }

    // Fall back to local config
    final config = _config;
    return config?[role] ?? PermissionCatalog.defaultPermissionsForRole(role);
  }

  /// Whether [role] currently holds [permission].
  bool can(UserRole role, AppPermission permission) {
    return effectivePermissions(role).contains(permission);
  }

  /// Whether [user] currently holds [permission]. A null/unknown user is
  /// always denied.
  bool canForUser(User? user, AppPermission permission) {
    if (user == null) return false;
    return can(user.role, permission);
  }

  /// Current effective configuration for every role (used for display).
  Map<UserRole, Set<AppPermission>> snapshot() {
    return {
      for (final role in UserRole.values) role: effectivePermissions(role),
    };
  }

  /// Persists a role's configuration (owner-only) and refreshes the cache.
  Future<void> saveRolePermissions({
    required UserRole role,
    required Set<AppPermission> permissions,
    required UserRole? actorRole,
  }) async {
    await _repository.saveRolePermissions(
      role: role,
      permissions: permissions,
      actorRole: actorRole,
    );
    await refresh();
  }

  /// Restores a role to built-in defaults (owner-only) and refreshes the cache.
  Future<void> resetRoleToDefaults({
    required UserRole role,
    required UserRole? actorRole,
  }) async {
    await _repository.resetRoleToDefaults(role: role, actorRole: actorRole);
    await refresh();
  }
}
