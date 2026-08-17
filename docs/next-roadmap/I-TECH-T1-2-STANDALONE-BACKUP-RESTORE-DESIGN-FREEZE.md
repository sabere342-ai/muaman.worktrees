# I-TECH T1-2: Standalone Backup / Restore Design Freeze

## 1. Executive Decision

**A — DESIGN FREEZE / FOLLOW ROADMAP**

The standalone backup/restore design contract is frozen. This document defines the authorized scope for a future implementation step. No production code is modified in this session.

## 2. Governing Context

| Item | Value |
|---|---|
| Frozen Roadmap | `docs/next-roadmap/I-TECH-NEXT-ROADMAP-FREEZE.md` @ `2295137` |
| Previous step | T1-1 (Brand Color Consumption) @ `ade506a` |
| This step | T1-2: Standalone Backup / Restore Design Freeze |
| Step type | Design freeze only — NOT implementation |
| Author | opencode / codex agent |

## 3. Current State — What Exists Today

### Backup Infrastructure

| Component | Status | Location |
|---|---|---|
| Backup creation | EXISTS — but only within clean-start flow | `clean_start_service.dart:129-161` |
| VACUUM INTO | EXISTS — single usage at line 146 | `clean_start_service.dart:146` |
| Backup verification | EXISTS — PRAGMA integrity_check + table check | `clean_start_service.dart:166-190` |
| Backup UI | EXISTS — directory picker inside clean-start dialog | `settings_screen.dart:668-761` |
| Standalone backup | DOES NOT EXIST | — |
| Restore from backup | DOES NOT EXIST | — |
| Backup directory preference | DOES NOT EXIST | — |
| Automatic/scheduled backup | DOES NOT EXIST | — |
| Backup encryption | DOES NOT EXIST | — |
| Retention policy | DOES NOT EXIST | — |

### Current Backup Flow (Clean-Start Only)

```
Owner → Settings → Clean Start section
  → Pick backup directory (FilePicker)
  → Type confirmation phrase "مسح البيانات"
  → CleanStartService.run()
    → _createBackupSnapshot()
      → VACUUM INTO <directory>/muaman_cleanstart_<timestamp>.db
      → Verify file exists and is non-empty
      → Open backup with independent connection
      → PRAGMA integrity_check
      → Verify at least one table exists
    → db.transaction() → wipe 7 transactional tables
    → Preserve users, role_permissions, app_settings
    → Return CleanStartReport
  → Show result dialog with deletion counts + backup path
```

### Current Backup File Format

- Format: Raw SQLite database file (`.db`)
- Created by: `VACUUM INTO` (compact, consistent snapshot of ALL tables)
- Filename pattern: `muaman_cleanstart_<timestamp>.db`
- Location: User-selected directory via FilePicker
- Contents: Complete database copy (all 10 tables, all rows)

### Current Database Schema (Version 6)

| Table | Purpose | Row Count Impact |
|---|---|---|
| `products` | Product catalog with stock tracking | Transactional |
| `sales` | Sale line items | Transactional |
| `returns` | Return line items | Transactional |
| `expenses` | Expense records | Transactional |
| `inventory_count` | Stocktake records | Transactional |
| `invoices` | Invoice headers | Transactional |
| `import_batches` | XLSX import audit | Transactional |
| `users` | User accounts | Preserved |
| `role_permissions` | Permission grants | Preserved |
| `app_settings` | Configuration key-value | Preserved |

## 4. Design Contract — Standalone Backup

### 4.1 Objective

Allow the owner to create a backup of the database at any time, without triggering any destructive operation.

### 4.2 Service Contract

```
StandaloneBackupService.createBackup({
  required String destinationDirectory,
})
→ Future<StandaloneBackupReport>
```

**Behavior:**
1. Validate destination directory exists and is writable
2. Create backup filename: `muaman_backup_<YYYY-MM-DD_HH-mm-ss>.db`
3. Execute `VACUUM INTO '<escaped_path>'`
4. Verify backup: file exists, is non-empty, PRAGMA integrity_check passes
5. Return report with: timestamp, backup path, file size, table count

**Preconditions:**
- Caller must be owner (enforce via existing `_requireOwner()` pattern)
- Database must be open and accessible

**Postconditions:**
- Original database is unchanged
- Backup file exists at specified path
- Backup is a consistent snapshot of ALL tables (same as current clean-start backup)

**Error cases:**
- `PermissionDeniedException` — non-owner attempted backup
- `BackupDirectoryNotFoundException` — destination directory does not exist
- `BackupCreationException` — VACUUM INTO failed
- `BackupVerificationException` — integrity check failed or tables missing

### 4.3 UI Contract

**Entry point:** Settings screen, new section above Clean Start (owner-only)

**Section title:** "نسخ احتياطي للبيانات" (Data Backup)

**Section description:** "إنشاء نسخة احتياطية من جميع البيانات الحالية. هذه عملية آمنة ولا تمسح أي بيانات." (Create a backup of all current data. This operation is safe and does not delete any data.)

**UI flow:**
1. Owner taps "إنشاء نسخة احتياطية" (Create Backup) button
2. System opens FilePicker for directory selection
3. Owner selects destination directory
4. System shows loading spinner during backup creation
5. On success: show AlertDialog with backup path and file size
6. On failure: show error message with specific failure reason

**Button style:** Follows existing brand color (from T1-1). No new button styles.

**Permission gate:** `_isOwner` check — same as clean-start section.

### 4.4 Backup Directory Preference (Optional Enhancement)

If the design includes persisting the last-used backup directory:

**New setting key:** `keyBackupDirectory` in `AppSettings`

**Behavior:**
- After successful backup, remember the directory path
- On next backup attempt, pre-fill the directory in FilePicker
- If remembered directory no longer exists, fall back to FilePicker selection

**Schema impact:** Additive — new `app_settings` key (backward compatible)

### 4.5 Acceptance Criteria for Future Implementation

1. Owner can create a backup from Settings without triggering any destructive operation
2. Backup file is a consistent SQLite database copy (all tables)
3. Backup verification runs automatically after creation
4. Success dialog shows backup path and file size
5. Non-owner cannot access backup functionality
6. Existing clean-start backup flow is NOT modified
7. `flutter analyze` passes
8. Existing tests pass
9. No new dependencies added to `pubspec.yaml`

## 5. Design Contract — Standalone Restore

### 5.1 Objective

Allow the owner to restore the database from a previously created backup file.

### 5.2 Service Contract

```
StandaloneRestoreService.restoreFromBackup({
  required String backupFilePath,
})
→ Future<StandaloneRestoreReport>
```

**Behavior:**
1. Validate backup file exists and is a valid SQLite database
2. Run PRAGMA integrity_check on the backup file
3. Verify schema version compatibility (backup must be version 6 or compatible)
4. Verify table structure matches expected schema
5. Create a safety backup of current database before restore: `muaman_presave_<timestamp>.db`
6. Close current database connection
7. Replace `muaman_store.db` with the backup file content
8. Reopen database connection
9. Verify restored database is accessible
10. Return report with: timestamp, restored-from path, pre-save backup path

**Preconditions:**
- Caller must be owner
- Backup file must be a valid SQLite database
- Backup schema version must be compatible (same major version)

**Postconditions:**
- Current database is replaced with backup content
- Pre-save backup exists at safety location
- Application continues normally with restored data

**Error cases:**
- `PermissionDeniedException` — non-owner attempted restore
- `BackupFileNotFoundException` — backup file does not exist
- `BackupInvalidException` — not a valid SQLite database
- `SchemaIncompatibilityException` — schema version mismatch
- `RestoreFailedException` — restore operation failed
- `PreSaveBackupFailedException` — safety backup before restore failed (abort restore)

### 5.3 UI Contract

**Entry point:** Settings screen, new section below Backup section (owner-only)

**Section title:** "استعادة البيانات من نسخة احتياطية" (Restore from Backup)

**Section description:** "استعادة البيانات من نسخة احتياطية سابقة. سيتم إنشاء نسخة احتياطية من البيانات الحالية قبل الاستعادة." (Restore data from a previous backup. A backup of current data will be created before restore.)

**UI flow:**
1. Owner taps "استعادة البيانات" (Restore Data) button
2. System opens FilePicker for file selection (filter: `.db` files)
3. Owner selects backup file
4. System shows confirmation dialog:
   - Warning: "سيتم استبدال جميع البيانات الحالية. سيتم إنشاء نسخة احتياطية من البيانات الحالية أولاً." (All current data will be replaced. A backup of current data will be created first.)
   - Show backup file name and date
   - Confirmation button: "استعادة" (Restore)
5. System shows loading spinner during restore
6. On success: show dialog with restored-from path and pre-save backup path
7. On failure: show error message — original data remains unchanged

**Permission gate:** `_isOwner` check.

### 5.4 Acceptance Criteria for Future Implementation

1. Owner can restore from a backup file selected via FilePicker
2. Pre-save safety backup is created before any destructive restore
3. Schema version compatibility is checked before restore
4. Backup integrity is verified before restore
5. Failed restore leaves original data unchanged
6. Non-owner cannot access restore functionality
7. Existing clean-start flow is NOT modified
8. `flutter analyze` passes
9. Existing tests pass
10. No new dependencies added to `pubspec.yaml`

## 6. Exclusions — What This Design Does NOT Cover

| Item | Status | Reason |
|---|---|---|
| Automatic/scheduled backups | OUT OF SCOPE | Requires background service design |
| Backup encryption | OUT OF SCOPE | Requires key management design |
| Cloud backup | OUT OF SCOPE | Requires Cloud roadmap |
| Cross-machine restore validation | OUT OF SCOPE | Requires schema versioning strategy |
| Backup retention policy | OUT OF SCOPE | Requires policy design |
| Incremental backups | OUT OF SCOPE | VACUUM INTO creates full snapshots |
| Backup compression | OUT OF SCOPE | VACUUM INTO already compacts |
| Multi-database restore | OUT OF SCOPE | Single database architecture |
| Restore from clean-start backup | IN SCOPE | Same file format |
| Backup of preserved tables only | OUT OF SCOPE | Full database backup is simpler and safer |

## 7. Schema Impact

| Change | Type | Migration | Backward Compatible |
|---|---|---|---|
| `keyBackupDirectory` setting | Additive key in `app_settings` | None (auto-created) | YES |
| No new tables | — | — | — |
| No new columns | — | — | — |
| No schema version increment | — | — | — |

## 8. Risk Assessment

| Domain | Assessment | Reason |
|---|---|---|
| Accounting | Unchanged | Backup/restore is a data-level operation, not logic |
| Inventory | Unchanged | Same reasoning |
| Permissions | Touched but safe | Owner-only gate follows existing pattern |
| Invoice/PDF | Unchanged | No invoice logic modified |
| Settings | Touched but safe | New UI section, additive only |
| Backup/Restore | Primary target | This is the feature being designed |
| Licensing/Trial | Unchanged | No licensing logic modified |
| Windows delivery | Unchanged | No platform changes |
| Frozen identity | Unchanged | `muaman_store.db` filename preserved |
| Cloud/Supabase | Out of scope | Explicitly excluded |
| Android | Out of scope | Explicitly excluded |
| Sync/offline | Out of scope | Explicitly excluded |

## 9. Dependencies

| Dependency | Required By | Status |
|---|---|---|
| T1-1 (Brand Color) | Visual consistency | COMPLETED |
| Owner permission system | Backup/restore gates | COMPLETED |
| Clean-start service patterns | Code reuse | AVAILABLE |
| DatabaseHelper singleton | Database access | AVAILABLE |
| FilePicker | Directory/file selection | AVAILABLE |
| Schema version 6 | Restore compatibility | CURRENT |

No blocking dependencies. Implementation can proceed after this design freeze.

## 10. Implementation Sequence (Future Authorization)

When implementation is authorized by the roadmap:

```
Step 1: StandaloneBackupService (service layer)
Step 2: Backup UI section in Settings (presentation layer)
Step 3: StandaloneRestoreService (service layer)
Step 4: Restore UI section in Settings (presentation layer)
Step 5: Integration tests
Step 6: Windows visual verification
```

Each step is independently commitable and accept/rejectable.

## 11. Frozen Identity Verification

| Element | Status |
|---|---|
| `muaman_store.db` filename | UNCHANGED — backup/restore operates on this file |
| Package name | UNCHANGED |
| Windows identity | UNCHANGED |
| DB schema version | UNCHANGED (version 6) |
| Existing `app_settings` keys | UNCHANGED (new key added only) |
| Existing table names | UNCHANGED |
| Existing column names | UNCHANGED |

## 12. Acceptance Criteria for This Design Freeze

1. Design contract for standalone backup is defined with service interface, UI flow, and acceptance criteria
2. Design contract for standalone restore is defined with service interface, UI flow, and acceptance criteria
3. Exclusions are explicitly listed
4. Schema impact is documented (additive only)
5. Risk assessment covers all domains
6. Dependencies are identified and all are satisfied
7. No production code was modified
8. No schema changes were made
9. Document follows roadmap naming conventions

## 13. Outcome

**A — DESIGN FREEZE ACCEPTED / FOLLOW ROADMAP**

This design freeze document defines the complete contract for a future standalone backup/restore implementation step. No code was modified. The roadmap is followed exactly.

## 14. Single Next Authorized Step

**T2-2: Expense Categories** (per `I-TECH-RISK-DEPENDENCY-MAP.md` Section 5)

Or: The next implementation step from the Frozen Roadmap after design review by the project owner.
