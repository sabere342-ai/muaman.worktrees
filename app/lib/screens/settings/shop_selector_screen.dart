import 'package:flutter/material.dart';
import '../../services/active_shop_context.dart';
import '../../services/shop_resolver.dart';

/// Screen that allows a user to select which shop they want to access
/// when they belong to multiple shops.
class ShopSelectorScreen extends StatefulWidget {
  final ShopResolver resolver;
  final void Function(String shopId, ShopMembership membership) onSelected;
  final VoidCallback? onCancel;

  const ShopSelectorScreen({
    super.key,
    required this.resolver,
    required this.onSelected,
    this.onCancel,
  });

  @override
  State<ShopSelectorScreen> createState() => _ShopSelectorScreenState();
}

class _ShopSelectorScreenState extends State<ShopSelectorScreen> {
  List<ShopMembership> _memberships = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMemberships();
  }

  Future<void> _loadMemberships() async {
    try {
      final memberships = await widget.resolver.getAllMemberships();
      if (mounted) {
        setState(() {
          _memberships = memberships;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل المتاجر: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectShop(ShopMembership membership) async {
    // Phase J (WS1 switch lifecycle): re-validate against ACTIVE memberships
    // and swap the tenant context atomically before persisting the choice.
    // In-flight sync cycles are unaffected: queue entries execute strictly
    // under their persisted entry.shop_id.
    try {
      await ActiveShopContext.instance.switchShop(membership.shopId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تعذّر تبديل المتجر: العضوية غير مصرح بها'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }
    await widget.resolver.selectShop(membership.shopId);
    widget.onSelected(membership.shopId, membership);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اختيار المتجر'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMemberships,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_memberships.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.store_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('لا توجد متاجر مرتبطة بهذا الحساب',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _memberships.length,
      itemBuilder: (context, index) {
        final membership = _memberships[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(Icons.store,
                size: 40,
                color: membership.isOwner ? Colors.teal : Colors.blue),
            title: Text(membership.shopName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                    'الدور: ${membership.membershipRole == 'owner' ? 'مالك' : membership.membershipRole == 'employee' ? 'موظف' : 'موظف مبيعات'}',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text(
                    'الحالة: ${membership.membershipStatus == 'ACTIVE' ? 'نشط' : membership.membershipStatus}',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            trailing: const Icon(Icons.arrow_back_ios, size: 16),
            onTap: membership.isActive ? () => _selectShop(membership) : null,
          ),
        );
      },
    );
  }
}
