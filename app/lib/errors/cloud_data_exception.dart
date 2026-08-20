enum CloudDataErrorType {
  unauthenticated,
  notMember,
  membershipInactive,
  licenseRequired,
  licenseExpired,
  permissionDenied,
  invalidInput,
  notFound,
  conflict,
  constraintViolation,
  insufficientStock,
  networkError,
  serverError,
  unknown,
}

class CloudDataException implements Exception {
  final CloudDataErrorType type;
  final String message;
  final int? httpStatus;
  final String? serverMessage;

  CloudDataException({
    required this.type,
    required this.message,
    this.httpStatus,
    this.serverMessage,
  });

  factory CloudDataException.fromPostgrest(
      String errorMessage, int? statusCode) {
    final lower = errorMessage.toLowerCase();

    if (statusCode == 401) {
      return CloudDataException(
        type: CloudDataErrorType.unauthenticated,
        message: 'Authentication required',
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (lower.contains('not a member') || lower.contains('not_member')) {
      return CloudDataException(
        type: CloudDataErrorType.notMember,
        message: 'Not a member of this shop',
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (lower.contains('membership is not active')) {
      return CloudDataException(
        type: CloudDataErrorType.membershipInactive,
        message: 'Membership is not active',
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (lower.contains('active license required')) {
      return CloudDataException(
        type: CloudDataErrorType.licenseRequired,
        message: 'Active license required',
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (lower.contains('license has expired')) {
      return CloudDataException(
        type: CloudDataErrorType.licenseExpired,
        message: 'License has expired',
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (lower.contains('permission denied') ||
        lower.contains('require_shop_permission')) {
      return CloudDataException(
        type: CloudDataErrorType.permissionDenied,
        message: 'Permission denied',
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (lower.contains('insufficient stock')) {
      return CloudDataException(
        type: CloudDataErrorType.insufficientStock,
        message: errorMessage,
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (lower.contains('not found') ||
        lower.contains('product not found') ||
        lower.contains('sale not found') ||
        lower.contains('return not found') ||
        lower.contains('expense not found') ||
        lower.contains('category not found') ||
        lower.contains('customer not found')) {
      return CloudDataException(
        type: CloudDataErrorType.notFound,
        message: errorMessage,
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (lower.contains('already exists') ||
        lower.contains('duplicate') ||
        lower.contains('unique') ||
        lower.contains('constraint')) {
      return CloudDataException(
        type: CloudDataErrorType.conflict,
        message: errorMessage,
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (statusCode == 403) {
      return CloudDataException(
        type: CloudDataErrorType.permissionDenied,
        message: errorMessage,
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (statusCode == 404) {
      return CloudDataException(
        type: CloudDataErrorType.notFound,
        message: errorMessage,
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (statusCode == 409) {
      return CloudDataException(
        type: CloudDataErrorType.conflict,
        message: errorMessage,
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (statusCode == 503) {
      return CloudDataException(
        type: CloudDataErrorType.networkError,
        message: 'Connection timeout or failure',
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    if (statusCode == null || statusCode >= 500) {
      return CloudDataException(
        type: CloudDataErrorType.serverError,
        message: 'Internal server error',
        httpStatus: statusCode,
        serverMessage: errorMessage,
      );
    }

    return CloudDataException(
      type: CloudDataErrorType.unknown,
      message: errorMessage,
      httpStatus: statusCode,
      serverMessage: errorMessage,
    );
  }

  @override
  String toString() => 'CloudDataException($type): $message';
}
