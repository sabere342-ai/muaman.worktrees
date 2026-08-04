import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MUAMAN-13E: reproducible compilation via /pathmap', () {
    final cmake = File('windows/CMakeLists.txt');
    final content = cmake.existsSync() ? cmake.readAsStringSync() : '';

    test('windows/CMakeLists.txt exists', () {
      expect(cmake.existsSync(), isTrue,
          reason: 'windows/CMakeLists.txt must exist');
    });

    test('MUAMAN_CANONICAL_ROOT is defined with value \\muaman\\src', () {
      expect(
          content, contains('set(MUAMAN_CANONICAL_ROOT "\\\\muaman\\\\src")'));
    });

    test('MUAMAN_CANONICAL_ROOT contains no drive letter or username', () {
      final match = RegExp(r'set\s*\(\s*MUAMAN_CANONICAL_ROOT\s+"([^"]+)"')
          .firstMatch(content);
      expect(match, isNotNull, reason: 'MUAMAN_CANONICAL_ROOT must be defined');
      final value = match!.group(1)!;
      expect(value, isNot(contains('saber')),
          reason: 'canonical root must not contain username');
      expect(value, isNot(contains('C:')),
          reason: 'canonical root must not contain drive letter C:');
      expect(value, isNot(contains('D:')),
          reason: 'canonical root must not contain drive letter D:');

      final upperFollowedByColon = RegExp(r'[A-Z]:');
      expect(upperFollowedByColon.hasMatch(value), isFalse,
          reason: 'canonical root must not contain any drive letter');
    });

    test('MUAMAN_SOURCE_ROOT is derived from CMAKE_CURRENT_SOURCE_DIR', () {
      expect(
          content,
          contains(
              'get_filename_component(MUAMAN_SOURCE_ROOT "\${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)'));
    });

    test('MUAMAN_SOURCE_ROOT does not hardcode checkout paths', () {
      expect(content, isNot(contains('C:\\\\dev')),
          reason: 'must not hardcode dev path');
      expect(content, isNot(contains('muaman.repro')),
          reason: 'must not hardcode repro path');
      expect(content, isNot(contains('worktrees')),
          reason: 'must not hardcode worktrees path');
      expect(content, isNot(contains('Users')),
          reason: 'must not hardcode Users path');
    });

    test('/experimental:deterministic is set on RELEASE', () {
      expect(
          content,
          contains(
              'string(APPEND CMAKE_CXX_FLAGS_RELEASE " /experimental:deterministic")'));
    });

    test('/experimental:deterministic is set on PROFILE', () {
      expect(
          content,
          contains(
              'string(APPEND CMAKE_CXX_FLAGS_PROFILE " /experimental:deterministic")'));
    });

    test('/experimental:deterministic is NOT set on DEBUG', () {
      expect(content,
          isNot(contains('CMAKE_CXX_FLAGS_DEBUG /experimental:deterministic')),
          reason: 'must not apply to Debug builds');
    });

    test('/experimental:deterministic is NOT set on RELWITHDEBINFO', () {
      expect(
          content,
          isNot(contains(
              'CMAKE_CXX_FLAGS_RELWITHDEBINFO /experimental:deterministic')),
          reason: 'must not apply to RelWithDebInfo builds');
    });

    test('/pathmap: is appended to CMAKE_CXX_FLAGS_RELEASE', () {
      expect(content,
          contains('string(APPEND CMAKE_CXX_FLAGS_RELEASE " /pathmap:'));
    });

    test('/pathmap: is appended to CMAKE_CXX_FLAGS_PROFILE', () {
      expect(content,
          contains('string(APPEND CMAKE_CXX_FLAGS_PROFILE " /pathmap:'));
    });

    test('/pathmap: is NOT set on DEBUG', () {
      expect(content, isNot(contains('CMAKE_CXX_FLAGS_DEBUG /pathmap:')),
          reason: 'must not apply to Debug builds');
    });

    test('pathmap block is inside if(MSVC) / endif()', () {
      final ifMsvc = content.indexOf('if(MSVC)');
      expect(ifMsvc, greaterThanOrEqualTo(0),
          reason: 'if(MSVC) guard must exist');

      final experimentalDeterministic =
          content.indexOf('/experimental:deterministic');
      final pathmap = content.indexOf('/pathmap:');
      expect(experimentalDeterministic, greaterThan(ifMsvc),
          reason: '/experimental:deterministic must be inside if(MSVC)');
      expect(pathmap, greaterThan(experimentalDeterministic),
          reason: '/pathmap: must come after /experimental:deterministic');

      final endif = content.lastIndexOf('endif()');
      expect(endif, greaterThan(pathmap),
          reason: 'endif() must close the if(MSVC) block after pathmap');
    });

    test('canonical root value contains no colon', () {
      final match = RegExp(r'set\s*\(\s*MUAMAN_CANONICAL_ROOT\s+"([^"]+)"')
          .firstMatch(content);
      expect(match, isNotNull, reason: 'MUAMAN_CANONICAL_ROOT must be defined');
      expect(match!.group(1), isNot(contains(':')),
          reason: 'canonical root must not contain a colon');
    });
  });
}
