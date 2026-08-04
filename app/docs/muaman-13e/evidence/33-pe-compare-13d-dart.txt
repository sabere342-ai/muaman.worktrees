import 'dart:convert';
import 'dart:io';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

int _u16(List<int> b, int off) => (b[off]) | (b[off + 1] << 8);
int _u32(List<int> b, int off) =>
    (b[off]) | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24);

const int kImageFileDll = 0x2000;

String? _peTypeOf(String path) {
  try {
    final f = File(path);
    if (!f.existsSync()) return null;
    final bytes = f.readAsBytesSync();
    if (bytes.length < 0x40 || bytes[0] != 0x4D || bytes[1] != 0x5A) {
      return null;
    }
    final peOff = _u32(bytes, 0x3C);
    if (peOff + 24 > bytes.length ||
        bytes[peOff] != 0x50 ||
        bytes[peOff + 1] != 0x45) {
      return null;
    }
    final characteristics = _u16(bytes, peOff + 22);
    return (characteristics & kImageFileDll) != 0 ? 'dll' : 'exe';
  } on FileSystemException {
    return null;
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

Future<void> main(List<String> args) async {
  final run1 = _value(args, '--run-1');
  final run2 = _value(args, '--run-2');
  final out = _value(args, '--out');
  if (run1 == null || run2 == null || out == null) {
    stderr.writeln('Usage: dart run tool/pe_compare_13d.dart '
        '--run-1 <pe-inspection.json> --run-2 <pe-inspection.json> '
        '--out <json>');
    exitCode = 64;
    return;
  }

  final j1 =
      jsonDecode(await File(run1).readAsString()) as Map<String, dynamic>;
  final j2 =
      jsonDecode(await File(run2).readAsString()) as Map<String, dynamic>;
  final byName1 = <String, Map<String, dynamic>>{
    for (final f in (j1['files'] as List).cast<Map<String, dynamic>>())
      f['fileName'] as String: f,
  };
  final byName2 = <String, Map<String, dynamic>>{
    for (final f in (j2['files'] as List).cast<Map<String, dynamic>>())
      f['fileName'] as String: f,
  };

  final names = (byName1.keys.toSet()..addAll(byName2.keys)).toList()..sort();
  final files = <Map<String, dynamic>>[];
  var allByteIdentical = true;
  var allTimestampsEqual = true;
  for (final name in names) {
    final f1 = byName1[name];
    final f2 = byName2[name];
    final pe1 = f1?['pe'] as Map<String, dynamic>?;
    final pe2 = f2?['pe'] as Map<String, dynamic>?;
    final machine = (pe1?['machine'] ?? pe2?['machine']) as int?;
    final path1 = f1?['path'] as String?;
    final peType = _peTypeOf(path1 ?? '');
    final ts1 = pe1?['coffTimeDateStamp'] as int?;
    final ts2 = pe2?['coffTimeDateStamp'] as int?;
    final sha1 = f1?['sha256'] as String?;
    final sha2 = f2?['sha256'] as String?;
    final size1 = f1?['sizeBytes'] as int?;
    final size2 = f2?['sizeBytes'] as int?;
    final byteIdentical = size1 == size2 && sha1 == sha2;
    final timestampEqual = ts1 == ts2;
    if (!byteIdentical) allByteIdentical = false;
    if (!timestampEqual) allTimestampsEqual = false;
    final errors = <String>[];
    if (f1 == null) errors.add('missing in run 1');
    if (f2 == null) errors.add('missing in run 2');

    files.add(<String, dynamic>{
      'fileName': name,
      'relativePath': name,
      'machine': machine,
      'peType': peType,
      'coffTimeDateStampRun1': ts1,
      'coffTimeDateStampRun2': ts2,
      'sha256Run1': sha1,
      'sha256Run2': sha2,
      'sizeRun1': size1,
      'sizeRun2': size2,
      'byteIdentical': byteIdentical,
      'timestampEqual': timestampEqual,
      'inspectionErrors': errors,
    });
  }

  final report = <String, dynamic>{
    'schema': 'muaman-13d-pe-comparison',
    'files': files,
    'allFilesByteIdentical': allByteIdentical,
    'allTimestampsEqual': allTimestampsEqual,
    'run1InspectionFile': run1,
    'run2InspectionFile': run2,
  };
  final outFile = File(out);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsString('${_encoder.convert(report)}\n', flush: true);
  stdout.writeln('PE comparison written: $out '
      '(${files.length} files, byteIdentical=$allByteIdentical, '
      'timestampsEqual=$allTimestampsEqual).');
}
