import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MUAMAN-13F: fresh-clone reproducibility guard', () {
    final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');

    test('tool script exists', () {
      expect(tool.existsSync(), isTrue,
          reason:
              'app/tool/muaman13f_fresh_clone_reproducibility.ps1 must exist');
    });

    final content = tool.existsSync() ? tool.readAsStringSync() : '';

    test('uses git clone --no-local', () {
      expect(content, contains('clone --no-local'),
          reason: 'must use git clone --no-local, not worktree or copy');
    });

    test('rejects git worktree usage', () {
      expect(content, isNot(contains('git worktree add')),
          reason: 'must not use git worktree add');
    });

    test('rejects source tree copy', () {
      expect(content, isNot(contains('Copy-Item -Recurse')),
          reason: 'must not copy source trees');
    });

    test('checks Git HEAD in both clones', () {
      expect(content, contains('Clone A'),
          reason: 'must reference Clone A');
      expect(content, contains('Clone B'),
          reason: 'must reference Clone B');
      expect(content, contains('rev-parse HEAD'),
          reason: 'must verify HEAD via rev-parse');
    });

    test('checks for alternates', () {
      expect(content, contains('alternates'),
          reason: 'must check for Git object alternates');
      expect(content, contains('INDEPENDENCE VIOLATION'),
          reason: 'must reject clones with alternates');
    });

    test('runs flutter clean', () {
      expect(content, contains('flutter clean'),
          reason: 'must run flutter clean before build');
    });

    test('runs flutter pub get', () {
      expect(content, contains('pub get'),
          reason: 'must run flutter pub get');
    });

    test('runs flutter build windows --release', () {
      expect(content, contains('build windows --release'),
          reason: 'must run flutter build windows --release');
    });

    test('generates file manifest', () {
      expect(content, contains('Get-ReleaseManifest'),
          reason: 'must generate release file manifest');
    });

    test('compares file counts between clones', () {
      expect(content, contains('fileCount'),
          reason: 'must compare file counts');
    });

    test('compares total bytes between clones', () {
      expect(content, contains('totalBytes'),
          reason: 'must compare total byte counts');
    });

    test('checks individual file sizes', () {
      expect(content, contains('sizeBytes'),
          reason: 'must compare individual file sizes');
    });

    test('verifies SHA-256 per file', () {
      expect(content, contains('sha256'),
          reason: 'must compare SHA-256 hashes per file');
    });

    test('performs binary comparison', () {
      expect(content, contains('Binary comparison'),
          reason: 'must perform byte-for-byte binary comparison');
    });

    test('creates deterministic ZIP', () {
      expect(content, contains('repro_zip'),
          reason: 'must create deterministic ZIP archives');
    });

    test('compares ZIP outputs', () {
      expect(content, contains('zipHash'),
          reason: 'must compare ZIP SHA-256 hashes');
    });

    test('runs PE inspection', () {
      expect(content, contains('pe_inspect'),
          reason: 'must inspect PE files');
    });

    test('runs path leak scan', () {
      expect(content, contains('leak_scan'),
          reason: 'must scan for path leaks');
    });

    test('generates machine-readable JSON output', () {
      expect(content, contains('acceptance-summary.json'),
          reason: 'must generate machine-readable acceptance summary');
    });

    test('exits with error on failure', () {
      expect(content, contains('throw'),
          reason: 'must throw/exit non-zero on any gate failure');
    });
  });

  group('MUAMAN-13F: leak scan UTF-16LE coverage', () {
    final leakScan = File('tool/leak_scan.dart');
    final leakContent =
        leakScan.existsSync() ? leakScan.readAsStringSync() : '';

    test('leak_scan.dart exists', () {
      expect(leakScan.existsSync(), isTrue,
          reason: 'app/tool/leak_scan.dart must exist');
    });

    test('scans for UTF-8 encoded forbidden paths', () {
      expect(leakContent, contains('utf8.encode'),
          reason: 'must scan UTF-8 encoded forbidden strings');
    });

    test('scans for UTF-16LE encoded forbidden paths', () {
      expect(leakContent, contains('utf16le'),
          reason: 'must scan UTF-16LE encoded forbidden strings');
    });

    test('reports both UTF-8 and UTF-16LE occurrences', () {
      expect(leakContent, contains('utf8Occurrences'),
          reason: 'must report UTF-8 hit count separately');
      expect(leakContent, contains('utf16leOccurrences'),
          reason: 'must report UTF-16LE hit count separately');
    });
  });

  group('MUAMAN-13F: baseline provenance', () {
    test('baseline SHA is hardcoded in tool script', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(content,
            contains('47f95000db103194e67e90795cf3b55652df1d64'),
            reason: 'baseline SHA must be the full 40-character hash');
      }
    });

    test('baseline message is verified', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(
            content,
            contains(
                'MUAMAN-13E: prove cross-path reproducible Windows releases'),
            reason: 'must verify baseline commit message');
      }
    });
  });

  group('MUAMAN-13F: clone path length verification', () {
    test('tool records path lengths for both clones', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(content, contains('pathLength'),
            reason: 'must record path lengths');
        expect(content, contains('Path length delta'),
            reason: 'must compute path length delta');
      }
    });

    test('clone paths must be different', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(content, contains('ClonePathA -eq'),
            reason: 'must reject equal clone paths');
        expect(content, contains('Clone paths must be different'),
            reason: 'must throw on equal clone paths');
      }
    });
  });

  group('MUAMAN-13F: evidence directory', () {
    test('docs/evidence/muaman-13f/ directory exists at repo root', () {
      final dir = Directory('../docs/evidence/muaman-13f');
      expect(dir.existsSync(), isTrue,
          reason: 'docs/evidence/muaman-13f/ must exist at repo root');
    });
  });

  group('MUAMAN-13F: tool script error handling', () {
    test('uses strict error handling', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(content, contains('ErrorActionPreference'),
            reason: 'must set ErrorActionPreference');
        expect(content, contains(RegExp(r'\bContinue\b')),
            reason: 'must use Continue to avoid stderr-2>&1 terminating on git output');
      }
    });

    test('uses strict mode', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(content, contains('Set-StrictMode'),
            reason: 'must use strict mode');
      }
    });
  });

  group('MUAMAN-13F: no local state dependency', () {
    test('tool does not copy artifacts between clones', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(content, isNot(contains('Copy-Item -Path')),
            reason: 'must not copy artifacts between clones');
      }
    });

    test('tool verifies no .dart_tool before build', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(content, contains('dart_tool'),
            reason: 'must verify no .dart_tool exists before build');
      }
    });

    test('tool checks no build/ before build', () {
      final tool = File('tool/muaman13f_fresh_clone_reproducibility.ps1');
      if (tool.existsSync()) {
        final content = tool.readAsStringSync();
        expect(content, contains('Pre-build cleanliness'),
            reason: 'must verify clean state before build');
      }
    });
  });
}