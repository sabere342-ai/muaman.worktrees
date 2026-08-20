import 'dart:convert';

import '../services/app_settings.dart';
import 'effective_permission_model.dart';

/// Local persistence for cloud permission snapshots.
///
/// Uses the existing `app_settings` key-value table for storage. Each shop's
/// permission snapshot is scoped by shop ID. The cache is informational only
/// and never serves as a security authority.
class PermissionCache {
  static const _prefix = 'cloud.permissions.';
  static const _lastSyncKey = 'cloud.permissions.lastSyncAt';
  static const _versionKey = 'cloud.permissions.version';

  /// Save a permission snapshot for a shop.
  Future<void> save(CloudPermissionSnapshot snapshot) async {
    final key = '$_prefix${snapshot.shopId}';
    final json = jsonEncode(snapshot.toJson());
    await AppSettings.setValue(key, json);
    await AppSettings.setValue(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Load a cached permission snapshot for a shop.
  ///
  /// Returns null if no cache exists or if the cache is corrupted.
  Future<CloudPermissionSnapshot?> load(String shopId) async {
    try {
      final key = '$_prefix$shopId';
      final raw = await AppSettings.getValue(key);
      if (raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CloudPermissionSnapshot.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Clear the cached snapshot for a specific shop.
  Future<void> clear(String shopId) async {
    final key = '$_prefix$shopId';
    await AppSettings.setValue(key, '');
  }

  /// Clear all cached permission data.
  Future<void> clearAll() async {
    final keysToClear = [
      _lastSyncKey,
      _versionKey,
    ];
    for (final key in keysToClear) {
      await AppSettings.setValue(key, '');
    }
  }

  /// Get the last successful sync timestamp.
  Future<DateTime?> getLastSyncTime() async {
    final raw = await AppSettings.getValue(_lastSyncKey);
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Get the current cache version token.
  Future<int> getVersion() async {
    final raw = await AppSettings.getValue(_versionKey);
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }

  /// Set the cache version token.
  Future<void> setVersion(int version) async {
    await AppSettings.setValue(_versionKey, '$version');
  }
}
