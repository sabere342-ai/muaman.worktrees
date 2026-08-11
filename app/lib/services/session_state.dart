import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'permission_resolver.dart';
import 'permissions.dart';

class SessionState extends ChangeNotifier {
  SessionState({PermissionResolver? resolver})
      : _resolver = resolver ?? PermissionResolver.instance;

  final PermissionResolver _resolver;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get currentRole => _currentUser?.role;

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

  void logout() {
    if (_currentUser == null) {
      return;
    }
    _currentUser = null;
    notifyListeners();
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
