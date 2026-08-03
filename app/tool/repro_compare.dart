import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'repro_manifest.dart';

class SnapshotFile {
  const SnapshotFile(this.sizeBytes, this.sha256);

  final int sizeBytes;
  final String sha256;
}

/// Indexes every file under [root] by normalized relative path.
Future<Map<String, SnapshotFile>> snapshotFileMap(Directory root) async {
  final files = root.listSync(recursive: true).whereType<File>().toList()
    ..sort(
        (a, b) => relativePathOf(root, a).compareTo(relativePathOf(root, b)));
  final map = <String, SnapshotFile>{};
  for (final file in files) {
    final path = relativePathOf(root, file);
    final bytes = await file.readAsBytes();
    map[path] = SnapshotFile(bytes.length, sha256.convert(bytes).toString());
  }
  return map;
}

/// Compares two release snapshots and returns a machine-readable report with
/// fixed field order.
Future<Map<String, dynamic>> compareDirectories(
  Directory run1,
  Directory run2,
) async {
  final map1 = await snapshotFileMap(run1);
  final map2 = await snapshotFileMap(run2);

  final onlyInRun1 = <String>[];
  final onlyInRun2 = <String>[];
  final sizeMismatches = <Map<String, dynamic>>[];
  final hashMismatches = <Map<String, dynamic>>[];

  for (final path in map1.keys) {
    if (!map2.containsKey(path)) {
      onlyInRun1.add(path);
      continue;
    }
    final f1 = map1[path]!;
    final f2 = map2[path]!;
    if (f1.sizeBytes != f2.sizeBytes) {
      sizeMismatches.add(<String, dynamic>{
        'path': path,
        'run1SizeBytes': f1.sizeBytes,
        'run2SizeBytes': f2.sizeBytes,
      });
    }
    if (f1.sha256 != f2.sha256) {
      hashMismatches.add(<String, dynamic>{
        'path': path,
        'run1SizeBytes': f1.sizeBytes,
        'run2SizeBytes': f2.sizeBytes,
        'run1Sha256': f1.sha256,
        'run2Sha256': f2.sha256,
      });
    }
  }
  for (final path in map2.keys) {
    if (!map1.containsKey(path)) {
      onlyInRun2.add(path);
    }
  }
  onlyInRun1.sort();
  onlyInRun2.sort();

  var run1Bytes = 0;
  var run2Bytes = 0;
  for (final f in map1.values) {
    run1Bytes += f.sizeBytes;
  }
  for (final f in map2.values) {
    run2Bytes += f.sizeBytes;
  }

  final identical = onlyInRun1.isEmpty &&
      onlyInRun2.isEmpty &&
      sizeMismatches.isEmpty &&
      hashMismatches.isEmpty;

  // Canonical, spec-level classifications of the per-file comparison.
  final changedPaths = <String>{};
  for (final mismatch in sizeMismatches) {
    changedPaths.add(mismatch['path'] as String);
  }
  for (final mismatch in hashMismatches) {
    changedPaths.add(mismatch['path'] as String);
  }
  final changedFiles = changedPaths.toList()..sort();

  final sameSizeDifferentHash = <String>[];
  for (final mismatch in hashMismatches) {
    if (mismatch['run1SizeBytes'] == mismatch['run2SizeBytes']) {
      sameSizeDifferentHash.add(mismatch['path'] as String);
    }
  }
  sameSizeDifferentHash.sort();

  return <String, dynamic>{
    'identical': identical,
    'allFilesByteIdentical': identical,
    'onlyInRun1': onlyInRun1,
    'onlyInRun2': onlyInRun2,
    'addedFiles': onlyInRun2,
    'removedFiles': onlyInRun1,
    'changedFiles': changedFiles,
    'sameSizeDifferentHashFiles': sameSizeDifferentHash,
    'sizeMismatches': sizeMismatches,
    'hashMismatches': hashMismatches,
    'run1FileCount': map1.length,
    'run2FileCount': map2.length,
    'fileCount': map1.length,
    'fileCountIdentical': map1.length == map2.length,
    'run1TotalBytes': run1Bytes,
    'run2TotalBytes': run2Bytes,
    'totalBytes': run1Bytes,
    'totalBytesIdentical': run1Bytes == run2Bytes,
  };
}

/// Returns a non-null description when the canonical sections of two full
/// manifests differ, null when they are byte-identical.
String? canonicalManifestDifference({
  required String manifest1Json,
  required String manifest2Json,
}) {
  final c1 = canonicalSectionFromManifestJson(manifest1Json);
  final c2 = canonicalSectionFromManifestJson(manifest2Json);
  if (c1 == c2) return null;
  return 'canonical manifest sections differ';
}

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

String renderReport(Map<String, dynamic> report) =>
    '${_encoder.convert(report)}\n';

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
  final run1Arg = _value(args, '--run-1');
  final run2Arg = _value(args, '--run-2');
  final outArg = _value(args, '--out');
  final manifest1Arg = _value(args, '--manifest-1');
  final manifest2Arg = _value(args, '--manifest-2');
  if (run1Arg == null || run2Arg == null) {
    stderr.writeln('Usage: dart run tool/repro_compare.dart '
        '--run-1 <dir> --run-2 <dir> --out <json> '
        '[--manifest-1 <file>] [--manifest-2 <file>]');
    exitCode = 64;
    return;
  }

  final report =
      await compareDirectories(Directory(run1Arg), Directory(run2Arg));

  if (manifest1Arg != null && manifest2Arg != null) {
    final m1 = await File(manifest1Arg).readAsString();
    final m2 = await File(manifest2Arg).readAsString();
    final diff =
        canonicalManifestDifference(manifest1Json: m1, manifest2Json: m2);
    report['canonicalManifestIdentical'] = diff == null;
    report['canonicalManifestDifference'] = diff;
    report['run1CanonicalManifestSha256'] = sha256
        .convert(utf8.encode(canonicalSectionFromManifestJson(m1)))
        .toString();
    report['run2CanonicalManifestSha256'] = sha256
        .convert(utf8.encode(canonicalSectionFromManifestJson(m2)))
        .toString();
  }

  final json = renderReport(report);
  if (outArg == null || outArg.isEmpty) {
    stdout.write(json);
  } else {
    final out = File(outArg);
    await out.parent.create(recursive: true);
    await out.writeAsString(json, flush: true);
  }

  if (report['identical'] == true) {
    stdout.writeln('COMPARE OK: release directories are identical.');
  } else {
    stdout.writeln('COMPARE DIFF: onlyInRun1=${report['onlyInRun1'].length} '
        'onlyInRun2=${report['onlyInRun2'].length} '
        'sizeMismatches=${report['sizeMismatches'].length} '
        'hashMismatches=${report['hashMismatches'].length}.');
  }
}
