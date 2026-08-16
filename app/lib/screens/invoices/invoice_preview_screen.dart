import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../database/invoice_repository.dart';
import '../../invoices/invoice_delivery.dart';
import '../../invoices/invoice_document_data.dart';
import '../../services/session_state.dart';

/// Read-only preview of a persisted invoice with print / save-PDF / open-PDF
/// actions. Data is loaded through [InvoiceRepository], whose reads are gated
/// at the database layer by [AppPermission.canViewSalesHistory].
class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.invoiceId,
    this.sessionState,
  });

  final int invoiceId;
  final SessionState? sessionState;

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final _repository = InvoiceRepository();
  final _delivery = InvoiceDelivery();

  InvoiceDocumentData? _data;
  Object? _loadError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loadError = null;
      _data = null;
    });
    try {
      final data = await _repository.buildDocumentData(
        widget.invoiceId,
        currentRole: widget.sessionState?.currentRole,
      );
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('فشلت العملية: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() {
    return _run(() async {
      await _delivery.print(_data!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم إرسال الفاتورة إلى الطابعة'),
      ));
    });
  }

  Future<void> _savePdf() {
    return _run(() async {
      final path = await _delivery.savePdf(_data!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            path == null ? 'تم إلغاء الحفظ' : 'تم حفظ الفاتورة في:\n$path'),
      ));
    });
  }

  Future<void> _openPdf() {
    return _run(() async {
      await _delivery.openPdf(_data!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عرض الفاتورة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('تعذر تحميل الفاتورة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('$_loadError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    final data = _data;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildShopCard(data),
        const SizedBox(height: 12),
        _buildMetaCard(data),
        const SizedBox(height: 12),
        _buildItemsCard(data),
        const SizedBox(height: 12),
        _buildTotalsCard(data),
        const SizedBox(height: 20),
        _buildActions(),
      ],
    );
  }

  Widget _buildShopCard(InvoiceDocumentData data) {
    final profile = data.shopProfile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.shopName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (profile.ownerOrManagerName.trim().isNotEmpty)
              Text(profile.ownerOrManagerName.trim(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (profile.phone.trim().isNotEmpty)
              Text(profile.phone.trim(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (profile.address.trim().isNotEmpty)
              Text(profile.address.trim(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (data.supportPhone.isNotEmpty)
              Text('للدعم: ${data.supportPhone}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard(InvoiceDocumentData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _metaRow('رقم الفاتورة', data.invoiceNumber),
            _metaRow(
                'التاريخ', DateFormat('yyyy/MM/dd HH:mm').format(data.date)),
            _metaRow('العميل', data.customerName),
            _metaRow('طريقة الدفع', paymentMethodLabel(data.paymentMethod)),
            _metaRow('عدد الأصناف', '${data.totalItems}'),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(InvoiceDocumentData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المنتجات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            for (final (index, line) in data.lines.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}. ',
                        style: const TextStyle(fontSize: 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.productName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(line.barcode,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMoney(line.lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${line.quantity} × ${formatMoney(line.unitPrice)}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(InvoiceDocumentData data) {
    return Card(
      color: const Color(0xFF0D47A1).withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('إجمالي الفاتورة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Text(
              formatMoney(data.totalAmount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0D47A1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _print,
            icon: const Icon(Icons.print),
            label: const Text('طباعة'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _savePdf,
            icon: const Icon(Icons.save_alt),
            label: const Text('حفظ PDF'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _openPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('فتح PDF'),
          ),
        ),
      ],
    );
  }
}
