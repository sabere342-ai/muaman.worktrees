import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'repro_manifest.dart';

/// Fixed entry timestamp so the ZIP never embeds wall-clock time.
/// 2000-01-01T00:00:00Z in epoch seconds.
const int kZipFixedTimestampEpochSeconds = 946684800;

/// Fixed deflate level so compression output is byte-identical across runs.
const int kZipCompressionLevel = 6;

/// Packed DOS date/time (2000-01-01T00:00:00) as reconstructed by the archive
/// package's ZIP decoder from the fixed timestamp above.
const int kZipFixedTimestampDosPacked = 0x28210000;

/// Name of the canonical manifest entry embedded inside the ZIP.
const String kZipCanonicalManifestEntryName = 'manifest.canonical.json';

/// Builds a byte-identical ZIP from [root].
///
/// Deterministic by construction: entries are added in lexicographic order of
/// normalized relative path, every entry uses a fixed timestamp, compression
/// uses a fixed level, no absolute or traversal paths are ever included, and
/// the optional canonical manifest is embedded as a fixed content entry.
Future<List<int>> buildDeterministicZipBytes({
  required Directory root,
  String? canonicalManifestJson,
}) async {
  final files = root.listSync(recursive: true).whereType<File>().toList()
    ..sort(
        (a, b) => relativePathOf(root, a).compareTo(relativePathOf(root, b)));

  final items = <(String, List<int>)>[];
  for (final file in files) {
    items.add((relativePathOf(root, file), await file.readAsBytes()));
  }
  if (canonicalManifestJson != null) {
    items.add(
        (kZipCanonicalManifestEntryName, utf8.encode(canonicalManifestJson)));
  }
  items.sort((a, b) => a.$1.compareTo(b.$1));

  final archive = Archive();
  for (final item in items) {
    archive.addFile(ArchiveFile(item.$1, item.$2.length, item.$2)
      ..lastModTime = kZipFixedTimestampEpochSeconds);
  }
  final encoded = ZipEncoder().encode(
    archive,
    level: kZipCompressionLevel,
    modified: DateTime.utc(2000, 1, 1),
  );
  if (encoded == null) {
    throw StateError('ZipEncoder returned null');
  }
  return encoded;
}

/// Writes the deterministic ZIP for [root] to [out] and returns its SHA-256.
///
/// [out] must not be inside [root], otherwise a later run would archive the
/// output of an earlier run and break determinism.
Future<String> buildDeterministicZipFile({
  required Directory root,
  required File out,
  String? canonicalManifestJson,
}) async {
  if (p.isWithin(root.absolute.path, out.absolute.path)) {
    throw ArgumentError('Output ZIP must be outside the release directory: '
        '${out.absolute.path}');
  }
  final bytes = await buildDeterministicZipBytes(
      root: root, canonicalManifestJson: canonicalManifestJson);
  await out.parent.create(recursive: true);
  await out.writeAsBytes(bytes, flush: true);
  return sha256.convert(bytes).toString();
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
  final manifestArg = _value(args, '--canonical-manifest');
  if (releaseDirArg == null || outArg == null) {
    stderr.writeln('Usage: dart run tool/repro_zip.dart '
        '--release-dir <dir> --out <zip> '
        '[--canonical-manifest <full-manifest.json>]');
    exitCode = 64;
    return;
  }

  final releaseDir = Directory(releaseDirArg);
  if (!releaseDir.existsSync()) {
    stderr.writeln('Release directory not found: ${releaseDir.path}');
    exitCode = 66;
    return;
  }

  String? canonicalJson;
  if (manifestArg != null) {
    final manifestFile = File(manifestArg);
    if (!manifestFile.existsSync()) {
      stderr.writeln('Manifest not found: ${manifestFile.path}');
      exitCode = 66;
      return;
    }
    canonicalJson =
        canonicalSectionFromManifestJson(await manifestFile.readAsString());
  }

  final sha = await buildDeterministicZipFile(
    root: releaseDir,
    out: File(outArg),
    canonicalManifestJson: canonicalJson,
  );
  stdout.writeln('ZIP written: ${File(outArg).absolute.path} sha256=$sha');
}
