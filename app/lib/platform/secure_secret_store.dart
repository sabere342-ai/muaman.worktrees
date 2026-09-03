import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Interface-first seam for sensitive local persistence (Phase K D7).
///
/// Implementations MUST back reads/writes with the platform credential
/// store (Android Keystore via the itech.app/secure_storage channel,
/// Windows DPAPI files). Plaintext or obfuscation-only persistence is forbidden for
/// production platforms; [InMemorySecureSecretStore] exists ONLY for test
/// profiles and fakes.
abstract class SecureSecretStore {
  /// Returns the stored value for [key], or null when absent.
  Future<String?> read(String key);

  /// Persists [value] under [key] in platform-protected storage.
  Future<void> write(String key, String value);

  /// Removes [key] if present.
  Future<void> delete(String key);

  /// Whether [key] currently exists.
  Future<bool> containsKey(String key);
}

/// S6-safe DPAPI-backed secret store for Windows (Governance Section N).
///
/// Unlike the historical [SecureActivationStore], this implementation:
/// - protects secrets at rest with Windows DPAPI `DataProtectionScope.CurrentUser`
///   (NEVER LocalMachine for S6 device private material);
/// - avoids writing plaintext to a temporary file: the plaintext value is
///   Base64-typed over the PowerShell stdin PIPELINE and the DPAPI-protected
///   ciphertext is returned on stdout — no private material in a command line,
///   no plaintext temp file, no XOR/obfuscation fallback, no SQLite;
/// - persists ONLY the DPAPI ciphertext (base64) to a file; the plaintext
///   enters process memory only transiently for the signing operation;
/// - fails closed on any read/decrypt/integrity failure.
///
/// It does NOT claim TPM/StrongBox/hardware non-exportability. The private
/// material may transiently enter Dart memory when signing requires it.
class WindowsDpapiSecureSecretStore implements SecureSecretStore {
  final Directory _baseDir;

  WindowsDpapiSecureSecretStore({Directory? baseDir})
      : _baseDir = baseDir ??
            Directory(
              _defaultS6Dir(),
            );

  static String _defaultS6Dir() {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (localAppData.isNotEmpty) {
        return p.join(localAppData, 'I-TECH', 's6-device');
      }
    }
    return p.join(Directory.current.path, '.itech', 's6-device');
  }

  String _pathFor(String key) {
    return p.join(_baseDir.path, '${_safeKey(key)}.bin');
  }

  String _safeKey(String key) {
    // Keys are simple identifiers; keep them filesystem-safe and distinct.
    return key.replaceAll(RegExp(r'[^A-Za-z0-9_.\-]'), '_');
  }

  @override
  Future<String?> read(String key) async {
    final file = File(_pathFor(key));
    if (!await file.exists()) return null;
    try {
      final ciphertextB64 = await file.readAsString();
      final ciphertext = base64Decode(ciphertextB64);
      final plain = await _dpapiCurrentUser(ciphertext, protect: false);
      if (plain == null) {
        throw StateError('DPAPI unprotect failed');
      }
      return utf8.decode(plain);
    } catch (_) {
      throw StateError(
          'S6_WINDOWS_DPAPI_READ_FAILED: fail closed (corrupt or unavailable)');
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      if (!await _baseDir.exists()) {
        await _baseDir.create(recursive: true);
      }
      final plain = utf8.encode(value);
      final ciphertext = await _dpapiCurrentUser(plain, protect: true);
      if (ciphertext == null) {
        throw StateError('DPAPI protect failed');
      }
      final tmp = File('${_pathFor(key)}.tmp');
      await tmp.writeAsString(base64Encode(ciphertext), flush: true);
      await tmp.rename(_pathFor(key));
    } catch (_) {
      throw StateError(
          'S6_WINDOWS_DPAPI_WRITE_FAILED: fail closed (storage unavailable)');
    }
  }

  @override
  Future<void> delete(String key) async {
    final file = File(_pathFor(key));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> containsKey(String key) async =>
      File(_pathFor(key)).exists();

  /// Protect / unprotect via PowerShell DPAPI with `DataProtectionScope.CurrentUser`.
  ///
  /// The plaintext/ciphertext is passed over the stdin PIPELINE (via
  /// [Process.start] stdin, Base64-encoded) — never a temporary plaintext
  /// file, never inline in the command line — and the result is read from
  /// stdout. `[Console]::In` / `[Console]::Out` are byte-pipe safe Base64
  /// streams. Fails closed (returns null) on any PowerShell error.
  Future<Uint8List?> _dpapiCurrentUser(Uint8List input,
      {required bool protect}) async {
    if (!Platform.isWindows) {
      throw StateError('Windows DPAPI only supported on Windows');
    }
    // Add-Type ensures System.Security.Cryptography.ProtectedData types are
    // resolvable (they are not auto-loaded in every PowerShell session).
    final script = protect
        ? r'''
Add-Type -AssemblyName System.Security;
$inB64 = [Console]::In.ReadToEnd().Trim();
$plain = [System.Convert]::FromBase64String($inB64);
$scope = [System.Security.Cryptography.DataProtectionScope]::CurrentUser;
$protected = [System.Security.Cryptography.ProtectedData]::Protect($plain, $null, $scope);
[Console]::Out.Write([System.Convert]::ToBase64String($protected));
'''
        : r'''
Add-Type -AssemblyName System.Security;
$inB64 = [Console]::In.ReadToEnd().Trim();
$enc = [System.Convert]::FromBase64String($inB64);
$scope = [System.Security.Cryptography.DataProtectionScope]::CurrentUser;
$plain = [System.Security.Cryptography.ProtectedData]::Unprotect($enc, $null, $scope);
[Console]::Out.Write([System.Convert]::ToBase64String($plain));
''';

    try {
      final inB64 = base64Encode(input);
      final process = await Process.start('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]);
      // Provide the input on stdin WITHOUT touching a temp file or cmdline.
      process.stdin.write(inB64);
      await process.stdin.flush();
      await process.stdin.close();

      // Read stdout and stderr to completion; both complete when PowerShell
      // exits and the pipes close, so this cannot deadlock on a full pipe.
      final outFuture = process.stdout.transform(utf8.decoder).join();
      final errFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      final outB64 = (await outFuture).trim();
      await errFuture;
      if (exitCode != 0 || outB64.isEmpty) {
        return null;
      }
      return base64Decode(outB64);
    } catch (_) {
      return null;
    }
  }
}



/// In-memory fake — TEST PROFILES ONLY. Values live in process memory and
/// are never durable or encrypted. Never wire this into a production
/// platform default.
class InMemorySecureSecretStore implements SecureSecretStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);
}
