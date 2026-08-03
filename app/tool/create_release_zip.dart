import 'dart:io';

import 'package:archive/archive.dart';

String? _value(List<String> args, String key) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == key && i + 1 < args.length) return args[i + 1];
    if (args[i].startsWith('$key=')) {
      return args[i].substring(key.length + 1);
    }
  }
  return null;
}

String _relativePath(Directory root, File file) {
  var rel = file.absolute.path.substring(root.absolute.path.length);
  rel = rel.replaceAll(r'\', '/');
  while (rel.startsWith('/')) {
    rel = rel.substring(1);
  }
  return rel;
}

Future<void> main(List<String> args) async {
  final releaseDirArg = _value(args, '--release-dir');
  final outArg = _value(args, '--out');
  final includeManifest = _value(args, '--include-manifest');
  if (releaseDirArg == null || outArg == null) {
    stderr.writeln('Usage: dart run tool/create_release_zip.dart '
        '--release-dir <dir> --out <zip> [--include-manifest <json>]');
    exitCode = 64;
    return;
  }

  final releaseDir = Directory(releaseDirArg);
  if (!releaseDir.existsSync()) {
    stderr.writeln('Release directory not found: ${releaseDir.path}');
    exitCode = 66;
    return;
  }

  final archive = Archive();
  final fixedModTime = DateTime.utc(2000, 1, 1).millisecondsSinceEpoch ~/ 1000;

  void addBytes(String archivePath, List<int> bytes) {
    archive.addFile(ArchiveFile(archivePath, bytes.length, bytes)
      ..lastModTime = fixedModTime);
  }

  final entries = releaseDir
      .listSync(recursive: true)
      .whereType<File>()
      .toList()
    ..sort((a, b) =>
        _relativePath(releaseDir, a).compareTo(_relativePath(releaseDir, b)));

  for (final file in entries) {
    addBytes(_relativePath(releaseDir, file), await file.readAsBytes());
  }

  if (includeManifest != null) {
    final manifestFile = File(includeManifest);
    if (!manifestFile.existsSync()) {
      stderr.writeln('Manifest not found: ${manifestFile.path}');
      exitCode = 66;
      return;
    }
    addBytes(
        manifestFile.uri.pathSegments.last, await manifestFile.readAsBytes());
  }

  final encoded = ZipEncoder().encode(archive);
  if (encoded == null) {
    stderr.writeln('Failed to encode zip.');
    exitCode = 1;
    return;
  }
  await File(outArg).writeAsBytes(encoded, flush: true);
  stdout.writeln('ZIP written: ${File(outArg).absolute.path}');
}
