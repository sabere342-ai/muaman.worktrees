import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../models/invoice.dart';
import '../../services/app_settings.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _searchController = TextEditingController();
  final _customerController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isLoading = true;
  bool _isSaving = false;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final List<_CartItem> _cartItems = [];
  String _buttonStyle = 'filled';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await AppSettings.initializeDefaults();
    _buttonStyle = await AppSettings.getButtonStyle();
    final defaultCustomer = await AppSettings.getDefaultCustomerName();
    _customerController.text = defaultCustomer;
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = products.where((p) => p.currentQuantity > 0).toList();
      _filteredProducts = _products;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.barcode.contains(query);
      }).toList();
    });
  }

  void _addProductToCart(Product product) {
    final existing = _cartItems.where((item) => item.product.id == product.id);
    if (existing.isNotEmpty) {
      final item = existing.first;
      if (item.quantity < product.currentQuantity) {
        setState(() => item.quantity += 1);
      }
      return;
    }

    setState(() {
      _cartItems.add(_CartItem(
        product: product,
        quantity: 1,
        salePrice: product.costPrice > 0 ? product.costPrice : 0,
      ));
    });
  }

  void _removeCartItem(_CartItem item) {
    setState(() {
      _cartItems.remove(item);
    });
  }

  void _updateCartItemQuantity(_CartItem item, int quantity) {
    setState(() {
      item.quantity = quantity.clamp(1, item.product.currentQuantity);
    });
  }

  void _updateCartItemPrice(_CartItem item, String value) {
    final price = double.tryParse(value) ?? 0;
    setState(() {
      item.salePrice = price;
    });
  }

  double get _invoiceTotal {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + item.salePrice * item.quantity,
    );
  }

  int get _invoiceQuantity {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  ButtonStyle get _actionStyle {
    if (_buttonStyle == 'outlined') {
      return OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0D47A1),
        side: const BorderSide(color: Color(0xFF0D47A1)),
      );
    }
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0D47A1),
      foregroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء فاتورة جديدة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _filterProducts,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن صنف بالاسم أو الباركود',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('منتجات المخزن',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _filteredProducts.isEmpty
                                    ? const Center(
                                        child: Text('لا توجد منتجات متاحة'))
                                    : GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 2.4,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                        itemCount: _filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              _filteredProducts[index];
                                          return GestureDetector(
                                            onTap: () =>
                                                _addProductToCart(product),
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.all(10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(product.name,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14)),
                                                    const SizedBox(height: 4),
                                                    Text('باركود: ${product.barcode}',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey)),
                                                    const Spacer(),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'الكمية: ${product.currentQuantity}',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        const Icon(
                                                          Icons.add_circle,
                                                          color: Color(0xFF0D47A1),
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('سلة الفاتورة',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _cartItems.isEmpty
                                    ? const Center(
                                        child: Text(
                                            'اضغط على المنتج لإضافته إلى الفاتورة'))
                                    : ListView.separated(
                                        itemCount: _cartItems.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final item = _cartItems[index];
                                          return Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.product.name,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight.bold),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          size: 18,
                                                        ),
                                                        onPressed: () =>
                                                            _removeCartItem(item),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text('باركود: ${item.product.barcode}',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey)),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            const Text('الكمية:'),
                                                            const SizedBox(width: 6),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.remove_circle_outline),
                                                              onPressed: item.quantity > 1
                                                                  ? () => _updateCartItemQuantity(item, item.quantity - 1)
                                                                  : null,
                                                            ),
                                                            Text('${item.quantity}'),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.add_circle_outline),
                                                              onPressed: item.quantity <
                                                                      item.product.currentQuantity
                                                                  ? () => _updateCartItemQuantity(item, item.quantity + 1)
                                                                  : null,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: TextField(
                                                          keyboardType:
                                                              TextInputType.number,
                                                          decoration:
                                                              const InputDecoration(
                                                            labelText:
                                                                'سعر البيع',
                                                            border:
                                                                OutlineInputBorder(),
                                                            prefixText: 'ج.م ',
                                                          ),
                                                          controller:
                                                              item.priceController,
                                                          onChanged: (value) =>
                                                              _updateCartItemPrice(
                                                                  item, value),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'إجمالي العنصر: ${(item.salePrice * item.quantity).toStringAsFixed(0)} ج.م',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _customerController,
                                decoration: const InputDecoration(
                                  labelText: 'اسم العميل',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _paymentMethod,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'cash',
                                    child: Text('نقدي'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'visa',
                                    child: Text('فيزا'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'insta_cash',
                                    child: Text('إنستا كاش'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _paymentMethod = value;
                                    });
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'طريقة الدفع',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'إجمالي الفاتورة: ${_invoiceTotal.toStringAsFixed(0)} ج.م',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'عدد المنتجات: $_invoiceQuantity',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _isSaving
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : SizedBox(
                                      width: double.infinity,
                                      child: _buttonStyle == 'outlined'
                                          ? OutlinedButton(
                                              onPressed: _saveInvoice,
                                              style: _actionStyle,
                                              child: const Text('حفظ الفاتورة'),
                                            )
                                          : ElevatedButton(
                                              onPressed: _saveInvoice,
                                              style: _actionStyle,
                                              child: const Text('حفظ الفاتورة'),
                                            ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _saveInvoice() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة منتج واحد على الأقل إلى الفاتورة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final customerName = _customerController.text.trim();
    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اسم العميل مطلوب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final invoice = Invoice(
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      customerName: customerName,
      paymentMethod: _paymentMethod,
      totalAmount: _invoiceTotal,
      totalItems: _invoiceQuantity,
    );

    final items = _cartItems
        .map((item) => Sale(
              date: DateTime.now(),
              productName: item.product.name,
              barcode: item.product.barcode,
              quantity: item.quantity,
              salePrice: item.salePrice,
              costPrice: item.product.costPrice,
            ))
        .toList();

    setState(() => _isSaving = true);
    try {
      await DatabaseHelper.instance.insertInvoiceWithItems(invoice, items);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ الفاتورة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    for (final item in _cartItems) {
      item.priceController.dispose();
    }
    super.dispose();
  }
}

class _CartItem {
  final Product product;
  int quantity;
  double salePrice;
  final TextEditingController priceController;

  _CartItem({
    required this.product,
    required this.quantity,
    required this.salePrice,
  }) : priceController = TextEditingController(text: salePrice.toStringAsFixed(0));
}
