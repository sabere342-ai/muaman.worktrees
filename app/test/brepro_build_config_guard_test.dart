import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reproducible linking: source build-config contract', () {
    final cmake = File('windows/CMakeLists.txt');
    final runnerCmake = File('windows/runner/CMakeLists.txt');
    final content = cmake.existsSync() ? cmake.readAsStringSync() : '';
    final runnerContent =
        runnerCmake.existsSync() ? runnerCmake.readAsStringSync() : '';

    test('windows/CMakeLists.txt exists', () {
      expect(cmake.existsSync(), isTrue,
          reason: 'windows/CMakeLists.txt must exist');
    });

    test('applies /Brepro to the Release EXE linker flags', () {
      expect(
          content,
          contains('string(APPEND '
              'CMAKE_EXE_LINKER_FLAGS_RELEASE " /Brepro")'));
    });

    test('applies /Brepro to the Release SHARED linker flags', () {
      expect(
          content,
          contains('string(APPEND '
              'CMAKE_SHARED_LINKER_FLAGS_RELEASE " /Brepro")'));
    });

    test('applies /Brepro only inside the MSVC guard', () {
      final ifMsvc = content.indexOf('if(MSVC)');
      final exeAppend = content
          .indexOf('string(APPEND CMAKE_EXE_LINKER_FLAGS_RELEASE " /Brepro")');
      final sharedAppend = content.indexOf(
          'string(APPEND CMAKE_SHARED_LINKER_FLAGS_RELEASE " /Brepro")');
      final endif = content.lastIndexOf('endif()');
      expect(ifMsvc, greaterThanOrEqualTo(0));
      expect(exeAppend, greaterThan(ifMsvc),
          reason: '/Brepro EXE append must be inside if(MSVC)');
      expect(sharedAppend, greaterThan(exeAppend));
      expect(endif, greaterThan(sharedAppend),
          reason: 'the if(MSVC) block must be closed after the appends');
    });

    test('does not add /Brepro to Debug or Profile linker flags', () {
      expect(content, isNot(contains('CMAKE_EXE_LINKER_FLAGS_DEBUG /Brepro')));
      expect(
          content, isNot(contains('CMAKE_EXE_LINKER_FLAGS_PROFILE /Brepro')));
      expect(
          content, isNot(contains('CMAKE_SHARED_LINKER_FLAGS_DEBUG /Brepro')));
      expect(content,
          isNot(contains('CMAKE_SHARED_LINKER_FLAGS_PROFILE /Brepro')));
    });

    test('relies on linker flags, not post-build binary patching', () {
      for (final c in [content, runnerContent]) {
        expect(c, isNot(contains('POST_BUILD')));
        expect(c, isNot(contains('add_custom_command')));
      }
    });
  });
}
