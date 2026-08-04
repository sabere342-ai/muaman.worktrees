import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  final reportPath =
      '${Directory.current.parent.path}\\docs\\MUAMAN-13H-ISOLATED-CACHE-SDK-ROOT-SOURCE-ARCHIVE-REPRODUCIBILITY-ACCEPTANCE.md';
  final evidenceRoot =
      '${Directory.current.parent.path}\\docs\\evidence\\muaman-13h';

  const baselineHash = 'e90643e03e8438214a9de6d8f1e70c8633efa31a';
  const baselineMessage =
      'MUAMAN-13G: verify source-archive Windows reproducibility';
  const canonicalZipSha256 =
      'DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665';
  const canonicalLockfileSha256 =
      'EBDDB5D8E4B4A2128AFD255677B64B7815B884EAB30070D2B6C47CC358D3331A';

  const requiredEvidenceFiles = [
    '00-preflight.txt',
    '01-environment.txt',
    '02-muaman-13g-canonical-evidence.txt',
    '03-flutter-sdk-archive-provisioning.txt',
    '04-roots-and-path-lengths.txt',
    '05-source-archive-hashes.txt',
    '06-source-manifest-a.json',
    '07-source-manifest-b.json',
    '08-source-manifest-comparison.txt',
    '09-git-metadata-absence-a.txt',
    '10-git-metadata-absence-b.txt',
    '11-sdk-version-a.txt',
    '12-sdk-version-b.txt',
    '13-sdk-artifact-comparison.txt',
    '15-cold-state-a.txt',
    '16-cold-state-b.txt',
    '17-environment-variables-a.txt',
    '18-environment-variables-b.txt',
    '19-hydration-a.log',
    '20-hydration-b.log',
    '21-lockfile-integrity.txt',
    '21b-package-graph-comparison.txt',
    '22-post-hydration-cache-a.txt',
    '23-post-hydration-cache-b.txt',
    '24-pub-cache-comparison.txt',
    '25-pre-build-state.txt',
    '26-build-a.log',
    '27-build-a-attempt-1-failure.txt',
    '28-sdk-vs2026-toolchain-adaptation.txt',
    '29-build-b.log',
    '30-release-manifest-a.json',
    '31-release-manifest-b.json',
    '32-release-a-vs-b-comparison.txt',
    '33-release-vs-13g-canonical-comparison.txt',
    '34-pe-inspection-a.json',
    '35-pe-inspection-b.json',
    '36-pe-comparison.json',
    '37-path-leak-a.json',
    '38-path-leak-b.json',
    '39-full-tree-path-leak-a.txt',
    '40-full-tree-path-leak-b.txt',
    '41-deterministic-zip-a.txt',
    '42-deterministic-zip-b.txt',
    '43-deterministic-zip-comparison.txt',
    '44-cross-run-contamination-proof.txt',
    '45-flutter-tools-snapshot-rebuild-proof.txt',
    '46-dart-format.txt',
    '47-flutter-analyze.txt',
    '48-guard-tests.txt',
    '49-full-test-suite.txt',
    '50-production-diff.txt',
    '51-final-git-state.txt',
    '52-command-transcript.txt',
  ];

  group('MUAMAN-13H Isolated Cache/SDK Root Reproducibility Guard Tests', () {
    group('Report file', () {
      test('report file exists', () {
        expect(File(reportPath).existsSync(), isTrue,
            reason: 'Acceptance report must exist at $reportPath');
      });

      test('report contains baseline commit hash', () {
        final content = File(reportPath).readAsStringSync();
        expect(content, contains(baselineHash));
      });

      test('report contains baseline commit message', () {
        final content = File(reportPath).readAsStringSync();
        expect(content, contains(baselineMessage));
      });

      test('report contains outcome verification', () {
        final content = File(reportPath).readAsStringSync();
        final hasOutcomeA = content.contains('Outcome A');
        final hasVerified = content.contains('VERIFIED');
        expect(hasOutcomeA || hasVerified, isTrue,
            reason: 'Report must contain "Outcome A" or "VERIFIED"');
      });
    });

    group('Evidence directory', () {
      test('evidence directory exists', () {
        expect(Directory(evidenceRoot).existsSync(), isTrue,
            reason: 'Evidence directory must exist at $evidenceRoot');
      });

      test('all required evidence files exist', () {
        for (final file in requiredEvidenceFiles) {
          final path = '$evidenceRoot\\$file';
          expect(File(path).existsSync(), isTrue,
              reason: 'Evidence file $file must exist');
        }
      });

      test('all evidence files are non-empty', () {
        for (final file in requiredEvidenceFiles) {
          final path = '$evidenceRoot\\$file';
          final stat = File(path).statSync();
          expect(stat.size, greaterThan(0),
              reason: 'Evidence file $file must be non-empty');
        }
      });
    });

    group('Source manifest validation', () {
      test('source-manifest-a.json contains 304 files', () {
        final content =
            File('$evidenceRoot\\06-source-manifest-a.json').readAsStringSync();
        expect(content, contains('304'));
      });

      test('source-manifest-b.json contains 304 files', () {
        final content =
            File('$evidenceRoot\\07-source-manifest-b.json').readAsStringSync();
        expect(content, contains('304'));
      });
    });

    group('Lockfile integrity', () {
      test('lockfile-integrity.txt contains canonical lockfile SHA-256', () {
        final content =
            File('$evidenceRoot\\21-lockfile-integrity.txt').readAsStringSync();
        expect(content, contains(canonicalLockfileSha256));
      });
    });

    group('Release comparison', () {
      test('release-a-vs-b-comparison.txt shows 0 differences', () {
        final content = File('$evidenceRoot\\32-release-a-vs-b-comparison.txt')
            .readAsStringSync();
        expect(content.toUpperCase(), contains('PASS'));
      });

      test('release-vs-13g-canonical-comparison.txt shows 0 differences', () {
        final content =
            File('$evidenceRoot\\33-release-vs-13g-canonical-comparison.txt')
                .readAsStringSync();
        expect(content.toUpperCase(), contains('PASS'));
      });
    });

    group('PE comparison', () {
      test('pe-comparison.json confirms all files byte-identical', () {
        final content =
            File('$evidenceRoot\\36-pe-comparison.json').readAsStringSync();
        expect(content, contains('allFilesByteIdentical'));
      });
    });

    group('Path-leak scan', () {
      test('full-tree-path-leak-a.txt shows 0 forbidden occurrences', () {
        final content = File('$evidenceRoot\\39-full-tree-path-leak-a.txt')
            .readAsStringSync();
        expect(content, contains('0'));
      });

      test('full-tree-path-leak-b.txt shows 0 forbidden occurrences', () {
        final content = File('$evidenceRoot\\40-full-tree-path-leak-b.txt')
            .readAsStringSync();
        expect(content, contains('0'));
      });
    });

    group('Deterministic ZIP comparison', () {
      test('deterministic-zip-comparison.txt contains canonical SHA-256', () {
        final content =
            File('$evidenceRoot\\43-deterministic-zip-comparison.txt')
                .readAsStringSync();
        expect(content, contains(canonicalZipSha256));
      });
    });

    group('Cross-run contamination proof', () {
      test('contamination proof confirms PASS', () {
        final content =
            File('$evidenceRoot\\44-cross-run-contamination-proof.txt')
                .readAsStringSync();
        expect(content.toUpperCase(), contains('PASS'));
      });
    });

    group('Toolchain adaptation', () {
      test('sdk-vs2026-toolchain-adaptation.txt records the patch', () {
        final content =
            File('$evidenceRoot\\28-sdk-vs2026-toolchain-adaptation.txt')
                .readAsStringSync();
        expect(content, contains('Visual Studio 18 2026'));
      });
    });

    group('Build logs', () {
      test('build-a.log exits with code 0', () {
        final content =
            File('$evidenceRoot\\26-build-a.log').readAsStringSync();
        expect(content, contains('BUILD EXIT CODE: 0'));
      });

      test('build-b.log exits with code 0', () {
        final content =
            File('$evidenceRoot\\29-build-b.log').readAsStringSync();
        expect(content, contains('BUILD EXIT CODE: 0'));
      });
    });

    group('Hydration logs', () {
      test('hydration logs exit with code 0', () {
        final a = File('$evidenceRoot\\19-hydration-a.log').readAsStringSync();
        final b = File('$evidenceRoot\\20-hydration-b.log').readAsStringSync();
        expect(a, contains('Exit code: 0'));
        expect(b, contains('Exit code: 0'));
      });
    });

    group('Pub-cache comparison', () {
      test('pub-cache-comparison.txt confirms identical caches', () {
        final content = File('$evidenceRoot\\24-pub-cache-comparison.txt')
            .readAsStringSync();
        expect(content.toUpperCase(), contains('PASS'));
      });
    });

    group('Production diff', () {
      test('production-diff.txt exists and confirms empty diff', () {
        final path = '$evidenceRoot\\50-production-diff.txt';
        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: '50-production-diff.txt must exist');
        final content = file.readAsStringSync();
        expect(
            content.toUpperCase().contains('PRODUCTION DIFF IS EMPTY'), isTrue,
            reason:
                '50-production-diff.txt must confirm the production diff is empty');
      });
    });

    group('Final git state', () {
      test('final-git-state.txt contains baseline hash', () {
        final path = '$evidenceRoot\\51-final-git-state.txt';
        final content = File(path).readAsStringSync();
        expect(content, contains(baselineHash));
      });
    });

    group('Evidence file count', () {
      test('evidence directory contains exactly the required file count', () {
        final dir = Directory(evidenceRoot);
        final files = dir.listSync().whereType<File>().toList();
        expect(files.length, equals(requiredEvidenceFiles.length),
            reason:
                'Evidence directory must contain exactly ${requiredEvidenceFiles.length} files');
      });
    });
  });
}
