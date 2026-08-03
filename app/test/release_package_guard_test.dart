import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/release_package_verifier.dart';

void main() {
  group('release package guard: sha256', () {
    test('accepts a full 64-hex lowercase digest', () {
      expect(
        isFullSha256('a' * 64),
        isTrue,
        reason: '64 lowercase hex characters must be accepted',
      );
      expect(
        isFullSha256('ab12' * 16),
        isTrue,
      );
    });

    test('rejects short, long, uppercase and non-hex values', () {
      expect(isFullSha256('a' * 63), isFalse);
      expect(isFullSha256('a' * 65), isFalse);
      expect(isFullSha256('A' * 64), isFalse);
      expect(isFullSha256('g' * 64), isFalse);
      expect(isFullSha256(''), isFalse);
    });
  });

  group('release package guard: relative paths', () {
    test('accepts release-relative paths', () {
      expect(isRelativePath('muaman_store.exe'), isTrue);
      expect(isRelativePath('flutter_windows.dll'), isTrue);
      expect(isRelativePath('data/app.so'), isTrue);
      expect(isRelativePath('data/flutter_assets/AssetManifest.json'), isTrue);
    });

    test('rejects absolute, drive-letter and traversal paths', () {
      expect(isRelativePath('/etc/passwd'), isFalse);
      expect(isRelativePath(r'C:\Windows\system32'), isFalse);
      expect(isRelativePath('C:/Windows/system32'), isFalse);
      expect(isRelativePath('../outside'), isFalse);
      expect(isRelativePath('data/../../muaman_store.exe'), isFalse);
    });
  });

  group('release package guard: path normalization', () {
    test('normalizes backslashes to forward slashes', () {
      expect(normalizeRelativePath(r'data\app.so'), 'data/app.so');
      expect(normalizeRelativePath('data/app.so'), 'data/app.so');
    });
  });

  group('release package guard: sensitive location', () {
    test('detects worktree path fragment', () {
      expect(
        pathExposesSensitiveLocation(
          r'C:\dev\muaman.worktrees\muaman-13a-clean-release-provenance\app.so',
          worktreePath:
              r'C:\dev\muaman.worktrees\muaman-13a-clean-release-provenance',
        ),
        isTrue,
      );
      expect(
        pathExposesSensitiveLocation('data/app.so',
            worktreePath: 'C:/dev/somewhere-else'),
        isFalse,
      );
    });

    test('detects username fragment', () {
      expect(
        pathExposesSensitiveLocation('users/saber/secret/app.so',
            username: 'saber'),
        isTrue,
      );
      expect(
        pathExposesSensitiveLocation('data/app.so', username: 'saber'),
        isFalse,
      );
    });
  });

  group('release package guard: deterministic ordering', () {
    test('sorts manifest files deterministically by normalized path', () {
      final files = [
        {'path': r'data\b.so', 'sizeBytes': 1, 'sha256': 'a' * 64},
        {'path': 'muaman_store.exe', 'sizeBytes': 1, 'sha256': 'a' * 64},
        {'path': 'data/a.so', 'sizeBytes': 1, 'sha256': 'a' * 64},
      ];
      final sorted = sortedManifestFiles(files);
      expect(
        sorted.map((e) => e['path']).toList(),
        ['data/a.so', r'data\b.so', 'muaman_store.exe'],
      );
      expect(
        sorted.map((e) => e['path']).toList(),
        sortedManifestFiles(files).map((e) => e['path']).toList(),
        reason: 'sorting must be stable and repeatable',
      );
    });
  });

  group('release package guard: gitignore protects build artifacts', () {
    test('.gitignore ignores the build directory', () {
      final gitignore = File('.gitignore');
      expect(gitignore.existsSync(), isTrue,
          reason: 'app/.gitignore must exist');
      final content = gitignore.readAsStringSync();
      expect(content, contains('/build/'));
      expect(content, contains('.dart_tool/'));
    });
  });
}
