import 'dart:async';

import '../config/app_config.dart';
import '../services/permission_resolver.dart';
import 'cloud_permission_repository.dart';
import 'effective_permission_model.dart';
import 'permission_cache.dart';

/// Orchestrates cloud-to-local permission synchronization.
///
/// This service:
/// 1. Fetches server-authoritative permissions via RPC
/// 2. Caches them locally for UI gating
/// 3. Updates the [PermissionResolver] with cloud data
/// 4. Handles cache invalidation and refresh
///
/// The cached permissions are NEVER the security authority. The server
/// reauthorizes every cloud RPC independently.
class PermissionSyncService {
  static final PermissionSyncService _instance = PermissionSyncService._();
  factory PermissionSyncService() => _instance;
  PermissionSyncService._();

  static PermissionSyncService get instance => _instance;

  final CloudPermissionRepository _repository = CloudPermissionRepository();
  final PermissionCache _cache = PermissionCache();
  final PermissionResolver _resolver = PermissionResolver.instance;

  CloudPermissionSnapshot? _currentSnapshot;
  String? _activeShopId;
  bool _syncing = false;

  /// Current permission snapshot (if synced).
  CloudPermissionSnapshot? get currentSnapshot => _currentSnapshot;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _syncing;

  /// The active shop ID this service is tracking.
  String? get activeShopId => _activeShopId;

  /// Sync permissions for the given shop.
  ///
  /// Fetches from the server, caches locally, and updates the resolver.
  /// On failure, falls back to cached data if available.
  Future<CloudPermissionSnapshot?> syncPermissions(String shopId) async {
    if (_syncing) return _currentSnapshot;
    _syncing = true;

    try {
      if (!AppConfig.isConfigured) {
        // Offline — use cached data
        final cached = await _cache.load(shopId);
        if (cached != null) {
          _currentSnapshot = cached;
          _activeShopId = shopId;
          _applyToResolver(cached);
        }
        return cached;
      }

      // Online: fetch from server
      final snapshot = await _repository.syncUserPermissions(shopId);
      _currentSnapshot = snapshot;
      _activeShopId = shopId;

      // Cache the result
      await _cache.save(snapshot);

      // Update the resolver
      _applyToResolver(snapshot);

      return snapshot;
    } catch (e) {
      // Server failure — fall back to cache
      final cached = await _cache.load(shopId);
      if (cached != null) {
        _currentSnapshot = cached;
        _activeShopId = shopId;
        _applyToResolver(cached);
      }
      return cached;
    } finally {
      _syncing = false;
    }
  }

  /// Force refresh permissions for the active shop.
  Future<CloudPermissionSnapshot?> refreshPermissions() async {
    if (_activeShopId == null) return null;
    return await syncPermissions(_activeShopId!);
  }

  /// Switch to a different shop and sync its permissions.
  Future<CloudPermissionSnapshot?> switchShop(String newShopId) async {
    // Clear current cloud snapshot (different shop)
    _currentSnapshot = null;
    _activeShopId = newShopId;
    return await syncPermissions(newShopId);
  }

  /// Clear in-memory state (on logout). Cache is retained.
  void reset() {
    _currentSnapshot = null;
    _activeShopId = null;
    _syncing = false;
    _clearResolver();
  }

  /// Whether the current snapshot is fresh enough to use.
  bool get isCurrentSnapshotFresh => _currentSnapshot?.isFresh ?? false;

  // ─── Private helpers ─────────────────────────────────────────────

  /// Apply cloud snapshot to the PermissionResolver.
  void _applyToResolver(CloudPermissionSnapshot snapshot) {
    _resolver.setCloudSnapshot(snapshot);
  }

  /// Clear cloud snapshot from the resolver.
  void _clearResolver() {
    _resolver.setCloudSnapshot(null);
  }
}
