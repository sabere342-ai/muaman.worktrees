import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

final RegExp _fullSha256 = RegExp(r'^[0-9a-f]{64}$');

bool isFullSha256(String value) => _fullSha256.hasMatch(value);

String normalizeRelativePath(String path) => path.replaceAll(r'\', '/');

bool isRelativePath(String path) {
  final normalized = normalizeRelativePath(path);
  if (normalized.startsWith('/')) return false;
  if (RegExp(r'^[A-Za-z]:/').hasMatch(normalized)) return false;
  if (normalized.split('/').contains('..')) return false;
  return true;
}

bool pathExposesSensitiveLocation(
  String path, {
  String? worktreePath,
  String? username,
}) {
  final normalized = normalizeRelativePath(path).toLowerCase();
  final worktree = worktreePath?.replaceAll(r'\', '/').toLowerCase();
  final user = username?.toLowerCase();
  if (worktree != null &&
      worktree.isNotEmpty &&
      normalized.contains(worktree)) {
    return true;
  }
  if (user != null && user.isNotEmpty && normalized.contains(user)) {
    return true;
  }
  return false;
}

List<Map<String, dynamic>> sortedManifestFiles(
  List<Map<String, dynamic>> files,
) {
  final copy = [...files];
  copy.sort((a, b) {
    final pa = normalizeRelativePath(a['path'] as String);
    final pb = normalizeRelativePath(b['path'] as String);
    return pa.compareTo(pb);
  });
  return copy;
}

Future<Map<String, dynamic>> readManifest(File file) async {
  final decoded = jsonDecode(await file.readAsString());
  return decoded as Map<String, dynamic>;
}

Future<String> fileSha256(File file) async {
  final bytes = await file.readAsBytes();
  return sha256.convert(bytes).toString();
}

class VerificationIssue {
  const VerificationIssue(this.check, this.detail);

  final String check;
  final String detail;

  @override
  String toString() => 'FAIL [$check] $detail';
}

class VerifyOptions {
  const VerifyOptions({
    required this.releaseDir,
    required this.manifestFile,
    this.zipFile,
    this.worktreePath,
    this.username,
  });

  final Directory releaseDir;
  final File manifestFile;
  final File? zipFile;
  final String? worktreePath;
  final String? username;
}

Future<List<VerificationIssue>> verifyReleasePackage(
  VerifyOptions options,
) async {
  final issues = <VerificationIssue>[];
  final manifest = await readManifest(options.manifestFile);
  final rawFiles = manifest['files'] as List<dynamic>;
  final entries = rawFiles.cast<Map<String, dynamic>>();

  if (entries.isEmpty) {
    issues
        .add(const VerificationIssue('manifest-not-empty', 'no files listed'));
  }

  for (final entry in entries) {
    final relPath = entry['path'] as String;
    final sha = entry['sha256'] as String;
    final size = entry['sizeBytes'] as int;

    if (!isFullSha256(sha)) {
      issues.add(VerificationIssue('sha256-full-length', '$relPath -> "$sha"'));
    }
    if (!isRelativePath(relPath)) {
      issues.add(VerificationIssue('relative-path', relPath));
    }
    if (pathExposesSensitiveLocation(relPath,
        worktreePath: options.worktreePath, username: options.username)) {
      issues.add(VerificationIssue(
          'no-sensitive-location', 'path exposes location: $relPath'));
    }

    final actual = File(p.join(options.releaseDir.path, relPath));
    if (!actual.existsSync()) {
      issues.add(VerificationIssue('file-exists', '$relPath is missing'));
      continue;
    }
    if (actual.lengthSync() != size) {
      issues.add(VerificationIssue(
          'file-size', '$relPath expected $size got ${actual.lengthSync()}'));
    }
    if (await fileSha256(actual) != sha) {
      issues.add(VerificationIssue('file-sha256', '$relPath hash mismatch'));
    }
  }

  final expectedOrder =
      sortedManifestFiles(entries).map((e) => e['path'] as String).toList();
  final actualOrder = entries.map((e) => e['path'] as String).toList();
  if (expectedOrder.join('\n') != actualOrder.join('\n')) {
    issues.add(const VerificationIssue(
        'deterministic-sort', 'manifest file list is not sorted by path'));
  }

  final manifestRaw = jsonEncode(manifest);
  final worktree = options.worktreePath?.replaceAll(r'\', '/').toLowerCase();
  final user = options.username?.toLowerCase();
  if (worktree != null &&
      worktree.isNotEmpty &&
      manifestRaw.toLowerCase().contains(worktree)) {
    issues.add(const VerificationIssue(
        'no-worktree-path', 'manifest exposes worktree path'));
  }
  if (user != null &&
      user.isNotEmpty &&
      manifestRaw.toLowerCase().contains(user)) {
    issues.add(
        const VerificationIssue('no-username', 'manifest exposes username'));
  }

  final exe = File(p.join(options.releaseDir.path, 'muaman_store.exe'));
  final dll = File(p.join(options.releaseDir.path, 'flutter_windows.dll'));
  final dataDir = Directory(p.join(options.releaseDir.path, 'data'));
  if (!exe.existsSync()) {
    issues.add(const VerificationIssue(
        'executable-present', 'muaman_store.exe missing'));
  }
  if (!dll.existsSync()) {
    issues.add(const VerificationIssue(
        'flutter-dll-present', 'flutter_windows.dll missing'));
  }
  if (!dataDir.existsSync()) {
    issues.add(
        const VerificationIssue('data-dir-present', 'data/ directory missing'));
  }

  final xlsxInRelease = options.releaseDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.xlsx'))
      .toList();
  if (xlsxInRelease.isNotEmpty) {
    issues.add(VerificationIssue('no-user-owned-workbook',
        'release dir contains xlsx: ${xlsxInRelease.map((f) => f.path).join(', ')}'));
  }

  final zipFile = options.zipFile;
  if (zipFile != null) {
    if (!zipFile.existsSync()) {
      issues.add(VerificationIssue('zip-exists', '${zipFile.path} missing'));
    } else {
      late Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      } catch (e) {
        issues.add(VerificationIssue('zip-decode', 'zip is corrupt: $e'));
        return issues;
      }
      final names =
          archive.files.map((f) => normalizeRelativePath(f.name)).toList();
      for (final name in names) {
        if (name == '.git' ||
            name.startsWith('.git/') ||
            name.contains('/.git/') ||
            name.contains('/.git')) {
          issues.add(VerificationIssue(
              'zip-no-git', 'zip contains git metadata: $name'));
        }
        if (name.contains('/build/') || name.startsWith('build/')) {
          issues.add(VerificationIssue(
              'zip-no-build-intermediates', 'zip contains build path: $name'));
        }
        if (name.endsWith('.dart')) {
          issues.add(VerificationIssue(
              'zip-no-source', 'zip contains source file: $name'));
        }
        if (name.endsWith('.xlsx')) {
          issues.add(VerificationIssue(
              'zip-no-user-owned-workbook', 'zip contains workbook: $name'));
        }
        if (name.contains('/test/') || name.startsWith('test/')) {
          issues.add(VerificationIssue(
              'zip-no-tests', 'zip contains test file: $name'));
        }
      }
      final exeEntry =
          archive.files.where((f) => f.name == 'muaman_store.exe').toList();
      if (exeEntry.isEmpty) {
        issues.add(const VerificationIssue(
            'zip-executable-present', 'zip has no muaman_store.exe'));
      }
    }
  }

  return issues;
}
