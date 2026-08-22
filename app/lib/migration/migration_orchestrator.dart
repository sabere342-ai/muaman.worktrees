import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../sync/sync_status.dart';
import 'cloud_migration_client.dart';
import 'content_fingerprint.dart';
import 'entity_migration_specs.dart';
import 'maintenance_mode.dart';
import 'migration_models.dart';
import 'migration_progress_repository.dart';
import 'preflight_service.dart';
import 'reconciliation_service.dart';
import 'snapshot_service.dart';

/// Frozen Phase I orchestration defaults (plan §3 W4: chunk size 200;
/// §1.5/D12: backoff constants reused from the Phase H engine).
class LegacyMigrationConfig {
  final String snapshotDirectory;
  final int chunkSize;

  /// Reused from the Phase H sync engine retry/backoff constants.
  final List<Duration> backoffSchedule;
  final int maxAttemptsPerChunk; // D12: max 5 attempts per chunk
  final int maxResumeAttempts; // D9/D12: 3 resume failures → ABORTED

  const LegacyMigrationConfig({
    // Empty → resolved at runtime via getDatabasesPath()/migration_snapshots
    // (D16), so the zero-argument const constructor is the production shape.
    this.snapshotDirectory = '',
    this.chunkSize = 200,
    this.backoffSchedule = const [
      Duration.zero,
      Duration(seconds: 5),
      Duration(seconds: 30),
      Duration(minutes: 2),
      Duration(minutes: 10),
    ],
    this.maxAttemptsPerChunk = 5,
    this.maxResumeAttempts = 3,
  });
}

/// Ledger-backed cross-reference resolver (D6). Learns mappings as chunks
/// are confirmed and can be rebuilt after a crash from the cloud ledger plus
/// snapshot rows (D12), so resume resolves references identically.
class LedgerReferenceResolver implements MigrationReferenceResolver {
  final Map<String, String> _categoryUuidByName = {};
  final Map<int, String> _productUuidByLocalId = {};
  final Map<int, String> _customerUuidByLocalId = {};

  @override
  String? categoryUuidByName(String? name) =>
      name == null ? null : _categoryUuidByName[name];

  @override
  String? productUuidByLocalId(int localId) => _productUuidByLocalId[localId];

  @override
  String? customerUuidByLocalId(int? localId) =>
      localId == null ? null : _customerUuidByLocalId[localId];

  @override
  void learn(String localTable, int localId, String? cloudUuid,
      {String? businessKey}) {
    if (cloudUuid == null || cloudUuid.isEmpty) return;
    switch (localTable) {
      case 'expense_categories':
        if (businessKey != null) _categoryUuidByName[businessKey] = cloudUuid;
        break;
      case 'products':
        _productUuidByLocalId[localId] = cloudUuid;
        break;
      case 'customers':
        _customerUuidByLocalId[localId] = cloudUuid;
        break;
    }
  }
}

/// One in-flight batch's runtime state (mirrors its durable progress row).
class _BatchRuntime {
  final String batchId;
  final String shopId;
  final LegacyMigrationStateMachine sm;
  final String snapshotPath;
  final String snapshotSha256;
  Map<String, dynamic> stats;
  String phase;
  String? lastTable;
  int lastLocalId;

  _BatchRuntime({
    required this.batchId,
    required this.shopId,
    required LegacyMigrationState initialState,
    required this.snapshotPath,
    required this.snapshotSha256,
    required this.stats,
    required this.phase,
    required this.lastTable,
    required this.lastLocalId,
  }) : sm = LegacyMigrationStateMachine(initial: initialState);
}

/// Phase I one-shot legacy migration pipeline (`LegacyMigrationService` of
/// plan §3 W2/W4/W6).
///
/// Contract highlights:
///  * D2 — reads come only from the pinned VACUUM INTO snapshot; live DB is
///    mutated solely by P10 stamping.
///  * D3 — single licensed shop per batch; foreign-shop rows quarantined,
///    unattributed rows adopted with owner consent at preflight.
///  * D4 — dedicated ingest RPCs, server-authoritative ids/versions.
///  * D7 — never touches sync_queue during import; SyncEngine stays idle via
///    maintenance mode; stamping is wrapped in runWithoutSyncEnqueue.
///  * D9 — durable state machine persisted with every checkpoint.
///  * D10 — content_fingerprint idempotency; terminal batches rejected.
///  * D12 — chunk retries with reused backoff constants; durable resume.
///  * D17 — SYNCED stamping exactly once, post-reconciliation PASS.
class LegacyMigrationService {
  final Database _db;
  final CloudMigrationClient _cloudClient;
  final Future<String?> Function() _shopIdProvider;
  final Future<bool> Function() _licenseCheck;
  final String Function() _batchIdGenerator;
  final LegacyMigrationConfig config;
  final LegacySnapshotService _snapshotService;
  final LegacyPreflightService _preflightService;
  final void Function(String message)? logger;

  MigrationProgressRepository? _progressRepo;
  VerifiedSnapshot? _pendingPreflightSnapshot;
  bool _pauseRequested = false;
  bool _abortRequested = false;
  bool _runInProgress = false;

  LegacyMigrationService({
    required Database db,
    required CloudMigrationClient cloudClient,
    required Future<String?> Function() shopIdProvider,
    required Future<bool> Function() licenseCheck,
    String Function()? batchIdGenerator,
    this.config = const LegacyMigrationConfig(snapshotDirectory: ''),
    LegacySnapshotService? snapshotService,
    LegacyPreflightService? preflightService,
    this.logger,
  })  : _db = db,
        _cloudClient = cloudClient,
        _shopIdProvider = shopIdProvider,
        _licenseCheck = licenseCheck,
        _batchIdGenerator = batchIdGenerator ?? _defaultBatchIdGenerator,
        _snapshotService = snapshotService ?? const LegacySnapshotService(),
        _preflightService = preflightService ?? const LegacyPreflightService();

  MigrationProgressRepository get _progress =>
      _progressRepo ??= MigrationProgressRepository(_db);

  /// Owner-visible pause between chunks; safe cancellation point.
  void requestPause() => _pauseRequested = true;

  /// Owner-initiated abort (D9): marks the batch closed keeping completed
  /// sub-phases; a running pipeline observes it before the next chunk.
  Future<void> abort(String batchId) async {
    final row = await _progress.getBatch(batchId);
    if (row == null) throw MigrationStateException('Unknown batch $batchId');
    final persisted = LegacyMigrationState.fromLabel(row['status'] as String);
    if (persisted.isTerminal) return; // already closed
    final sm = LegacyMigrationStateMachine(initial: persisted);
    sm.requireTransition(LegacyMigrationState.ABORTED);
    _abortRequested = true;
    await _persistState(batchId, sm.state,
        phase: row['phase'] as String,
        stats: MigrationProgressRepository.decodeStats(row) ?? const {},
        completedAt: DateTime.now().toIso8601String());
    await _log('Batch $batchId aborted by owner');
  }

  /// P0 census over a freshly pinned snapshot; feeds the consent screen.
  Future<PreflightReport> runPreflight() async {
    await _requireShopContext();
    final snapshot = await _ensureSnapshot();
    final shopId = (await _shopIdProvider())!;
    final snapshotDb = await _snapshotService.openReadOnly(snapshot.path);
    try {
      return await _preflightService.buildReport(
          snapshotDb: snapshotDb, shopId: shopId);
    } finally {
      await snapshotDb.close();
    }
  }

  /// Full pipeline on a brand-new batch: NOT_STARTED → … → COMPLETED /
  /// FAILED / ABORTED / PAUSED. Returns the batchId.
  Future<String> startBatch() async {
    if (_runInProgress) {
      throw const MigrationStateException('A migration run is already active');
    }
    final shopId = await _requireShopContext();
    final snapshot = await _ensureSnapshot();

    final batchId = _batchIdGenerator();
    final runtime = _BatchRuntime(
      batchId: batchId,
      shopId: shopId,
      initialState: LegacyMigrationState.NOT_STARTED,
      snapshotPath: snapshot.path,
      snapshotSha256: snapshot.sha256,
      stats: {'resumeAttempts': 0, 'failedResumes': 0},
      phase: 'P0',
      lastTable: null,
      lastLocalId: 0,
    );
    await _progress.insertBatch(
      batchId: batchId,
      shopId: shopId,
      phase: runtime.phase,
      status: runtime.sm.state.label,
      snapshotPath: snapshot.path,
      snapshotSha256: snapshot.sha256,
      stats: runtime.stats,
    );
    return _runPipeline(runtime, isResume: false);
  }

  /// Resumes a specific non-terminal batch (D10 rerun semantics: COMPLETED
  /// batches are rejected outright, FAILED/PAUSED continue).
  Future<String> resumeBatch(String batchId) async {
    if (_runInProgress) {
      throw const MigrationStateException('A migration run is already active');
    }
    final row = await _progress.getBatch(batchId);
    if (row == null) throw MigrationStateException('Unknown batch $batchId');
    final persisted = LegacyMigrationState.fromLabel(row['status'] as String);
    if (persisted.isTerminal) {
      // D10: rerunning a closed batch is rejected outright — a new batch is
      // required (ledger cross-batch fingerprint uniqueness keeps overlap
      // harmless, but a terminal batch itself never re-executes).
      throw MigrationStateException(
          'الدفعة $batchId مغلقة نهائيًا (${persisted.label}) ولا يمكن إعادة تشغيلها');
    }
    final runtime = _runtimeFromRow(row);
    return _runPipeline(runtime, isResume: true);
  }

  /// Resumes the latest non-terminal batch for the active shop (D12).
  Future<String> resumeLatestBatch() async {
    final shopId = await _requireShopContext();
    final row = await _progress.latestNonTerminalBatch(shopId);
    if (row == null) {
      throw const MigrationStateException('No resumable migration batch');
    }
    return resumeBatch(row['batch_id'] as String);
  }

  // =================== pipeline ===================

  Future<String> _runPipeline(
    _BatchRuntime rt, {
    required bool isResume,
  }) async {
    _runInProgress = true;
    _pauseRequested = false;
    _abortRequested = false;
    try {
      // Backup-verification gate (D9): snapshot exists + sha256 matches pin
      // + integrity_check ok. This promotes NOT_STARTED → BACKUP_VERIFIED on
      // ANY run (fresh or resume — a crashed fresh run may still sit at
      // NOT_STARTED durably); resumes re-verify the same pin (D12).
      final verified = await _snapshotService.verifyPinnedSnapshot(
        path: rt.snapshotPath,
        expectedSha256: rt.snapshotSha256,
      );
      if (!verified) {
        throw const SnapshotExceptionBridge(
            'النسخة المحورية غير صالحة أو تغيّر محتواها (فشل التحقق قبل الترحيل)');
      }
      if (rt.sm.state == LegacyMigrationState.NOT_STARTED) {
        rt.sm.requireTransition(LegacyMigrationState.BACKUP_VERIFIED);
        rt.phase = 'P0';
        await _persist(rt);
      }

      // Owner reset guard for repeatedly failed resumes (D9: FAILED becomes
      // ABORTED after N=3 resume failures).
      if (isResume &&
          rt.sm.state == LegacyMigrationState.FAILED &&
          ((rt.stats['failedResumes'] as num?)?.toInt() ?? 0) >=
              config.maxResumeAttempts) {
        rt.sm.requireTransition(LegacyMigrationState.ABORTED);
        await _persist(rt, completedAt: _now());
        throw const MigrationStateException(
            'تم تجاوز الحد الأقصى لمحاولات الاستئناف — يلزم إلغاء الدفعة وبدء دفعة جديدة');
      }
      if (((rt.stats['resumeAttempts'] as num?)?.toInt() ?? 0) >=
          config.maxResumeAttempts) {
        throw const MigrationStateException(
            'تم تجاوز الحد الأقصى لمحاولات الاستئناف — يلزم إلغاء الدفعة وبدء دفعة جديدة');
      }
      if (isResume) {
        rt.stats['resumeAttempts'] =
            ((rt.stats['resumeAttempts'] as num?)?.toInt() ?? 0) + 1;
      }

      _throwIfAborted(rt);
      rt.sm.requireTransition(LegacyMigrationState.RUNNING);
      await _persist(rt);

      MigrationMaintenanceMode.enable();
      Database? snapshotDb;
      try {
        snapshotDb = await _snapshotService.openReadOnly(rt.snapshotPath);
        final snapDb = snapshotDb; // promoted handle for stage closures

        // Non-chunk cloud interactions share the chunk failure contract:
        // any fault surfaces as MigrationCloudException so the D9 handler
        // below parks the batch in FAILED(resumable) instead of letting a
        // raw error strand it durably in RUNNING (unresumable).
        final resolver = await _guardCloudStage(
            'ledgerRebuild', () => _buildResolver(snapDb, rt));
        _throwIfAborted(rt);
        final missingRefs = await _runImportPhases(snapDb, rt, resolver);
        if (_pauseRequested) {
          // PAUSED is a durable resumable state: persisted BEFORE returning so
          // the owner sees the true state and resume continues from durable
          // progress rather than restarting destructive work.
          rt.sm.requireTransition(LegacyMigrationState.PAUSED);
          await _persist(rt);
          await _log('Batch ${rt.batchId} paused by owner');
          return rt.batchId;
        }

        await _guardCloudStage(
            'postPass', () => _runPostPass(snapDb, rt, resolver));
        _throwIfAborted(rt);

        // Superseded detection (D2 second line of defense): live counts must
        // still equal the pinned snapshot counts (maintenance mode should
        // have guaranteed this; programmatic writes would surface here).
        await _assertLiveNotSuperseded(snapshotDb, rt);

        rt.sm.requireTransition(LegacyMigrationState.RECONCILING);
        rt.phase = 'P10';
        await _persist(rt);

        final report = await _guardCloudStage(
            'reconcile', () => _reconcile(snapDb, rt, missingRefs));
        rt.stats['reconciliation'] = report.toMap();
        await _writeReportArtifact(rt, report);
        await _persist(rt);

        if (!report.verdictPass) {
          // FAIL blocks finalization (D15); FAILED(resumable→owner review).
          rt.sm.requireTransition(LegacyMigrationState.FAILED);
          await _persist(rt, completedAt: _now());
          await _log('Reconciliation FAIL for batch ${rt.batchId}');
          return rt.batchId;
        }

        await _guardCloudStage('stamping', () => _stampMigratedRows(rt));
        _throwIfAborted(rt);
        rt.sm.requireTransition(LegacyMigrationState.COMPLETED);
        rt.phase = 'DONE';
        await _persist(rt, clearCheckpoint: true, completedAt: _now());
        await _log('Batch ${rt.batchId} COMPLETED');
        return rt.batchId;
      } finally {
        MigrationMaintenanceMode.disable();
        await snapshotDb?.close();
      }
    } on MigrationChunkAbortException {
      // ABORTED is terminal (D9): stop safely, persist the terminal state if
      // not durable yet (owner abort() normally persists it first), and never
      // continue any further migration mutation or stamping.
      if (!rt.sm.state.isTerminal &&
          LegacyMigrationStateMachine.canTransition(
              rt.sm.state, LegacyMigrationState.ABORTED)) {
        rt.sm.requireTransition(LegacyMigrationState.ABORTED);
        await _persist(rt, completedAt: _now());
      }
      await _log('Batch ${rt.batchId} aborted — pipeline stopped safely');
      return rt.batchId;
    } on MigrationLedgerIncompleteException catch (e) {
      // P9 completeness gate failure blocks finalization like a FAIL verdict
      // (D15): FAILED(resumable), no stamping.
      if (!rt.sm.state.isTerminal &&
          (rt.sm.state == LegacyMigrationState.RUNNING ||
              rt.sm.state == LegacyMigrationState.RECONCILING)) {
        rt.sm.requireTransition(LegacyMigrationState.FAILED);
        rt.stats['ledgerCompleteness'] = {'verdict': 'INCOMPLETE'};
        await _persist(rt, completedAt: _now());
      }
      await _log(
          'Ledger incomplete for batch ${rt.batchId}, marked FAILED: $e');
      return rt.batchId;
    } on MigrationCloudException {
      // Chunk retry budget exhausted mid-pipeline → FAILED(resumable) (D12:
      // RUNNING and RECONCILING are both resumable-failure states per D9).
      if (!rt.sm.state.isTerminal &&
          (rt.sm.state == LegacyMigrationState.RUNNING ||
              rt.sm.state == LegacyMigrationState.RECONCILING)) {
        rt.sm.requireTransition(LegacyMigrationState.FAILED);
        rt.stats['failedResumes'] =
            ((rt.stats['failedResumes'] as num?)?.toInt() ?? 0) + 1;
        await _persist(rt, completedAt: _now());
      }
      rethrow;
    } finally {
      _runInProgress = false;
    }
  }

  /// Cooperative abort boundary: throws [MigrationChunkAbortException] when an
  /// owner abort was requested so every caller stops before further mutation
  /// (ABORTED is terminal; nothing downstream may run after this point).
  void _throwIfAborted(_BatchRuntime rt) {
    if (_abortRequested) {
      throw MigrationChunkAbortException(
          'Batch ${rt.batchId} aborted by owner');
    }
  }

  Future<Map<String, List<String>>> _runImportPhases(
    Database snapshotDb,
    _BatchRuntime rt,
    LedgerReferenceResolver resolver,
  ) async {
    final completedPhases =
        ((rt.stats['phases'] as Map?) ?? <String, dynamic>{})
            .cast<String, dynamic>();
    final tableStats = ((rt.stats['tables'] as Map?) ?? <String, dynamic>{})
        .cast<String, dynamic>();
    // Durable missing-reference evidence (D6/D15): seeded from the persisted
    // stats so a resumed run neither loses nor rewrites already-discovered
    // reconciliation evidence, and appended+persisted INCREMENTALLY below so
    // an interruption can never erase what was already found.
    final missingRefs = _decodeMissingRefs(rt.stats);

    for (final spec in kOrderedLegacyMigrationSpecs) {
      if (_pauseRequested) break;
      _throwIfAborted(rt);
      if (completedPhases[spec.phase] == 'DONE') continue;

      final perTable = ((tableStats[spec.localTableName] as Map?) ?? const {})
          .cast<String, dynamic>();
      var imported = (perTable['IMPORTED'] as num?)?.toInt() ?? 0;
      var duplicates = (perTable['SKIPPED_DUPLICATE'] as num?)?.toInt() ?? 0;
      var conflicts = (perTable['CONFLICT'] as num?)?.toInt() ?? 0;

      var cursor = (rt.lastTable == spec.localTableName) ? rt.lastLocalId : 0;

      while (true) {
        _throwIfAborted(rt);
        if (_pauseRequested) break;
        final q = spec.universeQuery(
          afterLocalId: cursor,
          limit: config.chunkSize,
          shopId: rt.shopId,
        );
        final rows = await snapshotDb.rawQuery(q.sql, q.args);
        if (rows.isEmpty) break;

        // Hard-FK guard (D6): inventory_count rows whose product mapping is
        // absent cannot be imported server-side; they are recorded as
        // explicit missing references — never silently dropped.
        final sendable = <Map<String, dynamic>>[];
        var discoveredRefs = 0;
        for (final row in rows) {
          if (spec.localTableName == 'inventory_count') {
            final productId = (row['productId'] as num?)?.toInt() ?? 0;
            if (resolver.productUuidByLocalId(productId) == null ||
                resolver.productUuidByLocalId(productId)!.isEmpty) {
              _recordMissingRef(
                rt,
                missingRefs,
                'inventory_count',
                'inventory_count#${row['migration_local_id']}: '
                    'product $productId not migrated',
              );
              discoveredRefs++;
              continue;
            }
          }
          sendable.add(row);
        }
        if (discoveredRefs > 0) {
          // Persist newly found reconciliation evidence before anything else
          // happens so an interruption cannot erase it.
          await _persist(rt);
        }
        if (sendable.isEmpty) {
          // The universe query projects the cursor identity explicitly as
          // `migration_local_id` (SELECT * omits rowid for TEXT-PK tables).
          cursor = rows
              .map((r) => (r['migration_local_id'] as num).toInt())
              .reduce(_max);
          rt.lastTable = spec.localTableName;
          rt.lastLocalId = cursor;
          await _persist(rt);
          continue;
        }

        final requests = sendable.map((row) {
          final payload = spec.businessPayload(row, resolver);
          return MigrationChunkRowRequest(
            localId: (row['migration_local_id'] as num).toInt(),
            fingerprint: ContentFingerprint.compute(payload),
            payload: payload,
          );
        }).toList();

        final results = await _sendChunkWithRetry(rt, spec, requests);
        // Abort boundary BEFORE any local bookkeeping: once an owner abort is
        // observed, no further state/checkpoint mutation may occur.
        _throwIfAborted(rt);

        var maxCursor = cursor;
        // The cursor covers EVERY row examined this chunk — including rows
        // diverted to the missing-reference bucket — so a partially-sent
        // chunk is never re-scanned (re-scanning would duplicate durable
        // evidence and corrupt the completeness math).
        for (final row in rows) {
          final examinedId = (row['migration_local_id'] as num).toInt();
          if (examinedId > maxCursor) maxCursor = examinedId;
        }
        for (final result in results) {
          switch (result.status) {
            case 'IMPORTED':
              imported++;
              break;
            case 'SKIPPED_DUPLICATE':
              duplicates++;
              break;
            case 'CONFLICT':
              conflicts++;
              break;
            default:
              throw MigrationStateException(
                  'Unexpected ingest status ${result.status}');
          }
          resolver.learn(spec.localTableName, result.localId, result.cloudUuid);
        }

        tableStats[spec.localTableName] = {
          'IMPORTED': imported,
          'SKIPPED_DUPLICATE': duplicates,
          'CONFLICT': conflicts,
        };
        rt.stats['tables'] = tableStats;

        // Checkpoint + state persisted together (D9) AFTER the server
        // confirmed the chunk (ledger confirmation callback equivalent).
        cursor = maxCursor;
        rt.lastTable = spec.localTableName;
        rt.lastLocalId = cursor;
        await _persist(rt);
      }

      if (_pauseRequested) break;
      _throwIfAborted(rt);
      completedPhases[spec.phase] = 'DONE';
      rt.stats['phases'] = completedPhases;
      rt.phase = spec.phase;
      rt.lastTable = spec.localTableName;
      rt.lastLocalId = cursor;
      await _persist(rt);
    }

    return missingRefs;
  }

  /// Reads durable missing-reference evidence from the batch stats
  /// (JSON-decoded shape: `{table: [entries...]}`).
  static Map<String, List<String>> _decodeMissingRefs(
      Map<String, dynamic> stats) {
    final raw = stats['missingRefs'];
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as List? ?? const []).map((e) => e.toString()).toList(),
      ),
    );
  }

  /// Appends one missing-reference entry to the durable evidence bucket. The
  /// append is idempotent: a crash between the evidence persist and the
  /// cursor persist re-examines the same row on resume and must not record
  /// it twice (duplicates would break ledger-completeness accounting). The
  /// caller persists immediately after a scan that produced NEW discoveries,
  /// so evidence survives interruption (D6/D15 incremental durability).
  void _recordMissingRef(
    _BatchRuntime rt,
    Map<String, List<String>> missingRefs,
    String table,
    String entry,
  ) {
    final bucket = missingRefs[table] ??= [];
    if (!bucket.contains(entry)) bucket.add(entry);
    rt.stats['missingRefs'] =
        missingRefs.map((key, value) => MapEntry(key, value));
  }

  /// Wraps a non-chunk cloud interaction (ledger rebuild, post-pass,
  /// reconciliation, stamping) so any fault surfaces as the chunk-path
  /// contract type [MigrationCloudException]; domain state exceptions pass
  /// through untouched.
  Future<T> _guardCloudStage<T>(String stage, Future<T> Function() body) async {
    try {
      return await body();
    } on MigrationCloudException {
      rethrow;
    } on MigrationStateException {
      rethrow;
    } catch (e) {
      await _log('Cloud stage $stage failed for batch: $e');
      throw MigrationCloudException('cloud stage "$stage" failed', e);
    }
  }

  Future<List<MigrationChunkRowResult>> _sendChunkWithRetry(
    _BatchRuntime rt,
    EntityMigrationSpec spec,
    List<MigrationChunkRowRequest> requests,
  ) async {
    var attempt = 0;
    while (true) {
      _throwIfAborted(rt);
      attempt++;
      try {
        return await _cloudClient.upsertChunk(
          batchId: rt.batchId,
          shopId: rt.shopId,
          localTable: spec.localTableName,
          rows: requests,
        );
      } catch (e) {
        if (_abortRequested) {
          throw MigrationChunkAbortException(
              'Batch ${rt.batchId} aborted by owner');
        }
        if (attempt >= config.maxAttemptsPerChunk) {
          await _log(
              'Chunk ${spec.localTableName}@${rt.lastLocalId} failed after '
              '$attempt attempts: $e');
          throw MigrationCloudException(
              'chunk failed after $attempt attempts', e);
        }
        final delayIndex =
            (attempt - 1).clamp(0, config.backoffSchedule.length - 1);
        await _log(
            'Chunk ${spec.localTableName} attempt $attempt failed, backing off '
            '${config.backoffSchedule[delayIndex].inMilliseconds}ms');
        await Future<void>.delayed(config.backoffSchedule[delayIndex]);
      }
    }
  }

  /// P9 post-pass: invoice↔sale link repair on the cloud side plus ledger
  /// completeness check (D6).
  Future<void> _runPostPass(Database snapshotDb, _BatchRuntime rt,
      LedgerReferenceResolver resolver) async {
    final mappings = await _cloudClient.fetchLedgerMappings(
        batchId: rt.batchId, shopId: rt.shopId);
    final byTable = <String, Map<int, MigrationLedgerEntry>>{};
    for (final m in mappings) {
      (byTable[m.localTable] ??= {})[m.localId] = m;
    }

    final links = <Map<String, String>>[];
    final salesRows = await snapshotDb.rawQuery(
        "SELECT rowid AS rid, * FROM sales WHERE invoiceId IS NOT NULL");
    for (final row in salesRows) {
      final saleLocalId = (row['rid'] as num).toInt();
      final saleEntry = byTable['sales']?[saleLocalId];
      if (saleEntry == null || saleEntry.status != 'IMPORTED') continue;
      final invoiceLocalId = (row['invoiceId'] as num?)?.toInt();
      final invoiceEntry =
          invoiceLocalId == null ? null : byTable['invoices']?[invoiceLocalId];
      if (invoiceEntry == null || invoiceEntry.status != 'IMPORTED') continue;
      links.add({
        'sale_cloud_uuid': saleEntry.cloudUuid,
        'invoice_cloud_uuid': invoiceEntry.cloudUuid,
      });
    }

    if (links.isNotEmpty) {
      await _cloudClient.postPassLinks(
        batchId: rt.batchId,
        shopId: rt.shopId,
        saleInvoiceLinks: links,
      );
    }

    // Ledger completeness (D5 + D15): every census row of this batch's
    // migration universe must be accounted for by exactly one durable ledger
    // outcome, with the explicit missing-reference bucket as the only
    // sanctioned remainder. A partially populated ledger (e.g. lost chunks,
    // truncated ledger dump) can NEVER finalize — this is a real expected-vs-
    // recorded comparison over the authoritative cloud ledger, not a row-count
    // proxy.
    final expected = await _censusCounts(snapshotDb, rt.shopId);
    final accounted = <String, int>{};
    for (final m in mappings) {
      accounted[m.localTable] = (accounted[m.localTable] ?? 0) + 1;
    }
    final missingByTable =
        ((rt.stats['missingRefs'] as Map?) ?? const {}).cast<String, List?>();
    final gaps = <String, Map<String, int>>{};
    for (final entry in expected.entries) {
      final expectedCount = entry.value;
      final accountedCount = accounted[entry.key] ?? 0;
      final missingRefCount = missingByTable[entry.key]?.length ?? 0;
      if (accountedCount + missingRefCount != expectedCount) {
        gaps[entry.key] = {
          'expected': expectedCount,
          'accounted': accountedCount,
          'missing_refs': missingRefCount,
        };
      }
    }
    if (gaps.isNotEmpty) {
      throw MigrationLedgerIncompleteException(
        'سجل الترحيل غير مكتمل: لا يمكن إثبات ترحيل كل صفوف اللقطة — $gaps',
      );
    }
    rt.stats['ledgerCompleteness'] = {
      'verdict': 'COMPLETE',
      'checked_at': _now(),
      'expected_rows':
          expected.values.fold<int>(0, (sum, count) => sum + count),
    };
    await _persist(rt);
  }

  Future<ReconciliationReport> _reconcile(
    Database snapshotDb,
    _BatchRuntime rt,
    Map<String, List<String>> missingRefs,
  ) async {
    final quarantineNotes = <String>[];
    final service = ReconciliationService(
      snapshotDb: snapshotDb,
      cloudClient: _cloudClient,
    );
    return service.reconcile(
      batchId: rt.batchId,
      shopId: rt.shopId,
      quarantinedNotes: quarantineNotes,
      missingRefsByTable: missingRefs,
    );
  }

  /// D17 finalization stamping: for every ledger IMPORTED row, set the exact
  /// Phase H sync metadata in one transaction per table, wrapped in
  /// [DatabaseHelper.runWithoutSyncEnqueue]; then defensively clear stale
  /// PENDING queue entries for stamped rows ONLY.
  ///
  /// Abort-aware: an owner abort observed before starting or between tables
  /// stops stamping immediately — ABORTED is terminal and no further mutation
  /// may occur after it.
  Future<void> _stampMigratedRows(_BatchRuntime rt) async {
    final mappings = await _cloudClient.fetchLedgerMappings(
        batchId: rt.batchId, shopId: rt.shopId);
    _throwIfAborted(rt);
    final byTable = <String, List<MigrationLedgerEntry>>{};
    // IMPORTED rows were newly created; SKIPPED_DUPLICATE rows matched
    // existing cloud content by fingerprint (D10) — BOTH carry the
    // authoritative cloud_uuid and must be stamped so the Phase H continuous
    // sync never re-uploads this history. CONFLICT rows stay unstamped for
    // owner review (D13).
    for (final m in mappings.where(
        (m) => m.status == 'IMPORTED' || m.status == 'SKIPPED_DUPLICATE')) {
      (byTable[m.localTable] ??= []).add(m);
    }

    for (final spec in kOrderedLegacyMigrationSpecs) {
      _throwIfAborted(rt); // terminal gate BEFORE each table's stamping txn
      final entries = byTable[spec.localTableName];
      if (entries == null || entries.isEmpty) continue;
      final idCol = spec.localTableName == 'app_settings' ? 'rowid' : 'id';
      final now = _now();

      await DatabaseHelper.runWithoutSyncEnqueue(() async {
        await _db.transaction((txn) async {
          final stampedIds = <int>[];
          for (final m in entries) {
            final updated = await txn.rawUpdate(
                'UPDATE ${spec.localTableName} SET '
                'cloud_uuid = ?, server_version = ?, sync_status = ?, '
                'last_synced_at = ? WHERE $idCol = ? AND cloud_uuid IS NULL',
                [
                  m.cloudUuid,
                  m.serverVersion,
                  EntitySyncStatus.SYNCED.label,
                  now,
                  m.localId,
                ]);
            if (updated > 0) stampedIds.add(m.localId);
          }
          for (final localId in stampedIds) {
            await txn.delete(
              'sync_queue',
              where: "entity_type = ? AND entity_id = ? AND status = 'PENDING'",
              whereArgs: [spec.entityTypeLabel, localId],
            );
          }
        });
      });

      rt.stats['stamped.${spec.localTableName}'] = entries.length;
      await _persist(rt);
    }
  }

  // =================== helpers ===================

  Future<String> _requireShopContext() async {
    if (!await _licenseCheck()) {
      throw const MigrationStateException(
          'الترحيل يتطلب ترخيصًا ساريًا وعضوية متجر نشطة');
    }
    final shopId = await _shopIdProvider();
    if (shopId == null || shopId.isEmpty) {
      throw const MigrationStateException(
          'لا يمكن بدء الترحيل بدون متجر نشط (سياق عضوية/ترخيص مفقود)');
    }
    return shopId;
  }

  Future<VerifiedSnapshot> _ensureSnapshot() async {
    final pending = _pendingPreflightSnapshot;
    if (pending != null && File(pending.path).existsSync()) {
      return pending;
    }
    final liveDb = _db;
    // Snapshot destination (D16): default to the repository-standard database
    // root (same directory family as muaman_store.db via sqflite's
    // getDatabasesPath) under a dedicated sub-directory. No custom path
    // bridge: plain sqflite + dart:io APIs only.
    var destination = config.snapshotDirectory;
    if (destination.trim().isEmpty) {
      destination = p.join(await getDatabasesPath(), 'migration_snapshots');
    }
    final snapshot = await _snapshotService.createVerifiedSnapshot(
      liveDb: liveDb,
      destinationDirectory: destination,
      fileBaseName: 'muaman_migration_snapshot',
    );
    _pendingPreflightSnapshot = snapshot;
    return snapshot;
  }

  Future<LedgerReferenceResolver> _buildResolver(
      Database snapshotDb, _BatchRuntime rt) async {
    final resolver = LedgerReferenceResolver();
    // Rebuild from the authoritative cloud ledger first (survives restarts),
    // then enrich category names from snapshot rows.
    final mappings = await _cloudClient.fetchLedgerMappings(
        batchId: rt.batchId, shopId: rt.shopId);
    final categoryNamesById = <int, String>{};
    final catRows =
        await snapshotDb.query('expense_categories', columns: ['id', 'name']);
    for (final r in catRows) {
      categoryNamesById[(r['id'] as num).toInt()] = r['name'] as String;
    }
    for (final m in mappings) {
      resolver.learn(m.localTable, m.localId, m.cloudUuid,
          businessKey: m.localTable == 'expense_categories'
              ? categoryNamesById[m.localId]
              : null);
    }
    return resolver;
  }

  Future<Map<String, int>> _censusCounts(
      Database snapshotDb, String shopId) async {
    final out = <String, int>{};
    for (final spec in kOrderedLegacyMigrationSpecs) {
      final count = ((await snapshotDb.rawQuery(
              'SELECT COUNT(*) AS c FROM ${spec.localTableName}'
              ' WHERE cloud_uuid IS NULL AND (shop_id IS NULL OR shop_id = ?)',
              [shopId]))
          .first['c'] as int);
      out[spec.localTableName] = count;
    }
    return out;
  }

  Future<void> _assertLiveNotSuperseded(
      Database snapshotDb, _BatchRuntime rt) async {
    final snapshotCounts = await _censusCounts(snapshotDb, rt.shopId);
    for (final entry in snapshotCounts.entries) {
      final table = entry.key;
      // Live universe may only have SHRUNK by rows this batch stamped
      // (cloud_uuid no longer NULL). Compare TOTAL row counts instead: any
      // concurrent business write would grow them despite maintenance mode.
      final liveTotal =
          ((await _db.rawQuery('SELECT COUNT(*) AS c FROM $table')).first['c']
              as int);
      final snapshotTotal =
          ((await snapshotDb.rawQuery('SELECT COUNT(*) AS c FROM $table'))
              .first['c'] as int);
      if (liveTotal != snapshotTotal) {
        rt.sm.requireTransition(LegacyMigrationState.ABORTED);
        await _persist(rt, completedAt: _now());
        throw MigrationStateException(
            'تم اكتشاف تعديلات على قاعدة البيانات أثناء الترحيل (batch superseded): $table');
      }
    }
  }

  Future<void> _writeReportArtifact(
      _BatchRuntime rt, ReconciliationReport report) async {
    try {
      final artifact = File('${rt.snapshotPath}.reconciliation.json');
      await artifact.writeAsString(const JsonEncoder.withIndent('  ').convert({
        ...report.toMap(),
        'stats': rt.stats,
        'generated_at': _now(),
      }));
    } catch (_) {
      // Report persistence beside the snapshot is best-effort; the durable
      // copy lives in stats_json.
    }
  }

  _BatchRuntime _runtimeFromRow(Map<String, dynamic> row) {
    final stats = MigrationProgressRepository.decodeStats(row) ?? {};
    return _BatchRuntime(
      batchId: row['batch_id'] as String,
      shopId: row['shop_id'] as String,
      initialState: LegacyMigrationState.fromLabel(row['status'] as String),
      snapshotPath: row['snapshot_path'] as String? ?? '',
      snapshotSha256: row['snapshot_sha256'] as String? ?? '',
      stats: stats,
      phase: row['phase'] as String,
      lastTable: row['last_table'] as String?,
      lastLocalId: (row['last_local_id'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _persist(
    _BatchRuntime rt, {
    bool clearCheckpoint = false,
    String? completedAt,
  }) async {
    await _progress.updateBatch(
      rt.batchId,
      phase: rt.phase,
      status: rt.sm.state.label,
      lastTable: rt.lastTable,
      lastLocalId: rt.lastLocalId,
      stats: rt.stats,
      clearCheckpoint: clearCheckpoint,
      completedAt: completedAt,
    );
  }

  /// Persists an externally driven state change (owner abort) for a batch
  /// that has no in-pipeline runtime object.
  Future<void> _persistState(
    String batchId,
    LegacyMigrationState status, {
    String? phase,
    Map<String, dynamic>? stats,
    String? completedAt,
  }) async {
    await _progress.updateBatch(
      batchId,
      phase: phase,
      status: status.label,
      stats: stats,
      completedAt: completedAt,
    );
  }

  Future<void> _log(String message) async {
    final sink = logger;
    if (sink != null) await Future.sync(() => sink(message));
  }
}

int _max(int a, int b) => a > b ? a : b;

String _now() => DateTime.now().toIso8601String();

/// Bridges snapshot verification failures into the pipeline's error path.
class SnapshotExceptionBridge extends MigrationStateException {
  const SnapshotExceptionBridge(super.message);
}

/// Thrown cooperatively when an abort interrupts a running pipeline.
class MigrationChunkAbortException extends MigrationStateException {
  const MigrationChunkAbortException(super.message);
}

/// P9 ledger-completeness gate failure: the durable cloud ledger does not
/// account for every snapshot row of the batch universe (minus the explicit
/// missing-reference bucket). Blocks finalization (D5/D15).
class MigrationLedgerIncompleteException extends MigrationStateException {
  const MigrationLedgerIncompleteException(super.message);
}

/// UUIDv4-shaped batch ids without external dependencies.
String _defaultBatchIdGenerator() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
