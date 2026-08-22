import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

/// Phase I / D10 content identity.
///
/// The fingerprint is the SHA-256 hex digest of the canonical JSON encoding of
/// an entity's business payload:
///
///  * object keys sorted lexicographically (byte-wise code-unit order),
///  * nested maps/lists canonicalized recursively,
///  * UTF-8 encoded,
///  * hashed with SHA-256, rendered lowercase hex.
///
/// Excluded by construction: the caller only passes business fields — local
/// `id`, `cloud_uuid`, `server_version`, `sync_status*`, `shop_id` and sync
/// timestamps never enter the map (D10 exclusion list). Money values are
/// serialized with Dart's shortest round-trip double representation so the
/// same IEEE754 input always yields the same digest across runs and devices.
class ContentFingerprint {
  ContentFingerprint._();

  /// Computes the stable fingerprint for a canonical business payload.
  static String compute(Map<String, dynamic> businessFields) {
    final bytes = utf8.encode(canonicalJson(businessFields));
    return crypto.sha256.convert(bytes).toString();
  }

  /// Canonical JSON: keys of every object level sorted lexicographically.
  static String canonicalJson(Map<String, dynamic> businessFields) {
    return jsonEncode(_canonicalize(businessFields));
  }

  static dynamic _canonicalize(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }
}
