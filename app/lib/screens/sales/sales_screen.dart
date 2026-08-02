import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/sale.dart';
import 'invoice_screen.dart';
import 'sales_report_screen.dart';

class SalesScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showFab;

  const SalesScreen({super.key, this.showAppBar = true, this.showFab = true});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;
  DateTime _filterDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final sales = await DatabaseHelper.instance.getAllSales();
    setState(() {
      _sales = sales.reversed.toList();
      _filteredSales = _sales;
      _isLoading = false;
    });
  }

  void _filterSales(String query) {
    setState(() {
      _filteredSales = _sales
          .where((s) =>
              s.productName.toLowerCase().contains(query.toLowerCase()) ||
              s.barcode.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('المبيعات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.assessment),
                  tooltip: 'التقارير',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SalesReportScreen()),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    if (value == 'اليوم') {
                      setState(() {
                        _filteredSales = _sales
                            .where((s) =>
                                DateFormat('yyyy-MM-dd').format(s.date) ==
                                DateFormat('yyyy-MM-dd').format(DateTime.now()))
                            .toList();
                      });
                    } else if (value == 'بال تاريخ') {
                      _selectDate();
                    } else {
                      setState(() => _filteredSales = _sales);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'الكل', child: Text('عرض الكل')),
                    const PopupMenuItem(
                        value: 'اليوم', child: Text('مبيعات اليوم')),
                    const PopupMenuItem(
                        value: 'بال تاريخ', child: Text('筛选 بالتاريخ')),
                  ],
                ),
                IconButton(
                    icon: const Icon(Icons.refresh), onPressed: _loadData),
              ],
            )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0D47A1).withOpacity(0.05),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSales,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الباركود...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'عدد العمليات: ${_filteredSales.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'الإجمالي: ${_filteredSales.fold(0.0, (sum, s) => sum + s.totalSaleValue).toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                    ? const Center(child: Text('لا توجد مبيعات'))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: _filteredSales.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemBuilder: (context, index) {
                            final sale = _filteredSales[index];
                            return _buildSaleCard(sale);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.showFab
          ? FloatingActionButton.extended(
              onPressed: () => _openInvoiceScreen(context),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('فاتورة جديدة'),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final dateStr = DateFormat('yyyy-MM-dd').format(sale.date);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.shopping_cart, color: Colors.blue),
        ),
        title: Text(sale.productName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'التاريخ: $dateStr\nالكمية: ${sale.quantity} | السعر: ${sale.salePrice.toStringAsFixed(0)} ج.م',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${sale.totalSaleValue.toStringAsFixed(0)} ج.م',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _confirmDeleteSale(sale),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _openInvoiceScreen(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoiceScreen(),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked;
        _filteredSales = _sales
            .where((s) =>
                DateFormat('yyyy-MM-dd').format(s.date) ==
                DateFormat('yyyy-MM-dd').format(picked))
            .toList();
      });
    }
  }

  void _confirmDeleteSale(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف عملية البيع'),
        content: Text('هل أنت متأكد من حذف بيع "${sale.productName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteSale(sale.id!);
              if (context.mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
