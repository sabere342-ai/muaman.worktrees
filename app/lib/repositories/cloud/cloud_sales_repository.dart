import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/cloud_data_exception.dart';
import '../../models/cloud/cloud_invoice.dart';
import '../../models/cloud/cloud_return.dart';
import '../../models/cloud/cloud_sale.dart';

class CloudSalesRepository {
  final SupabaseClient _client;

  CloudSalesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<CloudSale>> getSales(String shopId) async {
    try {
      final data = await _client
          .from('cloud_sales')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false);
      return (data as List).map((e) => CloudSale.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudSale> createSaleWithStock(
    String shopId, {
    required String barcode,
    required int quantity,
    required double salePrice,
    required DateTime date,
    String? invoiceId,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_sale_with_stock', params: {
        'p_shop_id': shopId,
        'p_barcode': barcode,
        'p_quantity': quantity,
        'p_sale_price': salePrice,
        'p_date': date.toIso8601String(),
        'p_invoice_id': invoiceId,
      });
      final result = await _client
          .from('cloud_sales')
          .select()
          .eq('id', data as String)
          .single();
      return CloudSale.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> deleteSaleWithRevert(String shopId, String saleId) async {
    try {
      final data = await _client.rpc('delete_cloud_sale_with_revert', params: {
        'p_shop_id': shopId,
        'p_sale_id': saleId,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudReturn> createReturnWithStock(
    String shopId, {
    required String barcode,
    required int quantity,
    required double salePrice,
    required DateTime date,
  }) async {
    try {
      final data = await _client.rpc('create_cloud_return_with_stock', params: {
        'p_shop_id': shopId,
        'p_barcode': barcode,
        'p_quantity': quantity,
        'p_sale_price': salePrice,
        'p_date': date.toIso8601String(),
      });
      final result = await _client
          .from('cloud_returns')
          .select()
          .eq('id', data as String)
          .single();
      return CloudReturn.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<bool> deleteReturnWithRevert(String shopId, String returnId) async {
    try {
      final data =
          await _client.rpc('delete_cloud_return_with_revert', params: {
        'p_shop_id': shopId,
        'p_return_id': returnId,
      });
      return data as bool;
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<CloudInvoice> createInvoiceWithItems(
    String shopId, {
    required String customerName,
    String? customerId,
    required String paymentMethod,
    required DateTime date,
    required List<Map<String, dynamic>> saleItems,
  }) async {
    try {
      final data =
          await _client.rpc('create_cloud_invoice_with_items', params: {
        'p_shop_id': shopId,
        'p_customer_name': customerName,
        'p_customer_id': customerId,
        'p_payment_method': paymentMethod,
        'p_date': date.toIso8601String(),
        'p_sale_items': saleItems,
      });
      final result = await _client
          .from('cloud_invoices')
          .select()
          .eq('id', data as String)
          .single();
      return CloudInvoice.fromJson(result);
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<List<CloudInvoice>> getInvoices(String shopId) async {
    try {
      final data = await _client
          .from('cloud_invoices')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false);
      return (data as List).map((e) => CloudInvoice.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }

  Future<List<CloudReturn>> getReturns(String shopId) async {
    try {
      final data = await _client
          .from('cloud_returns')
          .select()
          .eq('shop_id', shopId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false);
      return (data as List).map((e) => CloudReturn.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw CloudDataException.fromPostgrest(e.message, null);
    }
  }
}
