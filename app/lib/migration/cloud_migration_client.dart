import 'package:supabase_flutter/supabase_flutter.dart';

/// One row offered to the migration ingest RPC.
class MigrationChunkRowRequest {
  /// Snapshot-local integer id (ledger local_id).
  final int localId;

  /// Canonical content fingerprint (D10), computed client-side.
  final String fingerprint;

  /// Business payload (snake_case, reference-resolved).
  final Map<String, dynamic> payload;

  const MigrationChunkRowRequest({
    required this.localId,
    required this.fingerprint,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'fingerprint': fingerprint,
        'payload': payload,
      };
}

/// Per-row ingest verdict from the server. Status strings match the frozen
/// ledger contract exactly: IMPORTED | SKIPPED_DUPLICATE | CONFLICT (D5/D10).
class MigrationChunkRowResult {
  final int localId;
  final String status;
  final String? cloudUuid;
  final int? serverVersion;
  final String? detail;

  const MigrationChunkRowResult({
    required this.localId,
    required this.status,
    this.cloudUuid,
    this.serverVersion,
    this.detail,
  });
}

/// Ledger mapping entry used for resume-time reference rebuilding and
/// completeness checks (D5: the cloud ledger is the ONLY source of truth for
/// "was this row already migrated").
class MigrationLedgerEntry {
  final String localTable;
  final int localId;
  final String cloudUuid;
  final int serverVersion;
  final String status;

  const MigrationLedgerEntry({
    required this.localTable,
    required this.localId,
    required this.cloudUuid,
    required this.serverVersion,
    required this.status,
  });
}

/// Dedicated historical-migration ingest path (D4). Deliberately separate
/// from the Phase H SyncEngine upload loop and sync_queue (D7): the client
/// never routes these calls through continuous-sync infrastructure.
abstract class CloudMigrationClient {
  /// Imports one chunk atomically server-side; every row lands in the target
  /// cloud table AND the cloud_migration_ledger in the same transaction, with
  /// per-row IMPORTED / SKIPPED_DUPLICATE / CONFLICT verdicts.
  Future<List<MigrationChunkRowResult>> upsertChunk({
    required String batchId,
    required String shopId,
    required String localTable,
    required List<MigrationChunkRowRequest> rows,
  });

  /// P9 post-pass: repairs invoice↔sale links on the cloud side using fully
  /// resolved uuid pairs supplied by the client. Returns repair counts.
  Future<Map<String, dynamic>> postPassLinks({
    required String batchId,
    required String shopId,
    required List<Map<String, String>> saleInvoiceLinks,
  });

  /// Full ledger dump for a batch (reference rebuild + completeness checks).
  Future<List<MigrationLedgerEntry>> fetchLedgerMappings({
    required String batchId,
    required String shopId,
  });

  /// D15 reconciliation aggregates: per-table ledger status counts plus
  /// financial sums over cloud rows attributable to this batch via the
  /// ledger join.
  Future<Map<String, dynamic>> reconcileBatch({
    required String batchId,
    required String shopId,
  });
}

/// Supabase-backed implementation calling the SECURITY DEFINER function
/// family installed by supabase/migrations/..._phase_i_legacy_migration.sql.
/// Shop membership, license state and tenant isolation are enforced
/// server-side (fail-closed), mirroring every existing cloud data path.
class SupabaseCloudMigrationClient implements CloudMigrationClient {
  final SupabaseClient _client;

  SupabaseCloudMigrationClient({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<MigrationChunkRowResult>> upsertChunk({
    required String batchId,
    required String shopId,
    required String localTable,
    required List<MigrationChunkRowRequest> rows,
  }) async {
    final data = await _client.rpc('migration_upsert_chunk', params: {
      'p_batch_id': batchId,
      'p_shop_id': shopId,
      'p_local_table': localTable,
      'p_rows': rows.map((r) => r.toJson()).toList(),
    });
    final results = (data as Map)['results'] as List;
    return results.map((r) {
      final map = r as Map;
      return MigrationChunkRowResult(
        localId: (map['local_id'] as num).toInt(),
        status: map['status'] as String,
        cloudUuid: map['cloud_uuid'] as String?,
        serverVersion: (map['server_version'] as num?)?.toInt(),
        detail: map['detail'] as String?,
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> postPassLinks({
    required String batchId,
    required String shopId,
    required List<Map<String, String>> saleInvoiceLinks,
  }) async {
    final data = await _client.rpc('migration_post_pass_links', params: {
      'p_batch_id': batchId,
      'p_shop_id': shopId,
      'p_links': saleInvoiceLinks,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  @override
  Future<List<MigrationLedgerEntry>> fetchLedgerMappings({
    required String batchId,
    required String shopId,
  }) async {
    final data = await _client.rpc('migration_fetch_ledger', params: {
      'p_batch_id': batchId,
      'p_shop_id': shopId,
    });
    return (data as List)
        .map((e) => MigrationLedgerEntry(
              localTable: e['local_table'] as String,
              localId: (e['local_id'] as num).toInt(),
              cloudUuid: e['cloud_uuid'] as String,
              serverVersion: (e['server_version'] as num?)?.toInt() ?? 1,
              status: e['status'] as String,
            ))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> reconcileBatch({
    required String batchId,
    required String shopId,
  }) async {
    final data = await _client.rpc('migration_reconcile_batch', params: {
      'p_batch_id': batchId,
      'p_shop_id': shopId,
    });
    return Map<String, dynamic>.from(data as Map);
  }
}
