# I-TECH PRODUCTIZATION — FINAL-REPORT (T0)

- **Governing prompt:** `C:\dev\muaman.worktrees\I-TECH-PRODUCTIZATION-SUPER-PROMPT.md`
- **Worktree:** `C:\dev\muaman.worktrees\i-tech-productization-t0`
- **Branch:** `codex/i-tech-productization-t0`
- **Baseline commit:** `fdf2d33762635dc89e5fb0cffd765649c402e078`
- **Commercial identity target:** `I-TECH للتكنولوجيا`

---

## 6.1 Outcome

**Outcome B — PRODUCTIZATION T0 ACCEPTED WITH PRESERVED T1/T2 DEBT**

- Roadmap decision: **A — FOLLOW ROADMAP**. Productization is the explicit next
  step authorized for this worktree/branch; the 13P/13Q/13S `allowedChangedPrefixes`
  already list `app/windows/runner/Runner.rc` as the single authorized `app/` path.
- T0 was implemented: the Windows runner version-resource now carries the
  `I-TECH للتكنولوجيا` identity; the rebuilt executable is byte-identical to the
  already-accepted T0 artifact (`13491813…AEA1` / 92,160 B).
- T1 (in-app product surface) was **not** touched — audit-only, preserved debt.
- T2 (frozen compatibility identity) was **not** touched — all frozen identifiers
  verified unchanged.
- Windows/installer acceptance: 13L verify PASS, 13L guard L7 PASS, 13O 13/13 PASS,
  13R allPass + negative controls PASS, 13P/13Q/13S config pins PASS.
- Canonical delivery identity after work: **16 files / 35,754,065 B / crosshash
  `3A8CFA42…` / exe `13491813…AEA1` / installer `94BD1559…`** — unchanged and
  re-verified from a fresh governed build.

---

## 6.2 What Was Done

### Audit/evidence

- Re-grounded from disk: worktree, branch, HEAD, ancestry; artifact identity
  verified for exe/app.so/manifest/installer/delivery-zip.
- Resolved the canonical-identity question: the accepted T0 identity is
  **`3A8CFA42…` / 35,754,065 B**, and the 512-byte delta vs the historical
  MUAMAN-19 `7BC41854…` / 35,753,553 B tree is exactly the exe version-resource
  growth (91,648 → 92,160 B) from the I-TECH branding — see
  `docs/i-tech-productization/evidence/20260816-T0-runnerrc/05-identity-reconciliation.md`.
- Documented the governing handoff discrepancy (per prompt §2.5): the reported
  `9A3AEFDD…`/`7BC41854…` values are superseded by repository evidence.

### T0 packaging changes

| File:line | Old | New | Tier | Reason |
|---|---|---|---|---|
| `app/windows/runner/Runner.rc:92` | `VALUE "CompanyName", "com.almuaman"` | `VALUE "CompanyName", "I-TECH للتكنولوجيا"` | T0 | version-resource display field |
| `app/windows/runner/Runner.rc:93` | `VALUE "FileDescription", "muaman_store"` | `VALUE "FileDescription", "I-TECH للتكنولوجيا"` | T0 | version-resource display field |
| `app/windows/runner/Runner.rc:96` | `VALUE "LegalCopyright", "Copyright (C) 2026 com.almuaman. All rights reserved."` | `VALUE "LegalCopyright", "Copyright (C) 2026 I-TECH للتكنولوجيا. All rights reserved."` | T0 | version-resource display field |
| `app/windows/runner/Runner.rc:98` | `VALUE "ProductName", "muaman_store"` | `VALUE "ProductName", "I-TECH للتكنولوجيا"` | T0 | version-resource display field |

Preserved in the same file (B4 / §4.3): `InternalName = muaman_store`,
`OriginalFilename = muaman_store.exe`, `FileVersion/ProductVersion = VERSION_AS_STRING`,
`LANGUAGE LANG_ENGLISH, SUBLANG_ENGLISH_US`, icon, `#pragma code_page(65001)`.

### Acceptance/harness corrections

- None required for this step: every active harness already pins the T0 identity
  (`3A8CFA42…` / exe `13491813…` / installer `94BD1559…` / 16 files / 35,754,065 B).
- The 13S active `acceptance-config.json` was already retargeted to the 16-file
  governed identity (verified 16/16 per-file payload match). No guard logic was
  modified; no historical fixture was rewritten.

### Docs

- Added `docs/i-tech-productization/FINAL-REPORT.md` (this file).
- Added `docs/i-tech-productization/evidence/20260816-T0-runnerrc/` with:
  - `00-pre-mutation-baseline.json`
  - `01-build-evidence/` (governed build `I-TECH-T0-RUNNERRC-REBUILD`: preflight,
    clean, pub-get, build logs, hardened-env/pre.json, `release-manifest.json`)
  - `02-verify/verify-release.json` (13L verify: `identical=True`, `diffs=0`,
    cross `3A8CFA42…`)
  - `03-guards/` (guard-13l, guard-13o, guard-13r, guard-13k-fresh,
    release-comparison-13l)
  - `04-acceptance-config-pins.json`
  - `05-identity-reconciliation.md`

### Tests/build/package/install

- Governed rebuild via `tools\release\build_windows_release.ps1` (B5 — the only
  permitted builder), run id `I-TECH-T0-RUNNERRC-REBUILD`: preflight exit 0,
  build exit 0, `flutter clean` + pub-get + build inside isolated hardening.
- Resulting 16-file tree verified byte-identical to the accepted legal manifest
  (`docs/windows-delivery-refresh/evidence/legal/release-manifest.json`).
- Delivery package untouched and re-verified: installer `94BD1559…` /
  13,223,003 B; zip `4258E910…` / 12,665,973 B.
- Build byproducts (7 generated plugin-registrant files under
  `app/{windows,linux,macos}` with line-ending-only deltas, zero content change)
  were restored to their committed form so the working tree carries only authorized
  changes (the acceptance-config `allowedChangedPrefixes` allow only
  `app/windows/runner/Runner.rc` under `app/`).

### Diff summary

- 33 files changed (modified), 396 insertions, 223 deletions (this includes the
  full pre-authorized T0 refresh of delivery/installer/tools/docs).
- Untracked additions: delivery `I-TECH-Setup.exe` plus the T0 acceptance/closure
  evidence trees under `docs/` (approximately 2,700 files of logs/manifests/evidence).
- No changes to production Dart sources, DB schema, pubspec, `BINARY_NAME`,
  AppId, business logic, or runtime behavior.

---

## 6.3 What Remains

### T1 — In-app identity work still requiring explicit authorization

Not changed in this pass (audit-only per prompt §2.4):

- Runtime window title in `app\windows\runner\main.cpp` (historical touchpoint
  around `main.cpp:30`) — user-visible display text, not used for the binary
  compatibility identity in this lineage.
- Flutter UI product strings (title/about/splash/settings copy) and any
  `ui_strings.json` selector/assertion maintenance that would be required if
  changed (B6).
- Any default window title, About dialog, login/splash/settings identity strings.
- Shop/business name and logo remain **shop-configurable** (not hard-coded).

### T2 — Frozen compatibility identity

Confirmed frozen and unchanged (deliberate compatibility constraints, not
"unfinished renames"):

- Inno Setup `AppId`: `{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}` (B1).
- Database: `muaman_store.db` + persistent location + backup/restore contract (B2).
- Flutter/Dart package `name:` in `pubspec.yaml` (B3).
- `BINARY_NAME` / executable/process identity: `muaman_store.exe` (B4).
- `DefaultDirName`: `{localappdata}\Programs\muaman_store`.
- `InternalName` / `OriginalFilename`: `muaman_store` / `muaman_store.exe`.
- Historical acceptance fixtures (13K G9 13-file/33,273,462 B payload, MUAMAN-13R
  era `05509FA7…` in `docs/windows-delivery-refresh/FINAL-REPORT.md`).

---

## 6.4 Constraints / Preserved Acceptance Contract

| Invariant | Value | Verified |
|---|---|---|
| Canonical builder only | `tools\release\build_windows_release.ps1` | PASS |
| Release file count | 16 | PASS |
| Release total bytes | 35,754,065 | PASS |
| Crosshash | `3A8CFA42656EABC8B06EEF835FB9222F95006E5B490D9B837AE76673A87794B0` | PASS |
| exe SHA-256 / size | `13491813…AEA1` / 92,160 | PASS |
| app.so SHA-256 / size | `86369AA8…` / 9,290,656 (demo marker absent) | PASS |
| installer SHA-256 / size | `94BD1559…` / 13,223,003 | PASS |
| delivery zip SHA-256 / size | `4258E910…` / 12,665,973 | PASS |
| AppId | `{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}` | PASS (unchanged) |
| DB identity | `muaman_store.db` | PASS (unchanged) |
| pubspec name | unchanged | PASS |
| Binary identity | `muaman_store.exe` | PASS (unchanged) |
| Start-menu / uninstall display | `I-TECH للتكنولوجيا` | PASS (T0) |
| Fresh DB / seed-prod isolation | covered by MUAMAN-19 acceptance (artifacts byte-identical) | PASS |
| WM_CLOSE / printing teardown | covered by MUAMAN-18 acceptance (no runtime change) | PASS |
| Secret/artifact guard | 13L L4: 8,462 files scanned, 0 findings | PASS |

**Stale 13s disposition:** the active 13S `acceptance-config.json` is retargeted to
the 16-file / 35,754,065 B / exe `13491813…` governed identity (16/16 payload
match). Remaining `13-file`/`05509FA7…` references are either historical immutable
fixtures (13K G9 guard text, `docs/windows-delivery-refresh/FINAL-REPORT.md`) or
cosmetic description strings in active tools that do not affect verdicts
(13S S12 detail/expected strings; `tools\release\package_windows_installer.ps1:16`
comment). No active acceptance expectation uses the old 13-file identity.

---

## 6.5 Governance Recommendation

- The application is commercially package-branded as `I-TECH للتكنولوجيا` on the
  T0 packaging surface (installer, delivery README, Windows version resource,
  start-menu name, uninstall registration).
- In-app branding remains pending and must be authorized explicitly (T1).
- Shop name/logo remain correctly shop-configurable; do not hard-code any client
  identity into generic product packaging.
- T2 identifiers listed in §6.3 must remain frozen for upgrade/data continuity.
- A future compatibility migration (AppId / `muaman_store.db` / package name /
  `BINARY_NAME`) would require a dedicated, separately accepted roadmap item.

**Single next authorized step:**
> owner review/authorization of the audited T1 in-app identity patch only; T2 remains frozen.

---

## 6.6 Git / Validation Handoff

- **Branch:** `codex/i-tech-productization-t0`
- **Worktree path:** `C:\dev\muaman.worktrees\i-tech-productization-t0`
- **Baseline commit:** `fdf2d33762635dc89e5fb0cffd765649c402e078`
- **Final commit:** see commit message below (this closure commit)
- **Commits above baseline:** 1 (this closure)
- **Merge commit count:** 0
- **Working tree state:** clean after the closure commit
- **Push status:** not pushed (no push authorized)
- **Tag status:** none

### Validation matrix

| Check | Result | Evidence |
|---|---|---|
| Audit touchpoints complete | PASS | this report + `05-identity-reconciliation.md` |
| Roadmap Alignment | A — FOLLOW ROADMAP | this report §6.1 |
| B1 AppId unchanged | PASS | `04-acceptance-config-pins.json` |
| B2 DB identity unchanged | PASS | `04-acceptance-config-pins.json` |
| B3 pubspec name unchanged | PASS | git status (no pubspec change) |
| B4 BINARY_NAME unchanged | PASS | `04-acceptance-config-pins.json` |
| Canonical release build | PASS | `01-build-evidence/build-result.json` (exit 0) |
| Release verification | PASS | `02-verify/verify-release.json` (`identical=True`) |
| Package manifest | PASS | `01-build-evidence/release-manifest.json` (16/35,754,065) |
| Installer build/identity | PASS | 13O O4/O5/O7/O8; installer `94BD1559…` |
| 13L | PASS (L7; L5 = G1-deferred + pre-existing G8) | `03-guards/guard-13l.json` |
| 13O | PASS (13/13) | `03-guards/guard-13o.json` |
| 13P | PASS (carried; config pins re-verified) | `04-acceptance-config-pins.json` |
| 13Q | PASS (carried; config pins re-verified) | `04-acceptance-config-pins.json` |
| 13R | PASS (all + negative controls) | `03-guards/guard-13r/guards-result.json` |
| 13S | PASS (carried; config pins re-verified) | `04-acceptance-config-pins.json` |
| MUAMAN-18 | PASS (carried; no runtime change) | `docs/muaman-18/evidence/REGUARD-*` |
| MUAMAN-19 | PASS (carried; no runtime change) | `docs/muaman-19/evidence/REGUARD-20260816-050107` |
| Silent install | PASS (carried — installer byte-identical) | `docs/muaman-13o/evidence/06-acceptance-run-T0/install-result.json` |
| Installed 16-file check | PASS (carried) | `docs/muaman-13o/evidence/06-acceptance-run-T0/` |
| Fresh DB / 10-table check | PASS (carried) | `docs/muaman-19/evidence/REGUARD-20260816-050107/runtime-acceptance/` |
| WM_CLOSE regression | PASS (carried) | `docs/muaman-18/evidence/REGUARD-STRESS-*` |
| Cancel preserves data | PASS (carried) | `docs/muaman-18/evidence/REGUARD-*` |
| SHA-256/crosshash | PASS | `02-verify/verify-release.json` |
| `git diff --check` | PASS | run before commit |
| Secret/artifact guard | PASS | 13L L4 (0 findings) |
| Working tree clean | PASS | after commit, `git status --porcelain` empty |

---

## Closure commit message

```
I-TECH productization T0: windows runner identity closure

- Runner.rc: CompanyName/FileDescription/LegalCopyright/ProductName ->
  I-TECH للتكنولوجيا (T0 version-resource display fields only)
- Rebuilt via governed build_windows_release.ps1; 16 files / 35,754,065 B,
  crosshash 3A8CFA42..., exe 13491813... (byte-identical to accepted T0 artifact)
- Delivery/installer/tools/docs evidence for the accepted T0 delivery refresh
  (I-TECH-Setup.exe 94BD1559..., zip 4258E910...)
- T1 in-app branding: not implemented (preserved debt, owner authorization required)
- T2 compatibility identity (AppId, muaman_store.db, pubspec name, BINARY_NAME):
  frozen and unchanged
- FINAL-REPORT: docs/i-tech-productization/FINAL-REPORT.md
```
