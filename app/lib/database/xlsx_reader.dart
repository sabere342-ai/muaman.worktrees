import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class XlsxSheetData {
  final String name;
  final List<List<String?>> rows;
  XlsxSheetData(this.name, this.rows);
}

class XlsxReader {
  static Map<String, XlsxSheetData> read(String path) {
    final bytes = File(path).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final sharedStrings = _parseSharedStrings(archive);
    final sheetFiles = _getSheetFiles(archive);
    final result = <String, XlsxSheetData>{};

    for (final entry in sheetFiles.entries) {
      final file = archive.findFile('xl/worksheets/${entry.value}');
      if (file == null) continue;
      final xml = utf8.decode(file.content);
      final rows = _parseSheet(xml, sharedStrings);
      result[entry.key] = XlsxSheetData(entry.key, rows);
    }

    return result;
  }

  static List<String> _parseSharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return [];
    final xml = utf8.decode(file.content);
    final document = XmlDocument.parse(xml);
    final items = document.findAllElements('t');
    return items.map((e) => e.innerText).toList();
  }

  static Map<String, String> _getSheetFiles(Archive archive) {
    final file = archive.findFile('xl/workbook.xml');
    if (file == null) return {};
    final xml = utf8.decode(file.content);
    final document = XmlDocument.parse(xml);

    final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
    final relsXml = relsFile != null ? utf8.decode(relsFile.content) : '';
    final relsDoc = relsXml.isNotEmpty ? XmlDocument.parse(relsXml) : null;

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

  static List<List<String?>> _parseSheet(String xml, List<String> sharedStrings) {
    final document = XmlDocument.parse(xml);
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
