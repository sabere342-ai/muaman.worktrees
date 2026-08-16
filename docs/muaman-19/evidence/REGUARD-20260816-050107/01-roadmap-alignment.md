# ROADMAP ALIGNMENT CHECK — MUAMAN-19 re-guard on Productized I-TECH build

Run ID: `REGUARD-20260816-050107` — 2026-08-16 (local) / 2026-08-16T02:01Z (UTC)

## 1. Governing reference

- `I-TECH-PRODUCTIZATION-SUPER-PROMPT.md` (repo root, both worktrees).
  - Guard chain (§5.6): `13L → 13O..13S → 18 → 19`.
  - Productization is the governed pass; the 18/19 historical guards are
    re-run as re-guards on the Productized build.
- Historical MUAMAN-19 acceptance:
  - `docs/muaman-19/FINAL-REPORT.md` (Outcome A, baseline `23cb92e`).
  - `docs/muaman-19/EVIDENCE-SUMMARY.md` (contracts below).

## 2. Accepted chain status (current lineage)

| Phase | Outcome | Evidence |
|---|---|---|
| 13S | PASS (re-guard) | `docs/muaman-13s/evidence/20260816-024237/` allPass=true, NC 8/8 |
| MUAMAN-18 | PASS (re-guard) | `docs/muaman-18/evidence/REGUARD-20260816/` NC 4/4; `REGUARD-LC-20260816/` LC 20/20; `REGUARD-STRESS-20260816*/` 20/20 |
| MUAMAN-19 | THIS RE-GUARD | `docs/muaman-19/evidence/REGUARD-20260816-050107/` |

## 3. Current HEAD / worktree vs accepted commits

- Worktree: `C:\dev\muaman.worktrees\i-tech-productization-t0` (branch
  `codex/i-tech-productization-t0`, HEAD `fdf2d33`).
- `697a9f9` (MUAMAN-19) is an ancestor of HEAD (`merge-base --is-ancestor` = 0).
- `23cb92e` (MUAMAN-18) is an ancestor of HEAD.
- `7c6599b` (13S) is an ancestor of HEAD.
- Committed `app/` tree is identical between `697a9f9` and `fdf2d33`
  (`git diff --stat 697a9f9 fdf2d33 -- app/` is empty).
- Working tree carries the authorized, uncommitted T0 Productization refresh
  (delivery/installer/docs/tools only; no `app/` changes).

## 4. Current accepted productized artifact

- `app/build/windows/x64/runner/Release/muaman_store.exe`
- SHA-256 `134918133777C779890CA3BD4EC9CFFFD990AE04B48BE3A71DE8142B2F2FAEA1`
- 92,160 bytes — identical to the artifact that passed the MUAMAN-18 re-guard.

## 5. Contract being re-proved (from historical MUAMAN-19 acceptance)

1. Production-default path is define-free and seeds no demo data
   (`database_helper.dart:23` `bool.fromEnvironment('MUAMAN_SEED_DEMO')`
   defaults `false`; `database_helper.dart:152` gates `DataImporter.importData`).
2. Explicit seed path (`--dart-define=MUAMAN_SEED_DEMO=true`) populates the
   historical dataset: products=86, sales=225, returns=8, expenses=32,
   first barcode `2000000000001`.
3. Fresh production DB: transactional tables empty (products/sales/returns/
   expenses/invoices/import_batches/inventory_count/users/role_permissions = 0;
   app_settings = 4 runtime defaults).
4. Binary isolation: production `data/app.so` has 0 hits of `2000000000001`;
   seeded `data/app.so` has >=1 hit (AOT tree-shaking).
5. Installer/payload ships no seeded DB / no commissioning data.

## 6. Risk review

- No production code edit; no frozen identity (AppId / `muaman_store.db` /
  `muaman_store` / `muaman_store.exe` / pubspec name / BINARY_NAME) change.
- Builds: production artifact is verified as-is (no rebuild of the accepted
  binary); the seed path is a separate explicit verification build only.
- No risk to delivery/install/uninstall continuity, licensing, data, printing,
  or shutdown semantics.

## 7. Decision

**A — FOLLOW ROADMAP**

The historical MUAMAN-19 guard applies as-is to the current Productized I-TECH
build. No controlled deviation is required. No later phase is started after
this guard closes.
