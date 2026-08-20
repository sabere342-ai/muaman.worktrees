import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_product.dart';
import '../../repositories/cloud/cloud_product_repository.dart';

class CloudProductService {
  final CloudProductRepository _repository;

  CloudProductService({CloudProductRepository? repository})
      : _repository = repository ?? CloudProductRepository();

  Future<List<CloudProduct>> getProducts(String shopId) =>
      _repository.getProducts(shopId);

  Future<CloudProduct> getProduct(String shopId, String productId) =>
      _repository.getProduct(shopId, productId);

  Future<CloudProduct> createProduct(
    String shopId, {
    required String name,
    required String barcode,
    int openingQuantity = 0,
    double costPrice = 0,
  }) {
    if (name.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Product name is required',
      );
    }
    if (barcode.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Barcode is required',
      );
    }
    if (openingQuantity < 0) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Cannot be negative',
      );
    }
    if (costPrice < 0) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Cost price must be >= 0',
      );
    }
    return _repository.createProduct(
      shopId,
      name: name,
      barcode: barcode,
      openingQuantity: openingQuantity,
      costPrice: costPrice,
    );
  }

  Future<bool> updateProduct(
    String shopId,
    String productId, {
    String? name,
    String? barcode,
    int? openingQuantity,
    double? costPrice,
  }) {
    if (name != null && name.trim().isEmpty) {
      throw CloudDataException(
        type: CloudDataErrorType.invalidInput,
        message: 'Product name is required',
      );
    }
    return _repository.updateProduct(
      shopId,
      productId,
      name: name,
      barcode: barcode,
      openingQuantity: openingQuantity,
      costPrice: costPrice,
    );
  }

  Future<bool> deleteProduct(String shopId, String productId) =>
      _repository.deleteProduct(shopId, productId);
}
