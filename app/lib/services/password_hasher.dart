import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const int _saltLength = 16;
  static const int _iterations = 100000;
  static const int _keyLength = 32;

  String hashPassword(String password) {
    final salt =
        List<int>.generate(_saltLength, (_) => Random.secure().nextInt(256));
    final hash = _pbkdf2(password, salt);
    final saltBase64 = base64Encode(salt);
    final hashBase64 = base64Encode(hash);
    return '$saltBase64:$hashBase64';
  }

  bool verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = base64Decode(parts[0]);
    final storedHashBytes = base64Decode(parts[1]);
    final computedHash = _pbkdf2(password, salt);
    if (computedHash.length != storedHashBytes.length) return false;
    for (int i = 0; i < computedHash.length; i++) {
      if (computedHash[i] != storedHashBytes[i]) return false;
    }
    return true;
  }

  List<int> _pbkdf2(String password, List<int> salt) {
    final passwordBytes = utf8.encode(password);
    var u = _hmacSha256(passwordBytes, [...salt, 0, 0, 0, 1]);
    var result = List<int>.from(u);

    for (int i = 1; i < _iterations; i++) {
      u = _hmacSha256(passwordBytes, u);
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result.take(_keyLength).toList();
  }

  List<int> _hmacSha256(List<int> key, List<int> data) {
    const blockSize = 64;
    if (key.length > blockSize) {
      key = sha256.convert(key).bytes;
    }
    if (key.length < blockSize) {
      key = [...key, ...List.filled(blockSize - key.length, 0)];
    }

    final oKeyPad = List<int>.generate(blockSize, (i) => key[i] ^ 0x5c);
    final iKeyPad = List<int>.generate(blockSize, (i) => key[i] ^ 0x36);

    final innerDigest = sha256.convert([...iKeyPad, ...data]).bytes;
    return sha256.convert([...oKeyPad, ...innerDigest]).bytes;
  }
}
