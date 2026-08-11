import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'permissions.dart';

class SessionState extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get currentRole => _currentUser?.role;

  bool hasPermission(AppPermission permission) {
    if (_currentUser == null) return false;
    return Permissions.hasPermission(_currentUser!.role, permission);
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
