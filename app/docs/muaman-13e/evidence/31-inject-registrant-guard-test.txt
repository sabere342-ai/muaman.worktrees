import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MUAMAN-13E: Dart plugin registrant injection', () {
    final flutterCmake = File('windows/flutter/CMakeLists.txt');
    final flutterContent =
        flutterCmake.existsSync() ? flutterCmake.readAsStringSync() : '';

    final script = File('tool/inject_registrant_package.ps1');
    final scriptContent = script.existsSync() ? script.readAsStringSync() : '';

    test(
        'windows/flutter/CMakeLists.txt contains muaman_inject_registrant target',
        () {
      expect(flutterCmake.existsSync(), isTrue,
          reason: 'windows/flutter/CMakeLists.txt must exist');
      expect(flutterContent, contains('muaman_inject_registrant'));
    });

    test('uses file(TO_NATIVE_PATH ...) for both script and config paths', () {
      expect(
          flutterContent,
          contains(
              'file(TO_NATIVE_PATH "\${PROJECT_DIR}/tool/inject_registrant_package.ps1" MUAMAN_INJECT_SCRIPT)'));
      expect(
          flutterContent,
          contains(
              'file(TO_NATIVE_PATH "\${PROJECT_DIR}/.dart_tool/package_config.json" MUAMAN_PACKAGE_CONFIG)'));
    });

    test('add_dependencies(flutter_assemble muaman_inject_registrant)', () {
      expect(
          flutterContent,
          contains(
              'add_dependencies(flutter_assemble muaman_inject_registrant)'));
    });

    test('tool/inject_registrant_package.ps1 exists', () {
      expect(script.existsSync(), isTrue,
          reason: 'tool/inject_registrant_package.ps1 must exist');
    });

    test('PS1 script contains _muaman_registrant package name', () {
      expect(scriptContent, contains('_muaman_registrant'));
    });

    test('PS1 script contains rootUri = ../.dart_tool', () {
      expect(scriptContent, contains("rootUri         = '../.dart_tool'"));
    });

    test('PS1 script contains packageUri = .', () {
      expect(scriptContent, contains("packageUri      = '.'"));
    });

    test('PS1 script is idempotent: checks for already-present entry', () {
      expect(scriptContent, contains(r'Where-Object { $_.name -eq $regName }'));
    });

    test('windows/flutter/CMakeLists.txt contains MUAMAN-13E comment', () {
      expect(flutterCmake.existsSync(), isTrue,
          reason: 'windows/flutter/CMakeLists.txt must exist');
      expect(flutterContent, contains('MUAMAN-13E'));
    });
  });
}
