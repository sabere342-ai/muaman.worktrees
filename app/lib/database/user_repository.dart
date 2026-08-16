import '../models/user.dart';
import '../models/user_role.dart';
import '../services/password_hasher.dart';
import '../services/permissions.dart';
import '../services/permission_resolver.dart';
import 'database_helper.dart';

class DuplicateUsernameException implements Exception {
  final String username;
  DuplicateUsernameException(this.username);

  @override
  String toString() => 'DuplicateUsernameException: "$username" already exists';
}

class UserNotFoundException implements Exception {
  final String detail;
  UserNotFoundException([this.detail = '']);

  @override
  String toString() => 'UserNotFoundException: $detail';
}

class LastActiveOwnerException implements Exception {
  final String message;
  LastActiveOwnerException(this.message);

  @override
  String toString() => 'LastActiveOwnerException: $message';
}

class CannotDisableCurrentUserException implements Exception {
  @override
  String toString() => 'CannotDisableCurrentUserException';
}

class WeakPasswordException implements Exception {
  @override
  String toString() =>
      'WeakPasswordException: Password must be at least 6 characters';
}

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PasswordHasher _hasher = PasswordHasher();

  PermissionResolver permissionResolver = PermissionResolver.instance;

  void _requireAdminPermission(UserRole? currentRole) {
    if (currentRole == null ||
        !permissionResolver.can(currentRole, AppPermission.canManageUsers)) {
      throw const PermissionDeniedException(
          'غير مصرح بهذه العملية. هذه الخاصية غير متاحة لدورك.');
    }
  }

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  void _validateDisplayName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError('الاسم مطلوب');
    }
  }

  void _validateUsername(String username) {
    if (username.trim().isEmpty) {
      throw ArgumentError('اسم المستخدم مطلوب');
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw ArgumentError('كلمة المرور مطلوبة');
    }
    if (password.length < 6) {
      throw WeakPasswordException();
    }
  }

  void _validateRole(UserRole role) {
    try {
      UserRole.fromString(role.value);
    } on InvalidUserRoleException {
      rethrow;
    }
  }

  Future<int> createUser({
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
    bool isActive = true,
    UserRole? currentRole,
  }) async {
    _requireAdminPermission(currentRole);
    _validateDisplayName(displayName);
    _validateUsername(username);
    _validatePassword(password);
    _validateRole(role);

    final normalizedUsername = _normalizeUsername(username);
    final db = await _dbHelper.database;

    final existing = await db.rawQuery(
      'SELECT id FROM users WHERE LOWER(TRIM(username)) = ? LIMIT 1',
      [normalizedUsername],
    );
    if (existing.isNotEmpty) {
      throw DuplicateUsernameException(username);
    }

    final passwordHash = _hasher.hashPassword(password);
    final now = DateTime.now();

    final user = User(
      displayName: displayName.trim(),
      username: normalizedUsername,
      passwordHash: passwordHash,
      role: role,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    return await db.insert('users', user.toMap()..remove('id'));
  }

  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('users', orderBy: 'id ASC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserByUsername(String username) async {
    final normalized = _normalizeUsername(username);
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      'SELECT * FROM users WHERE LOWER(TRIM(username)) = ? LIMIT 1',
      [normalized],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<bool> hasAnyUser() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final count = (result.first['count'] as num?)?.toInt() ?? 0;
    return count > 0;
  }

  Future<int> updateUser({
    required int id,
    String? displayName,
    String? username,
    UserRole? role,
    bool? isActive,
    UserRole? currentRole,
  }) async {
    _requireAdminPermission(currentRole);
    final db = await _dbHelper.database;

    final existing = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) {
      throw UserNotFoundException('User id=$id not found');
    }

    final user = User.fromMap(existing.first);

    if (displayName != null) {
      _validateDisplayName(displayName);
    }
    if (username != null) {
      _validateUsername(username);
      final normalizedNew = _normalizeUsername(username);
      final dup = await db.rawQuery(
        'SELECT id FROM users WHERE LOWER(TRIM(username)) = ? AND id != ? LIMIT 1',
        [normalizedNew, id],
      );
      if (dup.isNotEmpty) {
        throw DuplicateUsernameException(username);
      }
    }
    if (role != null) {
      _validateRole(role);
    }

    if (isActive == false && user.role == UserRole.owner) {
      final activeOwners = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE role = ? AND isActive = 1 AND id != ?',
        ['owner', id],
      );
      final count = (activeOwners.first['count'] as num?)?.toInt() ?? 0;
      if (count == 0) {
        throw LastActiveOwnerException('لا يمكن تعطيل آخر مالك نشط');
      }
    }

    if (role != null && role != UserRole.owner && user.role == UserRole.owner) {
      final activeOwners = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE role = ? AND isActive = 1 AND id != ?',
        ['owner', id],
      );
      final count = (activeOwners.first['count'] as num?)?.toInt() ?? 0;
      if (count == 0) {
        throw LastActiveOwnerException('لا يمكن تغيير دور آخر مالك نشط');
      }
    }

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (displayName != null) updates['displayName'] = displayName.trim();
    if (username != null) updates['username'] = _normalizeUsername(username);
    if (role != null) updates['role'] = role.value;
    if (isActive != null) updates['isActive'] = isActive ? 1 : 0;

    final affected =
        await db.update('users', updates, where: 'id = ?', whereArgs: [id]);

    if (affected == 0) {
      throw StateError('فشل تحديث المستخدم');
    }

    return affected;
  }

  Future<void> resetPassword({
    required int id,
    required String newPassword,
    UserRole? currentRole,
  }) async {
    _requireAdminPermission(currentRole);
    _validatePassword(newPassword);

    final db = await _dbHelper.database;
    final existing = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) {
      throw UserNotFoundException('User id=$id not found');
    }

    final passwordHash = _hasher.hashPassword(newPassword);
    final now = DateTime.now().toIso8601String();

    final affected = await db.update(
      'users',
      {
        'passwordHash': passwordHash,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (affected == 0) {
      throw StateError('فشل إعادة تعيين كلمة المرور');
    }
  }

  Future<void> setUserActiveStatus({
    required int id,
    required bool isActive,
    int? currentUserId,
    UserRole? currentRole,
  }) async {
    _requireAdminPermission(currentRole);
    final db = await _dbHelper.database;

    final existing = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (existing.isEmpty) {
      throw UserNotFoundException('User id=$id not found');
    }

    if (currentUserId != null && id == currentUserId && !isActive) {
      throw CannotDisableCurrentUserException();
    }

    final user = User.fromMap(existing.first);
    if (user.role == UserRole.owner && !isActive) {
      final activeOwners = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE role = ? AND isActive = 1 AND id != ?',
        ['owner', id],
      );
      final count = (activeOwners.first['count'] as num?)?.toInt() ?? 0;
      if (count == 0) {
        throw LastActiveOwnerException('لا يمكن تعطيل آخر مالك نشط');
      }
    }

    final now = DateTime.now().toIso8601String();
    final affected = await db.update(
      'users',
      {
        'isActive': isActive ? 1 : 0,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (affected == 0) {
      throw StateError('فشل تحديث حالة المستخدم');
    }
  }

  Future<User?> authenticate(String username, String password) async {
    final user = await getUserByUsername(username);
    if (user == null) return null;
    if (!user.isActive) return null;
    if (!_hasher.verifyPassword(password, user.passwordHash)) return null;
    return user;
  }

  Future<void> updateLastLogin(int userId) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'lastLoginAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
