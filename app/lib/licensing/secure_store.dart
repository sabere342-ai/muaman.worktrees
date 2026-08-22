import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'secure_store_android.dart';

/// Storage contract for protected licensing activation state (Phase K D7).
///
/// Windows uses the historical DPAPI-backed [SecureActivationStore]
/// unchanged; Android uses the Keystore-backed [KeystoreActivationStore].
/// Consumers depend on this interface, never on a concrete platform store.
abstract class ProtectedActivationStore {
  Future<SecureActivationState?> read();
  Future<void> write(SecureActivationState state);
  Future<void> delete();
}

/// Resolves the platform-default protected activation store.
///
/// Android MUST NOT fall back to the insecure obfuscation path — it always
/// receives the Keystore-backed implementation. Every other platform keeps
/// the pre-Phase-K behavior byte-identical.
ProtectedActivationStore createDefaultProtectedActivationStore() {
  if (!kIsWeb && Platform.isAndroid) {
    return KeystoreActivationStore(const KeystoreChannelSecretStore());
  }
  return SecureActivationStore();
}

/// DPAPI-protected local activation state storage.
///
/// Per T3-2 §15:
/// - Stored in %LOCALAPPDATA%\I-TECH\licensing\activation.dat
/// - Encrypted with Windows DPAPI (CryptProtectData)
/// - Integrity-protected with HMAC-SHA256
/// - COMPLETELY SEPARATE from muaman_store.db
/// - NOT included in backup/restore
class SecureActivationStore implements ProtectedActivationStore {
  /// Per-installation HMAC secret key (generated on first activation).
  Uint8List? _hmacSecret;

  /// Path to the activation data directory.
  final String? directoryOverride;

  SecureActivationStore({this.directoryOverride});

  /// Get the activation data file path.
  String get _activationFilePath {
    if (directoryOverride != null) {
      return p.join(directoryOverride!, 'activation.dat');
    }
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (localAppData.isNotEmpty) {
        return p.join(localAppData, 'I-TECH', 'licensing', 'activation.dat');
      }
    }
    return p.join(
        Directory.current.path, '.itech', 'licensing', 'activation.dat');
  }

  /// Get the HMAC secret file path.
  String get _hmacSecretPath {
    final dir = p.dirname(_activationFilePath);
    return p.join(dir, '.hmac_secret');
  }

  /// Read the stored activation state.
  ///
  /// Returns null if no activation file exists.
  /// Returns [SecureActivationState] if valid.
  /// Throws [CorruptStateException] if file exists but is corrupted.
  @override
  Future<SecureActivationState?> read() async {
    final file = File(_activationFilePath);
    if (!file.existsSync()) {
      return null;
    }

    try {
      final encryptedBytes = await file.readAsBytes();
      if (encryptedBytes.isEmpty) {
        throw const CorruptStateException('Activation file is empty');
      }

      // Decrypt with DPAPI
      final decryptedBytes = _dpapiDecrypt(encryptedBytes);
      if (decryptedBytes == null) {
        throw const CorruptStateException('DPAPI decryption failed');
      }

      // Parse the structure
      if (decryptedBytes.length < 37) {
        throw const CorruptStateException('Activation file too small');
      }

      final version = decryptedBytes[0];
      if (version != 1) {
        throw CorruptStateException('Unknown file version: $version');
      }

      // Extract HMAC (last 32 bytes)
      final hmacFromBytes = decryptedBytes.sublist(decryptedBytes.length - 32);
      final dataBytes = decryptedBytes.sublist(0, decryptedBytes.length - 32);

      // Verify HMAC
      final secret = await _getOrCreateHmacSecret();
      final hmac = Hmac(sha256, secret);
      final computedHmac = hmac.convert(dataBytes).bytes;

      if (!_constantTimeCompare(
          hmacFromBytes, Uint8List.fromList(computedHmac))) {
        throw const CorruptStateException('HMAC integrity check failed');
      }

      // Parse data fields from HMAC-protected region
      int offset = 1; // skip version byte

      // business_id (36 bytes UUID string)
      final businessIdBytes = dataBytes.sublist(offset, offset + 36);
      final businessId = utf8.decode(businessIdBytes);
      offset += 36;

      // device_hash_length (2 bytes)
      final deviceHashLength = (dataBytes[offset] << 8) | dataBytes[offset + 1];
      offset += 2;

      // device_hash (variable)
      final deviceHash = dataBytes.sublist(offset, offset + deviceHashLength);
      offset += deviceHashLength;

      // token_length (4 bytes)
      final tokenLength = (dataBytes[offset] << 24) |
          (dataBytes[offset + 1] << 16) |
          (dataBytes[offset + 2] << 8) |
          dataBytes[offset + 3];
      offset += 4;

      // token_bytes (variable)
      final tokenBytes = dataBytes.sublist(offset, offset + tokenLength);
      offset += tokenLength;

      // activation_generation (2 bytes)
      final activationGeneration =
          (dataBytes[offset] << 8) | dataBytes[offset + 1];
      offset += 2;

      // created_at (8 bytes - epoch millis)
      final createdAt = (dataBytes[offset] << 56) |
          (dataBytes[offset + 1] << 48) |
          (dataBytes[offset + 2] << 40) |
          (dataBytes[offset + 3] << 32) |
          (dataBytes[offset + 4] << 24) |
          (dataBytes[offset + 5] << 16) |
          (dataBytes[offset + 6] << 8) |
          dataBytes[offset + 7];

      return SecureActivationState(
        businessId: businessId,
        deviceHash: Uint8List.fromList(deviceHash),
        tokenBytes: Uint8List.fromList(tokenBytes),
        activationGeneration: activationGeneration,
        createdAt: createdAt,
      );
    } on CorruptStateException {
      rethrow;
    } catch (e) {
      throw CorruptStateException('Failed to read activation file: $e');
    }
  }

  /// Write the activation state to the DPAPI-protected file.
  ///
  /// Uses atomic write (write to temp, then rename).
  @override
  Future<void> write(SecureActivationState state) async {
    final dir = Directory(p.dirname(_activationFilePath));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    // Build the data region
    final dataBuilder = BytesBuilder();

    // version (1 byte)
    dataBuilder.addByte(1);

    // business_id (36 bytes)
    final businessIdBytes = utf8.encode(state.businessId.padRight(36, '\x00'));
    dataBuilder.add(businessIdBytes.sublist(0, 36));

    // device_hash_length (2 bytes) + device_hash
    dataBuilder.addByte((state.deviceHash.length >> 8) & 0xFF);
    dataBuilder.addByte(state.deviceHash.length & 0xFF);
    dataBuilder.add(state.deviceHash);

    // token_length (4 bytes) + token_bytes
    final tokenLength = state.tokenBytes.length;
    dataBuilder.addByte((tokenLength >> 24) & 0xFF);
    dataBuilder.addByte((tokenLength >> 16) & 0xFF);
    dataBuilder.addByte((tokenLength >> 8) & 0xFF);
    dataBuilder.addByte(tokenLength & 0xFF);
    dataBuilder.add(state.tokenBytes);

    // activation_generation (2 bytes)
    dataBuilder.addByte((state.activationGeneration >> 8) & 0xFF);
    dataBuilder.addByte(state.activationGeneration & 0xFF);

    // created_at (8 bytes - epoch millis)
    final createdAt = state.createdAt;
    dataBuilder.addByte((createdAt >> 56) & 0xFF);
    dataBuilder.addByte((createdAt >> 48) & 0xFF);
    dataBuilder.addByte((createdAt >> 40) & 0xFF);
    dataBuilder.addByte((createdAt >> 32) & 0xFF);
    dataBuilder.addByte((createdAt >> 24) & 0xFF);
    dataBuilder.addByte((createdAt >> 16) & 0xFF);
    dataBuilder.addByte((createdAt >> 8) & 0xFF);
    dataBuilder.addByte(createdAt & 0xFF);

    final dataBytes = dataBuilder.toBytes();

    // Compute HMAC
    final secret = await _getOrCreateHmacSecret();
    final hmac = Hmac(sha256, secret);
    final hmacDigest = hmac.convert(dataBytes);

    // Build final: data + HMAC
    final fileBuilder = BytesBuilder();
    fileBuilder.add(dataBytes);
    fileBuilder.add(Uint8List.fromList(hmacDigest.bytes));

    // Encrypt with DPAPI
    final plainBytes = fileBuilder.toBytes();
    final encryptedBytes = _dpapiEncrypt(plainBytes);
    if (encryptedBytes == null) {
      throw StateError('DPAPI encryption failed');
    }

    // Atomic write
    final tempPath = '$_activationFilePath.tmp';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(encryptedBytes, flush: true);

    // Rename (atomic on most filesystems)
    await tempFile.rename(_activationFilePath);
  }

  /// Delete the activation file.
  @override
  Future<void> delete() async {
    final file = File(_activationFilePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Check if activation file exists.
  bool exists() => File(_activationFilePath).existsSync();

  // --- DPAPI operations (Windows-only via FFI) ---

  /// Encrypt bytes using Windows DPAPI.
  /// Returns null on failure.
  Uint8List? _dpapiEncrypt(Uint8List plainBytes) {
    if (!Platform.isWindows) {
      // Fallback for non-Windows: simple obfuscation (NOT secure —
      // for development/testing only)
      return _simpleObfuscate(plainBytes);
    }

    try {
      return _dpapiCryptProtect(plainBytes);
    } catch (_) {
      return null;
    }
  }

  /// Decrypt bytes using Windows DPAPI.
  /// Returns null on failure.
  Uint8List? _dpapiDecrypt(Uint8List encryptedBytes) {
    if (!Platform.isWindows) {
      // Fallback for non-Windows
      return _simpleDeobfuscate(encryptedBytes);
    }

    try {
      return _dpapiCryptUnprotect(encryptedBytes);
    } catch (_) {
      return null;
    }
  }

  /// Windows DPAPI CryptProtectData via Process.
  /// In production, this would use FFI for better performance.
  Uint8List? _dpapiCryptProtect(Uint8List plainBytes) {
    // For the initial implementation, use a process-based approach
    // In a production build, this would be direct FFI calls to
    // CryptProtectData/CryptUnprotectData
    try {
      // Write plain bytes to temp file, use PowerShell to DPAPI-encrypt
      final tempIn = '${Directory.systemTemp.path}\\itech_plain_$pid.bin';
      final tempOut = '${Directory.systemTemp.path}\\itech_enc_$pid.bin';
      File(tempIn).writeAsBytesSync(plainBytes);

      final result = Process.runSync('powershell', [
        '-Command',
        r'''
        $plain = [System.IO.File]::ReadAllBytes(''' +
            tempIn +
            r''');
        $protected = [System.Security.Cryptography.ProtectedData]::Protect(
          $plain, $null,
          [System.Security.Cryptography.DataProtectionScope]::LocalMachine
        );
        [System.IO.File]::WriteAllBytes(''' +
            tempOut +
            r''', $protected);
        '''
      ]);

      File(tempIn).deleteSync();
      if (result.exitCode == 0 && File(tempOut).existsSync()) {
        final encrypted = File(tempOut).readAsBytesSync();
        File(tempOut).deleteSync();
        return encrypted;
      }
    } catch (_) {}
    return null;
  }

  /// Windows DPAPI CryptUnprotectData via Process.
  Uint8List? _dpapiCryptUnprotect(Uint8List encryptedBytes) {
    try {
      final tempIn = '${Directory.systemTemp.path}\\itech_enc_r_$pid.bin';
      final tempOut = '${Directory.systemTemp.path}\\itech_dec_r_$pid.bin';
      File(tempIn).writeAsBytesSync(encryptedBytes);

      final result = Process.runSync('powershell', [
        '-Command',
        r'''
        $encrypted = [System.IO.File]::ReadAllBytes(''' +
            tempIn +
            r''');
        $plain = [System.Security.Cryptography.ProtectedData]::Unprotect(
          $encrypted, $null,
          [System.Security.Cryptography.DataProtectionScope]::LocalMachine
        );
        [System.IO.File]::WriteAllBytes(''' +
            tempOut +
            r''', $plain);
        '''
      ]);

      File(tempIn).deleteSync();
      if (result.exitCode == 0 && File(tempOut).existsSync()) {
        final plain = File(tempOut).readAsBytesSync();
        File(tempOut).deleteSync();
        return plain;
      }
    } catch (_) {}
    return null;
  }

  /// Simple obfuscation for non-Windows (development/testing only).
  Uint8List _simpleObfuscate(Uint8List data) {
    final key = _getObfuscationKey();
    final result = Uint8List(data.length + 4);
    result[0] = 0x49; // 'I'
    result[1] = 0x54; // 'T'
    result[2] = 0x45; // 'E'
    result[3] = 0x43; // 'C'
    for (int i = 0; i < data.length; i++) {
      result[i + 4] = data[i] ^ key[i % key.length];
    }
    return result;
  }

  Uint8List _simpleDeobfuscate(Uint8List data) {
    if (data.length < 4) throw const CorruptStateException('File too small');
    if (data[0] != 0x49 ||
        data[1] != 0x54 ||
        data[2] != 0x45 ||
        data[3] != 0x43) {
      throw const CorruptStateException('Invalid file header');
    }
    final key = _getObfuscationKey();
    final result = Uint8List(data.length - 4);
    for (int i = 0; i < result.length; i++) {
      result[i] = data[i + 4] ^ key[i % key.length];
    }
    return result;
  }

  Uint8List _getObfuscationKey() {
    return utf8.encode('I-TECH-LICENSING-SECURE-KEY-v1');
  }

  // --- HMAC secret management ---

  Future<Uint8List> _getOrCreateHmacSecret() async {
    if (_hmacSecret != null) return _hmacSecret!;

    final secretFile = File(_hmacSecretPath);
    if (secretFile.existsSync()) {
      _hmacSecret = await secretFile.readAsBytes();
      return _hmacSecret!;
    }

    // Generate new secret
    final dir = Directory(p.dirname(_hmacSecretPath));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _hmacSecret = Uint8List.fromList(
        List.generate(32, (_) => DateTime.now().microsecondsSinceEpoch & 0xFF));
    await secretFile.writeAsBytes(_hmacSecret!, flush: true);
    return _hmacSecret!;
  }

  /// Constant-time comparison.
  static bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// Stored activation state in the secure local file.
class SecureActivationState {
  final String businessId;
  final Uint8List deviceHash;
  final Uint8List tokenBytes;
  final int activationGeneration;
  final int createdAt;

  SecureActivationState({
    required this.businessId,
    required this.deviceHash,
    required this.tokenBytes,
    required this.activationGeneration,
    required this.createdAt,
  });
}

/// Exception for corrupted local state.
class CorruptStateException implements Exception {
  final String reason;
  const CorruptStateException(this.reason);
  @override
  String toString() => 'CorruptStateException: $reason';
}
