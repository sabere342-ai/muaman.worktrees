import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/customer.dart';
import '../../services/session_state.dart';
import '../../services/permissions.dart';

class CustomersScreen extends StatefulWidget {
  final SessionState? sessionState;
  const CustomersScreen({super.key, this.sessionState});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  bool get _canManage =>
      widget.sessionState?.hasPermission(AppPermission.canCreateSales) ?? false;

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final allCustomers = await DatabaseHelper.instance.getAllCustomers();
    setState(() {
      _customers = allCustomers;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((c) {
        if (!_showArchived && !c.isActive) return false;
        if (query.isEmpty) return true;
        return c.name.toLowerCase().contains(query) ||
            (c.phone?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _onSearchChanged(String query) => _applyFilter();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('العملاء',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            if (_canManage)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCustomers,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'بحث بالاسم أو رقم الهاتف',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_canManage)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _showArchived,
                            onChanged: (value) {
                              setState(() => _showArchived = value ?? false);
                              _applyFilter();
                            },
                          ),
                          const Text('عرض المؤرشفين'),
                          const Spacer(),
                          Text(
                            '${_filteredCustomers.length} عميل',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _filteredCustomers.isEmpty
                        ? Center(
                            child: Text(
                              _showArchived
                                  ? 'لا يوجد عملاء'
                                  : 'لا يوجد عملاء نشطين',
                              style: const TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredCustomers.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: customer.isSystem
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                    child: Icon(Icons.person,
                                        color: customer.isSystem
                                            ? Colors.white
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(customer.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      if (customer.isSystem)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'نظامي',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      if (!customer.isActive)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.orange.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'مؤرشف',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (customer.phone != null &&
                                          customer.phone!.isNotEmpty)
                                        Text('هاتف: ${customer.phone}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      if (customer.address != null &&
                                          customer.address!.isNotEmpty)
                                        Text('العنوان: ${customer.address}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  trailing: _canManage
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              onPressed: () =>
                                                  _showEditDialog(customer),
                                            ),
                                            if (!customer.isSystem)
                                              customer.isActive
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Icons.archive,
                                                          size: 20,
                                                          color: Colors.orange),
                                                      onPressed: () =>
                                                          _confirmArchive(
                                                              customer),
                                                    )
                                                  : IconButton(
                                                      icon: const Icon(
                                                          Icons.unarchive,
                                                          size: 20,
                                                          color: Colors.green),
                                                      onPressed: () =>
                                                          _reactivate(customer),
                                                    ),
                                          ],
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: _canManage
            ? FloatingActionButton.extended(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('عميل جديد'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة عميل جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل *',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('اسم العميل مطلوب'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                try {
                  await DatabaseHelper.instance.insertCustomer(
                    Customer(
                      name: name,
                      phone: phoneController.text.trim().isNotEmpty
                          ? phoneController.text.trim()
                          : null,
                      address: addressController.text.trim().isNotEmpty
                          ? addressController.text.trim()
                          : null,
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                    ),
                    currentRole: widget.sessionState?.currentRole,
                  );
                  if (context.mounted) Navigator.pop(context);
                  await _loadCustomers();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل إضافة العميل: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final addressController =
        TextEditingController(text: customer.address ?? '');
    final notesController = TextEditingController(text: customer.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل العميل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل *',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('اسم العميل مطلوب'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                try {
                  await DatabaseHelper.instance.updateCustomer(
                    customer.copyWith(
                      name: name,
                      phone: phoneController.text.trim().isNotEmpty
                          ? phoneController.text.trim()
                          : null,
                      address: addressController.text.trim().isNotEmpty
                          ? addressController.text.trim()
                          : null,
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                    ),
                    currentRole: widget.sessionState?.currentRole,
                  );
                  if (context.mounted) Navigator.pop(context);
                  await _loadCustomers();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل تعديل العميل: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmArchive(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('أرشفة العميل'),
          content: Text('هل تريد أرشفة العميل "${customer.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await DatabaseHelper.instance.archiveCustomer(
                    customer.id!,
                    currentRole: widget.sessionState?.currentRole,
                  );
                  if (context.mounted) Navigator.pop(context);
                  await _loadCustomers();
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل أرشفة العميل: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('أرشفة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reactivate(Customer customer) async {
    try {
      await DatabaseHelper.instance.reactivateCustomer(
        customer.id!,
        currentRole: widget.sessionState?.currentRole,
      );
      await _loadCustomers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تنشيط العميل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
