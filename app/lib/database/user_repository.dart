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

/// Thrown when a cloud membership role cannot be provisioned as a local
/// seller row (Phase L D-L3/D-L4). Owner-role memberships are ALWAYS
/// rejected here so a fresh device can never be elevated to ownership
/// through the seller cloud-login path.
class CloudIdentityRoleConflictException implements Exception {
  final String membershipRole;
  CloudIdentityRoleConflictException(this.membershipRole);

  @override
  String toString() =>
      'CloudIdentityRoleConflictException: cloud membership role '
      '"$membershipRole" cannot be provisioned as a seller local row';
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

  /// Set the cloud UUID for a local user (Phase D identity linking).
  /// Once set, the cloud UUID is immutable — this method is a no-op if
  /// the user already has a cloud UUID.
  Future<void> setCloudUuid(int userId, String cloudUuid) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'users',
      columns: ['cloud_uuid'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (existing.isEmpty) return;
    final current = existing.first['cloud_uuid'] as String?;
    if (current != null && current.isNotEmpty) return; // immutable once set
    await db.update(
      'users',
      {'cloud_uuid': cloudUuid},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Get the cloud UUID for a local user, if set.
  Future<String?> getCloudUuid(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      columns: ['cloud_uuid'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) return null;
    final uuid = rows.first['cloud_uuid'] as String?;
    return (uuid != null && uuid.isNotEmpty) ? uuid : null;
  }

  /// Get the local user by their cloud UUID.
  Future<User?> getUserByCloudUuid(String cloudUuid) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'cloud_uuid = ?',
      whereArgs: [cloudUuid],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Phase L (D-L4): provision or match the local user CACHE row for a
  /// cloud-authenticated seller, keyed immutably by `users.cloud_uuid`.
  ///
  /// The local row is a cache for SessionState plumbing — it is NEVER an
  /// authorization source. The role is mapped ONLY from the cloud
  /// membership role (employee -> employee, salesOnly -> salesOnly); any
  /// other membership role — including owner — is rejected (D-L3
  /// ownership-hijack prevention). No local password is required for
  /// cloud-mode sessions: the stored hash is an unusable random secret
  /// because cloud sessions never authenticate via the local PBKDF2 path.
  /// An existing row with the same cloud_uuid is reused, never duplicated.
  Future<User> upsertCloudUser({
    required String cloudUuid,
    String? displayName,
    required String membershipRole,
  }) async {
    if (cloudUuid.trim().isEmpty) {
      throw ArgumentError('معرف الحساب السحابي مطلوب');
    }
    final UserRole mappedRole;
    switch (membershipRole) {
      case 'employee':
        mappedRole = UserRole.employee;
        break;
      case 'salesOnly':
        mappedRole = UserRole.salesOnly;
        break;
      default:
        throw CloudIdentityRoleConflictException(membershipRole);
    }

    final db = await _dbHelper.database;
    final now = DateTime.now();
    final resolvedName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : null;

    final existing = await db.query(
      'users',
      where: 'cloud_uuid = ?',
      whereArgs: [cloudUuid],
    );

    if (existing.isNotEmpty) {
      // Reuse the existing cached row: refresh display name, mapped role
      // and last-login. Never duplicate rows for one cloud identity.
      final current = User.fromMap(existing.first);
      await db.update(
        'users',
        {
          'displayName': resolvedName ?? current.displayName,
          'role': mappedRole.value,
          'lastLoginAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [current.id],
      );
      return (await getUserById(current.id!))!;
    }

    var attempt = 0;
    var username = _cloudUsername(cloudUuid, attempt);
    while ((await getUserByUsername(username)) != null) {
      attempt += 1;
      username = _cloudUsername(cloudUuid, attempt);
    }

    final unusableSecret =
        'cloud-session:${now.microsecondsSinceEpoch}:$cloudUuid';
    final row = User(
      displayName: resolvedName ?? 'موظف',
      username: username,
      passwordHash: _hasher.hashPassword(unusableSecret),
      role: mappedRole,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
    );
    final map = row.toMap()..remove('id');
    map['cloud_uuid'] = cloudUuid;
    await db.insert('users', map);

    final created = await getUserByCloudUuid(cloudUuid);
    if (created == null) {
      throw StateError('فشل تجهيز حساب الموظف المحلي');
    }
    return created;
  }

  String _cloudUsername(String cloudUuid, int attempt) {
    final stem = cloudUuid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final prefix =
        stem.length >= 10 ? stem.substring(0, 10) : stem.padRight(10, '0');
    return attempt == 0 ? 'cloud.$prefix' : 'cloud.$prefix.$attempt';
  }
}
