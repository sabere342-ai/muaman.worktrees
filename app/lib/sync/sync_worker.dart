import 'dart:async';

import 'sync_engine.dart';

enum SyncWorkerState {
  idle,
  running,
  stopped,
}

class SyncWorker {
  final SyncEngine _engine;
  final Future<bool> Function() _connectivityCheck;
  final Future<bool> Function() _sessionCheck;
  final Future<void> Function(String message) _logger;
  final Duration _interval;

  /// Phase M M-I05 hook: an idempotent recovery/reconciliation sweep run
  /// ONCE when the worker starts (e.g. re-driving non-terminal conflict
  /// lifecycle rows). DR-M09: this does NOT activate any new production
  /// sync runtime scheduling; the periodic tick behavior is unchanged and
  /// the hook defaults to null (no-op).
  final Future<void> Function()? _recoverySweep;

  /// Phase P WS-1 hook: invoked after every completed queue cycle with the
  /// cycle result so the owning runtime can publish status (counters +
  /// last-synced timestamp) without coupling SyncWorker to SessionState.
  /// Defaults to null (no-op).
  final Future<void> Function(SyncResult result)? _onCycleComplete;

  Timer? _timer;
  SyncWorkerState _state = SyncWorkerState.stopped;
  bool _isProcessing = false;

  SyncWorkerState get state => _state;
  bool get isRunning => _state == SyncWorkerState.running && _timer != null;

  SyncWorker({
    required SyncEngine engine,
    required Future<bool> Function() connectivityCheck,
    required Future<bool> Function() sessionCheck,
    required Future<void> Function(String message) logger,
    Duration interval = const Duration(seconds: 30),
    Future<void> Function()? recoverySweep,
    Future<void> Function(SyncResult result)? onCycleComplete,
  })  : _engine = engine,
        _connectivityCheck = connectivityCheck,
        _sessionCheck = sessionCheck,
        _logger = logger,
        _interval = interval,
        _recoverySweep = recoverySweep,
        _onCycleComplete = onCycleComplete;

  void start() {
    if (_state == SyncWorkerState.running) return;

    _state = SyncWorkerState.running;
    _timer = Timer.periodic(_interval, (_) => _onTick());

    _logger('SyncWorker started (interval: ${_interval.inSeconds}s)');

    // Fire-and-forget single recovery sweep; errors are logged, never fatal.
    final sweep = _recoverySweep;
    if (sweep != null) {
      () async {
        try {
          await sweep();
          await _logger('SyncWorker: startup recovery sweep complete');
        } catch (e) {
          await _logger('SyncWorker: recovery sweep error: $e');
        }
      }();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _state = SyncWorkerState.stopped;
    _logger('SyncWorker stopped');
  }

  /// Drives one sync cycle immediately. Returns the cycle result, or null
  /// when the cycle was skipped (already processing, not running, session
  /// invalid or offline).
  Future<SyncResult?> syncNow() async {
    return _onTick();
  }

  Future<SyncResult?> _onTick() async {
    if (_isProcessing) return null;

    if (_state != SyncWorkerState.running) return null;

    final isSessionValid = await _sessionCheck();
    if (!isSessionValid) {
      await _logger('SyncWorker: session invalid, skipping cycle');
      return null;
    }

    final isOnline = await _connectivityCheck();
    if (!isOnline) {
      await _logger('SyncWorker: offline, skipping cycle');
      return null;
    }

    _isProcessing = true;
    try {
      await _logger('SyncWorker: starting sync cycle');
      final result = await _engine.processQueue();
      await _logger(
          'SyncWorker: cycle complete (processed=${result.processed}, '
          'synced=${result.synced}, failed=${result.failed}, '
          'conflicts=${result.conflicts})');
      final onComplete = _onCycleComplete;
      if (onComplete != null) {
        try {
          await onComplete(result);
        } catch (e) {
          await _logger('SyncWorker: status publication error: $e');
        }
      }
      return result;
    } catch (e) {
      await _logger('SyncWorker: cycle error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    stop();
  }
}
