import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/repro_manifest.dart';
import '../tool/repro_zip.dart';

Future<Directory> _tempDir(String prefix) async {
  final dir = await Directory.systemTemp.createTemp(prefix);
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return dir;
}

Future<void> _write(Directory root, String rel, String content) async {
  final file = File('${root.path}/$rel');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

void main() {
  group('repro zip: determinism', () {
    test('same inputs produce byte-identical zips', () async {
      final dir = await _tempDir('repro_zip_same_');
      final outDir = await _tempDir('repro_zip_same_out_');
      await _write(dir, 'data/app.so', 'snapshot');
      await _write(dir, 'muaman_store.exe', 'exe');
      final zip1 = File('${outDir.path}/out1.zip');
      final zip2 = File('${outDir.path}/out2.zip');
      final sha1 = await buildDeterministicZipFile(root: dir, out: zip1);
      final sha2 = await buildDeterministicZipFile(root: dir, out: zip2);
      expect(sha1, sha2);
      expect(zip1.readAsBytesSync(), zip2.readAsBytesSync());
    });

    test('output inside the release directory is rejected', () async {
      final dir = await _tempDir('repro_zip_guard_');
      await _write(dir, 'a.txt', 'x');
      expect(
        () => buildDeterministicZipFile(
            root: dir, out: File('${dir.path}/out.zip')),
        throwsArgumentError,
      );
    });

    test('entries are sorted lexicographically', () async {
      final dir = await _tempDir('repro_zip_sort_');
      final outDir = await _tempDir('repro_zip_sort_out_');
      await _write(dir, 'z.txt', 'z');
      await _write(dir, 'a/x.txt', 'ax');
      await _write(dir, 'b.txt', 'b');
      final zip = File('${outDir.path}/out.zip');
      await buildDeterministicZipFile(root: dir, out: zip);
      final archive = ZipDecoder().decodeBytes(zip.readAsBytesSync());
      final names = archive.files.map((f) => f.name).toList();
      final sorted = [...names]..sort();
      expect(names, sorted);
    });

    test('entry timestamps are fixed', () async {
      final dir = await _tempDir('repro_zip_time_');
      final outDir = await _tempDir('repro_zip_time_out_');
      await _write(dir, 'a.txt', 'x');
      await _write(dir, 'b.txt', 'y');
      final zip = File('${outDir.path}/out.zip');
      await buildDeterministicZipFile(root: dir, out: zip);
      final archive = ZipDecoder().decodeBytes(zip.readAsBytesSync());
      expect(archive.files, isNotEmpty);
      final times = archive.files.map((f) => f.lastModTime).toSet();
      expect(times, {kZipFixedTimestampDosPacked});
    });

    test('no absolute paths and no .. entries', () async {
      final dir = await _tempDir('repro_zip_paths_');
      final outDir = await _tempDir('repro_zip_paths_out_');
      await _write(dir, 'data/app.so', 'x');
      final zip = File('${outDir.path}/out.zip');
      await buildDeterministicZipFile(root: dir, out: zip);
      final archive = ZipDecoder().decodeBytes(zip.readAsBytesSync());
      for (final f in archive.files) {
        final name = f.name.replaceAll(r'\', '/');
        expect(name.startsWith('/'), isFalse, reason: '$name must be relative');
        expect(RegExp(r'^[A-Za-z]:/').hasMatch(name), isFalse,
            reason: '$name must not contain a drive letter');
        expect(name.split('/').contains('..'), isFalse,
            reason: '$name must not traverse');
      }
    });

    test('changing one file changes the zip sha256', () async {
      final a = await _tempDir('repro_zip_change_a_');
      final b = await _tempDir('repro_zip_change_b_');
      final outDir = await _tempDir('repro_zip_change_out_');
      await _write(a, 'a.txt', 'x');
      await _write(a, 'b.txt', 'same');
      await _write(b, 'a.txt', 'y');
      await _write(b, 'b.txt', 'same');
      final sha1 = await buildDeterministicZipFile(
          root: a, out: File('${outDir.path}/o1.zip'));
      final sha2 = await buildDeterministicZipFile(
          root: b, out: File('${outDir.path}/o2.zip'));
      expect(sha1, isNot(sha2));
    });

    test('canonical manifest is embedded with fixed content', () async {
      final dir = await _tempDir('repro_zip_manifest_');
      final outDir = await _tempDir('repro_zip_manifest_out_');
      await _write(dir, 'a.txt', 'x');
      final canonical =
          renderCanonicalManifest(await buildCanonicalManifest(dir));
      final zip = File('${outDir.path}/out.zip');
      await buildDeterministicZipFile(
        root: dir,
        out: zip,
        canonicalManifestJson: canonical,
      );
      final archive = ZipDecoder().decodeBytes(zip.readAsBytesSync());
      final entry =
          archive.files.where((f) => f.name == kZipCanonicalManifestEntryName);
      expect(entry, hasLength(1));
      final content = utf8.decode(entry.single.content as List<int>);
      expect(content, canonical);
    });
  });
}
