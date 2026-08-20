import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/services/cloud_auth_service.dart';

void main() {
  group('CloudAuthResult', () {
    test('1. Invalid credentials result', () {
      final result = CloudAuthResult.invalidCredentials();
      expect(result.isSuccess, false);
      expect(result.type, CloudAuthResultType.invalidCredentials);
    });

    test('2. Email already registered result', () {
      final result = CloudAuthResult.emailAlreadyRegistered();
      expect(result.isSuccess, false);
      expect(result.type, CloudAuthResultType.emailAlreadyRegistered);
    });

    test('3. Network unavailable result', () {
      final result = CloudAuthResult.networkUnavailable();
      expect(result.isSuccess, false);
      expect(result.type, CloudAuthResultType.networkUnavailable);
    });

    test('4. Unknown error result carries message', () {
      final result = CloudAuthResult.unknownError('Something went wrong');
      expect(result.isSuccess, false);
      expect(result.type, CloudAuthResultType.unknownError);
      expect(result.errorMessage, 'Something went wrong');
    });
  });

  group('CloudSignUpResult', () {
    test('1. Email already registered result', () {
      final result = CloudSignUpResult.emailAlreadyRegistered();
      expect(result.isSuccess, false);
      expect(result.type, CloudSignUpResultType.emailAlreadyRegistered);
    });

    test('2. Network unavailable result', () {
      final result = CloudSignUpResult.networkUnavailable();
      expect(result.isSuccess, false);
      expect(result.type, CloudSignUpResultType.networkUnavailable);
    });

    test('3. Unknown error result carries message', () {
      final result = CloudSignUpResult.unknownError('Failed');
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Failed');
    });
  });
}
