import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/return_item.dart';
import '../../models/product.dart';

import '../../services/session_state.dart';
import '../../services/permissions.dart';

class ReturnsScreen extends StatefulWidget {
  final SessionState? sessionState;
  const ReturnsScreen({super.key, this.sessionState});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  List<ReturnItem> _returns = [];
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final returns = await DatabaseHelper.instance.getAllReturns();
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _returns = returns.reversed.toList();
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalReturnValue =
        _returns.fold(0.0, (sum, r) => sum + r.totalReturnValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المرتجعات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('${_returns.length}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C))),
                    const Text('عدد المرتجعات', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text('${totalReturnValue.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C))),
                    const Text('إجمالي المرتجعات',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _returns.isEmpty
                    ? const Center(child: Text('لا توجد مرتجعات'))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: _returns.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final ret = _returns[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade50,
                                  child: const Icon(Icons.assignment_return,
                                      color: Colors.red),
                                ),
                                title: Text(ret.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'التاريخ: ${DateFormat('yyyy-MM-dd').format(ret.date)}\nالكمية: ${ret.quantity} | السعر: ${ret.salePrice.toStringAsFixed(0)} ج.م',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${ret.totalReturnValue.toStringAsFixed(0)} ج.م',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 14),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      onPressed: () => _confirmDelete(ret),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _canCreateReturns
          ? FloatingActionButton.extended(
              onPressed: () => _showAddReturnDialog(context),
              icon: const Icon(Icons.assignment_return),
              label: const Text('إرجاع'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  bool get _canCreateReturns =>
      widget.sessionState?.hasPermission(AppPermission.canCreateReturns) ??
      false;

  void _showAddReturnDialog(BuildContext context) {
    Product? selectedProduct;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تسجيل مرتجع'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<Product>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _products;
                    }
                    return _products.where((p) =>
                        p.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()) ||
                        p.barcode.contains(textEditingValue.text));
                  },
                  displayStringForOption: (Product p) => p.name,
                  onSelected: (Product selection) {
                    selectedProduct = selection;
                    setDialogState(() {});
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'بحث المنتج',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      dateController.text =
                          DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  decoration: const InputDecoration(
                      labelText: 'الكمية المرتجعة',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                      labelText: 'سعر البيع وقت الإرجاع',
                      border: OutlineInputBorder(),
                      prefixText: 'ج.م '),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (selectedProduct == null) return;
                final qty = int.tryParse(qtyController.text) ?? 0;
                final price = double.tryParse(priceController.text) ?? 0;
                if (qty <= 0) return;

                try {
                  await DatabaseHelper.instance.insertReturn(
                    ReturnItem(
                      date: selectedDate,
                      productName: selectedProduct!.name,
                      barcode: selectedProduct!.barcode,
                      quantity: qty,
                      salePrice: price,
                      costPrice: selectedProduct!.costPrice,
                    ),
                    currentRole: widget.sessionState?.currentRole,
                  );
                  if (context.mounted) Navigator.pop(context);
                  _loadData();
                } on PermissionDeniedException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(e.message),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('تسجيل المرتجع'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ReturnItem ret) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المرتجع'),
        content: Text('هل أنت متأكد من حذف مرتجع "${ret.productName}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final canDelete = widget.sessionState
                      ?.hasPermission(AppPermission.canDeleteReturns) ??
                  false;
              if (!canDelete) {
                if (context.mounted) {
                  Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: const Text('غير مصرح'),
                            content: const Text('لا يمكنك حذف المرتجعات.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('حسناً'))
                            ],
                          ));
                }
                return;
              }

              await DatabaseHelper.instance.deleteReturn(
                ret.id!,
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
}
