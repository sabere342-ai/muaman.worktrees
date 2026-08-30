import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migrationContent;

  setUpAll(() {
    final file = File(
        '../supabase/migrations/20260820000030_phase_p_a4_cloud_stock_adjustments.sql');
    migrationContent = file.readAsStringSync();
  });

  group('A4-01: cloud_stock_adjustments table defined', () {
    test('table defined with IF NOT EXISTS', () {
      expect(migrationContent,
          contains('CREATE TABLE IF NOT EXISTS cloud_stock_adjustments'));
    });
    test('shop_id tenant column', () {
      expect(migrationContent,
          contains('shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE'));
    });
    test('product_id FK restrict', () {
      expect(migrationContent,
          contains('REFERENCES cloud_products(id) ON DELETE RESTRICT'));
    });
    test('barcode column', () {
      expect(migrationContent, contains('barcode TEXT NOT NULL'));
    });
    test('projected_current column', () {
      expect(migrationContent, contains('projected_current INTEGER NOT NULL'));
    });
    test('shortfall positive-checked', () {
      expect(migrationContent,
          contains('shortfall INTEGER NOT NULL'));
      expect(migrationContent,
          contains('CONSTRAINT chk_cloud_stock_adj_shortfall CHECK (shortfall > 0)'));
    });
    test('adjustment_type typed and defaulted', () {
      expect(migrationContent,
          contains("adjustment_type TEXT NOT NULL DEFAULT 'OVERSOLD'"));
      expect(migrationContent,
          contains("CHECK (adjustment_type IN ('OVERSOLD', 'MANUAL'))"));
    });
    test('status typed and defaulted', () {
      expect(migrationContent, contains("status TEXT NOT NULL DEFAULT 'OPEN'"));
      expect(migrationContent,
          contains("CHECK (status IN ('OPEN', 'RESOLVED'))"));
    });
    test('idempotency_key column', () {
      expect(migrationContent, contains('idempotency_key TEXT,'));
    });
    test('shop-scoped idempotency unique constraint', () {
      expect(migrationContent,
          contains(
              'CONSTRAINT uniq_cloud_stock_adj_shop_key UNIQUE (shop_id, idempotency_key)'));
    });
    test('sale/return/invoice linkage FKs (SET NULL)', () {
      expect(migrationContent,
          contains('REFERENCES cloud_sales(id) ON DELETE SET NULL'));
      expect(migrationContent,
          contains('REFERENCES cloud_returns(id) ON DELETE SET NULL'));
      expect(migrationContent,
          contains('REFERENCES cloud_invoices(id) ON DELETE SET NULL'));
    });
    test('audit columns auth.users', () {
      expect(migrationContent,
          contains('resolved_by UUID REFERENCES auth.users(id)'));
      expect(migrationContent,
          contains('created_by UUID REFERENCES auth.users(id)'));
      expect(migrationContent, contains('created_at TIMESTAMPTZ NOT NULL DEFAULT now()'));
      expect(migrationContent, contains('deleted_at TIMESTAMPTZ'));
    });
  });

  group('A4-02: Indexes exist', () {
    final indexes = [
      'idx_cloud_stock_adj_shop_id',
      'idx_cloud_stock_adj_product_id',
      'idx_cloud_stock_adj_status',
      'idx_cloud_stock_adj_sale_id',
      'idx_cloud_stock_adj_idempotency_key',
    ];
    for (final idx in indexes) {
      test('index $idx exists', () {
        expect(migrationContent, contains('CREATE INDEX IF NOT EXISTS $idx'));
      });
    }
  });

  group('A4-03: RLS enabled with SELECT-only policy', () {
    test('RLS enabled', () {
      expect(migrationContent,
          contains('ALTER TABLE cloud_stock_adjustments ENABLE ROW LEVEL SECURITY'));
    });
    test('SELECT policy scoped to own shop via shop_members', () {
      expect(migrationContent,
          contains('CREATE POLICY shop_isolation_stock_adjustments ON cloud_stock_adjustments'));
      expect(migrationContent, contains('FOR SELECT TO authenticated'));
      expect(migrationContent, contains('shop_members.user_id = auth.uid()'));
      expect(migrationContent, contains("shop_members.status = 'ACTIVE'"));
    });
    test('no INSERT/UPDATE/DELETE policies', () {
      expect(migrationContent, isNot(contains('FOR INSERT')));
      expect(migrationContent, isNot(contains('FOR DELETE')));
    });
    test('direct table access revoked from authenticated', () {
      expect(migrationContent,
          contains('REVOKE ALL ON cloud_stock_adjustments FROM authenticated'));
    });
  });

  group('A4-04: Owner-gated RPCs exist', () {
    final rpcs = [
      'create_cloud_stock_adjustment',
      'list_cloud_stock_adjustments',
      'resolve_cloud_stock_adjustment',
    ];
    for (final fn in rpcs) {
      test('$fn defined as SECURITY DEFINER', () {
        expect(migrationContent, contains('CREATE OR REPLACE FUNCTION $fn'));
        expect(migrationContent, contains('SECURITY DEFINER'));
      });
      test('$fn enforces admin.settings.access', () {
        expect(migrationContent,
            contains("require_shop_permission(p_shop_id, 'admin.settings.access')"));
      });
    }
    test('create/list/resolve granted to authenticated', () {
      expect(migrationContent, contains('GRANT EXECUTE ON FUNCTION create_cloud_stock_adjustment'));
      expect(migrationContent, contains('GRANT EXECUTE ON FUNCTION list_cloud_stock_adjustments'));
      expect(migrationContent, contains('GRANT EXECUTE ON FUNCTION resolve_cloud_stock_adjustment'));
    });
  });

  group('A4-05: P-OD1 oversell sale now records durable adjustment', () {
    test('create_cloud_sale_with_stock_v2 re-created with same contract', () {
      expect(migrationContent,
          contains('CREATE OR REPLACE FUNCTION create_cloud_sale_with_stock_v2'));
      expect(migrationContent, contains('RETURNS JSONB'));
      expect(migrationContent,
          contains('p_allow_oversell BOOLEAN DEFAULT FALSE'));
    });
    test('auto-record insert present in oversell flow', () {
      expect(migrationContent, contains('INSERT INTO cloud_stock_adjustments'));
      expect(migrationContent, contains("'OVERSOLD', v_sale_id, p_invoice_id"));
      expect(migrationContent, contains('ON CONFLICT DO NOTHING'));
    });
    test('shortfall derived as positive from negative stock', () {
      expect(migrationContent, contains('GREATEST(0, -v_new_current)'));
    });
  });

  group('A4-06: Migration-28 concurrency contract preserved', () {
    test('row-lock serialization retained (SELECT ... FOR UPDATE)', () {
      expect(migrationContent, contains('FOR UPDATE'));
    });
    test('CAS oversell guard retained', () {
      expect(migrationContent, contains('phase_m_oversell_guard('));
    });
    test('idempotency lookup + record retained', () {
      expect(migrationContent, contains('phase_m_idempotency_lookup(p_idempotency_key)'));
      expect(migrationContent, contains('phase_m_idempotency_record('));
    });
    test('non-oversell path unchanged (validation + REVOKE contract)', () {
      expect(migrationContent, contains("IF v_product.current_quantity < p_quantity AND NOT p_allow_oversell THEN"));
      expect(migrationContent, contains("RAISE EXCEPTION 'Insufficient stock"));
    });
  });

  group('A4-07: Additive-only posture', () {
    test('no new REVOKE on pre-existing functions or tables', () {
      expect(migrationContent,
          isNot(contains('REVOKE ALL ON cloud_sales')));
      expect(migrationContent,
          isNot(contains('REVOKE ALL ON cloud_products')));
    });
    test('does not drop or alter legacy migration-25 tables', () {
      expect(migrationContent, isNot(contains('DROP TABLE')));
      expect(migrationContent, isNot(contains('ALTER TABLE cloud_products')));
      expect(migrationContent, isNot(contains('ALTER TABLE cloud_sales')));
    });
  });

  group('security audit', () {
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
    test('no GRANT ALL ON, no dynamic SQL, no conflict markers', () {
      expect(migrationContent, isNot(contains('GRANT ALL ON')));
      expect(migrationContent, isNot(contains('EXECUTE IMMEDIATE')));
      expect(migrationContent, isNot(contains('<<<<<<<')));
      expect(migrationContent, isNot(contains('>>>>>>>')));
    });
    test('no secrets', () {
      expect(migrationContent, isNot(contains('service_role')));
      expect(migrationContent, isNot(contains('jwt_secret')));
      expect(migrationContent, isNot(contains('password =')));
    });
  });
}