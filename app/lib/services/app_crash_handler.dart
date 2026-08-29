import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Phase P (WS-8): centralized crash/error capture with no-secret logging.
///
/// Every top-level error (zone-uncaught, Flutter framework, platform) is
/// routed through [report] so a release build never dies silently and never
/// leaks configured credentials into the console: the compiled-in Supabase
/// URL and anon key — and the placeholder defaults — are redacted from every
/// logged string.
class AppCrashHandler {
  AppCrashHandler._();

  /// Installs the framework + platform error sinks. Call after
  /// `WidgetsFlutterBinding.ensureInitialized()` and before `runApp`.
  static void install() {
    FlutterError.onError = (details) {
      report('Flutter framework error: ${details.exceptionAsString()}',
          details.stack);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      report('Platform error: $error', stack);
      return true;
    };
  }

  /// Logs [message] (and the first lines of [stack] when present) with all
  /// known secrets redacted. Never writes secrets to console, files, or logs.
  static void report(String message, [StackTrace? stack]) {
    final safe = redact(message);
    debugPrint('MuamanStore: $safe');
    if (stack != null) {
      final frames = stack.toString().split('\n').take(4).join('\n');
      debugPrint('MuamanStore stack:\n$frames');
    }
  }

  /// Replaces every configured secret (and the placeholder defaults) with
  /// `[REDACTED]`. Public so tests can verify no-secret behavior.
  static String redact(String text) {
    var out = text;
    for (final secret in _secrets) {
      if (secret.isNotEmpty) {
        out = out.replaceAll(secret, '[REDACTED]');
      }
    }
    return out;
  }

  static final List<String> _secrets = [
    AppConfig.supabaseUrl,
    AppConfig.supabaseAnonKey,
    'https://your-project-ref.supabase.co',
    'your-anon-key',
  ];
}
