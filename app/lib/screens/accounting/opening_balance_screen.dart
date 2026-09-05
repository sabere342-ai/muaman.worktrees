import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../models/account.dart';
import '../../models/ledger_entry.dart';
import '../../models/user_role.dart';
import '../../services/permissions.dart';
import '../../services/session_state.dart';

/// Phase P Group D D2 (P-OD5): dedicated owner-gated opening-balance setup
/// screen (D2-07 A). Lists accounts, enters opening balances per account,
/// corrections are explicit adjustment entries (D2-05 A).
class OpeningBalanceScreen extends StatefulWidget {
  final SessionState? sessionState;

  const OpeningBalanceScreen({super.key, this.sessionState});

  @override
  State<OpeningBalanceScreen> createState() => _OpeningBalanceScreenState();
}

class _OpeningBalanceScreenState extends State<OpeningBalanceScreen> {
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  bool get _isOwner => widget.sessionState?.currentRole == UserRole.owner;

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await DatabaseHelper.instance.getAllAccounts();
    setState(() {
      _accounts = accounts;
      _isLoading = false;
    });
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    AccountType? selectedType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة حساب افتتاحي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الحساب',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع الحساب',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty || selectedType == null) return;
                try {
                  await DatabaseHelper.instance.createAccount(
                    Account(
                      shopId: widget.sessionState?.activeShopId ?? '',
                      name: name,
                      accountType: selectedType!,
                    ),
                    currentRole: widget.sessionState?.currentRole,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  _loadAccounts();
                } on ArgumentError catch (e) {
                  if (context.mounted) {
                    _showError(e.message ?? 'خطأ');
                  }
                } on PermissionDeniedException catch (e) {
                  if (context.mounted) {
                    _showError(e.message);
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

  void _showOpeningBalanceDialog(Account account) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final effectiveDateController = TextEditingController(
      text: DateTime.now().toLocal().toIso8601String().substring(0, 10),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('رصيد افتتاحي — ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'المبلغ (${account.accountType.displayName})',
                border: const OutlineInputBorder(),
                hintText: account.accountType.isAsset
                    ? 'ملكية/مدينون للمتجر'
                    : 'عليه/مستحق',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: effectiveDateController,
              decoration: const InputDecoration(
                labelText: 'تاريخ فعال',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(amountController.text.trim()) ?? -1;
              if (amount < 0) {
                _showError('المبلغ يجب أن يكون صفرًا أو أكثر');
                return;
              }
              final date = effectiveDateController.text.trim();
              if (date.isEmpty) {
                _showError('تاريخ فعال مطلوب');
                return;
              }
              try {
                await DatabaseHelper.instance.insertOpeningBalance(
                  LedgerEntry(
                    shopId: widget.sessionState?.activeShopId ?? '',
                    accountId: account.id!,
                    amount: amount,
                    effectiveDate: date,
                    entryKind: EntryKind.opening,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  ),
                  currentRole: widget.sessionState?.currentRole,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } on ArgumentError catch (e) {
                if (context.mounted) {
                  _showError(e.message ?? 'خطأ');
                }
              } on PermissionDeniedException catch (e) {
                if (context.mounted) {
                  _showError(e.message);
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرصدة الافتتاحية',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadAccounts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? const Center(
                  child: Text('لا توجد حسابات',
                      style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: _accounts.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
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
                          child: Icon(Icons.account_balance,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(account.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(account.accountType.displayName,
                            style: const TextStyle(fontSize: 12)),
                        trailing: _isOwner
                            ? IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: () =>
                                    _showOpeningBalanceDialog(account),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: _isOwner
          ? FloatingActionButton.extended(
              onPressed: _showAddAccountDialog,
              icon: const Icon(Icons.add),
              label: const Text('حساب جديد'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
