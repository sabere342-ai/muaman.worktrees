import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

int _u16(List<int> b, int off) => (b[off]) | (b[off + 1] << 8);
int _u32(List<int> b, int off) =>
    (b[off]) | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24);

const int kImageFileDll = 0x2000;

class PeProbe {
  const PeProbe({
    required this.isPe,
    this.machine,
    this.peType,
    this.coffTimeDateStamp,
    this.error,
  });

  final bool isPe;
  final int? machine;
  final String? peType;
  final int? coffTimeDateStamp;
  final String? error;
}

PeProbe probePe(File file) {
  try {
    final bytes = file.readAsBytesSync();
    if (bytes.length < 0x40 || bytes[0] != 0x4D || bytes[1] != 0x5A) {
      return const PeProbe(isPe: false);
    }
    final peOff = _u32(bytes, 0x3C);
    if (peOff + 24 + 20 > bytes.length ||
        bytes[peOff] != 0x50 ||
        bytes[peOff + 1] != 0x45) {
      return PeProbe(isPe: false, error: 'PE signature not found at $peOff');
    }
    final machine = _u16(bytes, peOff + 4);
    final coff = _u32(bytes, peOff + 8);
    final characteristics = _u16(bytes, peOff + 22);
    final isDll = (characteristics & kImageFileDll) != 0;
    return PeProbe(
      isPe: true,
      machine: machine,
      peType: isDll ? 'dll' : 'exe',
      coffTimeDateStamp: coff,
    );
  } on FileSystemException catch (e) {
    return PeProbe(isPe: false, error: e.message);
  }
}

String _relativePath(Directory root, File file) {
  var rel = file.absolute.path.substring(root.absolute.path.length);
  rel = rel.replaceAll(r'\', '/');
  while (rel.startsWith('/')) {
    rel = rel.substring(1);
  }
  return rel;
}

String _extensionType(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '(none)';
  return fileName.substring(dot + 1).toLowerCase();
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

Future<void> main(List<String> args) async {
  final runId = _value(args, '--run-id') ?? '';
  final releaseDirArg = _value(args, '--release-dir');
  final peInspectionArg = _value(args, '--pe-inspection');
  final outArg = _value(args, '--out');
  if (releaseDirArg == null || outArg == null) {
    stderr.writeln('Usage: dart run tool/repro_inventory_13d.dart '
        '--release-dir <dir> --out <json> '
        '[--run-id <id>] [--pe-inspection <pe-inspection.json>]');
    exitCode = 64;
    return;
  }

  final releaseDir = Directory(releaseDirArg);
  if (!releaseDir.existsSync()) {
    stderr.writeln('Release directory not found: ${releaseDir.path}');
    exitCode = 66;
    return;
  }

  Map<String, Map<String, dynamic>> peByFile = {};
  if (peInspectionArg != null && File(peInspectionArg).existsSync()) {
    final json = jsonDecode(await File(peInspectionArg).readAsString())
        as Map<String, dynamic>;
    for (final f in (json['files'] as List).cast<Map<String, dynamic>>()) {
      peByFile[f['fileName'] as String] = f;
    }
  }

  final files = releaseDir.listSync(recursive: true).whereType<File>().toList()
    ..sort((a, b) =>
        _relativePath(releaseDir, a).compareTo(_relativePath(releaseDir, b)));

  var totalBytes = 0;
  var peCount = 0;
  final entries = <Map<String, dynamic>>[];
  for (final file in files) {
    final bytes = await file.readAsBytes();
    final sha = sha256.convert(bytes).toString();
    final probe = probePe(file);
    final fileName = file.uri.pathSegments.last;
    final insp = peByFile[fileName];
    totalBytes += bytes.length;
    if (probe.isPe) {
      peCount++;
    }
    entries.add(<String, dynamic>{
      'path': _relativePath(releaseDir, file),
      'sizeBytes': bytes.length,
      'sha256': sha,
      'fileType': probe.isPe
          ? (probe.peType == 'dll' ? 'dll' : 'exe')
          : _extensionType(fileName),
      'isPe': probe.isPe,
      'peTimestamp': probe.coffTimeDateStamp,
      'machine': probe.machine,
      'peType': probe.peType,
      'peInspectionMatched': insp != null,
      'inspectionError': probe.error,
    });
  }

  final report = <String, dynamic>{
    'schema': 'muaman-13d-release-inventory',
    'runId': runId,
    'fileCount': files.length,
    'totalBytes': totalBytes,
    'peFileCount': peCount,
    'files': entries,
  };
  final outFile = File(outArg);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsString('${_encoder.convert(report)}\n', flush: true);
  stdout.writeln('Inventory written: $outArg '
      '($totalBytes bytes, $peCount PE files).');
}
