import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/sale.dart';
import 'invoice_screen.dart';
import 'sales_report_screen.dart';

import '../../services/session_state.dart';
import '../../services/permissions.dart';
import '../invoices/invoice_preview_screen.dart';

class SalesScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showFab;
  final SessionState? sessionState;

  const SalesScreen(
      {super.key,
      this.showAppBar = true,
      this.showFab = true,
      this.sessionState});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;
  DateTime _filterDate = DateTime.now();

  bool get _canViewSalesHistory =>
      widget.sessionState?.hasPermission(AppPermission.canViewSalesHistory) ??
      false;

  bool get _canCreateSales =>
      widget.sessionState?.hasPermission(AppPermission.canCreateSales) ?? false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_canViewSalesHistory) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sales = await DatabaseHelper.instance
          .getAllSales(currentRole: widget.sessionState?.currentRole);
      if (!mounted) return;
      setState(() {
        _sales = sales.reversed.toList();
        _filteredSales = _sales;
        _isLoading = false;
      });
    } on SalesHistoryAccessDeniedException {
      if (!mounted) return;
      setState(() {
        _sales = [];
        _filteredSales = [];
        _isLoading = false;
      });
    }
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
    if (!_canViewSalesHistory) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('المبيعات',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: true,
              )
            : null,
        body: _buildCreateSaleEntry(context),
      );
    }
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('المبيعات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.assessment),
                  tooltip: 'التقارير',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SalesReportScreen(
                              sessionState: widget.sessionState)),
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
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
      floatingActionButton: widget.showFab && _canCreateSales
          ? FloatingActionButton.extended(
              onPressed: () => _openInvoiceScreen(context),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('فاتورة جديدة'),
              backgroundColor: Theme.of(context).colorScheme.primary,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sale.invoiceId != null)
                  IconButton(
                    icon: Icon(Icons.receipt_long,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    tooltip: 'عرض الفاتورة',
                    onPressed: () => _openInvoicePreview(sale.invoiceId!),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () {
                    final canDelete = widget.sessionState
                            ?.hasPermission(AppPermission.canDeleteSales) ??
                        false;
                    if (!canDelete) {
                      showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                title: const Text('غير مصرح'),
                                content:
                                    const Text('لا يمكنك حذف عمليات البيع.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('حسناً'))
                                ],
                              ));
                      return;
                    }
                    _confirmDeleteSale(sale);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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
        builder: (context) => InvoiceScreen(sessionState: widget.sessionState),
      ),
    );
    if (result == true && _canViewSalesHistory) {
      _loadData();
    }
  }

  void _openInvoicePreview(int invoiceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(
          invoiceId: invoiceId,
          sessionState: widget.sessionState,
        ),
      ),
    );
  }

  Widget _buildCreateSaleEntry(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_shopping_cart,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('إنشاء فاتورة بيع جديدة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'سجل المبيعات متاح للمالك فقط',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            if (_canCreateSales)
              ElevatedButton.icon(
                onPressed: () => _openInvoiceScreen(context),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('فاتورة جديدة',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              Text(
                'لا تملك صلاحية تسجيل فواتير بيع.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
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
              await DatabaseHelper.instance.deleteSale(
                sale.id!,
                currentRole: widget.sessionState?.currentRole,
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
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
