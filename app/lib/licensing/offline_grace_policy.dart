import 'entitlement_cache.dart';

/// Offline grace durations per license type.
///
/// Phase P (WS-4, plan §F.5 / B.6-B.7): grace follows the OWNER SPEC —
/// paid 7 days, perpetual 14 days (launch-compat), trial 0 days (a trial
/// must revalidate online; it has no offline runway). The former blanket
/// 24h `revalidationWindow` cap ran before the type-specific grace and
/// silently truncated paid/perpetual offline runways to a single day; it is
/// retired so the per-type durations are authoritative.
class OfflineGracePolicy {
  /// Grace for TRIAL: 0 — a trial cannot operate offline (B.7).
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

  bool _isTrial(dynamic snapshot) =>
      snapshot.licenseStatus == 'TRIAL' ||
      snapshot.isTrial == true ||
      snapshot.isTrialActive == true;

  /// Check if the cached entitlement is within the allowed offline window.
  ///
  /// The grace anchor is the TRUSTED baseline, resolved in priority order:
  ///   1. an explicitly supplied [trustedHighWater] (the independently
  ///      protected server-time high-water), when provided by the service;
  ///   2. the snapshot's authenticated `lastTrustedServerTimeUtc` (S8-bound);
  ///   3. the legacy plaintext `lastSuccessfulVerificationAt` (backward
  ///      compatible only when no S8 binding / high-water exists).
  ///
  /// A wall-clock rollback behind the trusted baseline beyond the declared
  /// skew tolerance fails closed (no offline grant) and can never extend or
  /// preserve offline grace (Governance K rule 3 / Section 13).
  ///
  /// Returns `true` if the entitlement may be used offline based on the
  /// cached state and elapsed time since the trusted baseline.
  bool isWithinGraceWindow(
    dynamic snapshot, {
    DateTime? currentTime,
    DateTime? trustedHighWater,
  }) {
    if (snapshot == null) return false;

    final now = (currentTime ?? DateTime.now().toUtc()).toUtc();

    // Resolve the trusted baseline (1 → 2 → 3 above).
    DateTime baseline;
    final explicitHighWater = trustedHighWater?.toUtc();
    final boundHighWater = snapshot.lastTrustedServerTimeUtc is DateTime
        ? (snapshot.lastTrustedServerTimeUtc as DateTime).toUtc()
        : null;
    final legacy = snapshot.lastSuccessfulVerificationAt is DateTime
        ? (snapshot.lastSuccessfulVerificationAt as DateTime).toUtc()
        : null;

    if (explicitHighWater != null) {
      baseline = explicitHighWater;
    } else if (boundHighWater != null) {
      baseline = boundHighWater;
    } else if (legacy != null) {
      baseline = legacy;
    } else {
      return false;
    }

    // Fail closed on a material wall-clock rollback behind the trusted
    // baseline: a backward jump never extends grace (R4). Minor skew within
    // the declared tolerance is tolerated (K rule 6) but never creates time.
    if (now
        .isBefore(baseline.subtract(OfflineGracePolicy.clockSkewTolerance))) {
      return false;
    }

    final elapsed = now.difference(baseline);

    if (elapsed.isNegative) {
      // Clock moved backwards — suspicious but don't extend grace
      return false;
    }

    // TRIAL: zero offline grace. A trial must revalidate online; even a
    // live trial gets no offline runway (B.7). Cached non-entitled trial
    // states are separately enforced by isCachedNonEntitled.
    if (_isTrial(snapshot)) {
      return false;
    }

    if (snapshot.licenseStatus == 'PERPETUAL') {
      // Perpetual: 14-day grace from the trusted baseline (launch-compat).
      return elapsed <= perpetualGrace;
    }

    // ACTIVE / paid: 7-day grace from the trusted baseline.
    return elapsed <= paidGrace;
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
