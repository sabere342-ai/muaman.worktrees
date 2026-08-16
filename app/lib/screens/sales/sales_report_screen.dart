import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/sale.dart';
import '../../services/permissions.dart';
import '../../services/session_state.dart';

class SalesReportScreen extends StatefulWidget {
  final SessionState? sessionState;

  const SalesReportScreen({super.key, this.sessionState});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _byDate = [];
  List<Map<String, dynamic>> _byProduct = [];
  List<Sale> _allSales = [];
  bool _isLoading = true;

  bool get _canViewSalesHistory =>
      widget.sessionState?.hasPermission(AppPermission.canViewSalesHistory) ??
      false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_canViewSalesHistory) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final summary = await DatabaseHelper.instance
          .getSalesSummary(currentRole: widget.sessionState?.currentRole);
      final byDate = await DatabaseHelper.instance
          .getSalesGroupByDate(currentRole: widget.sessionState?.currentRole);
      final byProduct = await DatabaseHelper.instance.getSalesGroupByProduct(
          currentRole: widget.sessionState?.currentRole);
      final allSales = await DatabaseHelper.instance
          .getAllSales(currentRole: widget.sessionState?.currentRole);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _byDate = byDate;
        _byProduct = byProduct;
        _allSales = allSales.reversed.toList();
        _isLoading = false;
      });
    } on SalesHistoryAccessDeniedException {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير المبيعات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'حسب التاريخ'),
            Tab(text: 'حسب المنتج'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: !_canViewSalesHistory
          ? const Center(
              child: Text('غير مصرح بمشاهدة تقارير المبيعات'),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildSummaryCards(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllSalesTab(),
                          _buildByDateTab(),
                          _buildByProductTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF0D47A1).withOpacity(0.05),
      child: Column(
        children: [
          Row(
            children: [
              _buildMiniCard(
                  'اليوم',
                  '${(_summary['todaySales'] ?? 0).toStringAsFixed(0)} ج.م',
                  '${_summary['todayQty'] ?? 0} قطعة',
                  Icons.today,
                  Colors.green),
              const SizedBox(width: 8),
              _buildMiniCard(
                  'الشهر',
                  '${(_summary['monthSales'] ?? 0).toStringAsFixed(0)} ج.م',
                  '${_summary['monthQty'] ?? 0} قطعة',
                  Icons.calendar_month,
                  Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniCard(
                  'الإجمالي',
                  '${(_summary['totalSales'] ?? 0).toStringAsFixed(0)} ج.م',
                  '${_summary['totalTransactions'] ?? 0} عملية',
                  Icons.shopping_cart,
                  Colors.indigo),
              const SizedBox(width: 8),
              _buildMiniCard(
                  'الربح',
                  '${(_summary['grossProfit'] ?? 0).toStringAsFixed(0)} ج.م',
                  '${_summary['totalQty'] ?? 0} قطعة مباعة',
                  Icons.trending_up,
                  (_summary['grossProfit'] ?? 0) >= 0
                      ? Colors.teal
                      : Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(title,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              Text(subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllSalesTab() {
    if (_allSales.isEmpty) {
      return const Center(child: Text('لا توجد مبيعات'));
    }
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: _allSales.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, index) {
              final sale = _allSales[index];
              return _buildSaleRow(sale, index);
            },
          ),
        ),
        _buildTableFooter(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFF0D47A1),
      child: const Row(
        children: [
          SizedBox(
              width: 30,
              child: Text('#',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('التاريخ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('المنتج',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))),
          Expanded(
              flex: 1,
              child: Text('الكمية',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('البيع',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('التكلفة',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('الربح',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildSaleRow(Sale sale, int index) {
    final profit = sale.totalSaleValue - sale.cogs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('${index + 1}',
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(DateFormat('MM/dd').format(sale.date),
                style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            flex: 3,
            child: Text(sale.productName,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 1,
            child: Text('${sale.quantity}',
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('${sale.totalSaleValue.toStringAsFixed(0)} ج.م',
                style: const TextStyle(fontSize: 11, color: Colors.green),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('${sale.cogs.toStringAsFixed(0)} ج.م',
                style: const TextStyle(fontSize: 11, color: Colors.orange),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('${profit.toStringAsFixed(0)} ج.م',
                style: TextStyle(
                    fontSize: 11,
                    color: profit >= 0 ? Colors.teal : Colors.red,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildTableFooter() {
    final totalSales = _allSales.fold(0.0, (sum, s) => sum + s.totalSaleValue);
    final totalCOGS = _allSales.fold(0.0, (sum, s) => sum + s.cogs);
    final totalProfit = totalSales - totalCOGS;
    final totalQty = _allSales.fold(0, (sum, s) => sum + s.quantity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFF0D47A1).withOpacity(0.1),
      child: Row(
        children: [
          const SizedBox(
              width: 30,
              child: Text('المجموع',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
              flex: 3,
              child: Text('${_allSales.length} عملية',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 1,
              child: Text('$totalQty',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('${totalSales.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('${totalCOGS.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                  textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('${totalProfit.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: totalProfit >= 0 ? Colors.teal : Colors.red),
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildByDateTab() {
    if (_byDate.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }
    return ListView.builder(
      itemCount: _byDate.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final item = _byDate[index];
        final date = DateTime.parse(item['date']);
        final profit = (item['grossProfit'] as num?)?.toDouble() ?? 0;
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 6),
                    Text(DateFormat('yyyy-MM-dd (EEEE)', 'ar').format(date),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Divider(height: 10),
                Row(
                  children: [
                    _buildDateStat(
                        'المبيعات',
                        '${((item['totalSales'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} ج.م',
                        Colors.green),
                    _buildDateStat(
                        'الكمية', '${item['totalQuantity']}', Colors.blue),
                    _buildDateStat('العمليات', '${item['transactionCount']}',
                        Colors.indigo),
                    _buildDateStat(
                        'التكلفة',
                        '${((item['totalCOGS'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} ج.م',
                        Colors.orange),
                    _buildDateStat('الربح', '${profit.toStringAsFixed(0)} ج.م',
                        profit >= 0 ? Colors.teal : Colors.red),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildByProductTab() {
    if (_byProduct.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: const Color(0xFF0D47A1).withOpacity(0.1),
          child: const Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('المنتج',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 1,
                  child: Text('الكمية',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('متوسط السعر',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('المبيعات',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('الربح',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _byProduct.length,
            itemBuilder: (context, index) {
              final item = _byProduct[index];
              final profit = (item['grossProfit'] as num?)?.toDouble() ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                  border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade200, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['productName']}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('${item['barcode']}',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Expanded(
                        flex: 1,
                        child: Text('${item['totalQuantity']}',
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text(
                            '${((item['avgPrice'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} ج.م',
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text(
                            '${((item['totalSales'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.green),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text('${profit.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                                fontSize: 11,
                                color: profit >= 0 ? Colors.teal : Colors.red,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
