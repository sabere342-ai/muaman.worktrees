import 'dart:io';
import 'dart:typed_data';

/// Loads the shop logo file bytes for embedding in the invoice PDF.
///
/// Fails safe: a missing, empty, oversized or unreadable logo file yields
/// `null` instead of an error, so a broken logo can never break an invoice.
class InvoiceLogoLoader {
  const InvoiceLogoLoader();

  /// Upper bound for an embeddable logo. Guards against pathological files.
  static const int maxLogoBytes = 4 * 1024 * 1024;

  Future<Uint8List?> loadBytes(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    try {
      if (!await file.exists()) return null;
      final length = await file.length();
      if (length <= 0 || length > maxLogoBytes) return null;
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }
}
