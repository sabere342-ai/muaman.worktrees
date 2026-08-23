import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../import/workbook_validation.dart';

class XlsxSheetData {
  final String name;
  final List<List<String?>> rows;
  XlsxSheetData(this.name, this.rows);
}

/// Phase N (N-D07): defensive XLSX container validation. Malformed input is
/// rejected with typed [WorkbookValidationException]s carrying Arabic user
/// messages — raw parser exceptions never escape to the UI.
class XlsxReader {
  static Map<String, XlsxSheetData> read(String path) {
    return readBytes(File(path).readAsBytesSync());
  }

  /// Byte-level entry point (Phase N): lets callers hash the exact bytes once
  /// (N-D11) and parse the very same buffer.
  static Map<String, XlsxSheetData> readBytes(Uint8List bytes) {
    validateWorkbookBytes(bytes.length);

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on WorkbookValidationException {
      rethrow;
    } catch (_) {
      throw const WorkbookValidationException(
        WorkbookErrorCode.corruptWorkbook,
        'الملف ليس أرشيف Excel صالحًا (حاوية ZIP غير صالحة)',
      );
    }

    if (archive.files.length > maxArchiveEntries) {
      throw const WorkbookValidationException(
        WorkbookErrorCode.corruptWorkbook,
        'بنية الأرشيف مشبوهة (عدد عناصر غير معقول)',
      );
    }

    // Zip-bomb guard (N-NFR04): bound total inflated size before parsing.
    int totalInflated = 0;
    for (final entry in archive.files) {
      totalInflated += entry.size;
      if (totalInflated > maxTotalInflatedBytes) {
        throw const WorkbookValidationException(
          WorkbookErrorCode.corruptWorkbook,
          'محتوى الملف منتفخ بشكل غير آمن',
        );
      }
    }

    if (archive.findFile('xl/workbook.xml') == null) {
      throw const WorkbookValidationException(
        WorkbookErrorCode.corruptWorkbook,
        'ملف Excel غير مكتمل (workbook.xml مفقود)',
      );
    }

    final sharedStrings = _parseSharedStrings(archive);
    final sheetFiles = _getSheetFiles(archive);
    final result = <String, XlsxSheetData>{};

    for (final entry in sheetFiles.entries) {
      final file = archive.findFile('xl/worksheets/${entry.value}');
      if (file == null) continue;
      final xml = _decodeUtf8(file.content as Uint8List);
      final rows = _parseSheet(xml, sharedStrings);
      result[entry.key] = XlsxSheetData(entry.key, rows);
    }

    return result;
  }

  static Uint8List _bytesOf(ArchiveFile file) {
    final content = file.content;
    if (content is Uint8List) return content;
    return Uint8List.fromList(List<int>.from(content as List<int>));
  }

  static String _decodeUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      throw const WorkbookValidationException(
        WorkbookErrorCode.corruptWorkbook,
        'ترميز الملف غير صالح',
      );
    }
  }

  static XmlDocument _parseXmlGuarded(String xml) {
    try {
      return XmlDocument.parse(xml);
    } catch (_) {
      throw const WorkbookValidationException(
        WorkbookErrorCode.corruptWorkbook,
        'بيانات XML داخل الملف تالفة',
      );
    }
  }

  static List<String> _parseSharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return [];
    final xml = _decodeUtf8(_bytesOf(file));
    final document = _parseXmlGuarded(xml);
    final items = document.findAllElements('t');
    return items.map((e) => e.innerText).toList();
  }

  static Map<String, String> _getSheetFiles(Archive archive) {
    final file = archive.findFile('xl/workbook.xml');
    if (file == null) return {};
    final xml = _decodeUtf8(_bytesOf(file));
    final document = _parseXmlGuarded(xml);

    final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
    final relsXml = relsFile != null ? _decodeUtf8(_bytesOf(relsFile)) : '';
    final relsDoc = relsXml.isNotEmpty ? _parseXmlGuarded(relsXml) : null;

    final idToTarget = <String, String>{};
    if (relsDoc != null) {
      for (final rel in relsDoc.findAllElements('Relationship')) {
        final id = rel.getAttribute('Id');
        final target = rel.getAttribute('Target');
        if (id != null && target != null) {
          idToTarget[id] = target.replaceAll('worksheets/', '');
        }
      }
    }

    final result = <String, String>{};
    for (final sheet in document.findAllElements('sheet')) {
      final name = sheet.getAttribute('name') ?? '';
      final id = sheet.getAttribute('r:id') ?? '';
      final target = idToTarget[id] ?? '';
      result[name] = target;
    }
    return result;
  }

  static List<List<String?>> _parseSheet(
      String xml, List<String> sharedStrings) {
    final document = _parseXmlGuarded(xml);
    final rows = <List<String?>>[];
    var maxCols = 0;

    for (final row in document.findAllElements('row')) {
      final cells = <String?>[];
      for (final cell in row.findElements('c')) {
        final ref = cell.getAttribute('r') ?? '';
        final colNum = _colIndexFromRef(ref);
        if (colNum < 0) continue;

        final type = cell.getAttribute('t');
        final vNode = cell.findElements('v').firstOrNull;
        final v = vNode?.innerText ?? '';

        String? value;
        if (type == 's' && v.isNotEmpty) {
          final idx = int.tryParse(v);
          if (idx != null && idx < sharedStrings.length) {
            value = sharedStrings[idx];
          }
        } else if (type == 'str' || type == 'e') {
          value = v;
        } else if (type == 'b') {
          value = v == '1' ? 'TRUE' : 'FALSE';
        } else if (v.isNotEmpty) {
          value = v;
        }

        while (cells.length <= colNum) {
          cells.add(null);
        }
        cells[colNum] = value;
      }
      rows.add(cells);
      if (cells.length > maxCols) maxCols = cells.length;
    }

    return rows;
  }

  static int _colIndexFromRef(String ref) {
    final match = RegExp(r'^([A-Z]+)').firstMatch(ref);
    if (match == null) return -1;
    final col = match.group(1)!;
    int result = 0;
    for (int i = 0; i < col.length; i++) {
      result = result * 26 + (col.codeUnitAt(i) - 64);
    }
    return result - 1;
  }
}
