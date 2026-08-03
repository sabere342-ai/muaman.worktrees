import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const int kCanonicalManifestSchemaVersion = 1;

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

/// Normalizes backslashes to forward slashes so manifest paths are portable.
String normalizeRelativePath(String path) => path.replaceAll(r'\', '/');

/// Computes the path of [file] relative to [root], always with `/` separators.
String relativePathOf(Directory root, File file) {
  var rel = file.absolute.path.substring(root.absolute.path.length);
  rel = rel.replaceAll(r'\', '/');
  while (rel.startsWith('/')) {
    rel = rel.substring(1);
  }
  return rel;
}

/// Lists every file under [root] sorted by normalized relative path.
Future<List<Map<String, dynamic>>> sortedFileEntries(Directory root) async {
  final files = root.listSync(recursive: true).whereType<File>().toList()
    ..sort((a, b) => normalizeRelativePath(relativePathOf(root, a))
        .compareTo(normalizeRelativePath(relativePathOf(root, b))));
  final entries = <Map<String, dynamic>>[];
  for (final file in files) {
    final bytes = await file.readAsBytes();
    entries.add(<String, dynamic>{
      'path': normalizeRelativePath(relativePathOf(root, file)),
      'sizeBytes': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
    });
  }
  return entries;
}

/// Builds the deterministic canonical section of a release manifest.
///
/// This is a pure function of the file tree: it contains only the file
/// count, total byte size, and a path-sorted list of
/// {path, sizeBytes, sha256}. It never contains timestamps, machine paths or
/// any other environment-dependent value.
Future<Map<String, dynamic>> buildCanonicalManifest(Directory root) async {
  final files = await sortedFileEntries(root);
  var totalBytes = 0;
  for (final file in files) {
    totalBytes += file['sizeBytes'] as int;
  }
  return <String, dynamic>{
    'fileCount': files.length,
    'totalBytes': totalBytes,
    'files': files,
  };
}

/// Serializes [map] with fixed field order, fixed indentation and `\n` EOL.
String renderCanonicalManifest(Map<String, dynamic> map) =>
    '${_encoder.convert(map)}\n';

/// Extracts and re-renders only the `canonical` section of a full manifest
/// JSON string so two manifests can be compared ignoring time-varying `meta`.
String canonicalSectionFromManifestJson(String fullManifestJson) {
  final decoded = jsonDecode(fullManifestJson) as Map<String, dynamic>;
  final canonical = decoded['canonical'] as Map;
  return renderCanonicalManifest(canonical.cast<String, dynamic>());
}

/// Wraps a canonical section with a fixed schema header and a `meta` section.
Map<String, dynamic> buildFullManifest({
  required Map<String, dynamic> canonical,
  required Map<String, dynamic> meta,
}) =>
    <String, dynamic>{
      'schema': 'muaman-repro-manifest',
      'schemaVersion': kCanonicalManifestSchemaVersion,
      'canonical': canonical,
      'meta': meta,
    };

/// Builds a full manifest (canonical + meta) for [root] in one step.
Future<Map<String, dynamic>> buildFullManifestForDir({
  required Directory root,
  required Map<String, dynamic> meta,
}) async {
  final canonical = await buildCanonicalManifest(root);
  return buildFullManifest(canonical: canonical, meta: meta);
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
  final releaseDirArg = _value(args, '--release-dir');
  final outArg = _value(args, '--out');
  if (releaseDirArg == null || outArg == null) {
    stderr.writeln('Usage: dart run tool/repro_manifest.dart '
        '--release-dir <dir> --out <json> '
        '[--run-id <id>] [--baseline-commit <sha>] [--branch <name>] '
        '[--platform <name>] [--architecture <arch>] [--build-mode <mode>] '
        '[--flutter-version <v>] [--dart-version <v>] [--built-at <iso>] '
        '[--clean-before <true|false>] [--clean-after <true|false>] '
        '[--pubspec-lock-hash <sha>]');
    exitCode = 64;
    return;
  }

  final releaseDir = Directory(releaseDirArg);
  if (!releaseDir.existsSync()) {
    stderr.writeln('Release directory not found: ${releaseDir.path}');
    exitCode = 66;
    return;
  }

  final meta = <String, dynamic>{
    'runId': _value(args, '--run-id') ?? '',
    'baselineCommit': _value(args, '--baseline-commit') ?? '',
    'branch': _value(args, '--branch') ?? '',
    'platform': _value(args, '--platform') ?? 'windows',
    'architecture': _value(args, '--architecture') ?? 'x64',
    'buildMode': _value(args, '--build-mode') ?? 'release',
    'flutterVersion': _value(args, '--flutter-version') ?? '',
    'dartVersion': _value(args, '--dart-version') ?? '',
    'builtAt': _value(args, '--built-at') ?? '',
    'sourceTreeCleanBeforeBuild': _value(args, '--clean-before') == 'true',
    'sourceTreeCleanAfterBuild': _value(args, '--clean-after') == 'true',
    'pubspecLockHash': _value(args, '--pubspec-lock-hash') ?? '',
  };

  final canonical = await buildCanonicalManifest(releaseDir);
  final manifest = buildFullManifest(canonical: canonical, meta: meta);
  final json = renderCanonicalManifest(manifest);

  if (outArg.isEmpty) {
    stdout.write(json);
  } else {
    final out = File(outArg);
    await out.parent.create(recursive: true);
    await out.writeAsString(json, flush: true);
  }
  stdout.writeln('Manifest built: ${canonical['fileCount']} files, '
      '${canonical['totalBytes']} bytes.');
}
