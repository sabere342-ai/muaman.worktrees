import 'dart:convert';
import 'dart:io';

const _defaultPackageUri =
    'package:_muaman_registrant/flutter_build/dart_plugin_registrant.dart';

const _canonicalRoot = r'\muaman\src';

void main(List<String> arguments) async {
  final args = _parseArgs(arguments);
  if (args == null) {
    stderr.writeln(
        'Usage: dart run tool/leak_scan.dart --release-dir=<dir> --forbidden=<s> [--expected-package-uri=<uri>] [--out=<json>]');
    exit(1);
  }

  final releaseDir = Directory(args.releaseDir);
  if (!releaseDir.existsSync()) {
    stderr.writeln('release-dir not found: ${args.releaseDir}');
    exit(1);
  }

  final forbidden = args.forbidden;
  final expectedPkgUri = args.expectedPackageUri;
  final fileResults = <_FileResult>[];

  for (final entry in _scanTargets(releaseDir)) {
    final bytes = await File(entry.path).readAsBytes();
    final relPath =
        entry.path.substring(releaseDir.path.length + 1).replaceAll('\\', '/');
    final forbiddenHits = <String, int>{};
    for (final pat in forbidden) {
      forbiddenHits[pat] = _countOccurrences(bytes, utf8.encode(pat));
    }

    int? pkgUriCount;
    if (expectedPkgUri != null && relPath == 'data/app.so') {
      pkgUriCount = _countOccurrences(bytes, utf8.encode(expectedPkgUri));
    }

    final canonicalCount =
        _countOccurrences(bytes, utf8.encode(_canonicalRoot));

    fileResults.add(_FileResult(
      path: relPath,
      sizeBytes: entry.size,
      forbiddenOccurrences: forbiddenHits,
      packageUriCount: pkgUriCount,
      canonicalRootCount: canonicalCount,
    ));
  }

  var totalForbiddenAll = 0;
  for (final f in fileResults) {
    totalForbiddenAll += f.forbiddenOccurrences.values.fold(0, (a, b) => a + b);
  }

  final appSoResult =
      fileResults.where((f) => f.path == 'data/app.so').firstOrNull;
  final pkgUriCountInAppSo = appSoResult?.packageUriCount;

  final allClear = totalForbiddenAll == 0 &&
      (expectedPkgUri == null || pkgUriCountInAppSo == 1);

  final json = {
    'schema': 'muaman-13e-leak-scan',
    'releaseDir': args.releaseDir,
    'forbidden': forbidden,
    'expectedPackageUri': expectedPkgUri,
    'files': fileResults.map((f) => f.toJson()).toList(),
    'totalForbiddenOccurrences': totalForbiddenAll,
    'allClear': allClear,
    'packageUriCountInAppSo': pkgUriCountInAppSo,
  };

  if (args.out != null) {
    File(args.out!).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }

  stdout.writeln(jsonEncode(json));

  if (!allClear) exit(1);
}

List<_ScanTarget> _scanTargets(Directory releaseDir) {
  final targets = <_ScanTarget>[];

  for (final rel in [
    'data/app.so',
    'muaman_store.exe',
    'printing_plugin.dll'
  ]) {
    final f = File('${releaseDir.path}\\$rel');
    if (f.existsSync()) {
      targets.add(_ScanTarget(path: f.path, size: f.lengthSync()));
    }
  }

  final dataDir = Directory('${releaseDir.path}\\data');
  if (dataDir.existsSync()) {
    for (final f in dataDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.dll') && !targets.any((t) => t.path == f.path)) {
        targets.add(_ScanTarget(path: f.path, size: f.lengthSync()));
      }
    }
  }

  for (final f in releaseDir.listSync().whereType<File>()) {
    if (f.path.endsWith('.dll') && !targets.any((t) => t.path == f.path)) {
      targets.add(_ScanTarget(path: f.path, size: f.lengthSync()));
    }
  }

  return targets;
}

int _countOccurrences(List<int> haystack, List<int> needle) {
  if (needle.isEmpty) return 0;
  var count = 0;
  final len = needle.length;
  outer:
  for (var i = 0; i <= haystack.length - len; i++) {
    for (var j = 0; j < len; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    count++;
    i += len - 1;
  }
  return count;
}

class _Args {
  final String releaseDir;
  final List<String> forbidden;
  final String? expectedPackageUri;
  final String? out;

  _Args(this.releaseDir, this.forbidden, this.expectedPackageUri, this.out);
}

_Args? _parseArgs(List<String> args) {
  String? releaseDir;
  final forbidden = <String>[];
  String? expectedPackageUri;
  String? out;

  for (final arg in args) {
    if (arg.startsWith('--release-dir=')) {
      releaseDir = arg.substring('--release-dir='.length);
    } else if (arg.startsWith('--forbidden=')) {
      forbidden.add(arg.substring('--forbidden='.length));
    } else if (arg.startsWith('--expected-package-uri=')) {
      expectedPackageUri = arg.substring('--expected-package-uri='.length);
    } else if (arg.startsWith('--out=')) {
      out = arg.substring('--out='.length);
    } else {
      return null;
    }
  }

  if (releaseDir == null || forbidden.isEmpty) return null;
  return _Args(
      releaseDir, forbidden, expectedPackageUri ?? _defaultPackageUri, out);
}

class _ScanTarget {
  final String path;
  final int size;
  _ScanTarget({required this.path, required this.size});
}

class _FileResult {
  final String path;
  final int sizeBytes;
  final Map<String, int> forbiddenOccurrences;
  final int? packageUriCount;
  final int canonicalRootCount;

  _FileResult({
    required this.path,
    required this.sizeBytes,
    required this.forbiddenOccurrences,
    this.packageUriCount,
    required this.canonicalRootCount,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'sizeBytes': sizeBytes,
        'forbiddenOccurrences': forbiddenOccurrences,
        if (packageUriCount != null) 'packageUriCount': packageUriCount,
        'canonicalRootCount': canonicalRootCount,
      };
}
