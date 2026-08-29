/// Domain exceptions for cloud permission operations.
///
/// These exceptions represent server-side authorization failures that the
/// client can translate into user-friendly messages. They are NEVER the
/// security boundary — the server is always the authority.
enum CloudPermissionError {
  unauthenticated,
  notMember,
  membershipInactive,
  licenseRequired,
  licenseExpired,
  permissionDenied,
  invalidPermission,
  shopMismatch,
  ownerRequired,
  overrideViolation,
  serverError,
  networkError,
}

/// Exception thrown when a cloud permission operation fails.
class CloudPermissionException implements Exception {
  final CloudPermissionError error;
  final String? message;
  final String? detail;

  const CloudPermissionException(
    this.error, {
    this.message,
    this.detail,
  });

  factory CloudPermissionException.fromRpcError(String? rpcMessage) {
    if (rpcMessage == null) {
      return const CloudPermissionException(CloudPermissionError.serverError);
    }

    final lower = rpcMessage.toLowerCase();
    if (lower.contains('unauthenticated')) {
      return const CloudPermissionException(
          CloudPermissionError.unauthenticated);
    }
    if (lower.contains('not_member')) {
      return const CloudPermissionException(CloudPermissionError.notMember);
    }
    if (lower.contains('membership_inactive')) {
      return const CloudPermissionException(
          CloudPermissionError.membershipInactive);
    }
    if (lower.contains('license_required')) {
      return const CloudPermissionException(
          CloudPermissionError.licenseRequired);
    }
    if (lower.contains('license_expired')) {
      return const CloudPermissionException(
          CloudPermissionError.licenseExpired);
    }
    if (lower.contains('permission_denied')) {
      return CloudPermissionException(
        CloudPermissionError.permissionDenied,
        detail: rpcMessage,
      );
    }
    if (lower.contains('invalid_permission')) {
      return const CloudPermissionException(
          CloudPermissionError.invalidPermission);
    }
    if (lower.contains('shop_mismatch')) {
      return const CloudPermissionException(CloudPermissionError.shopMismatch);
    }
    if (lower.contains('owner_required')) {
      return const CloudPermissionException(CloudPermissionError.ownerRequired);
    }
    if (lower.contains('override_violation')) {
      return const CloudPermissionException(
          CloudPermissionError.overrideViolation);
    }

    return CloudPermissionException(
      CloudPermissionError.serverError,
      detail: rpcMessage,
    );
  }

  /// User-facing message in Arabic.
  String get userMessage {
    switch (error) {
      case CloudPermissionError.unauthenticated:
        return 'يرجى تسجيل الدخول مرة أخرى';
      case CloudPermissionError.notMember:
        return 'أنت لست عضواً في هذا المحل';
      case CloudPermissionError.membershipInactive:
        return 'تم تعليق عضويتك. يرجى التواصل مع مالك النظام';
      case CloudPermissionError.licenseRequired:
        return 'يتطلب تفعيل الرخصة';
      case CloudPermissionError.licenseExpired:
        return 'انتهت الصلاحية. يرجى تفعيل الرخصة';
      case CloudPermissionError.permissionDenied:
        return 'ليس لديك صلاحية لهذه العملية';
      case CloudPermissionError.invalidPermission:
        return 'خطأ في الصلاحيات. يرجى إعادة المحاولة';
      case CloudPermissionError.shopMismatch:
        return 'خطأ في تحديد المحل';
      case CloudPermissionError.ownerRequired:
        return 'هذه العملية تتطلب صلاحيات المالك';
      case CloudPermissionError.overrideViolation:
        return 'لا يمكن منح صلاحيات المالك لدور آخر';
      case CloudPermissionError.serverError:
        return 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً';
      case CloudPermissionError.networkError:
        return 'خطأ في الاتصال. يرجى المحاولة لاحقاً';
    }
  }

  @override
  String toString() => 'CloudPermissionException($error: $message)';
}
