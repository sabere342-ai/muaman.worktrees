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

  Timer? _timer;
  SyncWorkerState _state = SyncWorkerState.stopped;
  bool _isProcessing = false;

  SyncWorkerState get state => _state;
  bool get isRunning =>
      _state == SyncWorkerState.running && _timer != null;

  SyncWorker({
    required SyncEngine engine,
    required Future<bool> Function() connectivityCheck,
    required Future<bool> Function() sessionCheck,
    required Future<void> Function(String message) logger,
    Duration interval = const Duration(seconds: 30),
  })  : _engine = engine,
        _connectivityCheck = connectivityCheck,
        _sessionCheck = sessionCheck,
        _logger = logger,
        _interval = interval;

  void start() {
    if (_state == SyncWorkerState.running) return;

    _state = SyncWorkerState.running;
    _timer = Timer.periodic(_interval, (_) => _onTick());

    _logger('SyncWorker started (interval: ${_interval.inSeconds}s)');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _state = SyncWorkerState.stopped;
    _logger('SyncWorker stopped');
  }

  Future<void> syncNow() async {
    await _onTick();
  }

  Future<void> _onTick() async {
    if (_isProcessing) return;

    if (_state != SyncWorkerState.running) return;

    final isSessionValid = await _sessionCheck();
    if (!isSessionValid) {
      await _logger('SyncWorker: session invalid, skipping cycle');
      return;
    }

    final isOnline = await _connectivityCheck();
    if (!isOnline) {
      await _logger('SyncWorker: offline, skipping cycle');
      return;
    }

    _isProcessing = true;
    try {
      await _logger('SyncWorker: starting sync cycle');
      final result = await _engine.processQueue();
      await _logger(
          'SyncWorker: cycle complete (processed=${result.processed}, '
          'synced=${result.synced}, failed=${result.failed}, '
          'conflicts=${result.conflicts})');
    } catch (e) {
      await _logger('SyncWorker: cycle error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    stop();
  }
}
