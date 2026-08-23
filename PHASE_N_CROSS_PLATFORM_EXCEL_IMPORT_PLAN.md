# PHASE N — CROSS-PLATFORM EXCEL IMPORT — IMPLEMENTATION PLAN

Status: PLANNING FROZEN (planning artifact only — no implementation performed in the planning session)

Planning session authority:

```text
AUTHORIZED_SESSION = PHASE_N_PLANNING
IMPLEMENTATION_AUTHORIZED = NO
REMOTE_MUTATION_AUTHORIZED = NO
SUPABASE_MUTATION_AUTHORIZED = NO
```

---

## 20.1 Governance & Authority

### Phase title

```text
CANONICAL_TITLE = Cross-Platform Excel Import
PHASE_ID = N
```

### Governing baseline (verified in this planning session, local git evidence)

```text
REPOSITORY ROOT   = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH            = codex/i-tech-next-roadmap-freeze
LOCAL_HEAD        = 8a8c267701060dc185cd70bd65a3be4834a91783  (Phase M implementation commit)
github remote URL = https://github.com/sabere342-ai/muaman.worktrees.git
github branch     = codex/i-tech-next-roadmap-freeze @ 8a8c267701060dc185cd70bd65a3be4834a91783
DIVERGENCE        = 0 0

PHASE_M_PLANNING_COMMIT    = da0f1559548c84cbba3949e95f0b8f2c8b3af025
  tag phase-m-planning-baseline-locked (tag object e7d6671f5858b5cca1fc1986750afdd5412a2944) peels to da0f155…
PHASE_M_IMPLEMENTATION_TAG = phase-m-implementation-locked
  (tag object 4a134112793077b4b34db43507536ecae108bd5d) peels to 8a8c267701060dc185cd70bd65a3be4834a91783
```

The `origin` remote (local/OneDrive path) is sacred historical infrastructure; it was NOT fetched,
pulled, pushed, pruned or modified. Only the `github` remote was queried, read-only (`git ls-remote`).

### Authoritative source documents

Primary authority: `PROJECT_MASTER_PLAN.md`. Applied hierarchy per PROJECT_MASTER_PLAN §18.

Anchors used (verbatim content verified in this session):

| Source | Anchor | Content relevant to Phase N |
|---|---|---|
| PROJECT_MASTER_PLAN §5 | D15 | "Excel import source — User-selected file (no fixed path)" |
| PROJECT_MASTER_PLAN §5 | D6 / D14 | Target platforms Windows + Android; offline required |
| PROJECT_MASTER_PLAN §13 | roadmap | Phase N = "Cross-Platform Excel Import — File picker, preview, validation, atomic import"; dependency: **N depends only on G** |
| PROJECT_MASTER_PLAN §16 | functional matrix | "Workbook Import — PRESERVED + cross-platform file picker" |
| PRODUCTIZATION_ARCHITECTURE_PLAN §14 | Excel Import Evolution | Target flow SELECT→VALIDATE→PREVIEW→CONFIRM→ATOMIC IMPORT→SUMMARY; security table (.xlsx only, ≤10 MB, content validation, SHA-256 dedup, atomic, graceful malformed handling, platform-appropriate permissions) |
| PHASE_G §32.2 / §6 / §7.2 / §8.2 | cloud_import_batches | "Phase G does NOT create cloud import_batches table. Phase N will add cloud_import_batches table as needed." (permission, not mandate) |
| PHASE_H §7 / §33 | workbook sync | "Cross-platform Excel import → Phase N — Phase N handles workbook sync" (ownership transfer, minimum meaning defined in §20.15 of this plan) |
| PHASE_K GA12 / §1.4 / D8 | Android deferral | Workbook import button hidden/disabled on Android in K; full SAF import stays Phase N; no silent breakage |
| PHASE_M §12 / §36 | scope boundary | Phase N excluded from M; DR-M05/M06/M07 remain OPEN-GATE; Migration 28 TEST deployment remains a Phase M residual |
| PRE_A identity register | workbook default filename | Legacy default workbook filename classified LEGACY-CUSTOMER; "Plan removal of hardcoded path — Phase N — user-selected file" |

Historical `docs/next-roadmap/*` references were noted but do not override this hierarchy.

### Planning-session boundaries

- This session created ONLY this plan document. No production code, schema, manifest, pubspec, or Supabase change.
- No tags created; no remote mutation; no Supabase access.
- The future implementation session executes this plan under a separate authorized session.

---

## 20.2 Verified Current State

All statements below are FACTS verified by direct inspection at commit
`8a8c267701060dc185cd70bd65a3be4834a91783` unless marked otherwise.

### Existing importer architecture

- `app/lib/database/workbook_importer.dart`
  - `WorkbookImporter` class (:88). Public entry `import({...})` (:426) with params:
    `workbookPath` (required path string), `db`, `allowZeroCost=false`,
    `skipShaCheck=true`, `expectedSha256=null`, `shopId=null`.
  - Pinned expected-hash constant `expectedSha256` (:89–90) =
    `e16c3b7ca089a2cc82fee383c514cc061eb0223e44d7ac1b766807fd28ae47c4`; only enforced when
    `skipShaCheck:false`. The UI currently passes `skipShaCheck:true`.
  - `preflight()` (:116): requires exactly six Arabic worksheets —
    `لوحة التحكم، المخزن، الجرد، المبيعات، المرتجعات، المصروفات` (:92–99); zero-cost rule for
    products with cost == 0 except name `'تحزية'` (:147–161), which requires explicit
    `allowZeroCost` confirmation.
  - `_applyImport()` (:171): wraps ALL business writes in ONE sqflite transaction
    (`db.transaction((txn){...})`, :193–394); raw `txn.insert` into `products`, `sales`,
    `returns`, `expenses`, `inventory_count`, each stamped with `shop_id`.
  - DEFECT RELEVANT TO PHASE N: the `import_batches` row is inserted AFTER the transaction
    commits (:472–494), outside it. A crash between commit and batch insert leaves imported data
    with NO batch row → the duplicate-hash guard would permit re-import (data duplication).
  - Duplicate guard: queries `import_batches` by `file_sha256` BEFORE parsing (:455–461);
    any prior batch with same hash throws `'تم استيراد هذا الملف مسبقًا …'` — a given workbook
    file can be imported exactly once, globally (see tenant note below).
  - Tenant stamping: effective shopId = explicit arg ?? `ActiveShopContext.instance.shopId`;
    import FAILS CLOSED without an active cloud-linked shop (:434–439).
- `app/lib/database/xlsx_reader.dart`
  - `XlsxReader.read(path)` (:12): synchronous `File.readAsBytesSync`, ZIP decode
    (`package:archive`), XML parse (`package:xml`), sharedStrings + workbook.xml/rels resolution.
    Whole-file in-memory parse. NO size cap, NO extension check, NO zip-hardening today.

### Settings path dependency (Windows UX today)

- `app/lib/screens/settings_screen.dart`
  - `_workbookPathController` (:34); loaded via `AppSettings.getWorkbookPath()` (:78, :97).
  - Import UI (:464–502): on Android (`PlatformCapabilities.isAndroid`) an explicit
    unavailable-card replaces the section ("استيراد بيانات Excel غير متاح على أجهزة Android في
    هذه المرحلة…") per Phase K D8; otherwise a free-text path TextField (:476–482) + import button.
  - `_importWorkbook()` (:1940–1982): reads path FROM THE TEXT FIELD; existence check;
    calls `WorkbookImporter.import(workbookPath: path, allowZeroCost: true, skipShaCheck: true)`
    (:1958–1963); on success persists the typed path via `AppSettings.setWorkbookPath(path)`
    (:1964); result via SnackBar. NO preview step. NO file picker.
- `app/lib/services/app_settings.dart`
  - `getWorkbookPath()` (:108): stored value if it exists on disk, ELSE falls back to
    `getDefaultWorkbookPath()` (:208+) which probes `Directory.current`/executable ancestor dirs
    for legacy customer-specific filenames (`شيت_ادارة_محل_شهر8.xlsx`,
    legacy `شيت_ادارة_محل_مؤمن_شهر8.xlsx`, folder `شهر 8`). This is the "fixed/default path"
    behavior D15 retires.

### SQLite import batch state

- `app/lib/database/database_helper.dart`: `schemaVersion = 15` (:93).
- `import_batches` DDL (:535–562): `id` PK AUTOINCREMENT, `file_sha256 TEXT NOT NULL UNIQUE`
  (**globally unique across shops** — current query :455 also shop-unscoped),
  `file_name`, `imported_at`, per-entity counts, financial totals, `reconciliation_json`,
  `shop_id TEXT`, `cloud_uuid TEXT` (cloud-ready columns already present).
- `sync_queue` table + indexes (:700–723); Phase M added `resolution_status`,
  `occurrence_token` (:791–812).

### Sync behavior today (FACT)

- Normal writes go through `DatabaseHelper` wrappers (e.g., `insertProduct` :873) which call
  `_enqueueAfterWrite` (:250–305) → `SyncQueueRepository.enqueue` (`sync_queue_repository.dart:154`)
  with idempotency key + persisted occurrence token (INV-M19).
- `WorkbookImporter._applyImport` uses RAW `txn.insert` and BYPASSES `_enqueueAfterWrite`
  entirely → **imported entities are NOT enqueued into sync_queue today** (INFERENCE from code
  paths; consistent with migration orchestrator note D7 at `migration_orchestrator.dart:119`).
- Enqueue suppression exists: `_enqueueSuppressionDepth` (:89, :264) with a suppression runner
  (:176–185) — reusable if bulk-import enqueue needs to be opt-out.
- Entity sync adapters exist per type (`app/lib/sync/adapters/*.dart`: product, sale, returnItem,
  invoice, expense, expenseCategory, inventoryCount, customer, shopSetting). There is NO
  import-batch adapter.

### Cloud state

- Local-first architecture; Supabase used for licensing/RBAC/shop membership and entity sync
  upload/download (Phase G/H/F). No cloud `import_batches` table exists
  (PHASE_G §32.2 explicitly deferred it). No Supabase mutation occurred or is planned here.

### Test baseline (measured in this session — see Section L of the forensic report)

- `flutter analyze`: 0 errors, 0 warnings, 60 pre-existing info-level lints (FACT).
- `flutter test`: **1336 passed, 7 failed** — the exact documented pre-existing set
  (3 × `test/widget_test.dart`, 4 × `test/features/shop_profile_settings_widget_test.dart`;
  all rooted in `Supabase.instance` initialization inside `CloudLicensingService` during auth-gate
  widget tests). Classified PRE_EXISTING (they occur at the exact Phase M implementation HEAD,
  which is the current clean HEAD; Phase M plan §34 documents "the documented 7 pre-existing
  failures").
- Import-domain targeted tests: `test/database/workbook_import_test.dart` +
  `test/tenant_isolation/import_stamping_test.dart` = **35/35 pass** (FACT).
- `git diff --check`: clean (only CRLF autocrlf warnings on generated plugin registrants —
  environmental, no conflict markers).

### Dependencies (FACT, `app/pubspec.yaml`)

Already present — **no new package is required**:

| Package | Version | Relevant role |
|---|---|---|
| `file_picker` | ^8.3.7 (:45) | Already used: logo pick (`settings_screen.dart:126`, FileType.custom) and saveFile (`invoice_delivery.dart:76`). Supports Windows dialog + Android SAF/document picker; returns a cache-copied file path for content URIs. |
| `crypto` | ^3.0.6 (:39) | SHA-256 already used by importer (`workbook_importer.dart:101–104`). |
| `archive` / `xml` | ^3.6.1 / ^6.5.0 | XlsxReader ZIP+XML parsing. |
| `sqflite` (+ffi) | ^2.3.2 | Local DB + transactions. |
| `path_provider` | ^2.1.4 | Temp/app dirs (Android-safe materialization if needed). |

---

## 20.3 Canonical Objective

Replace the fixed/path-based workbook import experience with a user-selected-file workflow on
Windows and Android, preserving the existing validated import domain:

```text
SELECT FILE → VALIDATE → PREVIEW → CONFIRM → ATOMIC IMPORT → RESULT SUMMARY
```

- Windows: native file-open dialog (existing `file_picker` package).
- Android: SAF document picker semantics via the same `file_picker` abstraction (removes the
  Phase K temporary unavailable-card).
- The governing objective (D15, ARCHITECTURE_PLAN §14) is NOT altered by this plan.

---

## 20.4 Explicit In-Scope / Out-of-Scope

### In scope

1. User-selected source file (Windows native picker; Android SAF/document picker) replacing the
   typed-path TextField as the normal UX.
2. File-level + container-level + structure-level validation pipeline (.xlsx-only, ≤10 MB,
   readable/non-empty/valid XLSX container, six expected sheets, column/type sanity).
3. Observational preview (counts, warnings, blocking errors, row-error sampling) with ZERO DB
   mutation before confirmation.
4. Atomic all-or-nothing import with the batch row moved INSIDE the import transaction.
5. SHA-256 import identity: hash of selected bytes, stored in `import_batches`, duplicate
   detection, batch lifecycle.
6. Result summary contract (success/failure, batch id/hash, counts, warnings, rollback outcome).
7. Windows parity: remove active reliance on stored/default workbook path for import.
8. Android parity: SAF selection, permission-minimal (no storage permission), cancellation,
   lifecycle safety.
9. Sync handoff: enqueue resulting business entities through the existing queue machinery
   (opt-in parameter; see N-D13). No new cloud tables.
10. Tests for everything above; regression protection for existing importer semantics.

### Out of scope (governance exclusions — repeat of prompt §12/§25/§20.25)

- Migration 28 TEST deployment (stays NOT_DEPLOYED_ANYWHERE; Phase M residual — may be
  recommended as a separate companion gate, never absorbed here).
- DR-M05 / DR-M06 / DR-M07 resolutions (OPEN-GATE preserved).
- SR-2 full E2E; M-C17 completion; M-C30 completion.
- Temporary safe-default replacement beyond the workbook default path retirement that D15/PRE_A
  explicitly assign to Phase N.
- Phase O (invoice branding/delivery), Phase P (production hardening), camera barcode scanning,
  Play Store publishing, subscriptions, VAT/tax expansion, supplier/purchase domains,
  accounting redesign, global sync-runtime activation (DR-M09 gate untouched),
  unrelated Android feature expansion, unrelated inventory-conflict work.

---

## 20.5 Decision Register

| ID | Decision | Rationale | Evidence | Impact |
|---|---|---|---|---|
| N-D01 | Reuse `file_picker` (^8.3.7, already a dependency) as the single file-source abstraction; do NOT add new packages. | Package already proven in-app (logo pick/saveFile); supports Windows dialog + Android SAF; narrowest viable change; pubspec untouched semantics preserved. | pubspec.yaml:45; settings_screen.dart:126; invoice_delivery.dart:76 | One adapter interface; both platforms same call shape. |
| N-D02 | Introduce `WorkbookSource` abstraction (interface returning picked-file handle: path, size, display name, cancel signal) implemented by `PickerWorkbookSource`; pure-Dart so tests inject fakes. | Decouples UI/platform from importer; enables unit/widget testing without real dialogs. | INFERENCE from current hard-wired path strings (settings_screen.dart:1941) | New small lib file; settings screen refactored to it. |
| N-D03 | Windows implementation = `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions:['xlsx'])`; keep returned path-based IO. | Existing desktop pattern; dart:io File works unchanged with XlsxReader. | settings_screen.dart:126 precedent | Minimal Windows delta. |
| N-D04 | Android implementation = same `file_picker` call (SAF-backed). Plugin copies content URI into app cache and returns a path; we treat that cached copy as the working file. | Avoids manual MethodChannel/SAF plumbing; avoids persisting URI permissions entirely (read-once consumption). | file_picker SAF behavior; AndroidManifest has ONLY INTERNET permission (manifest:6) → no new permissions needed | No manifest change; process-death safe because nothing persists across sessions. |
| N-D05 | Content-URI strategy: consume immediately after pick (hash → validate → preview from the same cached copy); do NOT persist URI grant; re-pick required after app restart. | Read-once import needs no durable grant; eliminates URI-expiry class of bugs. | N-D04 | Simpler lifecycle; documented UX consequence. |
| N-D06 | Enforce `.xlsx` extension AND ≤10 MB size cap BEFORE any byte read/parsing; cap constant `maxWorkbookBytes = 10 * 1024 * 1024` in domain layer (not UI). | ARCHITECTURE_PLAN §14 security table mandates both; current importer has neither. Size checked from file metadata (no full read) then re-checked against actual byte length after read. | workbook_importer.dart (absence of checks); ARCHITECTURE_PLAN §14 | Two cheap early rejections. |
| N-D07 | Container/content validation: wrap ZipDecoder+XmlDocument.parse in guarded errors; reject non-zip, missing `xl/workbook.xml`, unreadable sheets, and archive entries whose decompressed ratio/total exceeds sane bounds (zip-bomb guard) before sheet mapping. | Malformed workbooks must fail gracefully, never crash (ARCHITECTURE_PLAN §14); XlsxReader currently trusts input. | xlsx_reader.dart:13–30 | XlsxReader gains defensive error types (additive). |
| N-D08 | Preview model = pure function over parsed sheets: `buildPreview(sheets)` → counts (products/sales/returns/expenses/adjustments incl. skipped-row tallies per current skip rules), warnings (zero-cost 'تحزية', rows skipped by existing rules), blocking errors (missing sheets, invalid numerics where detectable). Preview performs NO DB access. | Preflight (:116–169) already computes most signals; extending it keeps one validation truth. Mutation-forbidden preview satisfies governance. | workbook_importer.dart preflight | New preview DTO + builder; preflight reused. |
| N-D09 | Validation severity model: BLOCKING = missing sheet / corrupt container / oversized / wrong extension / zero-cost without allowance / no active shop; WARNING = zero-cost 'تحزية' (with explicit confirm toggle), skipped note/empty rows summary; INFO = informational counts. Warnings DO permit confirmation when each has an explicit user acknowledgment control; blocking errors never do. | Mirrors existing allowZeroCost confirmation pattern (:156–161). | workbook_importer.dart:147–161; settings_screen.dart:1961 | Deterministic gating in UI. |
| N-D10 | Transaction ownership: single sqflite transaction owned by the importer covers ALL business inserts AND the `import_batches` insert (batch row moves INSIDE the transaction; report computed inside, returned after). Rollback boundary = that transaction. Nothing else (no settings writes, no UI state) occurs inside. | Fixes the discovered crash-window defect (batch written post-commit at :472); guarantees no partial import AND no unbatched successful import. | workbook_importer.dart:193, :470–494 | Core correctness change. |
| N-D11 | SHA-256: hash the exact selected file bytes (the cached copy bytes on Android equal the original document bytes), computed once after selection, reused for duplicate-check + batch record; lowercase hex (current format). Hash stored ONLY locally in `import_batches.file_sha256` in Phase N. | Current hashing logic (:101–104) retained; identity = content, never filename. | workbook_importer.dart:101–104, :445 | No behavioral surprise. |
| N-D12 | Duplicate semantics: keep GLOBAL `file_sha256` UNIQUE (zero local migration). Same-content re-selection → DUPLICATE_DETECTED terminal state showing original `imported_at`; failed/rolled-back imports leave NO batch row → retry with identical file is legal; same-name/different-content = different batch (allowed); different-name/same-content = duplicate (rejected). Per-shop uniqueness scoping recorded as CONDITIONAL future follow-up only if owner requests cross-shop re-import of identical bytes. | Zero-migration preference (prompt §20.13); current constraint + query are already global (:539, :455); workbooks are month-scoped per shop so collisions are edge-case; surfacing DUPLICATE_DETECTED is honest behavior. | database_helper.dart:539; workbook_importer.dart:455 | No v16 migration needed. |
| N-D13 | Batch lifecycle & sync handoff: add opt-in `enqueueSync` flag (default true for the new UI flow). When true, within the SAME transaction, enqueue resulting business entities (products/sales/returns/expenses/inventory_count) via the existing `_enqueueAfterWrite` machinery so they carry normal idempotency keys/occurrence tokens; the `import_batches` row itself is NOT enqueued (no adapter, stays local audit). Callers needing old behavior (tests, potential future orchestrator reuse) pass false. | PHASE_H §7 assigns "workbook sync" ownership to N with minimum meaning = imported business data participates in ordinary entity sync; batch cloud persistence adds no required behavior. Queue drain timing remains governed by existing sync runtime gates (DR-M09 untouched). | database_helper.dart:250–305, :89–185; sync adapters dir; PHASE_H §7 | Imported data becomes cloud-reachable through the standard, already-proven path. |
| N-D14 | DECISION_N_CLOUD_BATCHES = **NOT_REQUIRED**. | Canonical Phase N behavior (select/validate/preview/atomic/dedup/summary) is fully satisfied by local `import_batches`; cloud batch table would add migration+RLS+sync surface with no user-visible requirement. PHASE_G §32.2 wording is permissive ("as needed"), not mandatory. PRODUCTIZATION_MIGRATION_PLAN Step 9 mentions uploading import_batches, but PHASE_I explicitly excludes import_batches from the migration universe — the hierarchy resolves in favor of the specific Phase I/G exclusions. | PHASE_G §32.2; PHASE_I lines 59/81; local table already has cloud_uuid column reserved for the future | No Supabase change in Phase N. |
| N-D15 | Retire pinned `expectedSha256` gate from the USER flow: new UI flow never passes skipShaCheck:false; constant + param remain for backward compatibility/tests. Dedup responsibility transfers wholly to import_batches. | A pinned single-file signature contradicts D15 (user-selected arbitrary valid workbook); PRE_A flags the hardcoded default for removal; structural validation (N-D07/N-D08) replaces the pin as the trust mechanism. | workbook_importer.dart:89–90, :446–453; PRE_A register line 162 | Old pin becomes dead-in-UI but non-breaking. |
| N-D16 | UI replacement strategy: replace the path TextField + button with a select→preview→confirm wizard section inside Settings; REMOVE `AppSettings.getWorkbookPath()/setWorkbookPath()/getDefaultWorkbookPath()` from the import flow. Keep the `workbookPath` settings KEY known (cloud settings validation test still references it) but mark the legacy getters deprecated; delete `getDefaultWorkbookPath()` probing only if its last consumer is removed in this phase (CONDITIONAL, verified at implementation time). | D15 "no fixed path"; PRE_A remediation; cloud_service_validation_test.dart:144 constrains key removal. | settings_screen.dart:34–97, :464–502, :1940–1982; app_settings.dart:108–118, :208+ | Windows UX loses manual path entry; legacy discovery retired. |
| N-D17 | Result summary contract (final, frozen): `{status: SUCCEEDED|FAILED_ROLLED_BACK|DUPLICATE_DETECTED|CANCELLED|INVALID, batchId?, fileSha256, fileName, counts{products,sales,returns,expenses,adjustments}, warnings[], errors[], rolledBack:boolean}` — rendered from the importer's return value + caught typed exceptions. | Extends existing `ReconciliationReport` (kept intact) with status envelope; Arabic-renderable messages. | workbook_importer.dart:8–63 | Stable contract for UI + tests. |
| N-D18 | Testing strategy: fake `WorkbookSource` for widget tests; real sqflite (ffi) DB tests for atomicity/rollback/duplicate/hash; XlsxReader corruption fixtures built in-test (truncated zip, renamed .txt, oversized synthetic entry). Manual verification matrix for real Windows dialog + real Android SAF device. | Mirrors existing test styles (workbook_import_test.dart uses repo fixture workbook). | test/database/workbook_import_test.dart:16–30 | High-confidence, platform-independent coverage. |
| N-D19 | Rollback strategy: local transaction rollback is the only guaranteed rollback; sync-queue rows enqueued in the same transaction vanish with it; already-uploaded cloud effects are NOT promised reversible (consistent with local≠distributed atomicity bias). Feature fallback: keep the legacy typed-path flow compiled behind the removed-UI seam for one release? **NO** — D15 forbids fixed path as normal UX; instead, picker failure yields explicit SELECTION_ERROR with retry guidance. | Prompt §20.22; no impossible distributed promises. | — | Honest failure model. |

---

## 20.6 Functional Requirements

| ID | Requirement (objectively testable) |
|---|---|
| N-FR01 | On Windows, tapping "استيراد بيانات Excel" opens a native open dialog filtered to `.xlsx`; no text field is presented. |
| N-FR02 | On Android, the same action opens the system document picker filtered to `.xlsx`; the Phase K unavailable-card for THIS feature is removed. |
| N-FR03 | Cancelling the picker/dialog returns the app to IDLE with no state change and no error surfaced. |
| N-FR04 | A selected file whose extension ≠ `.xlsx` is rejected with a blocking error before reading bytes. |
| N-FR05 | A selected file > 10 MB is rejected with a blocking error before parsing; the cap is enforced in the domain layer. |
| N-FR06 | A non-XLSX payload renamed to `.xlsx` fails container validation with a clear corrupt-file error and no DB mutation. |
| N-FR07 | A workbook missing any of the six required sheets fails validation listing the missing sheet names (existing Arabic message preserved). |
| N-FR08 | Rows violating existing skip/type rules are tallied in preview (skipped counts) and do not block by themselves. |
| N-FR09 | Zero-cost products behave exactly as today ('تحزية' exception + explicit allowZeroCost confirmation). |
| N-FR10 | Preview displays per-entity counts, warnings, blocking errors, and up to the first 50 row-level errors, WITHOUT any DB write (asserted by test comparing DB state hash before/after preview). |
| N-FR11 | Confirmation is disabled while blocking errors exist; enabled with warnings only after explicit acknowledgments. |
| N-FR12 | Confirming runs the entire import + batch-record insert in ONE transaction; success produces the result summary with batch id and counts. |
| N-FR13 | An injected failure mid-import (test hook) leaves ZERO business rows and ZERO batch rows (full rollback verified). |
| N-FR14 | After success, re-selecting byte-identical content (even renamed) yields DUPLICATE_DETECTED showing the original `imported_at`; no second import occurs. |
| N-FR15 | After FAILED_ROLLED_BACK, re-importing the same file is permitted and succeeds. |
| N-FR16 | The stored/legacy default workbook path is NOT consulted by the new import flow at any point. |
| N-FR17 | Every imported row is stamped with the active shop; import without an active shop context fails closed (existing behavior preserved). |
| N-FR18 | With `enqueueSync:true` (default in new UI), successful import leaves pending sync_queue entries for each imported business entity; with `enqueueSync:false`, none. |
| N-FR19 | The result summary renders status, file name, SHA-256 (short form), counts, warnings, and rollback outcome; all strings render correctly in the RTL Arabic UI. |

---

## 20.7 Non-Functional Requirements

| ID | Requirement |
|---|---|
| N-NFR01 | Security: extension + size + container + structure validation layered (UI → domain → persistence constraints); no arbitrary-path trust; no execution of file content; hash handled as opaque identifier. |
| N-NFR02 | Atomicity: all-or-nothing including the batch record (N-D10); rollback trigger = any exception inside the transaction. |
| N-NFR03 | Performance: ≤10 MB workbooks parse/import within existing interactive budgets on target hardware; size check precedes reads; no redundant full-file reads (single read reused for hash+parse via the cached copy). |
| N-NFR04 | Memory: streaming-conscious limits — reject archives whose inflated size exceeds a sane multiple of the 10 MB cap (zip-bomb guard, N-D07). |
| N-NFR05 | Android lifecycle: picker flow tolerates backgrounding during pick; import itself runs in Dart with progress state; process death mid-flow loses only the ephemeral selection (documented UX), never data integrity. |
| N-NFR06 | Accessibility/RTL: all new UI follows existing Directionality.rtl patterns; semantic labels on buttons and progress indicators. |
| N-NFR07 | Error clarity: stable machine categories (§20.18) with human-readable Arabic messages; no raw stack traces in user-facing surfaces. |
| N-NFR08 | Offline: entire flow works fully offline; sync enqueue is local-only; no network dependency added. |
| N-NFR09 | Tenant isolation: shop stamping unchanged (fail-closed without active shop); batch lookup remains scoped per N-D12 decision (global uniqueness retained deliberately). |
| N-NFR10 | Idempotency: sync enqueue reuses occurrence-token machinery; duplicate replay of queue entries cannot double-upload (existing INV-M19 guarantee). |

---

## 20.8 Import State Machine

Repository-compatible terminology (extends existing `_isImporting` boolean into explicit states):

```text
IDLE
 └─ SELECTING          (picker open; cancellable)
     ├─ CANCELLED ──▶ IDLE
     └─ READING       (size/ext checks; byte access)
         ├─ INVALID ──▶ IDLE   (terminal for this attempt; reason shown)
         └─ VALIDATING  (container + structure + preflight)
             ├─ INVALID ──▶ IDLE
             ├─ DUPLICATE_DETECTED ──▶ IDLE (terminal; shows prior imported_at)
             └─ PREVIEW_READY (observational; mutations forbidden)
                 ├─ CANCELLED ──▶ IDLE (discard parsed state)
                 └─ IMPORTING (transaction open)
                     ├─ FAILED_ROLLED_BACK ──▶ IDLE (no data; retry legal)
                     └─ SUCCEEDED ──▶ IDLE (summary shown; batch recorded)
```

Terminal states per attempt: `INVALID`, `DUPLICATE_DETECTED`, `FAILED_ROLLED_BACK`,
`SUCCEEDED`, `CANCELLED`. All terminal states return to IDLE; only `SUCCEEDED` mutates data.

---

## 20.9 Validation Pipeline

Ordered stages; first failing BLOCKING stage stops the pipeline:

| Stage | Layer | Checks |
|---|---|---|
| V1 file-level | domain (pre-read) | extension == .xlsx; size ≤ 10 MB; file accessible/non-empty |
| V2 container-level | XlsxReader (guarded) | valid ZIP; zip-bomb bounds; `xl/workbook.xml` present/parseable |
| V3 workbook-structure | preflight (existing) | six required sheets present (existing Arabic error) |
| V4 row-level | preflight/preview (new tally) | numeric parseability, min-column presence, skip-rule tallies (note rows, empty name/barcode, الإجمالي terminators) |
| V5 cross-row/domain | preflight (existing) | zero-cost rule + 'تحزية' exception; duplicate barcode awareness reported as warning tally |
| V6 database validation | importer | active shop context (fail-closed); `file_sha256` duplicate probe |
| V7 persistence constraints | SQLite | NOT NULL / UNIQUE enforcement as final backstop |

Severity model per N-D09: BLOCKING (never confirmable), WARNING (confirmable with explicit
acknowledgment), INFORMATIONAL (display only).

---

## 20.10 Preview Contract

- Built by `buildPreview(sheets)` (pure; no `Database` parameter — structurally incapable of mutation).
- Shows: entity counts (products/sales/returns/expenses/adjustments), skipped-row tallies per rule,
  warnings (zero-cost 'تحزية' with name/barcode, ambiguous duplicates count), blocking errors,
  first ≤50 row-level errors (with sheet+row index), total error count if truncated.
- Sensitive data: only what the workbook already contains locally; no cloud transmission during preview.
- Parsed state: held in memory for the session only; discarded on cancel/navigation.
- Confirmation: re-runs the REAL importer from the same selected bytes (authoritative path), NOT
  from preview state — preview can never diverge from what commits (re-parse cost acceptable at
  ≤10 MB). The duplicate probe runs again at import time; a race between preview and confirm
  resolves conservatively (duplicate → DUPLICATE_DETECTED).

---

## 20.11 Atomicity & Transaction Design

```text
TRANSACTION ENTRY : db.transaction((txn) async { ... })   — opened ONLY in the import orchestrator
INSIDE  TXN       : products/sales/returns/expenses/inventory_count inserts (existing _applyImport body)
                    + optional sync_queue enqueues via _enqueueAfterWrite(executor: txn)  [N-D13]
                    + import_batches insert (MOVED inside; N-D10)
ROLLBACK TRIGGER  : any thrown exception inside the block → sqflite rolls back EVERYTHING
TRANSACTION EXIT  : commit → compute/return ReconciliationReport (pure computation)
OUTSIDE TXN       : UI state, snackbar/result rendering, nothing persistent
```

What must NEVER happen inside: settings writes, license calls, navigation, network I/O.
The current post-commit batch insert (workbook_importer.dart:472–494) is eliminated.

---

## 20.12 SHA-256 / Duplicate Import Contract

| Aspect | Contract |
|---|---|
| Hash source | Exact bytes of the selected/cached file (`sha256(bytes)` lowercase hex — unchanged algorithm) |
| When calculated | Once after selection, before validation; reused for duplicate probe and batch record |
| Storage | Local `import_batches.file_sha256` only (cloud storage out of scope per N-D14) |
| Uniqueness boundary | SQLite UNIQUE on `file_sha256` (global) — deliberate, zero-migration (N-D12) |
| Shop scoping | Batch rows carry `shop_id` for attribution; uniqueness intentionally NOT per-shop in Phase N |
| Duplicate behavior | Pre-parse rejection → `DUPLICATE_DETECTED` with original `imported_at` |
| Retry semantics | Rolled-back/failed imports leave no batch row → same file legally re-importable |
| Same content / different name | DUPLICATE (content is identity) |
| Same name / different content | Distinct batch (allowed) |
| Filename | Recorded for display only; never part of identity |

---

## 20.13 Local Database Design

**Zero migration.** Schema version stays 15. Existing structures satisfy every requirement:

- `import_batches` already has `file_sha256 UNIQUE`, counts, financials, `shop_id`, `cloud_uuid`.
- `sync_queue` already supports arbitrary entity enqueue with idempotency keys.
- No DDL changes, no backfill, no index changes, no version bump.

(CONDITIONAL future note, NOT Phase N: per-shop hash scoping would require v16 replacing the
UNIQUE index with `UNIQUE(shop_id, file_sha256)` — only if the owner ever requests cross-shop
identical-byte imports.)

---

## 20.14 Supabase Decision

```text
DECISION_N_CLOUD_BATCHES = NOT_REQUIRED
```

Justification: canonical Phase N behavior is fully local (N-D14 rationale). Business entities
reach the cloud through the EXISTING per-entity sync pipeline (N-D13) — no new cloud table, no
RLS authoring, no Supabase migration, no deployment. The `import_batches.cloud_uuid` column
reserved by earlier phases remains available if a future phase elects cloud batch persistence.
No SQL is created or deployed in this planning session.

---

## 20.15 Sync Contract

Minimum meaning of PHASE_H's "Phase N handles workbook sync", resolved against repository reality:

1. Does Phase N enqueue imported entities into the normal sync queue? **YES** — via
   `_enqueueAfterWrite` inside the import transaction (`enqueueSync:true` default; N-D13).
2. Does it sync only resulting business entities? **YES** — products, sales, returns, expenses,
   inventory_count; these have proven adapters.
3. Does an import batch itself need cloud representation? **NO** (N-D14).
4. No-echo preservation: unchanged — enqueue payloads carry shop_id + occurrence tokens; the
   existing download/no-echo filters apply verbatim; Phase N introduces no new cloud routes.
5. Local atomic vs asynchronous cloud: local commit is authoritative; queue drains per existing
   engine scheduling; sync runtime activation stays gated (DR-M09 untouched).
6. Can cloud sync failure roll back a committed local import? **NO** — explicitly not promised
   (local transaction atomicity ≠ distributed transaction). Failed uploads retry via existing
   queue mechanics with occurrence-token idempotency.

---

## 20.16 Windows UX

Journey: open Settings → "استيراد بيانات Excel" section shows a select button (no path field) →
native `.xlsx` dialog → automatic validation with progress → preview panel (counts/warnings/
errors + zero-cost acknowledgment checkbox when applicable) → confirm button (disabled while
blocking) → progress during import → result summary → done/back to IDLE. Cancel available at
selection and preview. Errors surface as inline Arabic messages + snackbar, categorized per §20.18.

Old workbook-path setting: the TextField, `_workbookPathController`, `AppSettings.get/setWorkbookPath`
and `getDefaultWorkbookPath()` are removed from the ACTIVE import flow (N-D16). The
`workbookPath` key remains known to cloud-settings validation (test constraint at
`cloud_service_validation_test.dart:144`); legacy getters are marked deprecated and deleted only
if their last reference is within this phase's touched set (CONDITIONAL, verified during
implementation).

---

## 20.17 Android UX

- Same visual flow as Windows; the select button invokes the system document picker (SAF) via
  `file_picker` (N-D04). The Phase K unavailable card for Excel import is REPLACED by the live
  flow (this is the Phase N deliverable K explicitly deferred to).
- Permissions: NONE added. SAF read access is granted by the picker itself; the manifest keeps
  only INTERNET (verified manifest:3–6).
- Content URI: consumed once through the plugin's cache copy (N-D05); no persisted grants; no
  manual `ContentResolver` code.
- Size check: performed on the returned cached file metadata before parsing.
- Lifecycle: backgrounding during pick is safe (system activity); process death discards only
  the ephemeral selection; import runs with visible progress; no work scheduled past app death.
- Cancel: system back/dismiss maps to CANCELLED.
- Large files: the 10 MB cap rejects before heavy work; parsing remains synchronous-but-bounded
  (≤10 MB), executed after a yielding frame so the spinner paints.

---

## 20.18 Error Model

Stable categories (machine) → Arabic message pattern (human):

| Category | Trigger | Blocking? |
|---|---|---|
| SELECTION_ERROR | picker unavailable/plugin failure | retry guidance shown |
| ACCESS_ERROR | unreadable/empty file | yes |
| UNSUPPORTED_FILE | extension ≠ .xlsx | yes |
| OVERSIZED_FILE | > 10 MB | yes |
| CORRUPT_WORKBOOK | non-zip / bad XML / bomb-guard trip | yes |
| SCHEMA_MISMATCH | missing sheet(s)/columns | yes (lists specifics) |
| VALIDATION_FAILURE | zero-cost w/o ack; row-type failures | per N-D09 |
| DUPLICATE_IMPORT | sha match in import_batches | terminal info |
| DATABASE_FAILURE | sqlite error during txn | yes |
| ROLLBACK_FAILURE | commit/rollback anomaly (defensive) | yes — surfaced loudly, DB left consistent-by-sqlite |
| INTERNAL_UNEXPECTED | anything else | logged + generic Arabic message |

All messages composed from category templates → clean RTL rendering; no exception interpolation
of raw English stack traces into user text (improves on current `'$e'` usage at
settings_screen.dart:1975).

---

## 20.19 Test Matrix

| ID | Coverage | Class |
|---|---|---|
| N-T01 | WorkbookSource abstraction returns handle; fake injection works | unit |
| N-T02 | Picker adapter (Windows) delegates to FilePicker with xlsx filter | platform-adapter (mocked channel) |
| N-T03 | Picker adapter (Android) delegates identically; no permission APIs touched | platform-adapter (mocked channel) |
| N-T04 | Picker cancel → CANCELLED, state IDLE, no side effects | widget |
| N-T05 | Valid .xlsx end-to-end: preview counts == committed counts == report counts | integration/db |
| N-T06 | Extension rejection (.xls/.txt/.xlsx.exe naming variants) | unit |
| N-T07 | Oversize rejection at 10 MB + 1 byte (synthetic) | unit |
| N-T08 | Corrupt workbook: truncated zip; text-renamed-.xlsx; missing workbook.xml | db/unit |
| N-T09 | Missing-sheet failure lists all missing names (regression of :120–124) | unit |
| N-T10 | Missing/short columns → skip tallies match legacy skip rules | unit |
| N-T11 | Invalid row values → row-level errors listed, capped at 50 | unit |
| N-T12 | Preview performs zero DB mutation (DB digest before/after equal) | integration/db |
| N-T13 | Successful import: single txn; products/sales/returns/expenses/inventory_count + batch row all present | integration/db |
| N-T14 | Late-failure injection → zero business rows AND zero batch rows (rollback incl. batch) | db |
| N-T15 | Hash correctness vs known SHA-256 vector; lowercase hex | unit |
| N-T16 | Same-content-different-name → DUPLICATE_DETECTED with original timestamp | db |
| N-T17 | Same-name-different-content → distinct batch accepted | db |
| N-T18 | Failed import then retry same file succeeds | db |
| N-T19 | Result summary contract fields complete for each terminal state | widget |
| N-T20 | Batch tracking fields (shop_id, counts, reconciliation_json) unchanged semantics | db (regression of import_stamping_test.dart) |
| N-T21 | enqueueSync true → pending queue rows exist; false → none; occurrence tokens present | db |
| N-T22 | Tenant isolation: no active shop → fail-closed message preserved | db (regression) |
| N-T23 | Android lifecycle: simulated process death between pick and confirm leaves DB untouched | unit (state-machine) |
| N-T24 | Windows path replacement: getWorkbookPath/getDefaultWorkbookPath not invoked by new flow (static assertion/test) | widget |
| N-T25 | Full regression of existing workbook_import_test.dart suite (35 tests) stays green | db/regression |

Manual verification (recorded, not automated): real Windows dialog run; real Android device SAF
run incl. backgrounding mid-pick and mid-preview.

---

## 20.20 Implementation Slices

| Slice | Content | Files | Tests | Entry gate | Exit gate | Depends on |
|---|---|---|---|---|---|---|
| N-S1 | WorkbookSource abstraction + domain validation constants (extension/size/bomb bounds) + typed error taxonomy | ADD `lib/import/workbook_source.dart`, `lib/import/workbook_validation.dart` (or adjacent to importer per house style) | N-T01, N-T06, N-T07 | baseline green | analyze clean; unit green | — |
| N-S2 | Platform picker adapters (Windows + Android via file_picker) behind N-S1 interface | ADD `lib/import/picker_workbook_source.dart` | N-T02, N-T03, N-T04 | N-S1 | mocked-channel tests green | N-S1 |
| N-S3 | Hardened XlsxReader (byte-entry + guards) + preview/validation model | MODIFY `lib/database/xlsx_reader.dart`; ADD preview builder near importer | N-T08, N-T10, N-T11, N-T12 | N-S1 | corrupt fixtures rejected; preview mutation-free proven | N-S1 |
| N-S4 | Atomic import orchestration (batch-inside-txn; report-from-within) | MODIFY `lib/database/workbook_importer.dart` | N-T05, N-T13, N-T14, N-T18, N-T20, N-T22, N-T25 | N-S3 | full rollback incl. batch proven; legacy suite green | N-S3 |
| N-S5 | SHA-256/idempotency wiring (hash-once; duplicate probe; enqueueSync flag via _enqueueAfterWrite) | MODIFY `workbook_importer.dart`; touch `database_helper.dart` only if executor plumbing requires | N-T15–T18, N-T21 | N-S4 | duplicate + enqueue contracts proven | N-S4 |
| N-S6 | Windows UI (wizard section; retire path field) | MODIFY `lib/screens/settings_screen.dart`; deprecate legacy AppSettings getters per N-D16 | N-T19, N-T24 | N-S5 | new flow green; no path-field remnants in import flow | N-S5 |
| N-S7 | Android UI (replace unavailable card with live flow) | MODIFY `settings_screen.dart` Android branch | N-T23 + widget parity tests | N-S6 | Android branch uses same flow; no manifest change | N-S6 |
| N-S8 | Sync handoff verification (queue drain compatibility; no-echo unchanged) | no new prod code expected | N-T21 extension | N-S5 | queue rows consumable by existing engine tests | N-S5 |
| N-S9 | Regression/closure verification + manual matrices recorded | none | N-T25 + full suite | all prior slices | exit criteria §20.26 met | N-S1..S8 |

Each slice = independently verifiable; commit series per slice per repository convention
(local commits only).

---

## 20.21 File-Level Change Map

| File/group | Action | Notes |
|---|---|---|
| `app/lib/import/workbook_source.dart` (new) | ADD | N-S1/S2 abstraction + adapters home (exact location follows importer adjacency conventions) |
| `app/lib/import/workbook_validation.dart` (new) | ADD | constants, error taxonomy, severity model |
| `app/lib/database/xlsx_reader.dart` | MODIFY | guarded container parsing, optional byte entry, bomb bounds |
| `app/lib/database/workbook_importer.dart` | MODIFY | batch-inside-txn, hash-once, enqueueSync flag, preview builder support, deprecate pinned-hash gate in UI path |
| `app/lib/screens/settings_screen.dart` | MODIFY | wizard section both platforms; remove path TextField/_controller usage in import flow; remove Android unavailable card FOR THIS FEATURE only |
| `app/lib/services/app_settings.dart` | CONDITIONAL MODIFY | deprecate/remove workbook-path getters per N-D16 (key retained for cloud-validation test) |
| `app/lib/database/database_helper.dart` | CONDITIONAL MODIFY | only if _enqueueAfterWrite needs executor exposure for raw-txn callers |
| `app/pubspec.yaml` / `pubspec.lock` | NO CHANGE | file_picker/crypto already present (N-D01) |
| `app/android/**` (incl. AndroidManifest.xml) | NO CHANGE | SAF needs no permission/plugin registration beyond file_picker (already registered) |
| `app/windows/**` | NO CHANGE | standard Win32 dialog ships with file_picker |
| supabase/** | NO CHANGE | N-D14 |
| `app/test/import/**` (new group) | ADD | N-T01..N-T24 homes |
| `app/test/database/workbook_import_test.dart` | MODIFY (minimal) / NO CHANGE | keep as regression anchor; adjust only where constructor seams change |
| Sacred artifacts | NO CHANGE (never touched) | MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md; delivery/I-TECH-Delivery-v1.0.0.zip |

No DELETE actions anticipated; any deletion arises only inside N-D16's CONDITIONAL clause with
reference-proof at implementation time.

---

## 20.22 Migration / Rollback Strategy

- Local schema: zero migration → nothing to roll back (N-D12/N-D13).
- Import transaction: sqflite rollback is complete and includes the batch row (N-D10).
- UI fallback: if a picker fails at runtime (plugin/dialog error), SELECTION_ERROR with retry;
  the legacy fixed-path flow is NOT resurrected (D15).
- Cloud: no cloud migration exists to roll back; enqueued-but-unsynced rows simply age in
  sync_queue per existing retention/retry semantics; already-synced third-party effects are not
  promised reversible.
- Feature disable: a compile-time seam (the N-S1 interface) allows reverting the UI to a
  "feature temporarily unavailable" card without touching the domain layer, if a release blocker
  ever demands it.

---

## 20.23 Security Threat Matrix

| Threat | Control |
|---|---|
| Fake .xlsx (renamed payload) | extension filter + container validation (V1/V2) + graceful CORRUPT_WORKBOOK |
| Zip bomb / resource exhaustion | inflated-size bound vs 10 MB cap; bounded parse; early oversize rejection |
| Oversized file | domain-layer 10 MB cap before read (metadata check + post-read recheck) |
| Malformed XML/package | XmlDocument.parse wrapped; typed failures; never crash |
| Unexpected worksheet structure | V3/V4 with explicit Arabic specifics (existing messages preserved) |
| Path misuse / arbitrary-path trust | path never user-typed; only picker-returned handles; no path persistence in flow |
| Android URI expiry | read-once consumption; no persisted grants (N-D05) |
| Cross-shop batch exposure | batches attributed via shop_id; uniqueness policy per N-D12; no cross-shop UI surface added |
| Duplicate replay | content-hash UNIQUE + DUPLICATE_DETECTED terminal state |
| Partial mutation | single-transaction design incl. batch row; injected-failure test N-T14 |
| Sync replay | occurrence tokens + idempotency keys (existing INV-M19) reused unchanged |

Layered validation ownership: UI validation (affordances/disabled buttons) · domain validation
(V1–V5) · persistence validation (V6–V7, SQLite constraints) · cloud authorization (unchanged
entity-sync RLS; no new cloud surface in Phase N).

---

## 20.24 Traceability Matrix

| Governance requirement | Decision | Slice | Tests | Exit criterion |
|---|---|---|---|---|
| D15 user-selected file | N-D01/D03/D04/D16 | N-S2, N-S6, N-S7 | N-T01–T04, T24 | Windows+Android flows verified; no path field |
| .xlsx only / ≤10 MB / content checks | N-D06/D07 | N-S1, N-S3 | N-T06–T08 | rejection tests green |
| Preview before mutation | N-D08/D09 | N-S3 | N-T11, N-T12 | zero-mutation proof green |
| Atomic import | N-D10 | N-S4 | N-T13, N-T14 | rollback incl. batch proven |
| SHA-256 identity/dedup | N-D11/D12/D15 | N-S5 | N-T15–T18 | duplicate contract verified |
| Result summary | N-D17 | N-S6/S7 | N-T19 | summary renders all terminals |
| Windows support (retire fixed path) | N-D03/D16 | N-S6 | N-T24, manual | manual matrix recorded |
| Android support (SAF, minimal perms) | N-D04/D05 | N-S7 | N-T03, N-T23, manual | manual matrix recorded; manifest untouched |
| Domain preservation | N-D08/D10 (reuse preflight/_applyImport) | N-S3/S4 | N-T25 | legacy 35-test suite green |
| Workbook sync (H §7 minimal meaning) | N-D13 | N-S5, N-S8 | N-T21 | enqueue contract green |
| cloud_import_batches conditional | N-D14 | none | none | NOT_REQUIRED documented |
| Security requirements (ARCH §14) | N-D06/D07/D11 | N-S1/S3 | N-T06–T08, T15 | threat matrix controls tested |

---

## 20.25 Explicit Non-Goals

Restated for closure (identical to §20.4 out-of-scope list): Migration 28 TEST deployment;
DR-M05/M06/M07; SR-2 full E2E; M-C17; M-C30; temporary safe-default replacement beyond the D15
workbook-default retirement; Phase O; Phase P; camera scanning; Play Store; subscriptions; VAT;
supplier/purchase domains; accounting redesign; sync-runtime activation (DR-M09); unrelated
Android/inventory work.

---

## 20.26 Exit Criteria (for the future implementation session)

1. `flutter analyze`: 0 errors, 0 warnings (info-lint count must not increase vs the recorded
   baseline of 60).
2. `flutter test`: green except the rigorously documented 7 pre-existing failures carried from
   the Phase M baseline (same set, same root cause) — any NEW failure blocks closure.
3. All Phase N tests (N-T01..N-T25) green.
4. `git diff --check`: clean.
5. Windows import flow manually verified end-to-end (recorded evidence).
6. Android import flow manually verified on a real device (recorded evidence).
7. Preview proven to perform zero DB mutation (N-T12).
8. Failed import proven to leave no partial business data AND no batch row (N-T14).
9. SHA-256 duplicate contract verified incl. rename and retry cases (N-T15–T18).
10. Sacred artifacts (`MUAMAN_STORE_VERIFIED_SOURCE_OF_TRUTH_REPORT.md`,
    `delivery/I-TECH-Delivery-v1.0.0.zip`) untouched: untracked, byte-identical
    (SHA-256 3D4D170DBFB2A0BD9834A128EF366E0C99B98681AD13BFE1DD877A179A4B4E07 /
    70F8480DE78086A88E56610CC6B4E623E5902C067A30FD5BCD90833ED1773418).
11. No unrelated scope absorbed; pubspec/manifest/Supabase untouched.
12. Clean repository; local commits only; no tags created by implementation (tagging belongs to
    the subsequent lock session).

PRE_IMPLEMENTATION_EXTERNAL_GATE_RECOMMENDATION (non-blocking, outside Phase N scope):
Migration 28 TEST deployment remains a Phase M residual; if the owner intends Phase N
implementation to interact with any TEST-project Supabase environment, deploying Migration 28
first—via a separate authorized session—is recommended to keep environment state coherent.
Phase N itself requires no cloud change (N-D14).

---

## 21. File Picker Package Decision (record)

```text
PACKAGE CANDIDATE : file_picker (ALREADY IN pubspec.yaml ^8.3.7 — no addition needed)
ROLE              : unified open-dialog (Windows) + SAF document picker (Android); returns
                    cache-copied path for content URIs
PLATFORMS         : Windows, Android (both Phase N targets) — verified in-package usage today
WHY NOT MANUAL    : hand-rolling Win32 dialogs + SAF MethodChannel would add native surface,
                    review burden, and risk contrary to "narrowest viable approach"
RISK              : plugin major-version drift (mitigated: already locked in lockfile; API used
                    is the simple pickFiles subset already exercised in-app)
LICENSING         : MIT (pub.dev) — no material concern
pubspec.yaml      : NOT modified in planning (rule honored)
```

---

END OF PLAN — frozen by the PHASE_N_PLANNING session at baseline
8a8c267701060dc185cd70bd65a3be4834a91783.
