/// Thrown by business write paths when legacy-migration maintenance mode is
/// active (Phase I / D11).
class MaintenanceModeException implements Exception {
  final String message;
  const MaintenanceModeException(this.message);

  @override
  String toString() => 'MaintenanceModeException: $message';
}

/// Phase I / D11 maintenance-mode seam.
///
/// While enabled, every [DatabaseHelper] business write throws early (the
/// guard is invoked from the central `_enforceLicensing` choke point shared by
/// all write APIs), so no live data can change between the pinned snapshot and
/// final stamping. Reads stay allowed and the UI may surface a persistent
/// banner keyed off [isEnabled]. The Phase H sync worker consults the same
/// flag to suspend polling while a batch runs (D7).
///
/// DB-level safety nets remain (snapshot-hash pinning plus live-delta
/// detection at finalization) because programmatic writes bypass this guard.
class MigrationMaintenanceMode {
  MigrationMaintenanceMode._();

  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  static void enable() => _enabled = true;

  static void disable() => _enabled = false;

  /// Must be called before any business mutation; throws when maintenance
  /// mode is active so writes fail closed before touching any table.
  static void ensureWritesAllowed() {
    if (_enabled) {
      throw const MaintenanceModeException(
          'ترحيل البيانات قيد التشغيل حاليًا. تعديل البيانات مقفل مؤقتًا حتى انتهاء الترحيل.');
    }
  }

  /// Test-only reset.
  static void resetForTest() => _enabled = false;
}
