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

  /// Phase H: Update sync counters (called by SyncWorker after each cycle).
  void updateSyncStatus({
    int? pendingCount,
    int? failedCount,
    int? conflictCount,
    DateTime? lastSyncedAt,
  }) {
    if (pendingCount != null) _pendingSyncCount = pendingCount;
    if (failedCount != null) _failedSyncCount = failedCount;
    if (conflictCount != null) _conflictSyncCount = conflictCount;
    if (lastSyncedAt != null) _lastSyncedAt = lastSyncedAt;
    notifyListeners();
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
    notifyListeners();
  }

  void logout() {
    if (_currentUser == null && _cloudSession == null) {
      return;
    }
    _currentUser = null;
    _cloudSession = null;
    notifyListeners();
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
