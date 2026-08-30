import 'package:sqflite/sqflite.dart';

import '../services/session_state.dart';
import 'adapters/customer_sync_adapter.dart';
import 'adapters/entity_sync_adapter.dart';
import 'adapters/expense_category_sync_adapter.dart';
import 'adapters/expense_sync_adapter.dart';
import 'adapters/inventory_count_sync_adapter.dart';
import 'adapters/invoice_sync_adapter.dart';
import 'adapters/product_sync_adapter.dart';
import 'adapters/return_sync_adapter.dart';
import 'adapters/sale_sync_adapter.dart';
import 'adapters/shop_settings_sync_adapter.dart';
import 'adapters/stock_adjustment_sync_adapter.dart';
import 'conflict_audit_repository.dart';
import 'conflict_resolver.dart';
import 'hydration_service.dart';
import 'incremental_sync_service.dart';
import 'sync_engine.dart';
import 'sync_queue_repository.dart';
import 'sync_status.dart';
import 'sync_worker.dart';

/// Builds the standard production adapter registry covering every
/// `SyncEntityType` in the Phase M sync contract.
Map<SyncEntityType, EntitySyncAdapter> buildStandardAdapters() => {
      SyncEntityType.product: ProductSyncAdapter(),
      SyncEntityType.sale: SaleSyncAdapter(),
      SyncEntityType.returnItem: ReturnSyncAdapter(),
      SyncEntityType.expense: ExpenseSyncAdapter(),
      SyncEntityType.expenseCategory: ExpenseCategorySyncAdapter(),
      SyncEntityType.customer: CustomerSyncAdapter(),
      SyncEntityType.invoice: InvoiceSyncAdapter(),
      SyncEntityType.inventoryCount: InventoryCountSyncAdapter(),
      SyncEntityType.shopSetting: ShopSettingsSyncAdapter(),
      SyncEntityType.stockAdjustment: StockAdjustmentSyncAdapter(),
    };

/// Phase P WS-1 — the application-owned device→cloud sync runtime (drain).
///
/// Closes the foundational "never-sync" risk (plan D.2 / §M.1): a single,
/// app-owned runtime that owns the `SyncWorker`, runs the initial
/// hydration/incremental pull, drives the startup crash-recovery sweep and
/// publishes live queue status to `SessionState`.
///
/// Shipping posture (plan §N): the drain is gated behind the
/// [drainEnabled] seam. With it `false` (the default) the runtime is
/// MEASURED, never network-active: it still resolves the tenant, publishes
/// queue counters and manages the lifecycle, but constructs no
/// `SyncWorker`/`SyncEngine` and performs zero cloud calls. Flipping the
/// seam to `true` (after the owner decision + verified live
/// `SyncCloudOperations`) activates the same tested lifecycle unchanged.
///
/// Fail-closed gates applied on every start attempt:
///   - no resolvable bound shop ⇒ nothing starts (offline-only tenants are
///     never harmed),
///   - unlicensed ⇒ nothing starts,
///   - no `SyncCloudOperations` wired ⇒ nothing starts (a drain with no
///     transport must not silently no-op),
///   - connectivity is evaluated per cycle by the `SyncWorker` (offline ⇒
///     defer, enqueue stays live).
class SyncRuntime {
  /// Creates an independent runtime (tests/dedicated shells). Application
  /// wiring uses the shared [instance] singleton.
  SyncRuntime();

  static final SyncRuntime instance = SyncRuntime();

  Database? _database;
  SyncQueueRepository? _queueRepository;
  ConflictAuditRepository? _conflictAuditRepository;
  Map<SyncEntityType, EntitySyncAdapter> _adapters = const {};
  SyncCloudOperations? _cloudOperations;
  HydrationCloudSource? _hydrationSource;
  SessionState? _sessionState;
  Future<bool> Function() _connectivityCheck = _offline;
  Future<bool> Function() _licenseCheck = _offline;
  Future<String?> Function() _shopIdProvider = () async => null;
  Future<void> Function(String message) _logger = (_) async {};
  bool _drainEnabled = false;
  bool _configured = false;
  Duration _interval = const Duration(seconds: 30);
  final Duration _initialPullLookback = const Duration(days: 30);

  SyncEngine? _engine;
  SyncWorker? _worker;
  String? _boundShopId;
  DateTime? _lastSyncedAt;

  static Future<bool> _offline() async => false;

  /// True when the periodic drain worker is currently running.
  bool get isRunning => _worker?.isRunning ?? false;

  /// The shipping posture seam: when false the runtime never performs
  /// network activity (WS-1 mechanism present, production drain OFF).
  bool get drainEnabled => _drainEnabled;

  /// The tenant bound by the current runtime, if any.
  String? get boundShopId => _boundShopId;

  bool get isConfigured => _configured;

  /// Configures the runtime dependencies. Idempotent: a second call with
  /// equivalent settings is a no-op; [reset] tears everything down.
  void configure({
    required Database database,
    SyncQueueRepository? queueRepository,
    ConflictAuditRepository? conflictAuditRepository,
    Map<SyncEntityType, EntitySyncAdapter>? adapters,
    SyncCloudOperations? cloudOperations,
    HydrationCloudSource? hydrationSource,
    SessionState? sessionState,
    Future<bool> Function()? connectivityCheck,
    Future<bool> Function()? licenseCheck,
    Future<String?> Function()? shopIdProvider,
    Future<void> Function(String message)? logger,
    bool? drainEnabled,
    Duration interval = const Duration(seconds: 30),
  }) {
    _database = database;
    _queueRepository = queueRepository ?? SyncQueueRepository(database);
    _conflictAuditRepository =
        conflictAuditRepository ?? ConflictAuditRepository(database);
    _adapters = adapters ?? const {};
    _cloudOperations = cloudOperations;
    _hydrationSource = hydrationSource;
    _sessionState = sessionState;
    _connectivityCheck = connectivityCheck ?? _offline;
    _licenseCheck = licenseCheck ?? _offline;
    _shopIdProvider = shopIdProvider ?? (() async => null);
    _logger = logger ?? (_) async {};
    _drainEnabled = drainEnabled ?? false;
    _interval = interval;
    _configured = true;
  }

  /// Starts (or re-provisions) the runtime for the given tenant.
  ///
  /// Idempotent: re-invocation while running re-publishes status and keeps
  /// the existing worker. Call on every session/shop-context establishment
  /// (cold-start resume AND interactive login).
  Future<void> ensureStarted({String? shopId}) async {
    if (!_configured) {
      await _log('SyncRuntime: not configured — no-op');
      return;
    }

    final resolved = shopId ?? await _shopIdProvider();
    if (resolved == null || resolved.isEmpty) {
      await _log('SyncRuntime: no bound shop — fail-closed, no drain');
      _stopWorkerQuietly();
      await publishStatus();
      return;
    }
    _boundShopId = resolved;

    if (!_drainEnabled) {
      await _log(
          'SyncRuntime: drain disabled (shipping posture) — managing status '
          'only, no network activity for shop $_boundShopId');
      await publishStatus();
      return;
    }

    if (_worker != null && _worker!.isRunning) {
      await publishStatus();
      return;
    }

    final licensed = await _licenseCheck();
    if (!licensed) {
      await _log('SyncRuntime: unlicensed — drain not started for shop '
          '$_boundShopId');
      _stopWorkerQuietly();
      await publishStatus();
      return;
    }

    final cloudOps = _cloudOperations;
    if (cloudOps == null) {
      await _log(
          'SyncRuntime: no SyncCloudOperations wired — drain not started '
          '(fail-safe) for shop $_boundShopId');
      await publishStatus();
      return;
    }

    await _buildAndStart(licensed: true);
    if (_worker != null && _worker!.isRunning) {
      await _runInitialSynchronization(shopId: resolved);
    }
    await publishStatus();
  }

  /// Stops the periodic drain and clears the bound tenant. Idempotent.
  Future<void> stop() async {
    _stopWorkerQuietly();
    _boundShopId = null;
    await publishStatus();
  }

  /// Drives one drain cycle immediately (test/driven cycles and manual
  /// sync triggers). Returns the cycle result when a worker is active,
  /// null when the runtime is not draining or the cycle was skipped.
  Future<SyncResult?> syncNow() async {
    final worker = _worker;
    if (worker == null || !worker.isRunning) return null;
    return worker.syncNow();
  }

  /// Full teardown: also clears configuration (test/session teardown).
  void reset() {
    _stopWorkerQuietly();
    _boundShopId = null;
    _engine = null;
    _worker = null;
    _database = null;
    _queueRepository = null;
    _conflictAuditRepository = null;
    _adapters = const {};
    _cloudOperations = null;
    _hydrationSource = null;
    _sessionState = null;
    _connectivityCheck = _offline;
    _licenseCheck = _offline;
    _shopIdProvider = () async => null;
    _logger = (_) async {};
    _drainEnabled = false;
    _configured = false;
  }

  /// Publishes the live queue state (pending/failed/conflict counts and the
  /// last successful sync) to [SessionState]. Safe to call anytime; a
  /// missing queue repository or session state is a silent no-op.
  Future<void> publishStatus() async {
    final state = _sessionState;
    if (state == null) return;

    final repo = _queueRepository;
    if (repo == null) {
      state.updateSyncStatus(
        pendingCount: 0,
        failedCount: 0,
        conflictCount: 0,
      );
      return;
    }

    final shopId = _boundShopId;
    final pending = await repo.getPendingCount(shopId: shopId);
    final failed = await repo.getFailedCount(shopId: shopId);
    final conflicts = await repo.getConflictCount(shopId: shopId);
    state.updateSyncStatus(
      pendingCount: pending,
      failedCount: failed,
      conflictCount: conflicts,
      lastSyncedAt: _lastSyncedAt,
    );
  }

  /// M-I05 startup recovery sweep: re-drives non-terminal conflict lifecycle
  /// rows so a crashed resolution can never stay stuck mid-flight. Runs ONCE
  /// on worker start. Idempotent and local-only.
  Future<void> _recoverySweep() async {
    final audit = _conflictAuditRepository;
    final shopId = _boundShopId;
    if (audit == null || shopId == null) return;

    final open = await audit.getOpenConflicts(shopId: shopId);
    var redriven = 0;
    for (final record in open) {
      if (record.status == ConflictLifecycleStatus.RESOLUTION_PENDING) {
        await audit.markReviewRequired(record.id);
        redriven++;
      }
    }
    await _log('SyncRuntime: recovery sweep redriven $redriven '
        'RESOLUTION_PENDING audit rows to REVIEW_REQUIRED');
  }

  Future<void> _buildAndStart({required bool licensed}) async {
    final db = _database;
    final queue = _queueRepository;
    final cloudOps = _cloudOperations;
    if (db == null || queue == null || cloudOps == null) return;
    if (_adapters.isEmpty) {
      await _log('SyncRuntime: no adapters wired — drain not started');
      return;
    }

    _engine = SyncEngine(
      queueRepository: queue,
      conflictResolver: ConflictResolver(_adapters),
      adapters: _adapters,
      connectivityCheck: _connectivityCheck,
      licenseCheck: _licenseCheck,
      shopIdProvider: () async => _boundShopId,
      logger: (entityType, operation, {details}) async {
        await _log('SyncRuntime: $entityType:$operation'
            '${details != null ? ' — $details' : ''}');
      },
      cloudOps: cloudOps,
      localDb: db,
      conflictAuditRepository: _conflictAuditRepository,
    );

    final worker = SyncWorker(
      engine: _engine!,
      connectivityCheck: _connectivityCheck,
      sessionCheck: () async => _boundShopId != null,
      logger: _logger,
      interval: _interval,
      recoverySweep: _recoverySweep,
      onCycleComplete: _onCycleComplete,
    );
    _worker = worker;
    worker.start();
    await _log('SyncRuntime: drain started for shop $_boundShopId '
        '(licensed=$licensed, interval=${_interval.inSeconds}s)');
  }

  Future<void> _onCycleComplete(SyncResult result) async {
    if (result.synced > 0 || result.processed > 0) {
      _lastSyncedAt = DateTime.now();
    }
    await publishStatus();
  }

  Future<void> _runInitialSynchronization({required String shopId}) async {
    final db = _database;
    final source = _hydrationSource;
    if (db == null || source == null) {
      await _log('SyncRuntime: no hydration source — initial pull skipped');
      return;
    }
    if (await _connectivityCheck() == false) {
      await _log('SyncRuntime: offline at start — initial pull deferred');
      return;
    }

    final adapters = _adapters.values.toList();
    if (adapters.isEmpty) return;

    final hydration = HydrationService(
      db: db,
      cloudSource: source,
      logger: (msg) => _log('SyncRuntime: $msg'),
      queueRepository: _queueRepository,
    );
    final hydrationResult =
        await hydration.hydrate(shopId: shopId, adapters: adapters);

    final incremental = IncrementalSyncService(
      db: db,
      cloudSource: source,
      logger: (msg) => _log('SyncRuntime: $msg'),
      queueRepository: _queueRepository,
    );
    final since = DateTime.now().toUtc().subtract(_initialPullLookback);
    final pullResult = await incremental.pullChanges(
      shopId: shopId,
      adapters: adapters,
      since: since,
    );

    await _log('SyncRuntime: initial sync complete (hydrated '
        'inserted=${hydrationResult.inserted} updated=${hydrationResult.updated} '
        'deferred=${hydrationResult.deferred}; pulled '
        'inserted=${pullResult.inserted} updated=${pullResult.updated} '
        'deferred=${pullResult.deferred})');
  }

  void _stopWorkerQuietly() {
    final worker = _worker;
    if (worker != null) {
      worker.dispose();
    }
    _worker = null;
    _engine = null;
  }

  Future<void> _log(String message) => _logger(message);
}
