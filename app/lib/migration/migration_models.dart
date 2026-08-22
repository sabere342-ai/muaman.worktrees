// The enum member names ARE the frozen durable status strings persisted in
// `legacy_migration_progress.status` (plan D8/D9) and exchanged with the
// owner-facing UI; they intentionally use the frozen SCREAMING_CASE spelling.
// ignore_for_file: constant_identifier_names
import 'package:sqflite/sqflite.dart';

/// Phase I / D9 batch lifecycle states.
enum LegacyMigrationState {
  NOT_STARTED,
  BACKUP_VERIFIED,
  RUNNING,
  PAUSED,
  RECONCILING,
  FAILED,
  ABORTED,
  COMPLETED;

  String get label => name;

  static LegacyMigrationState fromLabel(String label) =>
      LegacyMigrationState.values.firstWhere(
        (s) => s.label == label,
        orElse: () => throw StateError('Unknown migration state: $label'),
      );

  /// Terminal per D9: only these close a batch permanently.
  bool get isTerminal => this == COMPLETED || this == ABORTED;

  bool get isResumableFailure => this == FAILED;
}

/// Frozen D9 transition table.
///
/// ```
/// NOT_STARTED → BACKUP_VERIFIED → RUNNING ⇄ PAUSED
/// RUNNING → RECONCILING → COMPLETED
/// any of {RUNNING, PAUSED, RECONCILING} → FAILED(resumable) → RUNNING [resume]
/// any non-terminal state → ABORTED (owner-initiated)
/// ```
const Map<LegacyMigrationState, Set<LegacyMigrationState>>
    kLegacyMigrationTransitions = {
  LegacyMigrationState.NOT_STARTED: {
    LegacyMigrationState.BACKUP_VERIFIED,
    // Owner-initiated abort of a batch that never passed verification (D9).
    LegacyMigrationState.ABORTED,
  },
  LegacyMigrationState.BACKUP_VERIFIED: {
    LegacyMigrationState.RUNNING,
    LegacyMigrationState.ABORTED,
  },
  LegacyMigrationState.RUNNING: {
    LegacyMigrationState.PAUSED,
    LegacyMigrationState.RECONCILING,
    LegacyMigrationState.FAILED,
    LegacyMigrationState.ABORTED,
  },
  LegacyMigrationState.PAUSED: {
    LegacyMigrationState.RUNNING,
    LegacyMigrationState.FAILED,
    LegacyMigrationState.ABORTED,
  },
  LegacyMigrationState.RECONCILING: {
    LegacyMigrationState.COMPLETED,
    LegacyMigrationState.FAILED,
    LegacyMigrationState.ABORTED,
  },
  LegacyMigrationState.FAILED: {
    // Resume path; also owner reset via ABORTED (D12: ABORTED + new batch).
    LegacyMigrationState.RUNNING,
    LegacyMigrationState.ABORTED,
  },
  LegacyMigrationState.ABORTED: {},
  LegacyMigrationState.COMPLETED: {},
};

/// In-memory guard enforcing the frozen transition rules. The durable copy
/// lives in `legacy_migration_progress.status` and is persisted by the caller
/// in the same transaction as each chunk's checkpoint update (D9), so a crash
/// recovers from the last durable state.
class LegacyMigrationStateMachine {
  LegacyMigrationState _state;

  LegacyMigrationStateMachine(
      {LegacyMigrationState initial = LegacyMigrationState.NOT_STARTED})
      : _state = initial;

  LegacyMigrationState get state => _state;

  static bool canTransition(
          LegacyMigrationState from, LegacyMigrationState to) =>
      kLegacyMigrationTransitions[from]!.contains(to);

  void requireTransition(LegacyMigrationState to) {
    if (!canTransition(_state, to)) {
      throw StateError(
          'Illegal legacy-migration transition: ${_state.label} → ${to.label}');
    }
    _state = to;
  }

  void restore(LegacyMigrationState persisted) {
    if (persisted.isResumableFailure) {
      _state = persisted;
      return;
    }
    _state = persisted;
  }
}

/// Per-table ledger status counts mirrored from the cloud migration ledger.
class LedgerStatusCounts {
  final int imported;
  final int skippedDuplicate;
  final int conflict;

  const LedgerStatusCounts({
    this.imported = 0,
    this.skippedDuplicate = 0,
    this.conflict = 0,
  });

  int get total => imported + skippedDuplicate + conflict;

  factory LedgerStatusCounts.fromMap(Map<String, dynamic> map) =>
      LedgerStatusCounts(
        imported: (map['IMPORTED'] as num?)?.toInt() ?? 0,
        skippedDuplicate: (map['SKIPPED_DUPLICATE'] as num?)?.toInt() ?? 0,
        conflict: (map['CONFLICT'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'IMPORTED': imported,
        'SKIPPED_DUPLICATE': skippedDuplicate,
        'CONFLICT': conflict,
      };
}

/// One table's reconciliation outcome (D15).
class ReconciliationTableResult {
  final String tableName;
  final int expectedRows;
  final int imported;
  final int duplicatesSkipped;
  final int conflicts;
  final List<String> missingRefs;
  final Map<String, double> financialExpected;
  final Map<String, double> financialActual;

  const ReconciliationTableResult({
    required this.tableName,
    required this.expectedRows,
    required this.imported,
    required this.duplicatesSkipped,
    required this.conflicts,
    required this.missingRefs,
    required this.financialExpected,
    required this.financialActual,
  });

  /// D15 parity including the explicit missing-reference bucket: children
  /// with unresolvable hard references (e.g. inventory_count rows whose
  /// product vanished) are never dropped silently — they are counted here
  /// and listed in the report (D6 rationale).
  bool get countsMatch =>
      expectedRows ==
      imported + duplicatesSkipped + conflicts + missingRefs.length;

  /// Byte-exact comparison per D14 (equality asserted, never tolerance).
  bool get financialsMatch {
    for (final key in financialExpected.keys) {
      if (financialActual[key] != financialExpected[key]) return false;
    }
    for (final key in financialActual.keys) {
      if (!financialExpected.containsKey(key)) return false;
    }
    return true;
  }

  bool get pass => countsMatch && financialsMatch;

  Map<String, dynamic> toMap() => {
        'table': tableName,
        'expected_rows': expectedRows,
        'imported': imported,
        'duplicates_skipped': duplicatesSkipped,
        'conflicts': conflicts,
        'missing_refs': missingRefs,
        'financial_expected': financialExpected,
        'financial_actual': financialActual,
        'pass': pass,
      };
}

/// Full reconciliation verdict (D15). Only PASS unlocks P10 stamping.
class ReconciliationReport {
  final String batchId;
  final String shopId;
  final List<ReconciliationTableResult> tables;
  final List<String> quarantinedNotes;

  const ReconciliationReport({
    required this.batchId,
    required this.shopId,
    required this.tables,
    this.quarantinedNotes = const [],
  });

  bool get verdictPass => tables.every((t) => t.pass);

  String get verdict => verdictPass ? 'PASS' : 'FAIL';

  Map<String, dynamic> toMap() => {
        'batch_id': batchId,
        'shop_id': shopId,
        'verdict': verdict,
        'tables': tables.map((t) => t.toMap()).toList(),
        'quarantined_notes': quarantinedNotes,
      };

  static ReconciliationReport fromMap(Map<String, dynamic> map) =>
      ReconciliationReport(
        batchId: map['batch_id'] as String,
        shopId: map['shop_id'] as String,
        tables: (map['tables'] as List)
            .map((t) => ReconciliationTableResult(
                  tableName: t['table'] as String,
                  expectedRows: (t['expected_rows'] as num?)?.toInt() ?? 0,
                  imported: (t['imported'] as num?)?.toInt() ?? 0,
                  duplicatesSkipped:
                      (t['duplicates_skipped'] as num?)?.toInt() ?? 0,
                  conflicts: (t['conflicts'] as num?)?.toInt() ?? 0,
                  missingRefs:
                      (t['missing_refs'] as List?)?.cast<String>() ?? const [],
                  financialExpected:
                      _toDoubleMap(t['financial_expected']) ?? const {},
                  financialActual:
                      _toDoubleMap(t['financial_actual']) ?? const {},
                ))
            .toList(),
        quarantinedNotes:
            (map['quarantined_notes'] as List?)?.cast<String>() ?? const [],
      );
}

Map<String, double>? _toDoubleMap(Object? raw) {
  if (raw is! Map) return null;
  return {
    for (final e in raw.entries)
      e.key.toString(): (e.value is num) ? (e.value as num).toDouble() : 0.0,
  };
}

/// Census row for one migration universe table (P0 preflight / W8).
class PreflightTableCensus {
  final String tableName;
  final int totalRows;
  final int alreadyCloudLinked;
  final int rowsToMigrate;
  final int quarantinedForeignShop;
  final int adoptedUnattributed;

  const PreflightTableCensus({
    required this.tableName,
    required this.totalRows,
    required this.alreadyCloudLinked,
    required this.rowsToMigrate,
    required this.quarantinedForeignShop,
    required this.adoptedUnattributed,
  });

  Map<String, dynamic> toMap() => {
        'table': tableName,
        'total_rows': totalRows,
        'already_cloud_linked': alreadyCloudLinked,
        'rows_to_migrate': rowsToMigrate,
        'quarantined_foreign_shop': quarantinedForeignShop,
        'adopted_unattributed': adoptedUnattributed,
      };
}

/// P0 preflight output feeding the owner consent screen (W8 / D3 / D13).
class PreflightReport {
  final String shopId;
  final List<PreflightTableCensus> censuses;
  final List<Map<String, dynamic>> anomalies;
  final Map<String, int> liveBaselineCounts;

  const PreflightReport({
    required this.shopId,
    required this.censuses,
    required this.anomalies,
    required this.liveBaselineCounts,
  });

  Map<String, dynamic> toMap() => {
        'shop_id': shopId,
        'censuses': censuses.map((c) => c.toMap()).toList(),
        'anomalies': anomalies,
        'live_baseline_counts': liveBaselineCounts,
      };
}

/// Thrown when an orchestration precondition fails (resume caps exhausted,
/// rerun of a terminal batch, superseded batch, ...).
class MigrationStateException implements Exception {
  final String message;
  const MigrationStateException(this.message);

  @override
  String toString() => 'MigrationStateException: $message';
}

/// Thrown when the cloud ingest path fails after exhausting retries.
class MigrationCloudException implements Exception {
  final String message;
  final Object? cause;

  const MigrationCloudException(this.message, [this.cause]);

  @override
  String toString() =>
      'MigrationCloudException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Convenience helper used by services that need a read-only executor bound
/// either to a snapshot database or the live one.
typedef DatabaseOpener = Future<Database> Function();
