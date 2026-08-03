import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../tool/linker_evidence.dart';

const String _sampleVcxproj = '''
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <ProjectName>muaman_store</ProjectName>
  </PropertyGroup>
  <PropertyGroup Condition="'\$(Configuration)|\$(Platform)'=='Debug|x64'" Label="Configuration">
    <OutDir Condition="'\$(Configuration)|\$(Platform)'=='Debug|x64'">\\build\\debug\\</OutDir>
    <TargetName Condition="'\$(Configuration)|\$(Platform)'=='Debug|x64'">muaman_store</TargetName>
    <TargetExt Condition="'\$(Configuration)|\$(Platform)'=='Debug|x64'">.exe</TargetExt>
  </PropertyGroup>
  <PropertyGroup Condition="'\$(Configuration)|\$(Platform)'=='Release|x64'" Label="Configuration">
    <OutDir Condition="'\$(Configuration)|\$(Platform)'=='Release|x64'">\\build\\release\\</OutDir>
    <TargetName Condition="'\$(Configuration)|\$(Platform)'=='Release|x64'">muaman_store</TargetName>
    <TargetExt Condition="'\$(Configuration)|\$(Platform)'=='Release|x64'">.exe</TargetExt>
  </PropertyGroup>
  <ItemDefinitionGroup Condition="'\$(Configuration)|\$(Platform)'=='Debug|x64'">
    <Link>
      <AdditionalOptions>%(AdditionalOptions) /machine:x86</AdditionalOptions>
    </Link>
  </ItemDefinitionGroup>
  <ItemDefinitionGroup Condition="'\$(Configuration)|\$(Platform)'=='Release|x64'">
    <Link>
      <AdditionalOptions>%(AdditionalOptions) /machine:x64 /Brepro</AdditionalOptions>
      <AdditionalDependencies>kernel32.lib;user32.lib</AdditionalDependencies>
      <ProgramDataBaseFile>\\build\\release\\muaman_store.pdb</ProgramDataBaseFile>
      <ImportLibrary>\\build\\release\\muaman_store.lib</ImportLibrary>
      <SubSystem>Windows</SubSystem>
      <GenerateDebugInformation>false</GenerateDebugInformation>
    </Link>
  </ItemDefinitionGroup>
</Project>
''';

void main() {
  group('linker_evidence: vcxproj parsing', () {
    test('finds the Release link block and /Brepro once', () {
      final evidence = parseVcxprojLinkEvidence(_sampleVcxproj);
      expect(evidence.targetName, 'muaman_store');
      expect(evidence.outputPath, '/build/release/muaman_store.exe');
      expect(evidence.breproPresent, isTrue);
      expect(evidence.breproOccurrences, 1);
      expect(evidence.additionalOptions,
          '%(AdditionalOptions) /machine:x64 /Brepro');
      expect(evidence.subSystem, 'Windows');
      expect(evidence.generateDebugInformation, 'false');
    });

    test('never reads the Debug link block for Release evidence', () {
      final evidence = parseVcxprojLinkEvidence(_sampleVcxproj);
      expect(evidence.additionalOptions, isNot(contains('/machine:x86')));
      expect(evidence.outputPath, isNot(contains('debug')));
    });

    test('reports absence of /Brepro when missing', () {
      final xml = _sampleVcxproj.replaceFirst('/Brepro', '');
      final evidence = parseVcxprojLinkEvidence(xml);
      expect(evidence.breproPresent, isFalse);
      expect(evidence.breproOccurrences, 0);
    });
  });

  group('linker_evidence: diag log link command extraction', () {
    test('finds the real link.exe command line for the target output', () {
      const log = '''
Some diag noise
  Link:
    C:\\\\vs\\\\link.exe /OUT:"C:\\\\build\\\\release\\\\muaman_store.exe" /INCREMENTAL:NO /MACHINE:X64 /machine:x64 /Brepro foo.obj
More noise
''';
      final cmd = extractLinkCommandFromDiagLog(
        log,
        'C:/build/release/muaman_store.exe',
      );
      expect(cmd, isNotNull);
      expect(cmd, contains('link.exe'));
      expect(cmd, contains('/Brepro'));
    });

    test('returns null when no link command ran for the output', () {
      const log = 'No linker activity here.';
      expect(
        extractLinkCommandFromDiagLog(log, 'C:/x/muaman_store.exe'),
        isNull,
      );
    });
  });

  group('linker_evidence: robust text decoding', () {
    test('decodes plain UTF-8 text', () {
      const text = 'flutter build windows --release';
      expect(decodeTextRobustly(utf8.encode(text)), text);
    });

    test('decodes UTF-16 LE text with BOM', () {
      const text = 'link.exe /OUT:muaman_store.exe /Brepro';
      final utf16 = utf16LeEncode(text);
      expect(decodeTextRobustly(utf16), text);
    });

    test('decodes UTF-8 text with BOM', () {
      const text = 'MSBuild diag log line';
      final bom = [0xEF, 0xBB, 0xBF, ...utf8.encode(text)];
      expect(decodeTextRobustly(bom), text);
    });
  });
}

List<int> utf16LeEncode(String s) {
  final bytes = <int>[0xFF, 0xFE];
  for (final rune in s.runes) {
    final codeUnit = rune;
    bytes.add(codeUnit & 0xFF);
    bytes.add((codeUnit >> 8) & 0xFF);
  }
  return bytes;
}
