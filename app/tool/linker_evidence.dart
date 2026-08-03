/// Reads the actual, generated MSBuild command descriptions (the `*.vcxproj`
/// files that CMake produces inside `build/windows/x64/`) and emits machine
/// readable evidence that the `/Brepro` linker option reaches every required
/// target (executable + shared libraries) in the Release configuration.
///
/// This inspects the *generated* build commands (not the source configuration)
/// and, when an MSBuild diagnostic log is supplied, also records the exact
/// `link.exe` command line that was executed.
///
/// Usage:
///   dart run tool/linker_evidence.dart \
///     --run-id <id> \
///     --linker-path <link.exe> \
///     --linker-version <version> \
///     --vcxproj <path> [--vcxproj <path> ...] \
///     --diag-log <msbuild -v:diag log> \
///     --out <json>
library;

import 'dart:convert';
import 'dart:io';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

String _normalize(String path) => path.replaceAll(r'\', '/');

String? _firstTag(String text, String tag) {
  final m = RegExp('<$tag>([\\s\\S]*?)</$tag>').firstMatch(text);
  return m?.group(1);
}

/// Matches the Release-condition attribute that CMake writes into generated
/// MSBuild project files, e.g.
/// `Condition="'$(Configuration)|$(Platform)'=='Release|x64'"`.
const String _releaseConditionAttr =
    r'''Condition="'\$\(Configuration\)\|\$\(Platform\)'=='Release\|[^']*'">''';

/// Extracts the `Condition="'$(Configuration)|$(Platform)'=='Release|<plat>'"`
/// element content for [tag] inside [xml].
String? _releaseConditionTag(String xml, String tag) {
  final re = RegExp(
    '<$tag $_releaseConditionAttr([\\s\\S]*?)</$tag>',
  );
  final m = re.firstMatch(xml);
  return m?.group(1);
}

/// Extracts the `<ItemDefinitionGroup>` whose condition matches the Release
/// configuration, or null when absent.
String? _releaseItemDefinitionGroup(String xml) {
  final re = RegExp(
    '<ItemDefinitionGroup $_releaseConditionAttr([\\s\\S]*?)'
    '</ItemDefinitionGroup>',
  );
  final m = re.firstMatch(xml);
  return m?.group(1);
}

String? _targetNameFromVcxproj(String xml) {
  final projectName = _firstTag(xml, 'ProjectName');
  return projectName?.trim();
}

/// Parsed link evidence for one CMake target.
class TargetLinkEvidence {
  const TargetLinkEvidence({
    required this.targetName,
    required this.outputPath,
    required this.configuration,
    required this.additionalOptions,
    required this.additionalDependencies,
    required this.programDataBaseFile,
    required this.importLibrary,
    required this.subSystem,
    required this.generateDebugInformation,
    required this.linkIncremental,
    required this.breproPresent,
    required this.breproOccurrences,
    this.linkCommand,
  });

  final String targetName;
  final String outputPath;
  final String configuration;
  final String additionalOptions;
  final String additionalDependencies;
  final String programDataBaseFile;
  final String importLibrary;
  final String subSystem;
  final String generateDebugInformation;
  final String linkIncremental;
  final bool breproPresent;
  final int breproOccurrences;
  final String? linkCommand;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'targetName': targetName,
        'outputPath': outputPath,
        'configuration': configuration,
        'linkerFlags': additionalOptions,
        'additionalOptions': additionalOptions,
        'additionalDependencies': additionalDependencies
            .split(';')
            .where((final s) => s.isNotEmpty)
            .toList(),
        'programDataBaseFile': programDataBaseFile,
        'importLibrary': importLibrary,
        'subSystem': subSystem,
        'generateDebugInformation': generateDebugInformation,
        'linkIncremental': linkIncremental,
        'breproPresent': breproPresent,
        'breproOccurrences': breproOccurrences,
        'linkCommand': linkCommand,
      };
}

int _countBrepro(String options) {
  final matches = RegExp('/[Bb][Rr][Ee][Pp][Rr][Oo]').allMatches(options);
  var count = 0;
  for (final m in matches) {
    // Only count genuine /Brepro tokens (preceded by a delimiter).
    final start = m.start;
    if (start == 0 || options[start - 1] == ' ' || options[start - 1] == '\t') {
      count++;
    }
  }
  return count;
}

/// Parses a generated `*.vcxproj` and returns the Release-configuration link
/// evidence for it.
TargetLinkEvidence parseVcxprojLinkEvidence(String xml, {String? linkCommand}) {
  final targetName = _targetNameFromVcxproj(xml) ?? '';
  final outDir = _releaseConditionTag(xml, 'OutDir') ?? '';
  final targetExt = _releaseConditionTag(xml, 'TargetExt') ?? '';
  final targetNameValue = _releaseConditionTag(xml, 'TargetName') ?? targetName;
  final outputPath = _normalize('$outDir$targetNameValue$targetExt');

  final releaseGroup = _releaseItemDefinitionGroup(xml);
  final linkBlock =
      releaseGroup == null ? null : _firstTag(releaseGroup, 'Link');
  final additionalOptions = linkBlock == null
      ? ''
      : (_firstTag(linkBlock, 'AdditionalOptions') ?? '');
  final additionalDependencies = linkBlock == null
      ? ''
      : (_firstTag(linkBlock, 'AdditionalDependencies') ?? '');
  final programDataBaseFile = linkBlock == null
      ? ''
      : (_firstTag(linkBlock, 'ProgramDataBaseFile') ?? '');
  final importLibrary =
      linkBlock == null ? '' : (_firstTag(linkBlock, 'ImportLibrary') ?? '');
  final subSystem =
      linkBlock == null ? '' : (_firstTag(linkBlock, 'SubSystem') ?? '');
  final generateDebugInformation = linkBlock == null
      ? ''
      : (_firstTag(linkBlock, 'GenerateDebugInformation') ?? '');

  final linkIncremental = _releaseConditionTag(xml, 'LinkIncremental') ?? '';

  return TargetLinkEvidence(
    targetName: targetName,
    outputPath: outputPath,
    configuration: 'Release|x64',
    additionalOptions: additionalOptions,
    additionalDependencies: additionalDependencies,
    programDataBaseFile: _normalize(programDataBaseFile),
    importLibrary: _normalize(importLibrary),
    subSystem: subSystem,
    generateDebugInformation: generateDebugInformation,
    linkIncremental: linkIncremental,
    breproPresent: _countBrepro(additionalOptions) > 0,
    breproOccurrences: _countBrepro(additionalOptions),
    linkCommand: linkCommand,
  );
}

/// Searches an MSBuild `-v:diag` log for the executed `link.exe` command that
/// produced [outputPath] and returns the full command line, or null.
String? extractLinkCommandFromDiagLog(String log, String outputPath) {
  final outputName = outputPath.split('/').last;
  for (final line in const LineSplitter().convert(log)) {
    if (line.contains('link.exe') &&
        line.contains('/OUT:') &&
        line.contains(outputName)) {
      return line.trim();
    }
  }
  return null;
}

String? _value(List<String> args, String key) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == key && i + 1 < args.length) return args[i + 1];
    if (args[i].startsWith('$key=')) {
      return args[i].substring(key.length + 1);
    }
  }
  return null;
}

/// Decodes bytes that may carry a UTF-16 LE, UTF-8 BOM or plain UTF-8
/// encoding (MSBuild logs captured through PowerShell redirection are often
/// UTF-16 LE).
String decodeTextRobustly(List<int> bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    final sb = StringBuffer();
    for (var i = 2; i + 1 < bytes.length; i += 2) {
      sb.writeCharCode(bytes[i] | (bytes[i + 1] << 8));
    }
    return sb.toString();
  }
  var start = 0;
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    start = 3;
  }
  return utf8.decode(bytes.sublist(start), allowMalformed: true);
}

List<String> _values(List<String> args, String key) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == key && i + 1 < args.length) {
      result.add(args[i + 1]);
      i++;
    } else if (args[i].startsWith('$key=')) {
      result.add(args[i].substring(key.length + 1));
    }
  }
  return result;
}

Future<void> main(List<String> args) async {
  final runId = _value(args, '--run-id') ?? '';
  final linkerPath = _value(args, '--linker-path') ?? '';
  final linkerVersion = _value(args, '--linker-version') ?? '';
  final vcxprojs = _values(args, '--vcxproj');
  final diagLogs = _values(args, '--diag-log');
  final out = _value(args, '--out');
  if (vcxprojs.isEmpty || out == null) {
    stderr.writeln('Usage: dart run tool/linker_evidence.dart '
        '--run-id <id> --linker-path <link.exe> --linker-version <v> '
        '--vcxproj <path> [--vcxproj <path> ...] '
        '[--diag-log <msbuild -v:diag log> ...] --out <json>');
    exitCode = 64;
    return;
  }

  String? diagLogContent;
  if (diagLogs.isNotEmpty) {
    final buf = StringBuffer();
    for (final diagLog in diagLogs) {
      final f = File(diagLog);
      if (!f.existsSync()) {
        stderr.writeln('diag log not found: $diagLog');
        exitCode = 66;
        continue;
      }
      buf.write(decodeTextRobustly(await f.readAsBytes()));
    }
    diagLogContent = buf.toString();
  }

  final targets = <Map<String, dynamic>>[];
  for (final path in vcxprojs) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('vcxproj not found: $path');
      exitCode = 66;
      continue;
    }
    final xml = await file.readAsString();
    final evidence = parseVcxprojLinkEvidence(xml);
    if (diagLogContent != null) {
      final command = extractLinkCommandFromDiagLog(
        diagLogContent,
        evidence.outputPath,
      );
      targets.add(evidence.toJson()..['linkCommand'] = command);
    } else {
      targets.add(evidence.toJson());
    }
  }

  final report = <String, dynamic>{
    'schema': 'muaman-linker-evidence',
    'schemaVersion': 1,
    'runId': runId,
    'buildConfiguration': 'Release',
    'sourceConfigurationFiles': [
      'windows/CMakeLists.txt',
      'windows/runner/CMakeLists.txt',
      'windows/flutter/generated_plugins.cmake (generated)',
    ],
    'linkerExecutable': _normalize(linkerPath),
    'linkerVersion': linkerVersion,
    'targets': targets,
    'allTargetsBreproPresent': targets.isNotEmpty &&
        targets.every((final t) => t['breproPresent'] == true),
  };

  final outFile = File(out);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsString('${_encoder.convert(report)}\n', flush: true);
  stdout.writeln(report['allTargetsBreproPresent'] == true
      ? 'LINKER EVIDENCE OK: /Brepro present for all ${targets.length} targets.'
      : 'LINKER EVIDENCE FAIL: missing /Brepro for one or more targets.');
}
