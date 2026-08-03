import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

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
  if (releaseDirArg == null || outArg == null) {
    stderr.writeln('Usage: dart run tool/create_release_manifest.dart '
        '--release-dir <dir> --out <json> '
        '[--commit <sha>] [--branch <name>] [--built-at <iso>] '
        '[--flutter-version <v>] [--dart-version <v>] '
        '[--clean-before <true|false>] [--clean-after <true|false>]');
    exitCode = 64;
    return;
  }

  final releaseDir = Directory(releaseDirArg);
  if (!releaseDir.existsSync()) {
    stderr.writeln('Release directory not found: ${releaseDir.path}');
    exitCode = 66;
    return;
  }

  final entries = releaseDir
      .listSync(recursive: true)
      .whereType<File>()
      .toList()
    ..sort((a, b) =>
        _relativePath(releaseDir, a).compareTo(_relativePath(releaseDir, b)));

  final files = <Map<String, dynamic>>[];
  for (final file in entries) {
    final bytes = await file.readAsBytes();
    files.add({
      'path': _relativePath(releaseDir, file),
      'sizeBytes': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
    });
  }

  final manifest = <String, dynamic>{
    'project': _value(args, '--project') ?? 'Muaman Store',
    'phase': _value(args, '--phase') ?? 'MUAMAN-13A',
    'commit': _value(args, '--commit') ?? '',
    'branch': _value(args, '--branch') ?? '',
    'buildMode': _value(args, '--build-mode') ?? 'release',
    'platform': _value(args, '--platform') ?? 'windows',
    'architecture': _value(args, '--architecture') ?? 'x64',
    'builtAt': _value(args, '--built-at') ?? '',
    'flutterVersion': _value(args, '--flutter-version') ?? '',
    'dartVersion': _value(args, '--dart-version') ?? '',
    'sourceTreeCleanBeforeBuild': _value(args, '--clean-before') == 'true',
    'sourceTreeCleanAfterBuild': _value(args, '--clean-after') == 'true',
    'files': files,
  };

  const encoder = JsonEncoder.withIndent('  ');
  if (outArg.isEmpty) {
    stdout.write('${encoder.convert(manifest)}\n');
  } else {
    await File(outArg)
        .writeAsString('${encoder.convert(manifest)}\n', flush: true);
  }
  stdout.writeln('Manifest built: ${files.length} files.');
}
