enum SyncQueueOperation {
  CREATE,
  UPDATE,
  DELETE;

  String get label => name;
}

enum SyncQueueStatus {
  PENDING,
  SYNCED,
  FAILED,
  CONFLICT;

  String get label => name;
}

enum EntitySyncStatus {
  SYNCED,
  PENDING,
  CONFLICT;

  String get label => name;
}

enum ConflictResolutionPolicy {
  lastWriterWins,
  serverAuthoritative,
  latestTimestampWins,
}

enum SyncEntityType {
  product,
  sale,
  returnItem,
  expense,
  expenseCategory,
  customer,
  invoice,
  inventoryCount,
  shopSetting;

  String get label => name;

  /// Event-like entities are immutable financial/inventory observations
  /// (sales, returns, invoices, inventory counts). They are never
  /// LWW-resolved and replay must be idempotent. All other entities are
  /// mutable snapshots where true-timestamp LWW is permitted.
  bool get isEventLike => switch (this) {
        SyncEntityType.sale => true,
        SyncEntityType.returnItem => true,
        SyncEntityType.invoice => true,
        SyncEntityType.inventoryCount => true,
        _ => false,
      };
}

/// Lifecycle of a detected conflict beyond the legacy terminal CONFLICT
/// state (Phase M §20):
///   REVIEW_REQUIRED      - persisted, awaiting owner review
///   RESOLUTION_PENDING   - owner chose an action; system applying/verifying
///   RESOLVED             - terminal, carries resolution method/by/at/note
enum ConflictLifecycleStatus {
  REVIEW_REQUIRED,
  RESOLUTION_PENDING,
  RESOLVED;

  String get label => name;

  static ConflictLifecycleStatus? tryParse(String? value) {
    if (value == null) return null;
    for (final s in values) {
      if (s.label == value) return s;
    }
    return null;
  }
}

/// Who/what produced the final resolution of a conflict.
enum ConflictResolutionMethod {
  AUTO,
  POLICY,
  OWNER;

  String get label => name;
}

/// Offline oversell policy seam (Phase M §17 / DR-M06).
///
/// OD6 REMAINS OPEN. The shipped default is [preserveWithAdjustment]
/// (Option C mechanics + owner notification) classified as
/// ARCHITECTURE_RECOMMENDATION + TEMPORARY_SAFE_DEFAULT — NOT owner approval.
/// Switching behavior after an owner decision touches only this seam and its
/// tests; no commercial policy may leak into the sync engine itself.
enum OversellPolicyMode {
  /// Option B: preserve all events and allow negative derived stock without
  /// creating a reconciliation adjustment artifact.
  allowNegative,

  /// Option C (SHIPPED DEFAULT): preserve all events, create an explicit
  /// reconciliation adjustment artifact, notify owner, keep the stock
  /// equation exact and explainable.
  preserveWithAdjustment,

  /// Option D: preserve events but block convergence until the owner
  /// explicitly resolves the discrepancy.
  requireOwnerResolution,
}

enum SyncErrorType {
  networkUnavailable,
  licenseExpired,
  permissionDenied,
  conflictDetected,
  idempotencyViolation,
  versionMismatch,
  serverError,
  maxRetriesExceeded,
  queueCorrupted,
  unknown;

  String get label => name;

  bool get isRetryable => switch (this) {
        SyncErrorType.networkUnavailable => true,
        SyncErrorType.serverError => true,
        SyncErrorType.unknown => true,
        _ => false,
      };
}
