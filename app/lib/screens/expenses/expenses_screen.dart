import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/expense.dart';

import '../../services/session_state.dart';
import '../../services/permissions.dart';

class ExpensesScreen extends StatefulWidget {
  final SessionState? sessionState;
  const ExpensesScreen({super.key, this.sessionState});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    setState(() {
      _expenses = expenses.reversed.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadExpenses),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('${_expenses.length}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100))),
                    const Text('عدد المصروفات', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text('${totalExpenses.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100))),
                    const Text('إجمالي المصروفات',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? const Center(child: Text('لا توجد مصروفات'))
                    : RefreshIndicator(
                        onRefresh: _loadExpenses,
                        child: ListView.builder(
                          itemCount: _expenses.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade50,
                                  child: const Icon(Icons.money_off,
                                      color: Colors.orange),
                                ),
                                title: Text(expense.description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    'التاريخ: ${DateFormat('yyyy-MM-dd').format(expense.date)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${expense.amount.toStringAsFixed(0)} ج.م',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                          fontSize: 14),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      onPressed: () => _confirmDelete(expense),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('مصروف جديد'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مصروف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'البيان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'القيمة',
                  border: OutlineInputBorder(),
                  prefixText: 'ج.م ',
                ),
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
              if (descController.text.isEmpty ||
                  amountController.text.isEmpty) {
                return;
              }
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) {
                return;
              }

              await DatabaseHelper.instance.insertExpense(
                Expense(
                  date: selectedDate,
                  description: descController.text,
                  amount: amount,
                ),
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
              _loadExpenses();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المصروف'),
        content: Text('هل أنت متأكد من حذف "${expense.description}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final canDelete = widget.sessionState
                      ?.hasPermission(AppPermission.canManageUsers) ??
                  false;
              if (!canDelete) {
                if (context.mounted) {
                  Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: const Text('غير مصرح'),
                            content: const Text(
                                'لا يمكنك حذف العمليات. هذه الخاصية متاحة للمالك فقط.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('حسناً'))
                            ],
                          ));
                }
                return;
              }

              await DatabaseHelper.instance.deleteExpense(
                expense.id!,
                currentRole: widget.sessionState?.currentRole,
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
              _loadExpenses();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
