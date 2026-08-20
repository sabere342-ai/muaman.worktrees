import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_invoice.dart';
import '../../models/cloud/cloud_return.dart';
import '../../models/cloud/cloud_sale.dart';
import '../../repositories/cloud/cloud_sales_repository.dart';

class CloudSalesService {
  final CloudSalesRepository _repository;

  CloudSalesService({CloudSalesRepository? repository})
      : _repository = repository ?? CloudSalesRepository();

  Future<List<CloudSale>> getSales(String shopId) =>
      _repository.getSales(shopId);

  Future<CloudSale> createSaleWithStock(
    String shopId, {
    required String barcode,
    required int quantity,
    required double salePrice,
    required DateTime date,
    String? invoiceId,
  }) {
    if (quantity <= 0) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Must be > 0',
      );
    }
    if (salePrice <= 0) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Must be > 0',
      );
    }
    if (barcode.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Barcode is required',
      );
    }
    return _repository.createSaleWithStock(
      shopId,
      barcode: barcode,
      quantity: quantity,
      salePrice: salePrice,
      date: date,
      invoiceId: invoiceId,
    );
  }

  Future<bool> deleteSaleWithRevert(String shopId, String saleId) =>
      _repository.deleteSaleWithRevert(shopId, saleId);

  Future<CloudReturn> createReturnWithStock(
    String shopId, {
    required String barcode,
    required int quantity,
    required double salePrice,
    required DateTime date,
  }) {
    if (quantity <= 0) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Must be > 0',
      );
    }
    if (salePrice <= 0) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Must be > 0',
      );
    }
    return _repository.createReturnWithStock(
      shopId,
      barcode: barcode,
      quantity: quantity,
      salePrice: salePrice,
      date: date,
    );
  }

  Future<bool> deleteReturnWithRevert(String shopId, String returnId) =>
      _repository.deleteReturnWithRevert(shopId, returnId);

  Future<CloudInvoice> createInvoiceWithItems(
    String shopId, {
    required String customerName,
    String? customerId,
    required String paymentMethod,
    required DateTime date,
    required List<Map<String, dynamic>> saleItems,
  }) {
    if (customerName.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Customer name is required',
      );
    }
    if (paymentMethod.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Payment method is required',
      );
    }
    if (saleItems.isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'At least one item required',
      );
    }
    return _repository.createInvoiceWithItems(
      shopId,
      customerName: customerName,
      customerId: customerId,
      paymentMethod: paymentMethod,
      date: date,
      saleItems: saleItems,
    );
  }

  Future<List<CloudInvoice>> getInvoices(String shopId) =>
      _repository.getInvoices(shopId);

  Future<List<CloudReturn>> getReturns(String shopId) =>
      _repository.getReturns(shopId);
}
