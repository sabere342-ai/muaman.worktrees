import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import '../models/shop_profile.dart';
import '../models/user_role.dart';
import 'permission_resolver.dart';
import 'permissions.dart';
import 'shop_profile_repository.dart';

/// Central in-memory state for the shop identity.
///
/// Architecture:
///   persistent Shop Profile (app_settings table)
///         ↓
///   ShopProfileRepository (read/write)
///         ↓
///   ShopProfileService (ChangeNotifier singleton state + authorization)
///         ↓
///   UI / Settings / headers / branding consumers
///
/// Writes are authorized through [PermissionResolver] with
/// [AppPermission.canAccessSettings] — never via a direct role check.
class ShopProfileService extends ChangeNotifier {
  ShopProfileService({
    ShopProfileRepository? repository,
    String? logoDirectory,
  })  : _repository = repository ?? ShopProfileRepository(),
        _logoDirectory = logoDirectory;

  static final ShopProfileService instance = ShopProfileService();

  final ShopProfileRepository _repository;

  /// Overridable managed logo destination (used by tests to avoid writing next
  /// to the real application database).
  final String? _logoDirectory;

  static const Set<String> _supportedImageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.bmp',
    '.webp',
  };

  ShopProfile _current = ShopProfile.defaultProfile();
  bool _isLoaded = false;

  ShopProfile get current => _current;

  bool get isLoaded => _isLoaded;

  /// Loads (or reloads) the profile from persistence. A stored logo whose file
  /// no longer exists is normalized to "no logo" so consumers can fall back
  /// safely without crashing.
  Future<void> load() async {
    var profile = await _repository.load();
    if (profile.logoPath.isNotEmpty && !File(profile.logoPath).existsSync()) {
      profile = profile.copyWith(logoPath: '');
    }
    _current = profile;
    _isLoaded = true;
    notifyListeners();
  }

  /// Resets the in-memory state to defaults (used for test isolation and on
  /// logout-sensitive boundaries).
  void invalidate() {
    _current = ShopProfile.defaultProfile();
    _isLoaded = false;
  }

  /// Persists [profile]. Throws [PermissionDeniedException] unless the actor
  /// holds [AppPermission.canAccessSettings]. Throws [ArgumentError] for an
  /// invalid logo source path or a blank shop name.
  ///
  /// [logoSourcePath]: optional user-picked image path. When non-empty and
  /// different from the profile's current managed logo, a managed copy is
  /// stored next to the application database so the logo survives restart
  /// regardless of the original file.
  Future<void> save(
    ShopProfile profile, {
    UserRole? actorRole,
    String? logoSourcePath,
  }) async {
    _authorize(actorRole);

    final trimmed = profile.copyWith(shopName: profile.shopName.trim());
    if (trimmed.shopName.isEmpty) {
      throw ArgumentError('اسم المحل مطلوب');
    }

    var toSave = trimmed;
    final source = logoSourcePath?.trim() ?? '';
    if (source.isNotEmpty && source != profile.logoPath) {
      final managedPath = await _copyLogoToManagedLocation(source);
      toSave = toSave.copyWith(logoPath: managedPath);
    }

    await _repository.save(toSave);
    _current = toSave;
    _isLoaded = true;
    notifyListeners();
  }

  void _authorize(UserRole? actorRole) {
    if (actorRole == null ||
        !PermissionResolver.instance
            .can(actorRole, AppPermission.canAccessSettings)) {
      throw const PermissionDeniedException(
          'غير مصرح بتعديل بيانات المحل. هذه الخاصية غير متاحة لدورك.');
    }
  }

  Future<String> _copyLogoToManagedLocation(String sourcePath) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw ArgumentError('ملف الشعار غير موجود: $sourcePath');
    }
    final extension = p.extension(sourcePath).toLowerCase();
    if (!_supportedImageExtensions.contains(extension)) {
      throw ArgumentError('صيغة الشعار غير مدعومة: $extension');
    }

    final directory = _logoDirectory ?? await getDatabasesPath();
    await Directory(directory).create(recursive: true);
    final destination = p.join(directory, 'shop_logo$extension');
    await source.copy(destination);
    return destination;
  }
}
