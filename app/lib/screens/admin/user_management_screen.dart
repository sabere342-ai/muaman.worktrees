import 'package:flutter/material.dart';
import '../../database/user_repository.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/permissions.dart';
import '../../services/session_state.dart';
import '../settings/invite_employee_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final SessionState sessionState;

  const UserManagementScreen({super.key, required this.sessionState});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _repo = UserRepository();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _repo.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  String _roleDisplay(String role) {
    try {
      return UserRole.fromString(role).displayName;
    } catch (_) {
      return role;
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    UserRole selectedRole = UserRole.employee;
    bool isActive = true;
    bool isSaving = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          final nameFocus = FocusNode();
          final usernameFocus = FocusNode();
          final passwordFocus = FocusNode();
          final confirmFocus = FocusNode();

          Future<void> submitCreate() async {
            setDState(() {
              isSaving = true;
              error = null;
            });
            try {
              if (nameCtrl.text.trim().isEmpty) {
                throw ArgumentError('الاسم مطلوب');
              }
              if (usernameCtrl.text.trim().isEmpty) {
                throw ArgumentError('اسم المستخدم مطلوب');
              }
              if (passwordCtrl.text.isEmpty) {
                throw ArgumentError('كلمة المرور مطلوبة');
              }
              if (passwordCtrl.text.length < 6) {
                throw ArgumentError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
              }
              if (passwordCtrl.text != confirmCtrl.text) {
                throw ArgumentError('كلمة المرور وتأكيدها غير متطابقين');
              }

              await _repo.createUser(
                displayName: nameCtrl.text,
                username: usernameCtrl.text,
                password: passwordCtrl.text,
                role: selectedRole,
                isActive: isActive,
                currentRole: widget.sessionState.currentRole,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _loadUsers();
            } on ArgumentError catch (e) {
              setDState(() {
                error = e.message;
                isSaving = false;
              });
            } on DuplicateUsernameException {
              setDState(() {
                error = 'اسم المستخدم موجود بالفعل';
                isSaving = false;
              });
            } catch (e) {
              setDState(() {
                error = 'حدث خطأ: $e';
                isSaving = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('إنشاء مستخدم جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(error!,
                          style: TextStyle(
                              color: Colors.red.shade800, fontSize: 13)),
                    ),
                  TextField(
                      controller: nameCtrl,
                      focusNode: nameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(usernameFocus),
                      decoration: const InputDecoration(
                          labelText: 'الاسم', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: usernameCtrl,
                      focusNode: usernameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(passwordFocus),
                      decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: passwordCtrl,
                      focusNode: passwordFocus,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(confirmFocus),
                      decoration: const InputDecoration(
                          labelText: 'كلمة المرور',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: confirmCtrl,
                      focusNode: confirmFocus,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!isSaving) submitCreate();
                      },
                      decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                        labelText: 'الدور', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: UserRole.owner, child: Text('مالك')),
                      DropdownMenuItem(
                          value: UserRole.employee, child: Text('موظف')),
                      DropdownMenuItem(
                          value: UserRole.salesOnly,
                          child: Text('موظف مبيعات فقط')),
                    ],
                    onChanged: (v) => setDState(() => selectedRole = v!),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('حساب نشط'),
                    value: isActive,
                    onChanged: (v) => setDState(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (isSaving) const LinearProgressIndicator(),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        await submitCreate();
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('إنشاء'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(User user) async {
    final nameCtrl = TextEditingController(text: user.displayName);
    final usernameCtrl = TextEditingController(text: user.username);
    UserRole selectedRole = user.role;
    bool isActive = user.isActive;
    bool isSaving = false;
    String? error;
    final currentUserId = widget.sessionState.currentUser?.id;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('تعديل مستخدم'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(error!,
                        style: TextStyle(
                            color: Colors.red.shade800, fontSize: 13)),
                  ),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'الاسم', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                      labelText: 'الدور', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: UserRole.owner, child: Text('مالك')),
                    DropdownMenuItem(
                        value: UserRole.employee, child: Text('موظف')),
                    DropdownMenuItem(
                        value: UserRole.salesOnly,
                        child: Text('موظف مبيعات فقط')),
                  ],
                  onChanged: (v) => setDState(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(
                      currentUserId == user.id ? 'الحساب الحالي' : 'حساب نشط'),
                  value: isActive,
                  onChanged: currentUserId == user.id
                      ? null
                      : (v) => setDState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (isSaving) const LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDState(() {
                        isSaving = true;
                        error = null;
                      });
                      try {
                        if (nameCtrl.text.trim().isEmpty) {
                          throw ArgumentError('الاسم مطلوب');
                        }
                        if (usernameCtrl.text.trim().isEmpty) {
                          throw ArgumentError('اسم المستخدم مطلوب');
                        }

                        await _repo.updateUser(
                          id: user.id!,
                          displayName: nameCtrl.text,
                          username: usernameCtrl.text,
                          role: selectedRole,
                          isActive: isActive,
                          currentRole: widget.sessionState.currentRole,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadUsers();
                        if (currentUserId == user.id) {
                          final updated = await _repo.getUserById(user.id!);
                          if (updated != null) {
                            widget.sessionState.updateCurrentUser(updated);
                          }
                        }
                      } on CannotDisableCurrentUserException {
                        setDState(() {
                          error = 'لا يمكن تعطيل حسابك الحالي';
                          isSaving = false;
                        });
                      } on LastActiveOwnerException catch (e) {
                        setDState(() {
                          error = e.message;
                          isSaving = false;
                        });
                      } on DuplicateUsernameException {
                        setDState(() {
                          error = 'اسم المستخدم موجود بالفعل';
                          isSaving = false;
                        });
                      } on ArgumentError catch (e) {
                        setDState(() {
                          error = e.message;
                          isSaving = false;
                        });
                      } catch (e) {
                        setDState(() {
                          error = 'حدث خطأ: $e';
                          isSaving = false;
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetPasswordDialog(User user) async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isSaving = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text('إعادة تعيين كلمة المرور: ${user.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(error!,
                        style: TextStyle(
                            color: Colors.red.shade800, fontSize: 13)),
                  ),
                TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'كلمة المرور الجديدة',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        border: OutlineInputBorder())),
                if (isSaving) const LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDState(() {
                        isSaving = true;
                        error = null;
                      });
                      try {
                        if (passwordCtrl.text.isEmpty) {
                          throw ArgumentError('كلمة المرور مطلوبة');
                        }
                        if (passwordCtrl.text.length < 6) {
                          throw ArgumentError(
                              'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
                        }
                        if (passwordCtrl.text != confirmCtrl.text) {
                          throw ArgumentError(
                              'كلمة المرور وتأكيدها غير متطابقين');
                        }

                        await _repo.resetPassword(
                            id: user.id!,
                            newPassword: passwordCtrl.text,
                            currentRole: widget.sessionState.currentRole);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'تم إعادة تعيين كلمة المرور بنجاح')));
                        }
                      } on ArgumentError catch (e) {
                        setDState(() {
                          error = e.message;
                          isSaving = false;
                        });
                      } catch (e) {
                        setDState(() {
                          error = 'حدث خطأ: $e';
                          isSaving = false;
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('إعادة تعيين'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.sessionState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        // Phase L (D-L2): owner entry point to the cloud invitation flow
        // (invite-employee Edge Function). Permission-gated by
        // admin.users.manage; UI visibility is convenience only.
        actions: [
          if (widget.sessionState.hasPermission(AppPermission.canManageUsers))
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              tooltip: 'دعوة موظف',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: InviteEmployeeScreen(
                          sessionState: widget.sessionState),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('مستخدم جديد'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('لا يوجد مستخدمون'))
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isSelf = currentUser?.id == user.id;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: user.role == UserRole.owner
                                ? Colors.amber.shade100
                                : Colors.blue.shade50,
                            child: Icon(
                              user.role == UserRole.owner
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: user.role == UserRole.owner
                                  ? Colors.amber.shade800
                                  : Colors.blue,
                            ),
                          ),
                          title: Text(user.displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '@${user.username} | ${_roleDisplay(user.role.value)}${user.isActive ? '' : ' | معطل'}${isSelf ? ' | أنت' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showEditDialog(user);
                              } else if (value == 'resetPassword') {
                                _showResetPasswordDialog(user);
                              } else if (value == 'toggleActive') {
                                try {
                                  await _repo.setUserActiveStatus(
                                    id: user.id!,
                                    isActive: !user.isActive,
                                    currentUserId: currentUser?.id,
                                    currentRole:
                                        widget.sessionState.currentRole,
                                  );
                                  _loadUsers();
                                } on CannotDisableCurrentUserException {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'لا يمكن تعطيل حسابك الحالي')));
                                } on LastActiveOwnerException catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.message)));
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')));
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('تعديل')
                                  ])),
                              const PopupMenuItem(
                                  value: 'resetPassword',
                                  child: Row(children: [
                                    Icon(Icons.lock_reset, size: 18),
                                    SizedBox(width: 8),
                                    Text('إعادة تعيين كلمة المرور')
                                  ])),
                              PopupMenuItem(
                                value: 'toggleActive',
                                child: Row(
                                  children: [
                                    Icon(
                                        user.isActive
                                            ? Icons.block
                                            : Icons.check_circle,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text(user.isActive ? 'تعطيل' : 'تفعيل'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
