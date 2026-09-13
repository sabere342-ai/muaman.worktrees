# PHASE P — POST-WINDOWS-DELIVERY ANDROID PRODUCTION CONFIGURATION AND CONTROLLED ONLINE VALIDATION — PLAN

> PLANNING-ONLY ARTIFACT. NO NEXT-PHASE IMPLEMENTATION IS AUTHORIZED.
> This document is produced from READ-ONLY repository/source/artifact analysis
> plus Owner-supplied prior-session evidence. It does NOT execute, build,
> install, mutate, contact production, or perform any Play action.
>
> Contains NO passwords, NO DPAPI ciphertext, NO private key material, NO
> keystore bytes, NO Supabase service-role key, NO production anon key value, and
> NO access tokens. Public key/fingerprint hashes, paths, mechanisms and
> variable NAMES only.

---

## A. Purpose

Plan, in an implementation-ready form, the NEXT phase:

```text
NEXT_PHASE =
PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION
```

Goals of the planned phase (NOT started here):

1. Produce a production-connected Android release candidate (no service-role
   secrets; anon/publishable key only) using the fully verified signing
   pipeline.
2. Execute a controlled online validation against the Owner-authorized
   environment/identity using the approved physical test device (`f0deca9`).
3. Prove tenant/RLS, licensing, device-trust, offline-grace and sync behaviors
   against the live backend using Owner-controlled test data only.
4. Produce byte-reproducible evidence (hash, signing, badging, logcat, device
   state) for every step.
5. End at an explicit OWNER-AUTHORIZATION gate for any Play Store successor.

Constraints honored: OD7 / Sync Drain Activation remains separately governed;
no sync-drain activation is authorized or implied by this plan.

---

## B. Entry Baseline

From live forensics at planning time (VERIFIED):

```text
ROOT                  = C:/dev/muaman.worktrees/i-tech-next-roadmap-freeze
BRANCH                = codex/i-tech-next-roadmap-freeze
TRACKING              = github/codex/i-tech-next-roadmap-freeze
AUTHORIZED_REMOTE     = github
FORBIDDEN_REMOTE      = origin (never contacted)
LOCAL = TRACKING = DIRECT_GITHUB = MERGE_BASE = 896fc8411747ce61b82030948ef8e450ef8a1b72
AHEAD = 0 ; BEHIND = 0
HEAD_SUBJECT          = android: resume api 36 productization with canonical icon
ENTRY_CLASSIFICATION  = CASE_B_EXPECTED_BENIGN_RESIDUE
NO ACTIVE GIT OP      = verified (all markers absent, no index.lock)
```

The closeout companion artifact
`PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRIVATE_DEVICE_SMOKE_VALIDATION_CLOSEOUT.md`
records the predecessor PASS and its exact limits.

The plan is written against the canonical baseline commit `896fc84` as the
future build source, unless a later authorized change supersedes it.

---

## C. Evidence Sources

```text
A. Committed repository source/config (app/lib/config/app_config.dart,
   app/lib/main.dart, app/pubspec.yaml, app/android/app/build.gradle,
   app/android/gradle/production-signing.gradle, app/android/app/src/main/AndroidManifest.xml)
B. Committed Supabase migrations + Edge Functions (supabase/migrations/*,
   supabase/functions/*)
C. Committed predecessor governance artifacts (android productization chain:
   65f4440, eb97420, aa35163, 896fc84, plus Phase E/F/G/H/K/L/P plans)
D. On-disk release artifact (app-release.apk) inspected read-only (hash /
   apksigner / aapt2)
E. Owner-supplied prior-session smoke report (device serial f0deca9 evidence)
```

Every classification label below is one of:

```text
VERIFIED / INFERRED_FROM_CODE / OWNER_SUPPLIED_EVIDENCE / PLANNED /
REQUIRES_OWNER_DECISION / REQUIRES_FUTURE_VERIFICATION / BLOCKED
```

---

## D. Current Configuration Architecture (VERIFIED)

```text
FILE app/lib/config/app_config.dart:
  SUPABASE_URL      = String.fromEnvironment('SUPABASE_URL', defaultValue 'https://your-project-ref.supabase.co')
  SUPABASE_ANON_KEY = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue 'your-anon-key')
  SYNC_DRAIN_ENABLED= bool.fromEnvironment('SYNC_DRAIN_ENABLED', defaultValue false)
  isConfigured      = (URL ≠ placeholder) AND (ANON ≠ placeholder) AND both non-empty
```

- Injection mechanism: **compile-time `--dart-define`** (and conceptually
  `--dart-define-from-file`); no runtime config fetch, no environment file read
  in the app, no generated config.
- Values are `const` compile-time strings embedded into the Dart snapshot.
- `SYNC_DRAIN_ENABLED` defaults FALSE (owner-decision shipping posture, OD7) and
  must stay FALSE unless separately authorized.
- No `.env` is read by the Flutter app. `.env.example` documents only the
  intended public variables plus an explicitly SERVER-SIDE-ONLY
  `SUPABASE_SERVICE_ROLE_KEY` that MUST NOT enter the app.

---

## E. Current Supabase Initialization Path (VERIFIED)

```text
app/lib/main.dart:
  main() ->
    AppCrashHandler.install()
    (Windows/Linux/macOS: sqflite_common_ffi init)
    if (AppConfig.isConfigured) await Supabase.initialize(
        url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseAnonKey)
        with errors SWALLOWED -> offline-only fallback
    runApp(MyApp())

  AuthGate._initialize() ->
    local DB, AppSettings, PermissionResolver, ShopProfileService.load()
    CloudLicensingService.initialize() + DatabaseHelper licensing enforcer
    ActiveShopContext.configure(membershipValidator via ShopResolver.getAllMemberships)
    SyncRuntime.configure(drainEnabled: AppConfig.syncDrainEnabled)  // dormant when off
    if (isConfigured && auth.currentSession valid) _cloudAvailable = true
    if (isConfigured && _cloudAvailable) resumeCloudSessionAtStartup(fail-closed)
    SyncRuntime.ensureStarted() + publishStatus() (fail-closed)

Startup routing (AuthGate.build):
  initializing -> loading
  !hasUsers && offersFreshDeviceCloudBootstrap -> _FreshDeviceGate
       (Owner Setup / seller cloud login / accept invitation)
  !hasUsers -> FirstOwnerSetupScreen
  !isLoggedIn -> LoginScreen
  else -> FullAppShell
```

The tested offline APK exercised the unconfigured path and deterministically
surfaced `FirstOwnerSetupScreen` (OWNER_SUPPLIED_EVIDENCE, corroborated by
committed defaults). A production-configured build will flip `isConfigured` to
TRUE and traverse the cloud-enabled path, which this plan must validate.

---

## F. Public-Client-Config vs Secret Boundary (VERIFIED)

| Item | Classification | Must it enter the APK? |
|---|---|---|
| `SUPABASE_URL` (https://<ref>.supabase.co) | Public project URL | YES — intended client config |
| `SUPABASE_ANON_KEY` / publishable key | Public publishable client key, protected by RLS | YES — intended client config (passed as `publishableKey`) |
| `SUPABASE_SERVICE_ROLE_KEY` | SECRET server credential | NEVER — server-side only |
| Signing store/key passwords | SECRET | NEVER — recovered in-process via DPAPI at build time |
| `SYNC_DRAIN_ENABLED` | Feature switch (not secret) | Only via separate OD7 authorization |

Evidence: `main.dart` passes `AppConfig.supabaseAnonKey` as `publishableKey`;
`.env.example` explicitly documents the anon key as "safe for client-side use
with RLS" and the service-role key as "SERVER-SIDE ONLY / NEVER include in
Flutter source code or client binaries". Server writes are performed by
SECURITY DEFINER RPCs under RLS (migrations `.../00000020_database_functions.sql`
et al.); direct client table mutation is denied.

```text
ABSOLUTE RULE: SERVICE_ROLE / SECRET SERVER CREDENTIALS MUST NEVER BE BUILT INTO THE APK.
```

---

## G. Production Config Injection Strategy (PLANNED)

Recommended future build-time injection (kept consistent with the existing,
proven `--dart-define` mechanism — no app code change required):

```text
--dart-define=SUPABASE_URL=https://<production-project-ref>.supabase.co
--dart-define=SUPABASE_ANON_KEY=publishable-anon-key    (NOT service-role)
```

Rules:

1. Values are supplied ONLY at build time and NEVER committed.
2. The Supplier of Record is the Supabase production project's API settings
   (project URL + anon/publishable key). The Owner authorizes which exact
   project ref is the controlled validation target.
3. Optional reproducibility: `--dart-define-from-file=<gitignored file>` with a
   `.gitignore` entry, OR plain `--dart-define` in a recorded command line. Both
   are acceptable; the exact mechanism is a `REQUIRES_OWNER_DECISION` only if a
   committed template is wanted.
4. `SYNC_DRAIN_ENABLED` stays absent/false. `MUAMAN_SEED_DEMO`, if it exists in
   any build flavor, stays OFF (see committed reconciliation art. 65f4440 §I.4).
5. Build-time signs of the absence of secrets: verify the committed tree has no
   `SUPABASE_SERVICE_ROLE_KEY`, no real URL, no real anon key, no key/token
   material (git grep gate before build).

```text
REQUIRES_OWNER_DECISION #P: exact production project ref + whether the anon key
is supplied directly or via a gitignored define file.
```

---

## H. Build Artifact Strategy (PLANNED)

Minimum safe future build procedure (for the authorized next phase; NOT run
now):

```text
Source       = canonical HEAD 896fc84 (or its authorized successor)
Mode         = release only
API          = compileSdk 36 / targetSdk 36 / minSdk 21 (committed, VERIFIED)
ABIs         = arm64-v8a, armeabi-v7a, x86, x86_64 (observed on prior artifact)
Artifacts    = app/build/app/outputs/flutter-apk/app-release.apk
               (optionally app/build/app/outputs/bundle/release/app-release.aab
                for future Play, outside this phase unless authorized)
Command form =
  flutter build apk --release \
    --dart-define=SUPABASE_URL=<...> --dart-define=SUPABASE_ANON_KEY=<...>
  with packaging toolchain pinned to JDK 17:
  -Dorg.gradle.java.home=C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot
```

Toolchain facts carried from the committed reconciliation artifact 65f4440
(VERIFIED_FROM_COMMITTED_PREDECESSOR_ARTIFACTS, to be re-proven at execution):

```text
Flutter 3.24.5 / Dart 3.5.4, Gradle 8.3 (wrapper), AGP 8.1.0, Kotlin 1.8.22,
system JDK 21 with packaging JDK 17 (AGP 8.1.0 + JDK 21 core-for-system-modules
transform limitation), SDK platforms 33/34/35/36, build-tools 33.0.1/34.0.0/35.0.0.
```

Evidence that must be captured at execution (REQUIRES_FUTURE_VERIFICATION):

```text
- exact command line
- command exit code
- APK/AAB size + SHA-256 + SHA-1
- apksigner verify --verbose --print-certs (expect v1/v2 TRUE)
- aapt2 dump badging (package/version/SDK/label/launchable/locales/ABIs)
- git diff --name-only BEFORE and AFTER (expect EMPTY; build artifacts are gitignored)
```

`REQUIRES_OWNER_DECISION #V`: version identity for the produced candidate
(see §J).

---

## I. Signing Strategy (VERIFIED existing; reuse unchanged)

```text
app/android/gradle/production-signing.gradle:
  fail-closed two-source DPAPI (store-password.dpapi, key-password.dpapi)
  keystore SHA-256 locked = f97c6ab9c636c01d88c9d03d4a6092fa42c33a1575147174291ab6b1db76e1cd
  alias 'i-tech-upload', cert SHA-256 485e4187... / SHA-1 8343ef47...
  RSA 4096, SHA256withRSA, JKS, store ≠ key password, private-key sign/verify probe
  primary and backup keystores must match byte-for-byte
  release buildType has NO debug fallback
```

The prior artifact verified with v1+v2 APK Signature schemes — compatible with
Install/Play requirements for this minSdk. Play App Signing enrollment (if the
AAB is ever uploaded to Play) is a future external owner action; the upload key
remains the `i-tech-upload` key.

```text
SIGNING_CHANGES = NONE planned nor authorized
```

---

## J. Version Strategy (VERIFIED current + REQUIRES_OWNER_DECISION)

```text
Current committed identity (pubspec 1.0.0+2 / aapt2):
  versionCode = 2 ; versionName = 1.0.0
```

The tested smoke APK already used versionCode 2 / versionName 1.0.0. The next
controlled candidate must decide explicitly (`REQUIRES_OWNER_DECISION #V`):
keep `1.0.0+2` for the controlled validation, or advance (e.g. `1.0.1+3`).
Policy guardrails for the plan:

1. Every produced candidate reports its exact versionCode/versionName in its
   evidence block.
2. If a later Play upload is intended, versionCode must strictly increase
   monotonically across uploaded AABs (this is a future-Play concern, not this
   phase).
3. Never silently bump version identity; any advance is an explicit recorded
   decision.

---

## K. Controlled Test-Device Strategy (PLANNED)

```text
DEVICE_SERIAL = f0deca9   (Redmi Note 7 / MIUI; the Owner-approved private test device)
```

Rules for the future phase:

1. EVERY adb command MUST carry `-s f0deca9`. No broad/multi-device commands.
2. Capture pre-install package state FIRST:
   - `adb -s f0deca9 shell pm list packages | findstr com.itech.storemanagement`
   - `adb -s f0deca9 shell dumpsys package com.itech.storemanagement` (versions)
   - current focused activity snapshot before any change.
3. Decide clean vs upgrade explicitly (`REQUIRES_OWNER_DECISION #4`).
   - Upgrade (`adb -s f0deca9 install -r <apk>`) preserves the existing
     first-run/FirstOwnerSetup state and matches a real user path.
   - Clean (uninstall then install, with Owner consent) yields a deterministic
     first-run baseline on a wiped app data state.
   - Either is safe on this Owner-controlled device; the plan recommends the
     controlled UPGRADE test ONLY IF production config is introduced, because
     the existing install is an offline/unconfigured artifact whose app data is
     minimal. Final choice is the Owner's.
4. Preserve evidence of prior app state (screenshots/`dumpsys`/files) BEFORE
   mutation; do not delete anything on the device.
5. Install verification, package/version confirmation (pm path, dumpsys,
   aapt2), launch confirmation (`am start -n com.itech.storemanagement/...`),
   logcat capture, crash/ANR gate, Arabic/RTL sanity, app restart — each step is
   a recorded evidence block.
6. Offline/online transitions are exercised ONLY within the scope defined by the
   Owner decisions (flights, no GPT test data).
7. Final package-state evidence after validation (versions + data presence).

---

## L. Authentication / Owner Onboarding Validation (PLANNED)

Future controlled path to validate (with production config active):

```text
AUTH_FLOW_1  Fresh-device bootstrap: FirstOwnerSetupScreen -> owner identity
             -> Supabase sign-up (owner credentials) -> shop creation path
AUTH_FLOW_2  Cloud login (seller) + invitation acceptance (AcceptInvitationScreen)
AUTH_FLOW_3  Cold-start resume (resumeCloudSessionAtStartup) -> shop bound,
             strict tenant isolation re-armed, permissions re-synced
AUTH_FLOW_4  Logout -> Supabase signOut -> strict isolation suspended;
             re-login re-arms
```

Validation must prove the owner identity, shop provisioning/selection, expected
tenant association, and that tenant binding is authorization-gated
(`ActiveShopContext` membership validator is fail-closed on resolver error —
INFERRED_FROM_CODE + REQUIRES_FUTURE_VERIFICATION).

Which environment/identity is used is an OWNER DECISION (see §U #1/#2/#3):

```text
OPTION 1  already-existing dedicated test shop/account
OPTION 2  newly created controlled production test identity
OPTION 3  non-production/staging environment
```

Production account/shop creation is NOT authorized this session and will not be
performed by this plan; the chosen option must come from the Owner.

---

## M. Tenant / RLS Validation (PLANNED — fail-closed)

Future tests using Owner-controlled identities/data ONLY (never real customers):

```text
POSITIVE  correct tenant reads/writes its allowed rows (shop_id-scoped)
NEGATIVE  unrelated shop membership CANNOT read the tenant data
NEGATIVE  unrelated shop CANNOT mutate the tenant data
NEGATIVE  user cannot arbitrarily switch shop_id (binding validator fails closed)
NEGATIVE  client cannot bypass server authority (direct table writes denied;
          mutations only via SECURITY DEFINER RPCs)
NEGATIVE  unauthorized requests fail closed (non-member/anon deny)
VERIFY    service-role credentials absent from client (git grep + artifact scan)
```

Evidence base (VERIFIED from migrations): RLS enabled fail-closed on cloud
tables (`.../00000010_rls_policies.sql`); SELECT gated by ACTIVE `shop_members`
via `auth.uid()`; INSERT/UPDATE/DELETE restricted to service_role (client has no
direct write policies); business functions are SECURITY DEFINER with explicit
`search_path` and every sync RPC is `p_shop_id`-scoped, never trusting ambient
shop.

```text
REQUIRES_FUTURE_VERIFICATION: live cross-tenant negative results on the
Owner-controlled environment only.
```

---

## N. Licensing Validation (PLANNED)

Server-authored license/entitlement surfaces (VERIFIED from committed
migrations + client): `start_trial`, `verify_trial_status`,
`verify_license_entitlement`, `register_device`, `activate_device`,
`deactivate_device`, `get_device_list`, device limits/quota boards (Group B S2),
revocation/grace authority (S3). Product rules to reconcile at execution
(INFERRED_FROM_CODE / committed plans):

```text
TRIAL        1 user / 1 device ; offline grace 0 days
STARTER      2 users / 3 devices ; paid grace 7 days
PROFESSIONAL 5 users / 10 devices ; paid grace 7 days
ENTERPRISE   unlimited / unlimited ; paid grace 7 days
PERPETUAL    offline grace 14 days where applicable
```

Client `OfflineGracePolicy` (VERIFIED): trial grace = 0, paid = 7, perpetual =
14; clock rollback behind trusted baseline fails closed; cached
EXPIRED/SUSPENDED/REVOKED respected offline.

Planned checks:
- server-controlled trial lifecycle (start → verify → expiry), NOT offline-runnable
- entitlement evaluation across user counts/device limits
- activation/device limits and deactivation
- owner license token behavior against live production
- restart behavior (enforcement boundary installed before any write)

```text
REQUIRES_OWNER_DECISION #6: whether ANY future test may exercise a paid-tier
entitlement, or trial only. Licensing/device records are NOT mutated this session.
```

---

## O. Device Trust Validation (PLANNED)

```text
S6 per-install Ed25519 device identity (app/lib/licensing/s6_device_identity.dart):
  - FIRST INSTALL -> exactly one keypair in protected store
  - RESTART -> reuse SAME identity
  - CONCURRENT FIRST-LOAD -> single-flight convergence
  - SECURE STORE LOST/REINSTALL -> governed re-enrollment (new identity)
  - CORRUPT/SERVER-PUBKEY MISMATCH -> fail closed
Private seed never leaves protected storage (Android: Keystore-backed
itech.app/secure_storage channel). S8 trusted-server-time high-water lives in the
same protected store; cache is device-bound + Ed25519-signed
(s8_cache_integrity.dart).
```

Future checks: registration/trust round-trip, activation/device limits,
entitlement evaluation, owner license token, offline cache integrity, restart.
All against Owner-controlled environment only.

---

## P. Offline Grace Validation (PLANNED)

```text
- initial ONLINE bootstrap until a valid lease/high-water is established
- app reopen OFFLINE within grace: paid=7d / perpetual=14d; TRIAL=0 (must
  revalidate online)
- clock manipulation / rollback beyond tolerance -> fail closed, never extends grace
- cached non-entitled (EXPIRED/SUSPENDED/REVOKED) states never overridden by grace
- restart after offline reopen
```

Offline transitions are executed only where the Owner authorizes (see owner
decision #3/#4 boundaries).

---

## Q. Sync Validation (PLANNED — OD7 gated)

```text
SCOPE of this plan:
- initial online bootstrap
- local cache creation under the bound tenant
- offline app reopen
- durable queue/outbox behavior (tenant-scoped, idempotency-keyed)
- reconnect behavior
- LWW/conflict/adjudication where applicable (conflict_resolver, Option C
  oversold reconciliation)
- NO cross-shop sync (queue rows are shop_id-scoped; transport never consults
  ambient shop)
```

```text
CRITICAL: OD7 / SYNC DRAIN ACTIVATION remains separately governed.
This plan does NOT enable sync drain. Any future explicit Owner authorization
that names sync-drain activation is required before a drain-enabled build or
runtime is validated.
```

---

## R. Failure / Rollback Strategy (PLANNED)

1. Every validation step is reversible: dedicated, prefixed test records only;
   no customer data touched; no broad cleanup.
2. Before/after local DB state snapshots captured so a failed run can be
   diffed, not just eyeballed.
3. Fail-closed default on every gate: if an expected assertion (RLS negative,
   license state, device limit, grace expiry) is NOT reproduced, the phase
   STOPS and evidence is preserved; no attempt to "fix live" by deleting rows.
4. Rollback on device = restore prior committed source, re-install the prior
   known-good APK (if authorized), or reset ONLY Owner-controlled test data with
   explicit Owner consent. No database reset, no unrelated-row mutation, no
   schema change.
5. Rollback on repo = new normal commit reverting only this phase's allowlisted
   changes; no history rewrite; no force push.
6. Production data safety rules of §S are binding rollback constraints.

---

## S. Production Data Safety Rules (PLANNED — binding)

```text
- dedicated test data with clear identification and a reversible, documented lifecycle
- no deletion or mutation of real customer production data
- no mutation of unrelated shop rows
- no broad cleanup / no database reset
- no schema change unless separately authorized
- no irreversible licensing/device operation without explicit Owner approval
- no unbounded retry automation and no background drain unless separately authorized
- any write performed is recorded with a full before/after evidence diff
```

```text
IF the future phase needs ANY production write (account/shop/licensing/device):
REQUIRES_OWNER_DECISION #3 authorizes the exact narrowly-scoped write list FIRST.
```

---

## T. Logging / Evidence Capture (PLANNED)

For every executed command in the future phase:

```text
- exact command (full text)
- command exit code
- raw output preserved (logcat filtered to the package; dumpsys; screenshots;
  aapt2; apksigner; hash outputs)
- passed/failed counts for any tests, exact
- git diff --name-only before/after (empty expected)
- hashes and fingerprints of any artifact
- device serial repeatability (every adb line carries -s f0deca9)
- classification labels (VERIFIED / NOT_VERIFIED / PASS / FAIL) with no
  silent upgrading of NOT_VERIFIED to PASS
```

Flutter `Analyzer` results, if run, are reported raw (command/exit/errors/
warnings/infos) and never flattened into "0 errors = green".

---

## U. Required Owner Decisions (REQUIRES_OWNER_DECISION — NOT resolved here)

```text
1. Which environment for controlled online validation?
   (a) actual production with Owner-controlled test tenant
   (b) dedicated staging
   (c) other isolated environment

2. Which identity/shop will be used?
   (a) existing controlled test account/shop
   (b) newly created dedicated test identity
   (c) other

3. Is the next phase authorized to perform narrowly scoped PRODUCTION WRITES
   needed for account/shop/licensing validation? If YES, list the exact writes.

4. Clean install or controlled upgrade on f0deca9?

5. May existing production test data be reused?

6. May any future test exercise paid-tier entitlement, or TRIAL only?

7. Is ANY production sync mutation authorized?

8. Is a future AAB intended for local evidence only, or eventual Play upload?

OPTIONAL #P: production project-ref + anon-key supply mechanism (direct
--dart-define vs gitignored define file).
OPTIONAL #V: version identity for the controlled candidate.
```

This plan does NOT resolve any of these by assumption. Each is an explicit
owner gate for the next phase.

---

## V. Explicitly Prohibited Actions (this plan / future phase without new authority)

```text
PLAY Store: NO console open/upload/AAB-APK upload/testing-track/release/
submit/promote/publish/rollout/listing/signing change        (PLAY_STORE_ACTION = NONE)
Supabase production: NO insert/update/delete/upsert/no RPC with side effects/
no user/shop/device/license/subscription/entitlement creation/
no edge-function deploy/no migration apply/no RLS change/no secret change/
no auth-config change/no storage mutation/no sync-drain activation
Production config: NO real values committed, NO .env with secrets, NO
service-role in any artifact, NO AppConfig change this session
Builds: NO flutter build / gradle assemble / bundle this session
Device: NO adb install/uninstall/pm clear/settings put/device_config/
force-stop-as-workflow this session          (ANDROID_PRODUCTION_APK_INSTALLED = NO)
Repo: NO code/gradle/pubspec/manifest/assets/migration/function/SQL/signing/
dependency/version/generated/secret/config change this session
```

```text
If future execution requires a production mutation: write
BLOCKED_PENDING_EXPLICIT_SUPABASE_PRODUCTION_MUTATION_OWNER_AUTHORIZATION and STOP.
If future execution reaches a required Play action: write
BLOCKED_PENDING_EXPLICIT_PLAY_STORE_OWNER_AUTHORIZATION and STOP.
```

---

## W. Entry / Exit Gates for the Next Phase (PLANNED)

ENTRY GATES:

```text
- separate Owner authorization naming PHASE_..._PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION_OWNER_AUTHORIZATION
- all §U decisions resolved
- repository forensics clean (CASE_A/CASE_B; no divergence, no active op)
- the canonical source commit for the build is identified and allowlisted
- production config values are authorized and their source-of-truth recorded
- OD7 sync-drain is NOT part of the phase unless separately named
```

EXIT GATES:

```text
- every planned validation executed with preserved raw evidence
- have pass/fail classification per gate, NOT_VERIFIED never reported as PASS
- prior device package-state restored or leaving a documented final state
- allowlisted doc/build evidence committed + pushed to github + remote-lock proof
- successor (Play) NOT started
```

---

## X. Exact STOP Conditions (PLANNED — binding for the future phase)

```text
STOP on ANY of:
- unexpected tracked dirty/staged state or active Git op (CASE_C/D/E)
- remote divergence
- unauthorized file would need modification
- unresolved owner decision encountered mid-phase
- production mutation required without authorization
- secret exposure risk (any real key/token/password in a path that could be
  committed, logged, or printed)
- a planned assertion (RLS, licensing, device, grace) NOT reproduced
- any attempt to fix a failing gate by deleting/mutating real data
- any Play action demanded by flow
- authority conflict that cannot be resolved
```

On STOP: preserve all evidence, report exactly what blocked continuation, and
wait for new explicit Owner authorization.

---

## Y. Proposed Successor (NOT started)

```text
SUCCESSOR_ID =
PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRODUCTION_CONFIGURATION_AND_CONTROLLED_ONLINE_VALIDATION_OWNER_AUTHORIZATION

THIS IS AN OWNER-AUTHORIZATION GATE.
SUCCESSOR_STARTED = NO
AUTHORIZED_EXECUTION_SUCCESSOR_COUNT_FOR_THIS_SESSION = 0
After the Owner gate:
  a later Play phase is a FURTHER successor, only after the controlled
  production-connected validation PASSES and a new separate authorization exists.
```

No automatic continuation occurs from this session. This session plans; it does
not execute.

---

## Z. Final Planning Result Token

```text
PLANNING_RESULT =
PASS_PHASE_P_POST_WINDOWS_DELIVERY_ANDROID_PRIVATE_DEVICE_SMOKE_CLOSEOUT_AND_PRODUCTION_CONFIGURATION_PLANNING

OWNER_DECISIONS_REQUIRED = YES   (enumerated in §U; planning completed without resolving them)
SKILLS_DISCOVERED        = flutter-release, flutter-security, flutter-offline-data,
                           flutter-testing, flutter-core-engineering (available)
SKILLS_USED              = flutter-release, flutter-security, flutter-offline-data
PRIMARY_SKILL            = flutter-release
SKILL_SCOPE_EXPANSION    = NONE (skills are advisory; no authorization expansion)
ORIGIN_CONTACTED         = NO
PLAY_STORE_ACTION        = NONE
PRODUCTION_ACTION        = NONE
SUPABASE_PRODUCTION_MUTATION = NONE
ANDROID_PRODUCTION_BUILD_STARTED = NO
ANDROID_PRODUCTION_APK_INSTALLED = NO
SUCCESSOR_STARTED        = NO
TAG_CREATED              = NO
```

---

*End of Android production configuration and controlled online validation plan.*