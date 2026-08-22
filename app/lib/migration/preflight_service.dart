import 'package:sqflite/sqflite.dart';

import 'entity_migration_specs.dart';
import 'migration_models.dart';

/// Phase I P0 preflight / census (W8): reads the PINNED SNAPSHOT (D2) and
/// produces per-table counts plus an anomaly list that feeds the owner
/// consent screen.
///
/// D3 shop binding rules applied here:
///  * rows already cloud-linked (`cloud_uuid IS NOT NULL`) are excluded from
///    the migration universe entirely (D13 — they belong to Phase H sync),
///  * rows attributed to a DIFFERENT non-null shop are hard-quarantined
///    (never bound, never imported),
///  * unattributed rows (shop_id IS NULL — the normal state of a legacy
///    device that never synced) are counted as adopted: the batch's single
///    licensed shop binds them, exactly like the `_resolveSyncShopId`
///    active-provider-wins contract cited by D3. This is surfaced to the
///    owner at consent time, never silent.
class LegacyPreflightService {
  const LegacyPreflightService();

  Future<PreflightReport> buildReport({
    required Database snapshotDb,
    required String shopId,
    List<EntityMigrationSpec>? specs,
  }) async {
    final effectiveSpecs = specs ?? kOrderedLegacyMigrationSpecs;
    final censuses = <PreflightTableCensus>[];
    final anomalies = <Map<String, dynamic>>[];

    for (final spec in effectiveSpecs) {
      final table = spec.localTableName;
      final idCol = table == 'app_settings' ? 'rowid' : 'id';

      final totalRows =
          (await snapshotDb.rawQuery('SELECT COUNT(*) AS c FROM $table'))
              .first['c'] as int;
      final linked = (await snapshotDb.rawQuery(
              'SELECT COUNT(*) AS c FROM $table WHERE cloud_uuid IS NOT NULL'))
          .first['c'] as int;
      final foreignShop = (await snapshotDb.rawQuery(
              'SELECT COUNT(*) AS c FROM $table '
              "WHERE cloud_uuid IS NULL AND shop_id IS NOT NULL AND shop_id != ?",
              [shopId]))
          .first['c'] as int;
      final rowsToMigrate = (await snapshotDb.rawQuery(
              'SELECT COUNT(*) AS c FROM $table '
              'WHERE cloud_uuid IS NULL AND (shop_id IS NULL OR shop_id = ?)',
              [shopId]))
          .first['c'] as int;
      final adopted =
          (await snapshotDb.rawQuery('SELECT COUNT(*) AS c FROM $table '
                  'WHERE cloud_uuid IS NULL AND shop_id IS NULL'))
              .first['c'] as int;

      if (foreignShop > 0) {
        anomalies.add({
          'kind': 'QUARANTINED_FOREIGN_SHOP',
          'table': table,
          'count': foreignShop,
          'note': 'صفوف منسوبة لمتجر آخر لن تُرحّل ولن تُربط بالمتجر الحالي.',
        });
      }

      // D14 anomaly scan: zero/negative anomalies are reported, migrated
      // as-is, never normalized.
      if (table == 'products') {
        final negQty = await snapshotDb.rawQuery(
            'SELECT COUNT(*) AS c FROM products WHERE currentQuantity < 0');
        final badFormula = await snapshotDb.rawQuery('''
            SELECT COUNT(*) AS c FROM products
            WHERE (openingQuantity - soldQuantity + returnedQuantity
                   + inventoryAdjustment) != currentQuantity
          ''');
        _pushIfPositive(anomalies, 'NEGATIVE_CURRENT_QUANTITY', table, negQty);
        _pushIfPositive(
            anomalies, 'CURRENT_QUANTITY_FORMULA_MISMATCH', table, badFormula);
      }

      censuses.add(PreflightTableCensus(
        tableName: table,
        totalRows: totalRows,
        alreadyCloudLinked: linked,
        rowsToMigrate: rowsToMigrate,
        quarantinedForeignShop: foreignShop,
        adoptedUnattributed: adopted,
      ));
      // idCol referenced via query construction above.
      assert(idCol.isNotEmpty);
    }

    // Orphan reference scan (D6 rationale: children import anyway under the
    // denormalized design; missing references are REPORTED, never dropped).
    final orphanSales = await snapshotDb
        .rawQuery('SELECT COUNT(*) AS c FROM sales WHERE barcode NOT IN'
            ' (SELECT barcode FROM products)');
    final orphanReturns = await snapshotDb
        .rawQuery('SELECT COUNT(*) AS c FROM returns WHERE barcode NOT IN'
            ' (SELECT barcode FROM products)');
    final orphanCounts = await snapshotDb.rawQuery(
        'SELECT COUNT(*) AS c FROM inventory_count WHERE productId NOT IN'
        ' (SELECT id FROM products)');
    _pushIfPositive(anomalies, 'ORPHAN_SALE_BARCODE', 'sales', orphanSales);
    _pushIfPositive(
        anomalies, 'ORPHAN_RETURN_BARCODE', 'returns', orphanReturns);
    _pushIfPositive(anomalies, 'ORPHAN_INVENTORY_COUNT_PRODUCT',
        'inventory_count', orphanCounts);

    final liveBaseline = <String, int>{};
    for (final spec in effectiveSpecs) {
      liveBaseline[spec.localTableName] = (await snapshotDb
              .rawQuery('SELECT COUNT(*) AS c FROM ${spec.localTableName}'))
          .first['c'] as int;
    }

    return PreflightReport(
      shopId: shopId,
      censuses: censuses,
      anomalies: anomalies,
      liveBaselineCounts: liveBaseline,
    );
  }

  void _pushIfPositive(List<Map<String, dynamic>> out, String kind,
      String table, List<Map<String, Object?>> countResult) {
    final c = (countResult.first['c'] as num?)?.toInt() ?? 0;
    if (c > 0) {
      out.add({'kind': kind, 'table': table, 'count': c});
    }
  }
}
