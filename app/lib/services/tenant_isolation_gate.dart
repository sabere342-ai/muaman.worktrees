import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'app_settings.dart';

/// Probe result for one tenant-owned table (plan §N).
class TenantTableProbe {
  final String table;

  /// Rows that carry a cloud identity but would be INVISIBLE to the active
  /// shop under strict filtering. Must be 0 before arming.
  final int invisibleMigratedRows;

  /// Legacy local-only rows never migrated (`cloud_uuid IS NULL AND
  /// shop_id IS NULL`). Surfaced in every report, never silently discarded.
  final int residualUnattributedRows;

  const TenantTableProbe({
    required this.table,
    required this.invisibleMigratedRows,
    required this.residualUnattributedRows,
  });
}

/// Result of evaluating the Section-N strict-mode arming preconditions.
class IsolationArmingReport {
  final bool canArm;
  final List<String> blockers;
  final List<TenantTableProbe> probes;

  const IsolationArmingReport({
    required this.canArm,
    required this.blockers,
    required this.probes,
  });

  Map<String, int> get invisibleMigratedRows => {
        for (final p in probes) p.table: p.invisibleMigratedRows,
      };

  Map<String, int> get residualUnattributedRows => {
        for (final p in probes) p.table: p.residualUnattributedRows,
      };

  int get totalInvisibleMigrated =>
      probes.fold(0, (sum, p) => sum + p.invisibleMigratedRows);

  int get totalResidualUnattributed =>
      probes.fold(0, (sum, p) => sum + p.residualUnattributedRows);
}

/// WS6 — strict tenant-filter arming gate over the locked Phase I migration
/// handoff (plan §N).
///
/// Strict shop-scoped reads/writes may only be armed when:
///   1. The active shop's legacy migration has COMPLETED (no non-terminal
///      batch), or the install is genuinely fresh (nothing to attribute).
///   2. The visibility probe finds ZERO migrated rows (`cloud_uuid NOT NULL`)
///      that would be invisible to the active shop.
///   3. Residual unattributed rows exist only when a completed migration pass
///      already adopted attributed data for this shop — an unmigrated legacy
///      database blocks arming so local-only data cannot silently vanish.
///
/// Conservative default: UNARMED. Any failed precondition keeps the runtime
/// on legacy behavior and reports the exact blocker.
class TenantIsolationGate {
  /// AppSettings marker persisted when arming succeeds; cleared on disarm
  /// and force-cleared by restore (plan §P).
  static const String armedMarkerKey = 'cloud.tenantIsolationArmed';

  static const List<String> tenantTables = [
    'products',
    'sales',
    'returns',
    'expenses',
    'expense_categories',
    'customers',
    'invoices',
    'inventory_count',
  ];

  /// Evaluates all Section-N preconditions for [shopId] against [db].
  Future<IsolationArmingReport> evaluate({
    required Database db,
    required String shopId,
  }) async {
    final blockers = <String>[];
    final probes = <TenantTableProbe>[];

    // Precondition 1: migration state for the active shop.
    final nonTerminal = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM legacy_migration_progress "
      "WHERE shop_id = ? AND status NOT IN ('COMPLETED', 'ABORTED')",
      [shopId],
    );
    final hasNonTerminal = ((nonTerminal.first['c'] as num?)?.toInt() ?? 0) > 0;
    if (hasNonTerminal) {
      blockers.add('ترحيل البيانات القديمة غير مكتمل لهذا المتجر');
    }

    final completed = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM legacy_migration_progress "
      "WHERE shop_id = ? AND status = 'COMPLETED'",
      [shopId],
    );
    final hasCompleted = ((completed.first['c'] as num?)?.toInt() ?? 0) > 0;

    // Preconditions 2 + 3: per-table visibility probes.
    for (final table in tenantTables) {
      final invisible = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $table '
        'WHERE cloud_uuid IS NOT NULL AND (shop_id IS NULL OR shop_id != ?)',
        [shopId],
      );
      final residual = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $table '
        'WHERE cloud_uuid IS NULL AND shop_id IS NULL',
      );
      probes.add(TenantTableProbe(
        table: table,
        invisibleMigratedRows: (invisible.first['c'] as num?)?.toInt() ?? 0,
        residualUnattributedRows: (residual.first['c'] as num?)?.toInt() ?? 0,
      ));
    }

    final report = IsolationArmingReport(
      canArm: true,
      blockers: blockers,
      probes: probes,
    );

    // Hard precondition (N.2): no migrated row may become invisible.
    if (report.totalInvisibleMigrated > 0) {
      blockers.add(
          '${report.totalInvisibleMigrated} صف مُرحّل سيصبح غير مرئي للمتجر النشط');
    }

    // N.3 guard: unattributed legacy rows are only acceptable once a
    // completed migration pass exists for this shop (adoption ran). A fresh
    // install with nothing to attribute arms freely.
    if (!hasCompleted && report.totalResidualUnattributed > 0) {
      blockers.add(
          'توجد ${report.totalResidualUnattributed} صف محلي غير منسوب لم تُرحّل بعد');
    }

    return IsolationArmingReport(
      canArm: blockers.isEmpty,
      blockers: blockers,
      probes: probes,
    );
  }

  /// Arms strict tenant filtering after evaluating the preconditions. A
  /// failed evaluation returns the report unchanged WITHOUT arming.
  Future<IsolationArmingReport> arm({
    required Database db,
    required String shopId,
  }) async {
    final report = await evaluate(db: db, shopId: shopId);
    if (!report.canArm) return report;
    await AppSettings.setValue(armedMarkerKey, 'true');
    DatabaseHelper.setTenantIsolationArmed(true);
    return report;
  }

  /// Disarms strict filtering and clears the persistence marker (explicit
  /// owner action or policy reset).
  Future<void> disarm() async {
    await AppSettings.setValue(armedMarkerKey, 'false');
    DatabaseHelper.setTenantIsolationArmed(false);
  }

  /// Turns the runtime flag off while PRESERVING the persistence marker, so
  /// the next authorized login re-evaluates and re-arms (logout path).
  void suspendRuntime() {
    DatabaseHelper.setTenantIsolationArmed(false);
  }

  /// Startup/login re-arm: restores armed state only when the marker is
  /// present AND all Section-N preconditions still hold against the current
  /// database. Anything else leaves the runtime conservatively disarmed
  /// (never half-armed over unattributed data, plan §P).
  Future<bool> restoreAtStartup({
    required Database db,
    String? shopId,
  }) async {
    final marker = await AppSettings.getValue(armedMarkerKey);
    if (marker != 'true') return false;
    if (shopId == null || shopId.trim().isEmpty) return false;
    final report = await evaluate(db: db, shopId: shopId);
    final armed = report.canArm;
    DatabaseHelper.setTenantIsolationArmed(armed);
    return armed;
  }
}
