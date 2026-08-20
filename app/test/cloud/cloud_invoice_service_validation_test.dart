import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:muaman_store/errors/cloud_data_exception.dart';
import 'package:muaman_store/repositories/cloud/cloud_sales_repository.dart';
import 'package:muaman_store/services/cloud/cloud_sales_service.dart';

void main() {
  group('CloudSalesService invoice validation', () {
    late CloudSalesService service;

    setUp(() {
      service = CloudSalesService(
          repository: CloudSalesRepository(
              client: SupabaseClient('http://dummy', 'dummy')));
    });

    test('rejects empty customer name', () {
      expect(
        () => service.createInvoiceWithItems('shop',
            customerName: '',
            paymentMethod: 'cash',
            date: DateTime.now(),
            saleItems: [
              {'barcode': 'BC', 'quantity': 1, 'sale_price': 10}
            ]),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects empty payment method', () {
      expect(
        () => service.createInvoiceWithItems('shop',
            customerName: 'Customer',
            paymentMethod: '',
            date: DateTime.now(),
            saleItems: [
              {'barcode': 'BC', 'quantity': 1, 'sale_price': 10}
            ]),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects empty sale items', () {
      expect(
        () => service.createInvoiceWithItems('shop',
            customerName: 'Customer',
            paymentMethod: 'cash',
            date: DateTime.now(),
            saleItems: []),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects zero return quantity', () {
      expect(
        () => service.createReturnWithStock('shop',
            barcode: 'BC', quantity: 0, salePrice: 10, date: DateTime.now()),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });

    test('rejects negative return sale price', () {
      expect(
        () => service.createReturnWithStock('shop',
            barcode: 'BC', quantity: 1, salePrice: -1, date: DateTime.now()),
        throwsA(isA<CloudDataException>()
            .having((e) => e.type, 'type', CloudDataErrorType.invalidInput)),
      );
    });
  });
}
