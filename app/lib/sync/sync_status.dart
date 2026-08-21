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
