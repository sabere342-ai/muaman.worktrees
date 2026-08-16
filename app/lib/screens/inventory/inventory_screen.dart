import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/product.dart';

import '../../services/session_state.dart';
import '../../services/permissions.dart';

class InventoryScreen extends StatefulWidget {
  final SessionState? sessionState;
  const InventoryScreen({super.key, this.sessionState});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = products;
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.barcode.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('المخزن', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1A237E).withOpacity(0.05),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الباركود...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  'عدد الأصناف: ${_filteredProducts.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'إجمالي المخزون: ${_filteredProducts.fold(0, (sum, p) => sum + p.currentQuantity)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A237E)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('لا توجد أصناف'))
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          itemCount: _filteredProducts.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _canEditProducts
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة صنف'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  bool get _canEditProducts =>
      widget.sessionState?.hasPermission(AppPermission.canEditProducts) ??
      false;

  bool get _canDeleteProducts =>
      widget.sessionState?.hasPermission(AppPermission.canDeleteProducts) ??
      false;

  Widget _buildProductCard(Product product) {
    final isLowStock =
        product.currentQuantity <= 2 && product.currentQuantity >= 0;
    final isOut = product.currentQuantity <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOut
              ? Colors.red.shade100
              : isLowStock
                  ? Colors.orange.shade100
                  : Colors.green.shade100,
          child: Icon(
            isOut
                ? Icons.remove_circle_outline
                : isLowStock
                    ? Icons.warning_amber
                    : Icons.check_circle_outline,
            color: isOut
                ? Colors.red
                : isLowStock
                    ? Colors.orange
                    : Colors.green,
          ),
        ),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'باركود: ${product.barcode}\nالكمية: ${product.currentQuantity}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (_canEditProducts)
              const PopupMenuItem(value: 'edit', child: Text('تعديل')),
            if (_canDeleteProducts)
              const PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(context, product: product);
            } else if (value == 'delete') {
              _confirmDelete(product);
            }
          },
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final costController =
        TextEditingController(text: product?.costPrice.toString() ?? '');
    final openingQtyController =
        TextEditingController(text: product?.openingQuantity.toString() ?? '0');
    final isEditing = product != null;

    showDialog(
      context: context,
      builder: (context) {
        final nameFocus = FocusNode();
        final costFocus = FocusNode();
        final qtyFocus = FocusNode();
        var isSaving = false;

        Future<void> saveProduct() async {
          if (isSaving) return;
          final name = nameController.text.trim();
          if (name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('يجب إدخال اسم المنتج'),
                  backgroundColor: Colors.red),
            );
            return;
          }
          final costPrice = double.tryParse(costController.text) ?? 0;
          if (costPrice <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('يجب أن تكون تكلفة الصنف أكبر من صفر'),
                  backgroundColor: Colors.red),
            );
            return;
          }
          final openingQty = int.tryParse(openingQtyController.text) ?? 0;

          isSaving = true;
          try {
            if (isEditing) {
              await DatabaseHelper.instance.updateProduct(
                product.copyWith(
                  name: name,
                  costPrice: costPrice,
                ),
              );
            } else {
              final barcode = await DatabaseHelper.instance.generateBarcode();
              await DatabaseHelper.instance.insertProduct(
                Product(
                  name: name,
                  barcode: barcode,
                  openingQuantity: openingQty,
                  currentQuantity: openingQty,
                  costPrice: costPrice,
                  totalInventoryCost: openingQty * costPrice,
                ),
              );
            }
            if (context.mounted) Navigator.pop(context);
            _loadProducts();
          } on ArgumentError catch (e) {
            isSaving = false;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return AlertDialog(
          title: Text(isEditing ? 'تعديل الصنف' : 'إضافة صنف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  focusNode: nameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(costFocus),
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  focusNode: costFocus,
                  textInputAction:
                      isEditing ? TextInputAction.done : TextInputAction.next,
                  onSubmitted: (_) {
                    if (isEditing) {
                      saveProduct();
                    } else {
                      FocusScope.of(context).requestFocus(qtyFocus);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'سعر التكلفة',
                    border: OutlineInputBorder(),
                    prefixText: 'ج.م ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: openingQtyController,
                    focusNode: qtyFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      saveProduct();
                    },
                    decoration: const InputDecoration(
                      labelText: 'الكمية الافتتاحية',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await saveProduct();
              },
              child: Text(isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصنف'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final canDelete = widget.sessionState
                      ?.hasPermission(AppPermission.canDeleteProducts) ??
                  false;
              if (!canDelete) {
                if (context.mounted) {
                  Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: const Text('غير مصرح'),
                            content: const Text('لا يمكنك حذف الأصناف.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('حسناً'))
                            ],
                          ));
                }
                return;
              }

              try {
                await DatabaseHelper.instance.deleteProduct(
                  product.id!,
                  currentRole: widget.sessionState?.currentRole,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
                _loadProducts();
              } on ProductDeletionException catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
