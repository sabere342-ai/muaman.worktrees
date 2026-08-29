import '../sync/sync_status.dart';

class SyncException implements Exception {
  final SyncErrorType type;
  final String message;
  final Object? cause;

  const SyncException({
    required this.type,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'SyncException(${type.label}): $message';
}

class SyncConflictException extends SyncException {
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? serverData;
  final Map<String, dynamic>? localData;

  const SyncConflictException({
    required this.entityType,
    required this.entityId,
    this.serverData,
    this.localData,
    String message = 'Conflict detected',
  }) : super(
          type: SyncErrorType.conflictDetected,
          message: message,
        );

  @override
  String toString() => 'SyncConflictException($entityType:$entityId): $message';
}

class SyncIdempotencyException extends SyncException {
  final String idempotencyKey;

  const SyncIdempotencyException({
    required this.idempotencyKey,
    String message = 'Idempotency key already processed',
  }) : super(
          type: SyncErrorType.idempotencyViolation,
          message: message,
        );
}
