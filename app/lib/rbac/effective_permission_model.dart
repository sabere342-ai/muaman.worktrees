import '../services/permissions.dart';

/// An individual permission override entry.
class PermissionOverride {
  final String permissionId;
  final String effect; // 'ALLOW' or 'DENY'

  const PermissionOverride({
    required this.permissionId,
    required this.effect,
  });

  factory PermissionOverride.fromMap(Map<String, dynamic> map) {
    return PermissionOverride(
      permissionId: map['permission_id'] as String,
      effect: map['effect'] as String,
    );
  }

  bool get isAllow => effect == 'ALLOW';
  bool get isDeny => effect == 'DENY';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionOverride &&
        other.permissionId == permissionId &&
        other.effect == effect;
  }

  @override
  int get hashCode => Object.hash(permissionId, effect);
}

/// Server-resolved permission snapshot for a user in a specific shop.
///
/// This is the authoritative permission state from the cloud. The client
/// uses it for UI gating only — the server revalidates every cloud RPC.
class CloudPermissionSnapshot {
  final String shopId;
  final String memberRole;
  final Set<String> permissionIds;
  final List<PermissionOverride> overrides;
  final int catalogVersion;
  final DateTime serverTime;
  final DateTime permissionsUpdatedAt;
  final DateTime cachedAt;

  const CloudPermissionSnapshot({
    required this.shopId,
    required this.memberRole,
    required this.permissionIds,
    required this.overrides,
    required this.catalogVersion,
    required this.serverTime,
    required this.permissionsUpdatedAt,
    required this.cachedAt,
  });

  factory CloudPermissionSnapshot.fromRpc(
    Map<String, dynamic> data, {
    DateTime? localTime,
  }) {
    final permissionsList =
        (data['permissions'] as List?)?.map((e) => e as String).toList() ?? [];
    final overridesList = (data['overrides'] as List?)
            ?.map((e) =>
                PermissionOverride.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    return CloudPermissionSnapshot(
      shopId: data['shop_id'] as String,
      memberRole: data['member_role'] as String,
      permissionIds: permissionsList.toSet(),
      overrides: overridesList,
      catalogVersion: data['catalog_version'] as int? ?? 1,
      serverTime: data['server_time'] != null
          ? DateTime.parse(data['server_time'] as String)
          : DateTime.now().toUtc(),
      permissionsUpdatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : DateTime.now().toUtc(),
      cachedAt: localTime ?? DateTime.now(),
    );
  }

  /// Whether this snapshot is still fresh (within TTL).
  bool get isFresh {
    final age = DateTime.now().difference(cachedAt);
    return age.inHours < 1;
  }

  /// Whether the snapshot has changed since it was cached.
  bool isStaleWith(DateTime otherServerTime) {
    return permissionsUpdatedAt.isBefore(otherServerTime);
  }

  /// Convert to the AppPermission enum set used by the existing resolver.
  Set<AppPermission> toPermissionSet() {
    final result = <AppPermission>{};
    for (final id in permissionIds) {
      try {
        result.add(AppPermission.fromId(id));
      } catch (_) {
        // Unknown permission ID — skip (fail closed for unknown)
      }
    }
    return result;
  }

  /// Convert to JSON for cache persistence.
  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'member_role': memberRole,
      'permissions': permissionIds.toList(),
      'overrides': overrides
          .map((o) => {'permission_id': o.permissionId, 'effect': o.effect})
          .toList(),
      'catalog_version': catalogVersion,
      'server_time': serverTime.toIso8601String(),
      'permissions_updated_at': permissionsUpdatedAt.toIso8601String(),
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  /// Restore from JSON (cache deserialization).
  factory CloudPermissionSnapshot.fromJson(Map<String, dynamic> json) {
    return CloudPermissionSnapshot(
      shopId: json['shop_id'] as String,
      memberRole: json['member_role'] as String,
      permissionIds:
          (json['permissions'] as List?)?.map((e) => e as String).toSet() ?? {},
      overrides: (json['overrides'] as List?)
              ?.map((e) => PermissionOverride.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      catalogVersion: json['catalog_version'] as int? ?? 1,
      serverTime: DateTime.parse(json['server_time'] as String),
      permissionsUpdatedAt:
          DateTime.parse(json['permissions_updated_at'] as String),
      cachedAt: json['cached_at'] != null
          ? DateTime.parse(json['cached_at'] as String)
          : DateTime.now(),
    );
  }
}
