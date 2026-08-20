import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'permission_resolver.dart';
import 'permissions.dart';
import '../models/cloud_session.dart';

class SessionState extends ChangeNotifier {
  SessionState({PermissionResolver? resolver})
      : _resolver = resolver ?? PermissionResolver.instance;

  final PermissionResolver _resolver;
  User? _currentUser;
  CloudSession? _cloudSession;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get currentRole => _currentUser?.role;

  /// Cloud auth session context. Null when not cloud-linked or offline.
  CloudSession? get cloudSession => _cloudSession;
  bool get isCloudLinked => _cloudSession != null;
  bool get isOnline => _cloudSession?.isActive ?? false;
  String? get cloudUserId => _cloudSession?.userId;
  String? get activeShopId => _cloudSession?.activeShopId;

  /// The permission resolver this session is bound to.
  PermissionResolver get permissionResolver => _resolver;

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
