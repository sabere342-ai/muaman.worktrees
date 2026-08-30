import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../rbac/effective_permission_model.dart';
import 'permission_resolver.dart';
import 'permissions.dart';
import '../models/cloud_session.dart';

class SessionState extends ChangeNotifier {
  SessionState({PermissionResolver? resolver})
      : _resolver = resolver ?? PermissionResolver.instance;

  final PermissionResolver _resolver;
  User? _currentUser;
  CloudSession? _cloudSession;

  /// Phase H sync state tracking.
  int _pendingSyncCount = 0;
  int _failedSyncCount = 0;
  int _conflictSyncCount = 0;
  DateTime? _lastSyncedAt;

  /// A6 (truthful observability): whether the application-owned reconciliation
  /// engine is actually armed to sink the queue to cloud. It is `true` only
  /// when the drain seam is enabled AND a drain worker is live for the bound
  /// tenant. The UI must never present "fully synced"/success while this is
  /// `false`, because no successful reconciliation can have occurred regardless
  /// of pending/failed/conflict counts.
  bool _drainActive = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get currentRole => _currentUser?.role;

  /// Cloud auth session context. Null when not cloud-linked or offline.
  CloudSession? get cloudSession => _cloudSession;
  bool get isCloudLinked => _cloudSession != null;
  bool get isOnline => _cloudSession?.isActive ?? false;
  String? get cloudUserId => _cloudSession?.userId;
  String? get activeShopId => _cloudSession?.activeShopId;

  /// Phase H: Sync status accessors.
  int get pendingSyncCount => _pendingSyncCount;
  int get failedSyncCount => _failedSyncCount;
  int get conflictSyncCount => _conflictSyncCount;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get hasPendingSync => _pendingSyncCount > 0;
  bool get hasFailedSync => _failedSyncCount > 0;
  bool get hasConflictSync => _conflictSyncCount > 0;

  /// A6: whether the reconciliation engine is armed to sink to cloud.
  bool get drainActive => _drainActive;

  /// A6: a truthful derived "the device can actually reconcile" gate. Green /
  /// fully-synced success is only ever presented when this is `true`.
  bool get isReconciling => _drainActive;

  /// Phase H: Update sync counters (called by SyncWorker/Runtime after each
  /// cycle).
  ///
  /// A6 [drainActive] is the authoritative reconciliation-capability flag
  /// published by the owning runtime. It is intentionally optional so existing
  /// callers that only re-publish counts leave the capability unchanged.
  void updateSyncStatus({
    int? pendingCount,
    int? failedCount,
    int? conflictCount,
    DateTime? lastSyncedAt,
    bool? drainActive,
  }) {
    if (pendingCount != null) _pendingSyncCount = pendingCount;
    if (failedCount != null) _failedSyncCount = failedCount;
    if (conflictCount != null) _conflictSyncCount = conflictCount;
    if (lastSyncedAt != null) _lastSyncedAt = lastSyncedAt;
    if (drainActive != null) _drainActive = drainActive;
    notifyListeners();
  }

  /// A6: clears the sync status (counters, last-synced timestamp and the
  /// reconciliation capability). Called on session/tenant boundaries (logout,
  /// shop switch) so stale queue status from one tenant is never presented for
  /// another tenant or after unlink.
  void resetSyncStatus() {
    _clearSyncStatusFields();
    notifyListeners();
  }

  void _clearSyncStatusFields() {
    _pendingSyncCount = 0;
    _failedSyncCount = 0;
    _conflictSyncCount = 0;
    _lastSyncedAt = null;
    _drainActive = false;
  }

  /// The permission resolver this session is bound to.
  PermissionResolver get permissionResolver => _resolver;

  /// Cloud permission snapshot (Phase F). When set, cloud permissions are
  /// the authoritative source for permission checks.
  CloudPermissionSnapshot? get cloudPermissions => _resolver.cloudSnapshot;

  bool hasPermission(AppPermission permission) {
    if (_currentUser == null) return false;
    return _resolver.can(_currentUser!.role, permission);
  }

  void login(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void setCloudSession(CloudSession cloudSession) {
    _cloudSession = cloudSession;
    notifyListeners();
  }

  void clearCloudSession() {
    _cloudSession = null;
    _clearSyncStatusFields();
    notifyListeners();
  }

  void logout() {
    if (_currentUser == null && _cloudSession == null) {
      return;
    }
    _currentUser = null;
    _cloudSession = null;
    // A6: never let one tenant's sync status leak past logout.
    resetSyncStatus();
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
