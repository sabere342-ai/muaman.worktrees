import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/repro_compare.dart';
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
  group('repro compare: directory equality', () {
    test('identical directories compare equal', () async {
      final a = await _tempDir('repro_cmp_id_a_');
      final b = await _tempDir('repro_cmp_id_b_');
      await _write(a, 'a.txt', 'x');
      await _write(a, 'data/b.so', 'y');
      await _write(b, 'a.txt', 'x');
      await _write(b, 'data/b.so', 'y');
      final r = await compareDirectories(a, b);
      expect(r['identical'], isTrue);
      expect(r['onlyInRun1'], isEmpty);
      expect(r['onlyInRun2'], isEmpty);
      expect(r['sizeMismatches'], isEmpty);
      expect(r['hashMismatches'], isEmpty);
      expect(r['run1FileCount'], 2);
      expect(r['run2FileCount'], 2);
      expect(r['run1TotalBytes'], r['run2TotalBytes']);
    });

    test('detects an extra file in run 1', () async {
      final a = await _tempDir('repro_cmp_extra_a_');
      final b = await _tempDir('repro_cmp_extra_b_');
      await _write(a, 'a.txt', 'x');
      await _write(a, 'extra.dll', 'e');
      await _write(b, 'a.txt', 'x');
      final r = await compareDirectories(a, b);
      expect(r['identical'], isFalse);
      expect(r['onlyInRun1'], ['extra.dll']);
    });

    test('detects a missing file in run 1 (extra in run 2)', () async {
      final a = await _tempDir('repro_cmp_missing_a_');
      final b = await _tempDir('repro_cmp_missing_b_');
      await _write(a, 'a.txt', 'x');
      await _write(b, 'a.txt', 'x');
      await _write(b, 'new.dll', 'n');
      final r = await compareDirectories(a, b);
      expect(r['identical'], isFalse);
      expect(r['onlyInRun2'], ['new.dll']);
    });

    test('detects a size mismatch', () async {
      final a = await _tempDir('repro_cmp_size_a_');
      final b = await _tempDir('repro_cmp_size_b_');
      await _write(a, 'a.txt', 'short');
      await _write(b, 'a.txt', 'a much longer content');
      final r = await compareDirectories(a, b);
      expect(r['identical'], isFalse);
      expect((r['sizeMismatches'] as List).single['path'], 'a.txt');
    });

    test('detects a hash mismatch even when sizes are equal', () async {
      final a = await _tempDir('repro_cmp_hash_a_');
      final b = await _tempDir('repro_cmp_hash_b_');
      await _write(a, 'a.txt', 'abcdef');
      await _write(b, 'a.txt', 'abcdeg');
      final r = await compareDirectories(a, b);
      expect(r['identical'], isFalse);
      expect(r['sizeMismatches'], isEmpty);
      final hm = (r['hashMismatches'] as List).cast<Map<String, dynamic>>();
      expect(hm.single['path'], 'a.txt');
      expect(hm.single['run1Sha256'], isNot(hm.single['run2Sha256']));
    });

    test('reports file counts and total bytes', () async {
      final a = await _tempDir('repro_cmp_counts_a_');
      final b = await _tempDir('repro_cmp_counts_b_');
      await _write(a, 'a.txt', '12345');
      await _write(b, 'a.txt', '12345');
      await _write(b, 'b.txt', '1');
      final r = await compareDirectories(a, b);
      expect(r['run1FileCount'], 1);
      expect(r['run2FileCount'], 2);
      expect(r['run1TotalBytes'], 5);
      expect(r['run2TotalBytes'], 6);
    });
  });

  group('repro compare: canonical manifest comparison', () {
    test('equal canonical sections report identical', () async {
      final dir = await _tempDir('repro_cmp_man_same_');
      await _write(dir, 'a.txt', 'x');
      final full = renderCanonicalManifest(buildFullManifest(
        canonical: await buildCanonicalManifest(dir),
        meta: const {'runId': 'run-1', 'builtAt': 't1'},
      ));
      expect(
        canonicalManifestDifference(manifest1Json: full, manifest2Json: full),
        isNull,
      );
    });

    test('changed content reports a difference', () async {
      final a = await _tempDir('repro_cmp_man_a_');
      final b = await _tempDir('repro_cmp_man_b_');
      await _write(a, 'a.txt', 'x');
      await _write(b, 'a.txt', 'y');
      final fullA = renderCanonicalManifest(buildFullManifest(
        canonical: await buildCanonicalManifest(a),
        meta: const {'runId': 'run-1'},
      ));
      final fullB = renderCanonicalManifest(buildFullManifest(
        canonical: await buildCanonicalManifest(b),
        meta: const {'runId': 'run-2'},
      ));
      expect(
        canonicalManifestDifference(manifest1Json: fullA, manifest2Json: fullB),
        isNotNull,
      );
    });
  });
}
