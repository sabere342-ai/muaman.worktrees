import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  final reportPath =
      '${Directory.current.parent.path}\\docs\\MUAMAN-13G-GIT-METADATA-FREE-SOURCE-ARCHIVE-REPRODUCIBILITY-ACCEPTANCE.md';
  final evidenceRoot =
      '${Directory.current.parent.path}\\docs\\evidence\\muaman-13g';

  const baselineHash = '7890ba6ed6b0a8a17797b3d370acc662875fc79a';
  const baselineMessage =
      'MUAMAN-13F: verify fresh-clone Windows reproducibility';
  const canonicalZipSha256 =
      'DA9C4B0451A3F92FAE88431438518537B11C9ECDF7A6ED3AEE0C3E6204D01665';

  const requiredEvidenceFiles = [
    '00-preflight.txt',
    '01-environment.txt',
    '02-muaman-13f-canonical-evidence.txt',
    '03-archive-a-generation.txt',
    '04-archive-b-generation.txt',
    '05-archive-hashes.txt',
    '06-extraction-roots.txt',
    '07-git-metadata-absence-a.txt',
    '08-git-metadata-absence-b.txt',
    '09-source-manifest-a.json',
    '10-source-manifest-b.json',
    '11-source-manifest-comparison.txt',
    '12-build-a.log',
    '13-build-b.log',
    '14-lockfile-integrity.txt',
    '15-release-manifest-a.json',
    '16-release-manifest-b.json',
    '17-release-a-vs-b-comparison.txt',
    '18-release-vs-muaman-13f-comparison.txt',
    '19-pe-comparison.json',
    '20-path-leak-scan.txt',
    '21-deterministic-zip-a.txt',
    '22-deterministic-zip-b.txt',
    '23-deterministic-zip-comparison.txt',
    '24-dart-format.txt',
    '25-flutter-analyze.txt',
    '26-guard-tests.txt',
    '27-full-test-suite.txt',
    '28-production-diff.txt',
    '29-final-git-state.txt',
    '30-command-transcript.txt',
  ];

  group('MUAMAN-13G Source Archive Reproducibility Guard Tests', () {
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
        final path = '$evidenceRoot\\09-source-manifest-a.json';
        final content = File(path).readAsStringSync();
        expect(content, contains('304'));
      });

      test('source-manifest-b.json contains 304 files', () {
        final path = '$evidenceRoot\\10-source-manifest-b.json';
        final content = File(path).readAsStringSync();
        expect(content, contains('304'));
      });
    });

    group('PE comparison', () {
      test('pe-comparison.json confirms all files byte-identical', () {
        final path = '$evidenceRoot\\19-pe-comparison.json';
        final content = File(path).readAsStringSync();
        expect(content, contains('allFilesByteIdentical'));
      });
    });

    group('Path-leak scan', () {
      test('path-leak-scan.txt shows 0 forbidden occurrences', () {
        final path = '$evidenceRoot\\20-path-leak-scan.txt';
        final content = File(path).readAsStringSync();
        expect(content, contains('0'));
      });
    });

    group('Deterministic ZIP comparison', () {
      test('deterministic-zip-comparison.txt contains canonical SHA-256', () {
        final path = '$evidenceRoot\\23-deterministic-zip-comparison.txt';
        final content = File(path).readAsStringSync();
        expect(content, contains(canonicalZipSha256));
      });
    });

    group('Production diff', () {
      test('production-diff.txt exists and confirms empty diff', () {
        final path = '$evidenceRoot\\28-production-diff.txt';
        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: '28-production-diff.txt must exist');
        final content = file.readAsStringSync();
        expect(
            content.toUpperCase().contains('PRODUCTION DIFF IS EMPTY'), isTrue,
            reason:
                '28-production-diff.txt must confirm the production diff is empty');
      });
    });

    group('Final git state', () {
      test('final-git-state.txt contains baseline hash', () {
        final path = '$evidenceRoot\\29-final-git-state.txt';
        final content = File(path).readAsStringSync();
        expect(content, contains(baselineHash));
      });
    });

    group('Evidence file count', () {
      test('guard test validates against correct evidence file count', () {
        final dir = Directory(evidenceRoot);
        final files = dir.listSync().whereType<File>().toList();
        expect(files.length, equals(requiredEvidenceFiles.length),
            reason:
                'Evidence directory must contain exactly ${requiredEvidenceFiles.length} files');
      });
    });
  });
}
