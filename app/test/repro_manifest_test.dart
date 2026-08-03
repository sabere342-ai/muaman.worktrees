import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/repro_manifest.dart';

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
  group('repro manifest: canonical determinism', () {
    test('same file tree produces byte-identical canonical manifests',
        () async {
      final a = await _tempDir('repro_manifest_same_a_');
      final b = await _tempDir('repro_manifest_same_b_');
      await _write(a, 'data/b.so', 'beta');
      await _write(a, 'a.txt', 'alpha');
      await _write(a, 'data/nested/c.bin', 'bytes');
      await _write(b, 'data/b.so', 'beta');
      await _write(b, 'a.txt', 'alpha');
      await _write(b, 'data/nested/c.bin', 'bytes');
      final canonicalA =
          renderCanonicalManifest(await buildCanonicalManifest(a));
      final canonicalB =
          renderCanonicalManifest(await buildCanonicalManifest(b));
      expect(canonicalA, canonicalB);
      expect(canonicalA, isNotEmpty);
    });

    test('files are sorted by relative path and paths are relative only',
        () async {
      final dir = await _tempDir('repro_manifest_sort_');
      await _write(dir, 'z.txt', 'z');
      await _write(dir, 'a/x.txt', 'ax');
      await _write(dir, 'b.txt', 'b');
      final canonical = await buildCanonicalManifest(dir);
      final files = (canonical['files'] as List).cast<Map<String, dynamic>>();
      final paths = files.map((f) => f['path'] as String).toList();
      final sorted = [...paths]..sort();
      expect(paths, sorted);
      for (final path in paths) {
        expect(path.startsWith('/'), isFalse, reason: '$path must be relative');
        expect(RegExp(r'^[A-Za-z]:/').hasMatch(path), isFalse,
            reason: '$path must not contain a drive letter');
        expect(path.split('/').contains('..'), isFalse,
            reason: '$path must not traverse');
      }
    });

    test('sha256, sizes, file count and total bytes are correct', () async {
      final dir = await _tempDir('repro_manifest_hash_');
      await _write(dir, 'a.txt', 'hello');
      final canonical = await buildCanonicalManifest(dir);
      expect(canonical['fileCount'], 1);
      expect(canonical['totalBytes'], 5);
      final files = (canonical['files'] as List).cast<Map<String, dynamic>>();
      expect(files.single['path'], 'a.txt');
      expect(files.single['sizeBytes'], 5);
      expect(
        files.single['sha256'],
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      );
    });

    test('canonical section never contains the absolute build path', () async {
      final dir = await _tempDir('repro_manifest_abspath_');
      await _write(dir, 'data/app.so', 'x');
      final canonicalJson =
          renderCanonicalManifest(await buildCanonicalManifest(dir));
      final normalizedRoot =
          dir.absolute.path.replaceAll(r'\', '/').toLowerCase();
      expect(canonicalJson.toLowerCase().contains(normalizedRoot), isFalse,
          reason: 'canonical JSON must not embed the machine build path');
      expect(RegExp(r'[A-Za-z]:/').hasMatch(canonicalJson), isFalse);
    });

    test('changing one file changes the canonical manifest', () async {
      final a = await _tempDir('repro_manifest_diff_a_');
      final b = await _tempDir('repro_manifest_diff_b_');
      await _write(a, 'a.txt', 'x');
      await _write(b, 'a.txt', 'y');
      final canonicalA = await buildCanonicalManifest(a);
      final canonicalB = await buildCanonicalManifest(b);
      expect(renderCanonicalManifest(canonicalA),
          isNot(renderCanonicalManifest(canonicalB)));
      final filesA = (canonicalA['files'] as List).cast<Map<String, dynamic>>();
      final filesB = (canonicalB['files'] as List).cast<Map<String, dynamic>>();
      expect(filesA.single['sizeBytes'], filesB.single['sizeBytes']);
      expect(filesA.single['sha256'], isNot(filesB.single['sha256']));
    });

    test('meta does not participate in canonical comparison', () async {
      final dir = await _tempDir('repro_manifest_meta_');
      await _write(dir, 'a.txt', 'x');
      final fullA = renderCanonicalManifest(buildFullManifest(
        canonical: await buildCanonicalManifest(dir),
        meta: const {'runId': 'run-1', 'builtAt': '2026-01-01T00:00:00Z'},
      ));
      final fullB = renderCanonicalManifest(buildFullManifest(
        canonical: await buildCanonicalManifest(dir),
        meta: const {'runId': 'run-2', 'builtAt': '2026-08-03T00:00:00Z'},
      ));
      expect(fullA, isNot(fullB));
      expect(canonicalSectionFromManifestJson(fullA),
          canonicalSectionFromManifestJson(fullB));
    });
  });
}
