import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../sales/sales_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, double> _financialData = {};
  Map<String, dynamic> _inventoryData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final financial = await DatabaseHelper.instance.getDashboardData();
    final inventory = await DatabaseHelper.instance.getInventorySummary();
    setState(() {
      _financialData = financial;
      _inventoryData = inventory;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildFinancialSection(),
                    const SizedBox(height: 16),
                    _buildInventorySection(),
                    const SizedBox(height: 16),
                    _buildOperationsSection(),
                    const SizedBox(height: 16),
                    _buildFormulaSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.store, size: 48, color: Colors.white),
          SizedBox(height: 8),
          Text(
            'لوحة تحكم محل مؤمن',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'كل الأرقام محدثة تلقائيًا',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    return _buildSection(
      title: 'الملخص المالي',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF1B5E20),
      children: [
        _buildDataRow(
            'إجمالي المبيعات', _financialData['totalSales'] ?? 0, Colors.green),
        _buildDataRow('إجمالي المرتجعات', _financialData['totalReturns'] ?? 0,
            Colors.red),
        _buildDataRow(
            'صافي المبيعات', _financialData['netSales'] ?? 0, Colors.blue,
            isBold: true),
        const Divider(),
        _buildDataRow('تكلفة البضاعة المباعة', _financialData['totalCOGS'] ?? 0,
            Colors.orange),
        _buildDataRow('تكلفة البضاعة المرتجعة',
            _financialData['totalReturnedCOGS'] ?? 0, Colors.teal),
        _buildDataRow('صافي تكلفة المبيعات', _financialData['netCOGS'] ?? 0,
            Colors.orange,
            isBold: true),
        const Divider(),
        _buildDataRow(
            'مجمل الربح', _financialData['grossProfit'] ?? 0, Colors.indigo,
            isBold: true),
        _buildDataRow('إجمالي المصروفات', _financialData['totalExpenses'] ?? 0,
            Colors.deepOrange),
        const Divider(),
        _buildDataRow('صافي الربح', _financialData['netProfit'] ?? 0,
            const Color(0xFF004D40),
            isBold: true, fontSize: 18),
      ],
    );
  }

  Widget _buildInventorySection() {
    return _buildSection(
      title: 'المخزون',
      icon: Icons.inventory_2,
      color: const Color(0xFF0D47A1),
      children: [
        _buildStatRow('إجمالي قيمة المخزون',
            '${(_inventoryData['totalInventoryValue'] ?? 0).toStringAsFixed(0)} ج.م'),
        _buildStatRow('عدد الأصناف', '${_inventoryData['itemCount'] ?? 0}'),
        _buildStatRow(
            'إجمالي الكمية الحالية', '${_inventoryData['totalQuantity'] ?? 0}'),
      ],
    );
  }

  Widget _buildOperationsSection() {
    return _buildSection(
      title: 'حركة العمليات',
      icon: Icons.receipt_long,
      color: const Color(0xFF4A148C),
      children: [
        _buildStatRow('عمليات البيع', '${_inventoryData['salesCount'] ?? 0}'),
        _buildStatRow(
            'عمليات الإرجاع', '${_inventoryData['returnsCount'] ?? 0}'),
        _buildStatRow(
            'سجلات المصروفات', '${_inventoryData['expensesCount'] ?? 0}'),
        const Divider(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SalesReportScreen()),
              );
            },
            icon: const Icon(Icons.assessment, size: 18),
            label: const Text('تقارير المبيعات التفصيلية',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormulaSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'صافي الربح = (إجمالي المبيعات - المرتجعات - تكلفة البضاعة المباعة الصافية) - المصروفات',
        style: TextStyle(fontSize: 12, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, double value, Color color,
      {bool isBold = false, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize != null ? fontSize - 4 : 14,
              )),
          Text(
            '${value.toStringAsFixed(0)} ج.م',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: fontSize ?? 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
