/// Exception thrown when the trial has expired and a license is required.
class TrialExpiredException implements Exception {
  const TrialExpiredException();

  String get message => 'انتهت الفترة التجريبية. يرجى تفعيل الرخصة.';

  @override
  String toString() => 'TrialExpiredException: $message';
}

/// Exception thrown when a paid license has expired.
class LicenseExpiredException implements Exception {
  const LicenseExpiredException();

  String get message => 'انتهت صلاحية الرخصة. يرجى التواصل مع I Tech.';

  @override
  String toString() => 'LicenseExpiredException: $message';
}

/// Exception thrown when a license has been suspended.
class LicenseSuspendedException implements Exception {
  const LicenseSuspendedException();

  String get message => 'تم تعليق الرخصة. يرجى التواصل مع I Tech.';

  @override
  String toString() => 'LicenseSuspendedException: $message';
}

/// Exception thrown when the device limit has been reached.
class DeviceLimitReachedException implements Exception {
  final int currentDevices;
  final int maxDevices;

  const DeviceLimitReachedException({
    required this.currentDevices,
    required this.maxDevices,
  });

  String get message =>
      'تم الوصول إلى الحد الأقصى للأجهزة ($currentDevices/$maxDevices). '
      'يرجى التواصل مع مالك المتجر.';

  @override
  String toString() => 'DeviceLimitReachedException: $message';
}

/// Exception thrown when a device activation has been revoked.
class DeviceRevokedException implements Exception {
  const DeviceRevokedException();

  String get message => 'هذا الجهاز لم يعد مصرحاً به.';

  @override
  String toString() => 'DeviceRevokedException: $message';
}

/// Exception thrown when entitlement cannot be determined.
class EntitlementUnknownException implements Exception {
  const EntitlementUnknownException();

  String get message => 'يتطلب التحقق من الرخصة. يرجى الاتصال بالإنترنت.';

  @override
  String toString() => 'EntitlementUnknownException: $message';
}

/// Exception thrown when a clock rollback is detected.
class ClockRollbackDetectedException implements Exception {
  const ClockRollbackDetectedException();

  String get message => 'تم اكتشاف تغيير غير طبيعي في الوقت. يرجى التحقق.';

  @override
  String toString() => 'ClockRollbackDetectedException: $message';
}

/// Unified cloud licensing exception for write enforcement.
///
/// This is the exception thrown by [CloudLicensingService.enforceActive()]
/// to replace the old [LicenseActivationRequiredException].
class CloudLicenseWriteBlockedException implements Exception {
  final String message;

  const CloudLicenseWriteBlockedException(this.message);

  @override
  String toString() => 'CloudLicenseWriteBlockedException: $message';
}
