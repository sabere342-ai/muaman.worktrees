import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/product.dart';

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;
  int? _savingProductId;

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
            const Text('الجرد', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.purple.shade50,
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
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
            child: const Text(
              'أدخل الكمية الفعلية لكل صنف لعملية الجرد',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      itemCount: _filteredProducts.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _buildCountCard(product);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(Product product) {
    final actualController =
        TextEditingController(text: product.currentQuantity.toString());
    final isSaving = _savingProductId == product.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'النظام: ${product.currentQuantity} | التكلفة: ${product.costPrice.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: actualController,
                decoration: const InputDecoration(
                  labelText: 'العد الفعلي',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.save, color: Color(0xFF4A148C)),
                    onPressed: () => _saveCount(product, actualController),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCount(
      Product product, TextEditingController controller) async {
    final actual = int.tryParse(controller.text);
    if (actual == null) {
      _showMessage('الرجاء إدخال رقم صحيح', Colors.red);
      return;
    }

    setState(() => _savingProductId = product.id);

    try {
      final diff = await DatabaseHelper.instance
          .saveInventoryCount(product.id!, actual, '');

      if (!mounted) return;

      String msg;
      if (diff > 0) {
        msg = 'زيادة +$diff - تم تسجيل التسوية';
      } else if (diff < 0) {
        msg = 'عجز $diff - تم تسجيل التسوية';
      } else {
        msg = 'مطابق';
      }
      _showMessage(
          '${product.name}: $msg', diff == 0 ? Colors.green : Colors.orange);
      _loadProducts();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      _showMessage(e.message, Colors.red);
    } on StateError catch (e) {
      if (!mounted) return;
      _showMessage(e.message, Colors.red);
    } catch (e) {
      if (!mounted) return;
      _showMessage('حدث خطأ: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _savingProductId = null);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
