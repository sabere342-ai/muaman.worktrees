import '../invoices/invoice_document_data.dart';
import '../models/invoice.dart';
import '../models/sale.dart';
import '../models/shop_profile.dart';
import '../models/user_role.dart';
import '../services/app_settings.dart';
import '../services/shop_profile_repository.dart';
import 'database_helper.dart';

/// Read-side access to invoices for preview/print/PDF/export.
///
/// Every read goes through [DatabaseHelper]'s sales-history gate
/// ([AppPermission.canViewSalesHistory]) at the data layer, so a reprint can
/// never leak history to an unauthorized role even if a screen is reached
/// directly.
class InvoiceRepository {
  InvoiceRepository({
    DatabaseHelper? database,
    ShopProfileRepository? profileRepository,
  })  : _database = database ?? DatabaseHelper.instance,
        _profileRepository = profileRepository ?? ShopProfileRepository();

  final DatabaseHelper _database;
  final ShopProfileRepository _profileRepository;

  Future<Invoice?> getInvoiceById(int id, {UserRole? currentRole}) =>
      _database.getInvoiceById(id, currentRole: currentRole);

  Future<List<Sale>> getInvoiceItems(int invoiceId, {UserRole? currentRole}) =>
      _database.getSalesByInvoiceId(invoiceId, currentRole: currentRole);

  /// Assembles the read model for the PDF/preview from the persisted invoice,
  /// its sale rows and the current shop profile branding. The PDF total is the
  /// persisted [Invoice.totalAmount] — never recomputed with different logic.
  Future<InvoiceDocumentData> buildDocumentData(int invoiceId,
      {UserRole? currentRole}) async {
    final invoice = await getInvoiceById(invoiceId, currentRole: currentRole);
    if (invoice == null) {
      throw StateError('الفاتورة غير موجودة: $invoiceId');
    }
    final items = await getInvoiceItems(invoiceId, currentRole: currentRole);
    final profile = await _loadProfile();
    final supportPhone = await AppSettings.getSupportPhone();
    final invoiceTitle = await AppSettings.getInvoiceTitle();
    final invoiceFooterText = await AppSettings.getInvoiceFooterText();
    final itechAttributionText = await AppSettings.getItechAttributionText();
    return InvoiceDocumentData(
      invoiceNumber: invoice.invoiceNumber,
      date: invoice.date,
      customerName: invoice.customerName,
      paymentMethod: invoice.paymentMethod,
      totalAmount: invoice.totalAmount,
      totalItems: invoice.totalItems,
      shopProfile: profile,
      lines: [
        for (final item in items)
          InvoiceLineData(
            barcode: item.barcode,
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.salePrice,
          ),
      ],
      supportPhone: supportPhone,
      invoiceTitle: invoiceTitle,
      invoiceFooterText: invoiceFooterText,
      itechAttributionText: itechAttributionText,
    );
  }

  Future<ShopProfile> _loadProfile() => _profileRepository.load();
}
