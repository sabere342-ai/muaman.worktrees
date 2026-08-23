import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/user_repository.dart';
import '../../rbac/permission_sync_service.dart';
import '../../services/invitation_service.dart';

/// Screen where an invited employee accepts their invitation,
/// creates a local account, and links it to their cloud identity.
class AcceptInvitationScreen extends StatefulWidget {
  final String? initialEmail;

  const AcceptInvitationScreen({super.key, this.initialEmail});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _acceptInvitation() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error = 'البريد الإلكتروني مطلوب';
        _isLoading = false;
      });
      return;
    }
    if (password.isEmpty || password.length < 6) {
      setState(() {
        _error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        _isLoading = false;
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _error = 'كلمة المرور وتأكيدها غير متطابقين';
        _isLoading = false;
      });
      return;
    }

    try {
      // Sign in to Supabase (the account was pre-created by the Edge Function).
      final auth = Supabase.instance.client.auth;
      final response = await auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        setState(() {
          _error = 'فشل تسجيل الدخول';
          _isLoading = false;
        });
        return;
      }

      final userId = response.session!.user.id;

      // Get user's shops to find the pending invitation.
      final invitationService = InvitationService();
      final memberships = await invitationService.getActiveMemberships();

      if (memberships.isEmpty) {
        setState(() {
          _error = 'لا توجد دعوات معلقة لهذا الحساب';
          _isLoading = false;
        });
        return;
      }

      // Accept the invitation (the membership was pre-created as PENDING).
      final shopId = memberships.first['shop_id'].toString();
      final result = await invitationService.acceptInvitation(
        shopId: shopId,
        userId: userId,
      );

      if (!result.isSuccess) {
        setState(() {
          _error = result.errorMessage ?? 'فشل قبول الدعوة';
          _isLoading = false;
        });
        return;
      }

      // Phase L (D-L4): provision/match the local user CACHE row keyed by
      // the cloud identity (users.cloud_uuid). The role is mapped ONLY
      // from the cloud membership; no local password is stored for the
      // cloud-mode session. The local row is never an authorization
      // source — the server reauthorizes every RPC independently.
      final repo = UserRepository();
      final membershipRole =
          memberships.first['membership_role']?.toString() ?? 'employee';
      await repo.upsertCloudUser(
        cloudUuid: userId,
        displayName: displayName.isNotEmpty ? displayName : email,
        membershipRole: membershipRole,
      );

      // Phase L (GA9): refresh synced permissions BEFORE entering the
      // shell so the permission-driven shell reflects the accepted
      // membership immediately.
      try {
        await PermissionSyncService.instance.syncPermissions(shopId);
      } catch (_) {
        // Offline / sync failure — cached defaults apply until next login.
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول الدعوة بنجاح')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قبول الدعوة'),
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
                    Icon(Icons.mark_email_read,
                        size: 64, color: Colors.teal.shade700),
                    const SizedBox(height: 16),
                    Text('قبول الدعوة',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('أنشئ حسابك للانضمام للمتجر',
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
                        labelText: 'الاسم (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _acceptInvitation,
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
                            : const Text('قبول الدعوة',
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
