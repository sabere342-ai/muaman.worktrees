import 'entitlement_cache.dart';

/// Offline grace durations per license type.
class OfflineGracePolicy {
  /// The maximum duration for which a cached entitlement may be used offline
  /// before revalidation is required.
  static const Duration revalidationWindow = Duration(hours: 24);

  /// Grace for TRIAL: until cached trial_ends_at.
  static const Duration trialGrace = Duration.zero;

  /// Grace for ACTIVE (paid): 7 days from last server sync.
  static const Duration paidGrace = Duration(days: 7);

  /// Grace for PERPETUAL: 14 days from last server sync.
  static const Duration perpetualGrace = Duration(days: 14);

  /// Tolerance for clock skew detection (5 minutes).
  static const Duration clockSkewTolerance = Duration(minutes: 5);

  /// Maximum allowed clock rollback before triggering tamper detection (30 min).
  static const Duration clockRollbackThreshold = Duration(minutes: 30);

  final EntitlementCache _cache;

  OfflineGracePolicy({EntitlementCache? cache})
      : _cache = cache ?? EntitlementCache();

  /// Check if the cached entitlement is within the allowed offline window.
  ///
  /// Returns `true` if the entitlement may be used offline based on the
  /// cached state and elapsed time since last server verification.
  bool isWithinGraceWindow(
    dynamic snapshot, {
    DateTime? currentTime,
  }) {
    if (snapshot == null) return false;

    final now = currentTime ?? DateTime.now().toUtc();
    final lastSync = snapshot.lastSuccessfulVerificationAt as DateTime;
    final elapsed = now.difference(lastSync);

    if (elapsed.isNegative) {
      // Clock moved backwards — suspicious but don't extend grace
      return false;
    }

    // Check revalidation window (24 hours)
    if (elapsed > revalidationWindow) {
      return false;
    }

    // Check type-specific grace
    if (snapshot.isTrialActive == true) {
      // For trial: valid only until trial_ends_at
      final trialExpires = snapshot.trialExpiresAt as DateTime?;
      if (trialExpires != null && now.isAfter(trialExpires)) {
        return false;
      }
      return true;
    }

    if (snapshot.isPaidActive == true) {
      // For paid: 7-day grace from last sync
      return elapsed <= paidGrace;
    }

    if (snapshot.licenseStatus == 'PERPETUAL') {
      // For perpetual: 14-day grace from last sync
      return elapsed <= perpetualGrace;
    }

    return false;
  }

  /// Detect clock rollback by comparing current wall clock to last observed.
  ///
  /// Returns `true` if a material clock rollback is detected (beyond tolerance).
  Future<bool> detectClockRollback() async {
    final lastObserved = await _cache.getLastObservedClock();
    if (lastObserved == null) return false;

    final now = DateTime.now();
    final diff = lastObserved.difference(now);

    // If the current time is materially behind the last observed time,
    // the user may have rolled back the clock.
    if (diff > clockRollbackThreshold) {
      return true;
    }

    return false;
  }

  /// Whether the cached state explicitly indicates an expired/suspended/revoked
  /// license. Such non-entitled states must be cached and respected offline.
  bool isCachedNonEntitled(dynamic snapshot) {
    if (snapshot == null) return true;
    if (!snapshot.hasLicense) return true;

    final status = snapshot.licenseStatus as String?;
    if (status == 'EXPIRED' || status == 'SUSPENDED' || status == 'REVOKED') {
      return true;
    }

    if (snapshot.isTrial == true && snapshot.trialActive != true) {
      return true;
    }

    return false;
  }
}
