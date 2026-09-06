import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/period_report.dart';
import '../../services/permissions.dart';
import '../../services/session_state.dart';

class PeriodReportScreen extends StatefulWidget {
  final SessionState? sessionState;

  const PeriodReportScreen({super.key, this.sessionState});

  @override
  State<PeriodReportScreen> createState() => _PeriodReportScreenState();
}

class _PeriodReportScreenState extends State<PeriodReportScreen> {
  PeriodType _periodType = PeriodType.month;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _compareWithPrevious = false;
  PeriodReport? _report;
  bool _isLoading = false;

  bool get _canViewSalesHistory =>
      widget.sessionState?.hasPermission(AppPermission.canViewSalesHistory) ??
      false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (!_canViewSalesHistory) {
      setState(() {
        _report = null;
        _isLoading = false;
      });
      return;
    }

    if (_periodType == PeriodType.customRange) {
      if (_customStart == null || _customEnd == null) {
        setState(() {
          _report = null;
          _isLoading = false;
        });
        return;
      }
    }

    setState(() => _isLoading = true);

    final bounds = _periodType == PeriodType.customRange
        ? PeriodReport.computePeriodBounds(_periodType,
            customStart: _customStart!, customEnd: _customEnd!)
        : PeriodReport.computePeriodBounds(_periodType);

    try {
      final report = await DatabaseHelper.instance.getPeriodReport(
        start: bounds.start,
        end: bounds.end,
        periodType: _periodType,
        currentRole: widget.sessionState?.currentRole,
      );

      PeriodReport? previous;
      if (_compareWithPrevious) {
        final prevBounds = _periodType == PeriodType.customRange
            ? PeriodReport.computePreviousPeriodBounds(_periodType,
                customStart: _customStart!, customEnd: _customEnd!)
            : PeriodReport.computePreviousPeriodBounds(_periodType);
        previous = await DatabaseHelper.instance.getPeriodReport(
          start: prevBounds.start,
          end: prevBounds.end,
          periodType: _periodType,
          currentRole: widget.sessionState?.currentRole,
        );
      }

      if (!mounted) return;
      setState(() {
        _report = previous != null
            ? report.copyWith(previousPeriod: previous)
            : report;
        _isLoading = false;
      });
    } on SalesHistoryAccessDeniedException {
      if (!mounted) return;
      setState(() {
        _report = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _report = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final initialStart = _customStart ?? DateTime(now.year, now.month, 1);
    final initialEnd = _customEnd ?? now;
    final result = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      saveText: 'تطبيق',
      cancelText: 'إلغاء',
      confirmText: 'تطبيق',
    );
    if (result == null) return;
    setState(() {
      _customStart = result.start;
      _customEnd = result.end;
    });
    _loadReport();
  }

  String _formatCurrency(double value) {
    final fmt = NumberFormat('#,##0', 'ar');
    return '${fmt.format(value)} ج.م';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الأرباح',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_canViewSalesHistory && _report != null)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                  _loadReport();
                }),
        ],
      ),
      body: !_canViewSalesHistory
          ? const Center(
              child: Text(
                'غير مصرح بمشاهدة تقارير المبيعات',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                _buildControls(colorScheme),
                Expanded(child: _buildBody(colorScheme)),
              ],
            ),
    );
  }

  Widget _buildControls(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<PeriodType>(
            value: _periodType,
            decoration: const InputDecoration(
              labelText: 'نوع الفترة',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: PeriodType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _periodType = v;
                if (v == PeriodType.customRange) {
                  _customStart = null;
                  _customEnd = null;
                }
              });
              _loadReport();
            },
          ),
          if (_periodType == PeriodType.customRange) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                _customStart == null
                    ? 'اختر نطاق التواريخ'
                    : '${PeriodReport.formatDateOnly(_customStart!)} → '
                        '${PeriodReport.formatDateOnly(_customEnd ?? _customStart!)}',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('مقارنة بالفترة السابقة'),
            value: _compareWithPrevious,
            onChanged: (v) {
              setState(() => _compareWithPrevious = v);
              _loadReport();
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_periodType == PeriodType.customRange &&
        (_customStart == null || _customEnd == null)) {
      return const Center(child: Text('اختر نطاق التواريخ لعرض التقرير'));
    }
    if (_report == null) {
      return const Center(child: Text('اضغط على زر التحديث لعرض التقرير'));
    }
    return _buildReport(colorScheme);
  }

  Widget _buildReport(ColorScheme colorScheme) {
    final r = _report!;
    final bool showNetResult = r.complete;
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!r.complete)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'الصافي غير متاح — البيانات غير مكتملة',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 4),
              if (!r.complete) const SizedBox(height: 8),
              _buildPeriodHeader(r),
              const SizedBox(height: 8),
              _buildRow('إيراد', r.revenue, color: Colors.green),
              _buildRow('مرتجعات', r.returns,
                  color: Colors.red, isDeduction: true),
              _buildRow('صافي إيراد', r.netRevenue,
                  color: r.netRevenue >= 0 ? Colors.teal : Colors.red),
              const SizedBox(height: 4),
              _buildRow('تكلفة البضاعة المباعة', r.cogs, color: Colors.orange),
              _buildRow('مرتجع تكلفة', r.returnedCogs,
                  color: Colors.red, isDeduction: true),
              _buildRow('صافي التكلفة', r.netCogs,
                  color: r.netCogs >= 0 ? Colors.orange : Colors.red),
              const SizedBox(height: 4),
              _buildRow('الربح الإجمالي', r.grossProfit,
                  color: r.grossProfit >= 0 ? Colors.teal : Colors.red,
                  isTotal: true),
              _buildRow('مصاريف', r.expenses,
                  color: Colors.red, isDeduction: true),
              _buildRow('تعديلات الرصيد الافتتاحي', r.openingBalanceAdjustments,
                  color: r.openingBalanceAdjustments >= 0
                      ? Colors.blue
                      : Colors.red),
              const Divider(thickness: 1),
              _buildRow(
                r.complete ? 'الصافي' : 'الصافي (غير متاح)',
                r.netResult,
                color: r.netResult >= 0 ? Colors.teal : Colors.red,
                isTotal: true,
                suppressValue: !showNetResult,
              ),
              const SizedBox(height: 8),
              Text(
                '${r.transactionCount} معاملة',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              if (r.previousPeriod != null) ...[
                const SizedBox(height: 8),
                Text(
                  'نمو الصافي: ${_formatGrowthRate(r.netResultGrowthRate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        r.netResultGrowthRate >= 0 ? Colors.teal : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodHeader(PeriodReport r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('الفترة: ${r.periodType.label}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        Text('${r.start} → ${r.end}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRow(
    String label,
    double value, {
    required Color color,
    bool isTotal = false,
    bool isDeduction = false,
    bool suppressValue = false,
  }) {
    final displayValue = isDeduction && value != 0 ? -value.abs() : value;
    final text = suppressValue ? '—' : _formatCurrency(displayValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 14 : 12,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: Colors.grey.shade700)),
          Text(text,
              style: TextStyle(
                  fontSize: isTotal ? 15 : 13,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }

  String _formatGrowthRate(double rate) {
    final percentFmt = NumberFormat('#.##', 'ar');
    return '${rate >= 0 ? '+' : ''}${percentFmt.format(rate * 100)}%';
  }
}
