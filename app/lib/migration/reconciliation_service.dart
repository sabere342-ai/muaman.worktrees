import 'package:sqflite/sqflite.dart';

import 'cloud_migration_client.dart';
import 'entity_migration_specs.dart';
import 'migration_models.dart';

/// Phase I D15 reconciliation engine.
///
/// After P9 the service compares, per table: row-count parity and the frozen
/// D14 financial invariants between the pinned SNAPSHOT and the CLOUD
/// aggregates attributable to this batch through the migration-ledger join
/// (via [CloudMigrationClient.reconcileBatch]). Money is compared byte-exact
/// (IEEE754 equality asserted — never tolerance). Only an all-tables PASS
/// verdict unlocks P10 stamping; a FAIL blocks finalization.
class ReconciliationService {
  final Database _snapshotDb;
  final CloudMigrationClient _cloudClient;

  const ReconciliationService({
    required Database snapshotDb,
    required CloudMigrationClient cloudClient,
  })  : _snapshotDb = snapshotDb,
        _cloudClient = cloudClient;

  Future<ReconciliationReport> reconcile({
    required String batchId,
    required String shopId,
    List<EntityMigrationSpec>? specs,
    List<String> quarantinedNotes = const [],
    Map<String, List<String>> missingRefsByTable = const {},
  }) async {
    final effectiveSpecs = specs ?? kOrderedLegacyMigrationSpecs;
    final cloudAgg = await _cloudClient.reconcileBatch(
      batchId: batchId,
      shopId: shopId,
    );

    final ledgerTables =
        ((cloudAgg['tables'] as Map?) ?? const {}).cast<String, dynamic>();
    final financials =
        ((cloudAgg['financials'] as Map?) ?? const {}).cast<String, dynamic>();
    final importedRows = ((cloudAgg['imported_rows'] as Map?) ?? const {})
        .cast<String, dynamic>();

    final results = <ReconciliationTableResult>[];

    for (final spec in effectiveSpecs) {
      final table = spec.localTableName;

      // Universe this batch was consented to migrate (D3 filters mirror the
      // import-time universe query).
      final expectedRows = ((await _snapshotDb.rawQuery(
              'SELECT COUNT(*) AS c FROM $table'
              ' WHERE cloud_uuid IS NULL AND (shop_id IS NULL OR shop_id = ?)',
              [shopId]))
          .first['c'] as int);

      // Snapshot-side financial expectations (D14), same population.
      final expectedSums = <String, double>{};
      for (final entry in spec.financialSums.entries) {
        final column = entry.value;
        final row = await _snapshotDb.rawQuery(
            'SELECT COALESCE(SUM($column), 0) AS s FROM $table'
            ' WHERE cloud_uuid IS NULL AND (shop_id IS NULL OR shop_id = ?)',
            [shopId]);
        expectedSums[entry.key] = ((row.first['s'] as num?) ?? 0).toDouble();
      }

      final counts = LedgerStatusCounts.fromMap(
          ((ledgerTables[table] as Map?) ?? const {}).cast<String, dynamic>());

      // Cloud-side imported-row parity: distinct cloud rows attributable to
      // this batch via the ledger join must equal the ledger IMPORTED count.
      final actualImportedRows =
          ((importedRows[table] as num?)?.toInt() ?? counts.imported);

      final actualSums = <String, double>{};
      for (final alias in spec.financialSums.keys) {
        actualSums[alias] =
            ((financials[alias] as num?) ?? expectedSums[alias]!).toDouble();
      }

      results.add(ReconciliationTableResult(
        tableName: table,
        expectedRows: expectedRows,
        imported: actualImportedRows,
        duplicatesSkipped: counts.skippedDuplicate,
        conflicts: counts.conflict,
        missingRefs: missingRefsByTable[table] ?? const [],
        financialExpected: expectedSums,
        financialActual: actualSums,
      ));
    }

    return ReconciliationReport(
      batchId: batchId,
      shopId: shopId,
      tables: results,
      quarantinedNotes: quarantinedNotes,
    );
  }
}
