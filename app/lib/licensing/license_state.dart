/// Licensing state machine per T3-2 §22.
///
/// This is the single source of truth for entitlement state resolution.
/// Deterministic: same inputs always produce the same state.
enum EntitlementState {
  /// No activation has ever been performed on this installation.
  /// DPAPI activation file not found.
  uninitialized(0),

  /// User must activate to access protected operations.
  /// Operational state at enforcement boundary.
  activationRequired(1),

  /// Valid entitlement, verified signature, matching device and business.
  active(2),

  /// Entitlement valid but in restricted/safe mode (future: after expiry).
  activeRestricted(3),

  /// Ed25519 signature verification failed.
  invalidSignature(4),

  /// DPAPI file exists but cannot be parsed, decrypted, or fails HMAC.
  localStateCorrupt(5),

  /// Token's business_id does not match locally stored business_id.
  businessMismatch(6),

  /// Token's device_id_hash does not match current device fingerprint.
  deviceMismatch(7),

  /// Server determined that a transfer is needed.
  transferRequired(8),

  /// Server has revoked this license (detected on next server contact).
  revoked(9),

  /// Token version not supported by this client build.
  unsupportedTokenVersion(10),

  /// Activation request in progress (transient state).
  activating(11),

  /// Server unavailable during activation attempt.
  serverUnavailable(12);

  final int id;
  const EntitlementState(this.id);

  static EntitlementState fromId(int id) {
    return EntitlementState.values.firstWhere(
      (s) => s.id == id,
      orElse: () => EntitlementState.uninitialized,
    );
  }

  /// Whether this state blocks new commercial transactions.
  bool get blocksWrites {
    switch (this) {
      case EntitlementState.active:
        return false;
      case EntitlementState.uninitialized:
      case EntitlementState.activationRequired:
      case EntitlementState.activeRestricted:
      case EntitlementState.invalidSignature:
      case EntitlementState.localStateCorrupt:
      case EntitlementState.businessMismatch:
      case EntitlementState.deviceMismatch:
      case EntitlementState.transferRequired:
      case EntitlementState.revoked:
      case EntitlementState.unsupportedTokenVersion:
      case EntitlementState.activating:
      case EntitlementState.serverUnavailable:
        return true;
    }
  }

  /// Whether read/view operations are always allowed in this state.
  bool get allowsRead => true;

  /// Whether backup/export is always allowed in this state.
  bool get allowsBackup => true;

  /// Whether activation/recovery operations are always allowed.
  bool get allowsActivation => true;

  /// Arabic human-readable label for UI display.
  String get labelAr {
    switch (this) {
      case EntitlementState.uninitialized:
        return 'غير مُهيأ';
      case EntitlementState.activationRequired:
        return 'يتطلب تفعيل';
      case EntitlementState.active:
        return 'نشطة';
      case EntitlementState.activeRestricted:
        return 'نشطة (محدودة)';
      case EntitlementState.invalidSignature:
        return 'توقيع غير صالح';
      case EntitlementState.localStateCorrupt:
        return 'بيانات الترخيص تالفة';
      case EntitlementState.businessMismatch:
        return 'عدم تطابق النشاط';
      case EntitlementState.deviceMismatch:
        return 'عدم تطابق الجهاز';
      case EntitlementState.transferRequired:
        return 'يتطلب نقل';
      case EntitlementState.revoked:
        return 'مُلغاة';
      case EntitlementState.unsupportedTokenVersion:
        return 'إصدار غير مدعوم';
      case EntitlementState.activating:
        return 'جاري التفعيل...';
      case EntitlementState.serverUnavailable:
        return 'الخادم غير متاح';
    }
  }
}

/// Classification of business operations for enforcement.
enum OperationCategory {
  /// Read-only operations (view records, reports, print existing).
  read,

  /// Licensed write operations (create/edit/delete business data).
  licensedWrite,

  /// Backup and export operations (always allowed).
  backupExport,

  /// License recovery operations (activate, transfer - always allowed).
  licenseRecovery,

  /// Administrative non-business writes (settings that don't affect
  /// financial/business state — always allowed).
  nonBusinessAdmin,
}

/// Thrown by business write methods when the licensing entitlement is not
/// ACTIVE. UI code should catch this separately from PermissionDeniedException
/// to display a licensing-specific message (e.g., prompting for activation).
class LicenseActivationRequiredException implements Exception {
  const LicenseActivationRequiredException();

  String get message =>
      'الترخيص غير مفعّل. يرجى تفعيل الرخصة لتنفيذ هذه العملية.';

  @override
  String toString() => 'LicenseActivationRequiredException: $message';
}

/// Result of an enforcement check.
class EnforcementDecision {
  final bool allowed;
  final EntitlementState state;
  final String? reason;

  const EnforcementDecision({
    required this.allowed,
    required this.state,
    this.reason,
  });

  static const allow = EnforcementDecision(
    allowed: true,
    state: EntitlementState.active,
  );

  static EnforcementDecision denied(
    EntitlementState state, {
    String? reason,
  }) {
    return EnforcementDecision(
      allowed: false,
      state: state,
      reason: reason,
    );
  }
}
