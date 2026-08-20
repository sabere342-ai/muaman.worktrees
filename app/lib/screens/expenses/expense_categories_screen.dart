import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/expense_category.dart';
import '../../models/user_role.dart';
import '../../services/session_state.dart';
import '../../services/permissions.dart';

class ExpenseCategoriesScreen extends StatefulWidget {
  final SessionState? sessionState;
  const ExpenseCategoriesScreen({super.key, this.sessionState});

  @override
  State<ExpenseCategoriesScreen> createState() =>
      _ExpenseCategoriesScreenState();
}

class _ExpenseCategoriesScreenState extends State<ExpenseCategoriesScreen> {
  List<ExpenseCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  bool get _isOwner => widget.sessionState?.currentRole == UserRole.owner;

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final categories = await DatabaseHelper.instance.getAllExpenseCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصنيفات المصروفات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadCategories),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(
                  child:
                      Text('لا توجد تصنيفات', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: _categories.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: Icon(Icons.label,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(category.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: _isOwner
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () =>
                                        _showRenameDialog(category),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    onPressed: () => _confirmDelete(category),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: _isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('تصنيف جديد'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تصنيف'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'اسم التصنيف',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              try {
                await DatabaseHelper.instance.insertExpenseCategory(
                  ExpenseCategory(name: name),
                  currentRole: widget.sessionState?.currentRole,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
                _loadCategories();
              } on ArgumentError catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.message ?? 'خطأ'),
                        backgroundColor: Colors.red),
                  );
                }
              } on PermissionDeniedException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.message), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(ExpenseCategory category) {
    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل التصنيف'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'اسم التصنيف',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                return;
              }

              try {
                await DatabaseHelper.instance.renameExpenseCategory(
                  category.id!,
                  newName,
                  currentRole: widget.sessionState?.currentRole,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
                _loadCategories();
              } on ArgumentError catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.message ?? 'خطأ'),
                        backgroundColor: Colors.red),
                  );
                }
              } on PermissionDeniedException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.message), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التصنيف'),
        content: Text('هل أنت متأكد من حذف التصنيف "${category.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteExpenseCategory(
                  category.id!,
                  currentRole: widget.sessionState?.currentRole,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
                _loadCategories();
              } on StateError catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: const Text('لا يمكن الحذف'),
                            content: Text(e.message),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('حسناً'))
                            ],
                          ));
                }
              } on PermissionDeniedException catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.message), backgroundColor: Colors.red),
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
}
