/// Read-only PE/COFF inspection used to prove reproducible linking.
///
/// Records the raw COFF header timestamp and the IMAGE_DEBUG_DIRECTORY
/// timestamps (with their file offsets) for a set of PE files, plus the full
/// SHA-256 of each file. It never modifies the input files.
///
/// Two modes:
///   dart run tool/pe_inspect.dart --run-id <id> --out <json>
///       --file <path> [--file <path> ...]
///   dart run tool/pe_inspect.dart --compare <run1.json> <run2.json>
///       --out <json>
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

int _u16(List<int> b, int off) => (b[off]) | (b[off + 1] << 8);

int _u32(List<int> b, int off) =>
    (b[off]) | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24);

/// One IMAGE_DEBUG_DIRECTORY entry found in a PE image.
class PeDebugEntry {
  const PeDebugEntry({
    required this.type,
    required this.timeDateStamp,
    required this.fileOffset,
  });

  final int type;
  final int timeDateStamp;

  /// File offset of the start of this IMAGE_DEBUG_DIRECTORY entry.
  final int fileOffset;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'timeDateStamp': timeDateStamp,
        'timeDateStampOffset': fileOffset + 4,
        'fileOffset': fileOffset,
      };
}

/// Extracted PE/COFF metadata for a single file.
class PeMetadata {
  const PeMetadata({
    required this.fileName,
    required this.path,
    required this.sizeBytes,
    required this.sha256,
    required this.peOffset,
    required this.machine,
    required this.coffTimeDateStamp,
    required this.coffTimeDateStampOffset,
    required this.numberOfSections,
    required this.checksum,
    required this.sizeOfImage,
    required this.linkerVersion,
    required this.osVersionMajor,
    required this.osVersionMinor,
    required this.debugEntries,
  });

  final String fileName;
  final String path;
  final int sizeBytes;
  final String sha256;
  final int peOffset;
  final int machine;
  final int coffTimeDateStamp;
  final int coffTimeDateStampOffset;
  final int numberOfSections;
  final int checksum;
  final int sizeOfImage;
  final int linkerVersion;
  final int osVersionMajor;
  final int osVersionMinor;
  final List<PeDebugEntry> debugEntries;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fileName': fileName,
        'path': path,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'pe': <String, dynamic>{
          'peOffset': peOffset,
          'machine': machine,
          'coffTimeDateStamp': coffTimeDateStamp,
          'coffTimeDateStampOffset': coffTimeDateStampOffset,
          'numberOfSections': numberOfSections,
          'checksum': checksum,
          'sizeOfImage': sizeOfImage,
          'linkerVersion': linkerVersion,
          'osVersion': '$osVersionMajor.$osVersionMinor',
          'debugEntries':
              debugEntries.map((final entry) => entry.toJson()).toList(),
        },
      };
}

/// Reads the PE/COFF metadata of [file]. Throws [FormatException] when the
/// file is not a valid PE image.
PeMetadata inspectPe(File file, {required String fileName}) {
  final bytes = file.readAsBytesSync();
  if (bytes.length < 0x40 || bytes[0] != 0x4D || bytes[1] != 0x5A) {
    throw const FormatException('not a PE image (missing MZ header)');
  }
  final peOff = _u32(bytes, 0x3C);
  if (peOff + 24 + 20 > bytes.length) {
    throw FormatException('truncated PE header (peOff=$peOff)');
  }
  if (bytes[peOff] != 0x50 || bytes[peOff + 1] != 0x45) {
    throw const FormatException('no PE signature');
  }
  final opt = peOff + 24;
  if (opt + 120 > bytes.length) {
    throw const FormatException('truncated optional header');
  }
  final magic = _u16(bytes, opt);
  if (magic != 0x10B && magic != 0x20B) {
    throw FormatException('unexpected optional header magic 0x'
        '${magic.toRadixString(16)}');
  }
  final machine = _u16(bytes, peOff + 4);
  final numberOfSections = _u16(bytes, peOff + 6);
  final coffTimeDateStamp = _u32(bytes, peOff + 8);
  final coffTimeDateStampOffset = peOff + 8;
  final sizeOfOptionalHeader = _u16(bytes, peOff + 20);
  final checksum = _u32(bytes, opt + 64);
  final sizeOfImage = _u32(bytes, opt + 56);
  final linkerVersion = _u16(bytes, opt + 2);
  final osVersionMajor = _u16(bytes, opt + 40);
  final osVersionMinor = _u16(bytes, opt + 42);

  final debugEntries = <PeDebugEntry>[];
  final dataDirStart = magic == 0x20B ? 112 : 96;
  final numberOfRvaAndSizes = _u32(bytes, opt + (magic == 0x20B ? 108 : 92));
  if (numberOfRvaAndSizes > 6) {
    final debugRva = _u32(bytes, opt + dataDirStart + 6 * 8);
    final debugSize = _u32(bytes, opt + dataDirStart + 6 * 8 + 4);
    final sectionTable = opt + sizeOfOptionalHeader;
    if (debugSize > 0 &&
        debugRva > 0 &&
        sectionTable + numberOfSections * 40 <= bytes.length) {
      int? debugFileOffset;
      for (var i = 0; i < numberOfSections; i++) {
        final s = sectionTable + i * 40;
        final virtualAddress = _u32(bytes, s + 12);
        final virtualSize = _u32(bytes, s + 8);
        final rawSize = _u32(bytes, s + 16);
        final rawPointer = _u32(bytes, s + 20);
        final end =
            virtualAddress + (virtualSize > rawSize ? virtualSize : rawSize);
        if (debugRva >= virtualAddress && debugRva < end) {
          debugFileOffset = rawPointer + (debugRva - virtualAddress);
          break;
        }
      }
      if (debugFileOffset != null) {
        final entryCount = debugSize ~/ 28;
        for (var i = 0; i < entryCount; i++) {
          final e = debugFileOffset + i * 28;
          if (e + 28 > bytes.length) break;
          debugEntries.add(PeDebugEntry(
            type: _u32(bytes, e + 12),
            timeDateStamp: _u32(bytes, e + 4),
            fileOffset: e,
          ));
        }
      }
    }
  }

  return PeMetadata(
    fileName: fileName,
    path: file.absolute.path,
    sizeBytes: bytes.length,
    sha256: sha256.convert(bytes).toString(),
    peOffset: peOff,
    machine: machine,
    coffTimeDateStamp: coffTimeDateStamp,
    coffTimeDateStampOffset: coffTimeDateStampOffset,
    numberOfSections: numberOfSections,
    checksum: checksum,
    sizeOfImage: sizeOfImage,
    linkerVersion: linkerVersion,
    osVersionMajor: osVersionMajor,
    osVersionMinor: osVersionMinor,
    debugEntries: debugEntries,
  );
}

/// Compares two run inspection payloads (each the `files` list of a
/// pe-inspection.json) keyed by [fileName] and reports equality per file.
///
/// Returns a machine-readable report with a `files` list and a final
/// `allFilesByteIdentical` boolean.
Map<String, dynamic> compareInspections(
  List<Map<String, dynamic>> run1Files,
  List<Map<String, dynamic>> run2Files,
) {
  final byName1 = <String, Map<String, dynamic>>{
    for (final f in run1Files) f['fileName'] as String: f,
  };
  final byName2 = <String, Map<String, dynamic>>{
    for (final f in run2Files) f['fileName'] as String: f,
  };

  final files = <Map<String, dynamic>>[];
  final fileNames = (byName1.keys.toSet()..addAll(byName2.keys)).toList()
    ..sort();
  for (final name in fileNames) {
    final f1 = byName1[name];
    final f2 = byName2[name];
    if (f1 == null || f2 == null) {
      files.add(<String, dynamic>{
        'fileName': name,
        'presentInRun1': f1 != null,
        'presentInRun2': f2 != null,
        'byteIdentical': false,
      });
      continue;
    }
    final pe1 = f1['pe'] as Map<String, dynamic>;
    final pe2 = f2['pe'] as Map<String, dynamic>;
    final debug1 = (pe1['debugEntries'] as List).cast<Map<String, dynamic>>();
    final debug2 = (pe2['debugEntries'] as List).cast<Map<String, dynamic>>();
    final debugTs1 = debug1.map((final e) => e['timeDateStamp']).toList();
    final debugTs2 = debug2.map((final e) => e['timeDateStamp']).toList();
    files.add(<String, dynamic>{
      'fileName': name,
      'sizeEqual': f1['sizeBytes'] == f2['sizeBytes'],
      'sha256Equal': f1['sha256'] == f2['sha256'],
      'byteIdentical':
          f1['sizeBytes'] == f2['sizeBytes'] && f1['sha256'] == f2['sha256'],
      'coffTimeDateStampEqual':
          pe1['coffTimeDateStamp'] == pe2['coffTimeDateStamp'],
      'coffTimeDateStampRun1': pe1['coffTimeDateStamp'],
      'coffTimeDateStampRun2': pe2['coffTimeDateStamp'],
      'debugTimeDateStampsEqual': debugTs1.length == debugTs2.length &&
          const ListEquality().equals(debugTs1, debugTs2),
      'debugTimeDateStampsRun1': debugTs1,
      'debugTimeDateStampsRun2': debugTs2,
    });
  }

  return <String, dynamic>{
    'files': files,
    'allFilesByteIdentical': files.every(
      (final f) => f['byteIdentical'] == true,
    ),
  };
}

class ListEquality {
  const ListEquality();
  bool equals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

String? _value(List<String> args, String key) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == key && i + 1 < args.length) return args[i + 1];
    if (args[i].startsWith('$key=')) {
      return args[i].substring(key.length + 1);
    }
  }
  return null;
}

List<String> _values(List<String> args, String key) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == key && i + 1 < args.length) {
      result.add(args[i + 1]);
      i++;
    } else if (args[i].startsWith('$key=')) {
      result.add(args[i].substring(key.length + 1));
    }
  }
  return result;
}

Future<void> _writeJson(String path, Map<String, dynamic> value) async {
  final out = File(path);
  await out.parent.create(recursive: true);
  await out.writeAsString('${_encoder.convert(value)}\n', flush: true);
}

Future<List<Map<String, dynamic>>> _loadInspectionFiles(String path) async {
  final map =
      jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
  return (map['files'] as List).cast<Map<String, dynamic>>();
}

Future<void> main(List<String> args) async {
  final compareArgs = _values(args, '--compare');
  if (compareArgs.isNotEmpty) {
    final out = _value(args, '--out');
    if (compareArgs.length != 2 || out == null) {
      stderr.writeln('Usage: dart run tool/pe_inspect.dart '
          '--compare <run1.json> <run2.json> --out <json>');
      exitCode = 64;
      return;
    }
    final report = compareInspections(
      await _loadInspectionFiles(compareArgs[0]),
      await _loadInspectionFiles(compareArgs[1]),
    );
    report['run1File'] = compareArgs[0];
    report['run2File'] = compareArgs[1];
    await _writeJson(out, report);
    stdout.writeln(report['allFilesByteIdentical'] == true
        ? 'PE COMPARE OK: all inspected files byte-identical.'
        : 'PE COMPARE DIFF: byte-identical=${report['allFilesByteIdentical']}.');
    return;
  }

  final runId = _value(args, '--run-id') ?? '';
  final out = _value(args, '--out');
  final files = _values(args, '--file');
  if (out == null || files.isEmpty) {
    stderr.writeln('Usage: dart run tool/pe_inspect.dart '
        '--run-id <id> --out <json> --file <path> [--file <path> ...]');
    exitCode = 64;
    return;
  }

  final inspected = <Map<String, dynamic>>[];
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('$path: not found');
      exitCode = 66;
      continue;
    }
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      inspected.add(inspectPe(file, fileName: fileName).toJson());
    } on FormatException catch (e) {
      stderr.writeln('$path: ${e.message}');
      exitCode = 66;
    }
  }

  await _writeJson(out, <String, dynamic>{
    'schema': 'muaman-pe-inspection',
    'schemaVersion': 1,
    'runId': runId,
    'files': inspected,
  });
  stdout.writeln('PE inspection written: $out (${inspected.length} files).');
}
