import 'dart:io';

import 'release_package_verifier.dart';

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
  final releaseDir = _value(args, '--release-dir');
  final manifestPath = _value(args, '--manifest');
  final zipPath = _value(args, '--zip');
  final worktreePath = _value(args, '--worktree');
  final username = _value(args, '--username');

  if (releaseDir == null || manifestPath == null) {
    stderr.writeln('Usage: dart run tool/verify_release_package.dart '
        '--release-dir <dir> --manifest <file> '
        '[--zip <file>] [--worktree <path>] [--username <name>]');
    exitCode = 64;
    return;
  }

  final issues = await verifyReleasePackage(VerifyOptions(
    releaseDir: Directory(releaseDir),
    manifestFile: File(manifestPath),
    zipFile: zipPath != null ? File(zipPath) : null,
    worktreePath: worktreePath,
    username: username,
  ));

  if (issues.isEmpty) {
    stdout.writeln('VERIFY OK: all release-package guards passed.');
    exitCode = 0;
  } else {
    for (final issue in issues) {
      stderr.writeln(issue.toString());
    }
    stdout.writeln('VERIFY FAILED: ${issues.length} guard(s) violated.');
    exitCode = 1;
  }
}
