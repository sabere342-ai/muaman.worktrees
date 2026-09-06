/// Phase P Group D D3 (P-OD6): arbitrary-period profit report model.
///
/// Captures the frozen D3 accounting contract: Revenue / Returns / Net Revenue
/// / COGS / Returned COGS / Net COGS / Gross Profit / Expenses /
/// Opening-Balance Adjustments / Net Result, plus a [complete] fail-closed flag
/// (plan D3-03) that suppresses authoritative "net profit" labeling when any
/// required input source is not proven fully accessible.
class PeriodBounds {
  final String start;
  final String end;
  const PeriodBounds(this.start, this.end);
}

enum PeriodType {
  day('day'),
  week('week'),
  month('month'),
  quarter('quarter'),
  year('year'),
  customRange('custom_range');

  const PeriodType(this.value);

  final String value;

  static PeriodType fromValue(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => PeriodType.day,
    );
  }

  String get label {
    switch (this) {
      case PeriodType.day:
        return 'يوم';
      case PeriodType.week:
        return 'أسبوع';
      case PeriodType.month:
        return 'شهر';
      case PeriodType.quarter:
        return 'ربع سنة';
      case PeriodType.year:
        return 'سنة';
      case PeriodType.customRange:
        return 'تاريخ مخصص';
    }
  }
}

class PeriodReport {
  final String start;
  final String end;
  final PeriodType periodType;

  final double revenue;
  final double returns;
  final double netRevenue;

  final double cogs;
  final double returnedCogs;
  final double netCogs;

  final double grossProfit;
  final double expenses;
  final double openingBalanceAdjustments;
  final double netResult;

  final bool complete;
  final int transactionCount;

  /// Optional period-over-period comparison (D3 extensionability item).
  final PeriodReport? previousPeriod;

  PeriodReport({
    required this.start,
    required this.end,
    required this.periodType,
    required this.revenue,
    required this.returns,
    required this.netRevenue,
    required this.cogs,
    required this.returnedCogs,
    required this.netCogs,
    required this.grossProfit,
    required this.expenses,
    required this.openingBalanceAdjustments,
    required this.netResult,
    required this.complete,
    required this.transactionCount,
    this.previousPeriod,
  });

  /// Growth rate of [netResult] vs [previousPeriod]. Returns 0 when no
  /// previous period is available or when the previous result was zero.
  double get netResultGrowthRate {
    if (previousPeriod == null) return 0.0;
    if (previousPeriod!.netResult == 0) return 0.0;
    return (netResult - previousPeriod!.netResult) /
        previousPeriod!.netResult.abs();
  }

  static String formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday % 7));
  }

  static DateTime _startOfQuarter(DateTime date) {
    final quarterStartMonth = ((date.month - 1) ~/ 3) * 3 + 1;
    return DateTime(date.year, quarterStartMonth, 1);
  }

  /// Computes date-only [startInclusive, endExclusive) boundaries for the
  /// given [periodType]. For [PeriodType.customRange], both [customStart]
  /// and [customEnd] must be supplied; the selected end date is made
  /// end-exclusive by advancing one day.
  ///
  /// [reference] defaults to `DateTime.now()` (device local). Tests pass an
  /// explicit reference to make boundary assertions deterministic.
  static PeriodBounds computePeriodBounds(
    PeriodType periodType, {
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    switch (periodType) {
      case PeriodType.day:
        return PeriodBounds(
          formatDateOnly(now),
          formatDateOnly(now.add(const Duration(days: 1))),
        );
      case PeriodType.week:
        final sunday = _startOfWeek(now);
        return PeriodBounds(
          formatDateOnly(sunday),
          formatDateOnly(sunday.add(const Duration(days: 7))),
        );
      case PeriodType.month:
        return PeriodBounds(
          formatDateOnly(DateTime(now.year, now.month, 1)),
          formatDateOnly(DateTime(now.year, now.month + 1, 1)),
        );
      case PeriodType.quarter:
        final qStart = _startOfQuarter(now);
        return PeriodBounds(
          formatDateOnly(qStart),
          formatDateOnly(DateTime(qStart.year, qStart.month + 3, 1)),
        );
      case PeriodType.year:
        return PeriodBounds(
          formatDateOnly(DateTime(now.year, 1, 1)),
          formatDateOnly(DateTime(now.year + 1, 1, 1)),
        );
      case PeriodType.customRange:
        if (customStart == null || customEnd == null) {
          throw ArgumentError(
              'customStart and customEnd are required for custom_range');
        }
        return PeriodBounds(
          formatDateOnly(customStart),
          formatDateOnly(customEnd.add(const Duration(days: 1))),
        );
    }
  }

  /// Computes date-only boundaries for the period immediately preceding the
  /// one returned by [computePeriodBounds]. Used for optional period-over-period
  /// comparison (D3 extensibility item, plan §D3/24).
  static PeriodBounds computePreviousPeriodBounds(
    PeriodType periodType, {
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    switch (periodType) {
      case PeriodType.day:
        return PeriodBounds(
          formatDateOnly(now.subtract(const Duration(days: 1))),
          formatDateOnly(now),
        );
      case PeriodType.week:
        final sunday = _startOfWeek(now);
        return PeriodBounds(
          formatDateOnly(sunday.subtract(const Duration(days: 7))),
          formatDateOnly(sunday),
        );
      case PeriodType.month:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        return PeriodBounds(
          formatDateOnly(
              DateTime(firstOfMonth.year, firstOfMonth.month - 1, 1)),
          formatDateOnly(firstOfMonth),
        );
      case PeriodType.quarter:
        final qStart = _startOfQuarter(now);
        return PeriodBounds(
          formatDateOnly(DateTime(qStart.year, qStart.month - 3, 1)),
          formatDateOnly(qStart),
        );
      case PeriodType.year:
        return PeriodBounds(
          formatDateOnly(DateTime(now.year - 1, 1, 1)),
          formatDateOnly(DateTime(now.year, 1, 1)),
        );
      case PeriodType.customRange:
        if (customStart == null || customEnd == null) {
          throw ArgumentError(
              'customStart and customEnd are required for custom_range');
        }
        final endExclusive = customEnd.add(const Duration(days: 1));
        final duration = endExclusive.difference(customStart);
        return PeriodBounds(
          formatDateOnly(customStart.subtract(duration)),
          formatDateOnly(customStart),
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
      'periodType': periodType.value,
      'revenue': revenue,
      'returns': returns,
      'netRevenue': netRevenue,
      'cogs': cogs,
      'returnedCogs': returnedCogs,
      'netCogs': netCogs,
      'grossProfit': grossProfit,
      'expenses': expenses,
      'openingBalanceAdjustments': openingBalanceAdjustments,
      'netResult': netResult,
      'complete': complete ? 1 : 0,
      'transactionCount': transactionCount,
      'previousPeriod': previousPeriod?.toMap(),
    };
  }

  factory PeriodReport.fromJson(Map<String, dynamic> json) =>
      PeriodReport.fromMap(json);

  factory PeriodReport.fromMap(Map<String, dynamic> map) {
    final prev = map['previousPeriod'];
    return PeriodReport(
      start: map['start'] as String? ?? '',
      end: map['end'] as String? ?? '',
      periodType: PeriodType.fromValue(map['periodType'] as String? ?? 'day'),
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0,
      returns: (map['returns'] as num?)?.toDouble() ?? 0,
      netRevenue: (map['netRevenue'] as num?)?.toDouble() ?? 0,
      cogs: (map['cogs'] as num?)?.toDouble() ?? 0,
      returnedCogs: (map['returnedCogs'] as num?)?.toDouble() ?? 0,
      netCogs: (map['netCogs'] as num?)?.toDouble() ?? 0,
      grossProfit: (map['grossProfit'] as num?)?.toDouble() ?? 0,
      expenses: (map['expenses'] as num?)?.toDouble() ?? 0,
      openingBalanceAdjustments:
          (map['openingBalanceAdjustments'] as num?)?.toDouble() ?? 0,
      netResult: (map['netResult'] as num?)?.toDouble() ?? 0,
      complete: map['complete'] == 1,
      transactionCount: (map['transactionCount'] as num?)?.toInt() ?? 0,
      previousPeriod: prev != null
          ? PeriodReport.fromMap(Map<String, dynamic>.from(prev as Map))
          : null,
    );
  }

  PeriodReport copyWith({
    String? start,
    String? end,
    PeriodType? periodType,
    double? revenue,
    double? returns,
    double? netRevenue,
    double? cogs,
    double? returnedCogs,
    double? netCogs,
    double? grossProfit,
    double? expenses,
    double? openingBalanceAdjustments,
    double? netResult,
    bool? complete,
    int? transactionCount,
    PeriodReport? previousPeriod,
  }) {
    return PeriodReport(
      start: start ?? this.start,
      end: end ?? this.end,
      periodType: periodType ?? this.periodType,
      revenue: revenue ?? this.revenue,
      returns: returns ?? this.returns,
      netRevenue: netRevenue ?? this.netRevenue,
      cogs: cogs ?? this.cogs,
      returnedCogs: returnedCogs ?? this.returnedCogs,
      netCogs: netCogs ?? this.netCogs,
      grossProfit: grossProfit ?? this.grossProfit,
      expenses: expenses ?? this.expenses,
      openingBalanceAdjustments:
          openingBalanceAdjustments ?? this.openingBalanceAdjustments,
      netResult: netResult ?? this.netResult,
      complete: complete ?? this.complete,
      transactionCount: transactionCount ?? this.transactionCount,
      previousPeriod: previousPeriod ?? this.previousPeriod,
    );
  }
}
