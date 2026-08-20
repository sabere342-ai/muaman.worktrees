import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migrationContent;

  setUpAll(() {
    final file = File(
        '../supabase/migrations/20260820000025_phase_g_cloud_data_foundation.sql');
    migrationContent = file.readAsStringSync();
  });

  group('SECURITY DEFINER audit', () {
    test('every function is SECURITY DEFINER', () {
      final functionBodies =
          migrationContent.split(r'CREATE OR REPLACE FUNCTION');
      for (var i = 1; i < functionBodies.length; i++) {
        final body = functionBodies[i];
        expect(body, contains('SECURITY DEFINER'),
            reason: 'Function at position $i missing SECURITY DEFINER');
      }
    });

    test('every function has SET search_path = public', () {
      final functionBodies =
          migrationContent.split(r'CREATE OR REPLACE FUNCTION');
      for (var i = 1; i < functionBodies.length; i++) {
        final body = functionBodies[i];
        expect(body, contains('SET search_path = public'),
            reason: 'Function at position $i missing search_path');
      }
    });
  });

  group('No dangerous patterns', () {
    test('no unqualified public execute grants on tables', () {
      expect(migrationContent, isNot(contains('GRANT ALL ON')));
    });
    test('no dynamic SQL (EXECUTE IMMEDIATE)', () {
      expect(migrationContent, isNot(contains('EXECUTE IMMEDIATE')));
    });
  });

  group('No conflict markers', () {
    test('no <<<<<<< markers', () {
      expect(migrationContent, isNot(contains('<<<<<<<')));
    });
    test('no ======= conflict markers', () {
      final lines = migrationContent.split('\n');
      for (final line in lines) {
        if (line.trim() == '=======') {
          fail('Found git conflict marker ======= at line: $line');
        }
      }
    });
    test('no >>>>>>> markers', () {
      expect(migrationContent, isNot(contains('>>>>>>>')));
    });
  });

  group('No secrets', () {
    test('no service_role key', () {
      expect(migrationContent, isNot(contains('service_role')));
    });
    test('no JWT secret', () {
      expect(migrationContent, isNot(contains('jwt_secret')));
    });
    test('no password patterns', () {
      expect(migrationContent, isNot(contains('password =')));
    });
  });
}
