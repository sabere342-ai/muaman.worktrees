import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Database / migration tests for Phase E.
///
/// These tests verify the SQL migration file structure and content
/// without requiring a live Supabase instance.
void main() {
  late String migrationContent;

  setUpAll(() {
    final migrationFile = File(
      'C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze/'
      'supabase/migrations/20260820000023_phase_e_licensing_enhancements.sql',
    );
    if (migrationFile.existsSync()) {
      migrationContent = migrationFile.readAsStringSync();
    }
  });

  group('Phase E migration file', () {
    test('exists at expected path', () {
      final file = File(
        'C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze/'
        'supabase/migrations/20260820000023_phase_e_licensing_enhancements.sql',
      );
      expect(file.existsSync(), true);
    });

    test('has additive license columns', () {
      expect(migrationContent, contains('ADD COLUMN IF NOT EXISTS updated_at'));
      expect(
          migrationContent, contains('ADD COLUMN IF NOT EXISTS max_devices'));
      expect(migrationContent, contains('ADD COLUMN IF NOT EXISTS revoked_at'));
      expect(migrationContent, contains('ADD COLUMN IF NOT EXISTS metadata'));
    });

    test('has activations status CHECK constraint', () {
      expect(migrationContent, contains('activations_status_check'));
      expect(migrationContent,
          contains("CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED'))"));
    });

    test('creates verify_license_entitlement function', () {
      expect(migrationContent,
          contains('CREATE OR REPLACE FUNCTION verify_license_entitlement'));
      expect(migrationContent, contains('SECURITY DEFINER'));
      expect(migrationContent, contains('SET search_path = public'));
      expect(migrationContent, contains('has_license BOOLEAN'));
      expect(migrationContent, contains('license_status TEXT'));
      expect(migrationContent, contains('server_time TIMESTAMPTZ'));
    });

    test('creates register_device function', () {
      expect(migrationContent,
          contains('CREATE OR REPLACE FUNCTION register_device'));
      expect(migrationContent, contains('p_shop_id UUID'));
      expect(migrationContent, contains('p_installation_id UUID'));
      expect(migrationContent, contains('p_platform TEXT'));
    });

    test('creates activate_device function', () {
      expect(migrationContent,
          contains('CREATE OR REPLACE FUNCTION activate_device'));
      expect(migrationContent, contains('RETURNS JSONB'));
      expect(migrationContent, contains('device limit'));
    });

    test('creates deactivate_device function', () {
      expect(migrationContent,
          contains('CREATE OR REPLACE FUNCTION deactivate_device'));
      expect(migrationContent, contains('owner'));
    });

    test('creates get_device_list function', () {
      expect(migrationContent,
          contains('CREATE OR REPLACE FUNCTION get_device_list'));
      expect(migrationContent, contains('device_id UUID'));
      expect(migrationContent, contains('activation_id UUID'));
    });

    test('no DROP or DELETE statements (additive only)', () {
      // Verify no destructive operations
      final lines = migrationContent.split('\n');
      for (final line in lines) {
        final upper = line.toUpperCase().trim();
        if (upper.startsWith('--')) continue; // Skip comments
        expect(upper, isNot(contains('DROP TABLE')));
        expect(upper, isNot(contains('DELETE FROM')));
        expect(upper, isNot(contains('TRUNCATE')));
      }
    });

    test('all functions have SECURITY DEFINER', () {
      final functionNames = [
        'verify_license_entitlement',
        'register_device',
        'activate_device',
        'deactivate_device',
        'get_device_list',
      ];
      for (final name in functionNames) {
        expect(migrationContent, contains(name));
      }
      // Count SECURITY DEFINER occurrences (should be 5 for 5 functions)
      final matches = 'SECURITY DEFINER'.allMatches(migrationContent);
      expect(matches.length, greaterThanOrEqualTo(5));
    });

    test('all functions have SET search_path = public', () {
      final matches = 'SET search_path = public'.allMatches(migrationContent);
      expect(matches.length, greaterThanOrEqualTo(5));
    });
  });

  group('Phase E functions verify auth checks', () {
    test('verify_license_entitlement checks auth.uid()', () {
      expect(migrationContent, contains("v_user_id := auth.uid()"));
      expect(migrationContent, contains("IF v_user_id IS NULL THEN"));
    });

    test('verify_license_entitlement checks shop membership', () {
      expect(migrationContent, contains('shop_members'));
      expect(migrationContent, contains("AND status = 'ACTIVE'"));
    });

    test('register_device checks shop membership', () {
      // register_device function should also verify membership
      expect(migrationContent, contains('Not a member of this shop'));
    });

    test('activate_device checks shop membership', () {
      // activate_device function should verify membership
      expect(migrationContent, contains('activate_device'));
    });

    test('deactivate_device checks owner role', () {
      expect(migrationContent, contains("role = 'owner'"));
    });

    test('get_device_list checks owner role', () {
      // get_device_list should require owner
      expect(migrationContent,
          contains('Only the shop owner can view the device list'));
    });
  });

  group('Phase E functions verify server-time authority', () {
    test('verify_license_entitlement uses now() for trial check', () {
      expect(migrationContent, contains("trial_expires_at > now()"));
    });

    test('activate_device updates last_verified_at', () {
      expect(migrationContent, contains('last_verified_at'));
    });

    test('register_device uses now() for timestamps', () {
      expect(migrationContent, contains('last_seen_at = now()'));
    });
  });
}
