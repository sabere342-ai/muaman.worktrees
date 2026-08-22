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
