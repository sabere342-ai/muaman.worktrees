import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/session_state.dart';

/// Screen for owners to invite employees to their shop.
///
/// The actual invitation is created by the `invite-employee` Edge Function.
/// This screen calls the Edge Function with the user's JWT to perform
/// the server-side operation.
class InviteEmployeeScreen extends StatefulWidget {
  final SessionState sessionState;

  const InviteEmployeeScreen({super.key, required this.sessionState});

  @override
  State<InviteEmployeeScreen> createState() => _InviteEmployeeScreenState();
}

class _InviteEmployeeScreenState extends State<InviteEmployeeScreen> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _selectedRole = 'employee';
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _inviteEmployee() async {
    setState(() {
      _error = null;
      _success = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error = 'البريد الإلكتروني مطلوب';
        _isLoading = false;
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _error = 'البريد الإلكتروني غير صالح';
        _isLoading = false;
      });
      return;
    }

    final shopId = widget.sessionState.activeShopId;
    if (shopId == null) {
      setState(() {
        _error = 'لم يتم تحديد المتجر';
        _isLoading = false;
      });
      return;
    }

    try {
      // Call the Edge Function to create the invitation.
      // The Edge Function uses service-role to create the auth user and membership.
      final response = await Supabase.instance.client.functions.invoke(
        'invite-employee',
        body: {
          'shop_id': shopId,
          'email': email,
          'display_name': displayName.isNotEmpty ? displayName : email,
          'role': _selectedRole,
        },
      );

      if (response.status != 200) {
        final data = response.data as Map<String, dynamic>?;
        setState(() {
          _error = data?['error'] ?? 'فشل إرسال الدعوة';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _success = 'تم إرسال الدعوة بنجاح إلى $email';
        _isLoading = false;
      });
      _emailController.clear();
      _displayNameController.clear();
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دعوة موظف'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add,
                        size: 64, color: Colors.teal.shade700),
                    const SizedBox(height: 16),
                    Text('دعوة موظف جديد',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('أدخل بيانات الموظف لإرسال الدعوة',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(_error!,
                            style: TextStyle(color: Colors.red.shade800)),
                      ),
                    if (_success != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(_success!,
                            style: TextStyle(color: Colors.green.shade800)),
                      ),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم العرض (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'الدور',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'employee', child: Text('موظف')),
                        DropdownMenuItem(
                            value: 'salesOnly', child: Text('موظف مبيعات فقط')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _inviteEmployee,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('إرسال الدعوة',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
