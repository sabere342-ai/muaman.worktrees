import 'dart:convert';

import 'package:flutter/services.dart';

import '../platform/secure_secret_store.dart';
import 'secure_store.dart';

/// [SecureSecretStore] backed by the Android Keystore through the
/// `itech.app/secure_storage` method channel (Phase K D7, GA6
/// platform-channel option).
///
/// The native handler persists through EncryptedSharedPreferences with the
/// master key held in the Android Keystore — no plaintext secrets at rest.
/// Native failures surface as [PlatformException] so callers fail closed;
/// no plaintext fallback exists. This class performs no storage of its own
/// beyond delegation.
class KeystoreChannelSecretStore implements SecureSecretStore {
  static const MethodChannel _channel =
      MethodChannel('itech.app/secure_storage');

  const KeystoreChannelSecretStore();

  @override
  Future<String?> read(String key) =>
      _channel.invokeMethod<String>('read', {'key': key});

  @override
  Future<void> write(String key, String value) => _channel.invokeMethod<void>(
        'write',
        {'key': key, 'value': value},
      );

  @override
  Future<void> delete(String key) =>
      _channel.invokeMethod<void>('delete', {'key': key});

  @override
  Future<bool> containsKey(String key) async =>
      await _channel.invokeMethod<bool>('containsKey', {'key': key}) ?? false;
}

/// Keystore-backed activation state store for Android (Phase K D7).
///
/// Implements the exact [ProtectedActivationStore] contract consumed by
/// [LicensingService], replacing the insecure XOR-obfuscation fallback that
/// previously served non-Windows platforms. The activation state is
/// serialized to JSON and persisted exclusively through the provided
/// [SecureSecretStore] (Keystore-encrypted at rest); nothing is written to
/// plain files, SQLite, SharedPreferences, or logs.
class KeystoreActivationStore implements ProtectedActivationStore {
  static const String _storageKey = 'itech.licensing.activation.state';

  final SecureSecretStore _secretStore;

  KeystoreActivationStore(this._secretStore);

  @override
  Future<SecureActivationState?> read() async {
    final raw = await _secretStore.read(_storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return SecureActivationState(
        businessId: map['businessId'] as String,
        deviceHash: Uint8List.fromList((map['deviceHash'] as List).cast<int>()),
        tokenBytes: Uint8List.fromList((map['tokenBytes'] as List).cast<int>()),
        activationGeneration: map['activationGeneration'] as int,
        createdAt: map['createdAt'] as int,
      );
    } on CorruptStateException {
      rethrow;
    } catch (_) {
      throw const CorruptStateException(
          'Keystore activation state is corrupted');
    }
  }

  @override
  Future<void> write(SecureActivationState state) async {
    final raw = jsonEncode({
      'businessId': state.businessId,
      'deviceHash': state.deviceHash.toList(),
      'tokenBytes': state.tokenBytes.toList(),
      'activationGeneration': state.activationGeneration,
      'createdAt': state.createdAt,
    });
    await _secretStore.write(_storageKey, raw);
  }

  @override
  Future<void> delete() async {
    await _secretStore.delete(_storageKey);
  }
}
