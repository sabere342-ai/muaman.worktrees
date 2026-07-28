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
        title: const Text('الجرد', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'أدخل الكمية الفعلية لكل صنف لعملية الجرد',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
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
    final actualController = TextEditingController(text: product.currentQuantity.toString());

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
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            IconButton(
              icon: const Icon(Icons.save, color: Color(0xFF4A148C)),
              onPressed: () async {
                final actual = int.tryParse(actualController.text) ?? 0;
                await DatabaseHelper.instance.saveInventoryCount(product.id!, actual, '');

                if (context.mounted) {
                  final diff = actual - product.currentQuantity;
                  String msg;
                  if (diff > 0) {
                    msg = 'زيادة +$diff - تم تسجيل التسوية';
                  } else if (diff < 0) {
                    msg = 'عجز $diff - تم تسجيل التسوية';
                  } else {
                    msg = 'مطابق';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name}: $msg'),
                      backgroundColor: diff == 0 ? Colors.green : Colors.orange,
                    ),
                  );
                  _loadProducts();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
