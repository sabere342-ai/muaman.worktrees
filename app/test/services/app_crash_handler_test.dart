import 'package:flutter_test/flutter_test.dart';
import 'package:muaman_store/services/app_crash_handler.dart';

void main() {
  group('AppCrashHandler no-secret logging (WS-8)', () {
    test('placeholder anon key and URL are redacted from messages', () {
      expect(
        AppCrashHandler.redact('failed with your-anon-key'),
        isNot(contains('your-anon-key')),
      );
      expect(
        AppCrashHandler.redact(
            'could not reach https://your-project-ref.supabase.co'),
        isNot(contains('your-project-ref.supabase.co')),
      );
    });

    test('non-secret operational text passes through unmodified', () {
      const msg = 'sale write failed for invoice SALE-123 at shop 7';
      expect(AppCrashHandler.redact(msg), msg);
    });

    test('redact replaces secrets with a consistent marker', () {
      expect(
        AppCrashHandler.redact('pre your-anon-key post'),
        contains('[REDACTED]'),
      );
    });

    test('report runs without throwing on messages and stacks', () {
      AppCrashHandler.report('sale write failed', StackTrace.current);
      AppCrashHandler.report('zone error');
    });
  });
}
