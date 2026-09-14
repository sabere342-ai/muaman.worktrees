# First-Owner Bootstrap Corrective Fix — Session Closeout Report

Status: CLOSED (corrective fix committed, remote-lock verified)
Branch: `codex/i-tech-next-roadmap-freeze`
Session: OpenCode only — no Codex/Kilo delegation.

## Root Cause

`UserRepository.createUser` requires an existing `currentRole` with
`canManageUsers`. During true first-owner bootstrap the local `users` table is
empty, no actor/currentRole exists yet, and main routing reaches
`FirstOwnerSetupScreen` precisely because `hasAnyUser() == false`. The hardened
guard therefore made first-owner creation impossible.

Verified failing path:

```
FirstOwnerSetupScreen
→ IdentityLinker.onboardFreshOwner
→ UserRepository.createUser
→ _requireAdminPermission(currentRole = null)
→ PermissionDeniedException
```

Failure occurs BEFORE Supabase onboarding completion, `startTrial`,
`registerDevice`, and `activateDevice`. No Supabase schema/RLS/Auth-policy
issue was established.

## Authorized Corrective Fix

Dedicated fail-closed first-owner bootstrap path in `UserRepository`:

- `createFirstOwner({ displayName, username, password, ... })`
- Succeeds ONLY when `hasAnyUser() == false`.
- If ANY local user already exists: throws `PermissionDeniedException`
  (repository-level fail-closed authorization exception).
- Bootstrapped user ALWAYS has `role == owner`.
- Preserves display-name / username / password validation and duplicate
  constraint checks; transaction/integrity behavior unchanged.
- The ONLY mutation that may skip `_requireAdminPermission`/`canManageUsers`.
- Normal user-management paths (`createUser`, `updateUser`, `resetPassword`,
  `setUserActiveStatus`, user-management UI) remain admin-guarded and
  unchanged.

The empty-table invariant is centralized in the repository data layer and is
NOT trusted to UI visibility checks.

## Called-Site Changes (authorized scope only)

- `app/lib/services/identity_linker.dart` — `onboardFreshOwner` local-user
  creation routed through `createFirstOwner`.
- `app/lib/screens/auth/first_owner_setup_screen.dart` — local-only fallback
  routed through `createFirstOwner`.
- No unrelated account-management flows changed.

## Files Changed (committed)

- `app/lib/database/user_repository.dart`
- `app/lib/services/identity_linker.dart`
- `app/lib/screens/auth/first_owner_setup_screen.dart`
- `app/test/database/first_owner_bootstrap_test.dart` (new regression tests)

## Pre-Existing Authorized Carry-Over Preserved

`app/pubspec.yaml` version `1.0.0+2 → 1.0.0+3` from the interrupted authorized
production-validation session was preserved untouched. It is not part of this
corrective commit.

## Regression Tests

New focused file `app/test/database/first_owner_bootstrap_test.dart`:

- A. Empty database: `createFirstOwner` succeeds; created user role == `owner`.
- B. Second bootstrap denial after a user exists
      (`PermissionDeniedException`).
- B2. Denial also when only a non-owner user exists.
- B3. Failed bootstrap leaves no partial user row.
- B4. Bootstrap preserves validation on an empty table.
- C. `createUser` without `currentRole` is denied.
- C2. `createUser` with a non-owner `currentRole` is denied.
- C3. `createUser` with owner authorization still succeeds.
- D. `salesOnly` cannot create users (no permission regression).
- D2. `employee` cannot create users (no permission regression).

Validation evidence (exact):

- `flutter test test/database/first_owner_bootstrap_test.dart`
  → exit 0, 10 passed, 0 failed.
- `flutter test test/database/user_repository_test.dart test/database/permission_hardening_test.dart`
  → exit 0, 75 passed, 0 failed.
- `flutter test` (full suite) → exit 0, 1859 passed, 0 failed.
- `flutter analyze` → 0 errors, 0 warnings, 71 infos (matches established
  pre-existing baseline; no analyzer issue references task-touched files).

## Forbidden-Mutation Declaration

```
SUPABASE_SCHEMA_MUTATION = NONE
RLS_POLICY_MUTATION = NONE
AUTH_POLICY_MUTATION = NONE
SERVICE_ROLE_USED = NO
PRODUCTION_DATA_MUTATION = NONE
DEVICE_MUTATION = NONE
PLAY_STORE_ACTION = NONE
OD7_SYNC_DRAIN_ACTIVATION = NONE
ORIGIN_CONTACTED = NO
```

No production-config file was read/copied/staged/committed. No credentials
were exposed. No stash/untracked residue was touched.

## Production Validation

Production-connected on-device validation was NOT resumed in this session
(no APK rebuild, no device install, no Owner Setup retry, no trial/registration
/activation, no RLS/sync validation, no production writes). That resumes only
under a subsequent Owner-authorized continuation from the corrective-fix HEAD.