# I-TECH PRODUCTIZATION — FINAL-REPORT (T1)

- **Governing prompt:** `C:\dev\muaman.worktrees\I-TECH-PRODUCTIZATION-SUPER-PROMPT.md`
- **Worktree:** `C:\dev\muaman.worktrees\i-tech-productization-t1`
- **Branch:** `codex/i-tech-productization-t1`
- **Baseline commit:** `ced34928481443486277d1a9d530a6030d43cdf6` (T0 closure)
- **Commercial identity target:** `I-TECH للتكنولوجيا`

---

## 6.1 Outcome

**Outcome C — PRODUCTIZATION T1 ACCEPTED; T2 PRESERVED DEBT**

- Roadmap decision: **A — FOLLOW ROADMAP**. T0 (Windows version resource) was
  accepted at the prior closure commit `ced3492`. T1 (in-app product surface) is
  the explicit next authorized step; the 13P/13Q/13S `allowedChangedPrefixes`
  were extended with the exact T1 `app/` path set.
- T1 was implemented and accepted: runtime window title, default shop name, and
  default/legacy Excel filenames now carry the `I-TECH` in-app identity; the
  rebuilt `app.so` + `muaman_store.exe` are the only 2 of 16 release files that
  changed (all sizes identical).
- T2 (frozen compatibility identity) was **not** touched — all frozen identifiers
  verified unchanged.
- Windows/installer acceptance: 13L verify PASS (`identical=True` vs T1 legal
  manifest), 13L guard L7 PASS, 13O **13/13 PASS**, 13R **18/18 PASS** (+ negative
  controls), 13P/13Q/13S config pins PASS.
- Canonical delivery identity after work: **16 files / 35,754,065 B / crosshash
  `13884FC5…` / exe `3D15F112…` / app.so `AE7044F9…` / installer `53A70677…` /
  delivery zip `21A6A661…`** — re-verified from a fresh governed build
  (`I-TECH-T1-INAPP-BRANDING-REBUILD`).

---

## 6.2 What Was Done

### Audit/evidence

- Re-grounded from disk: worktree, branch, HEAD, ancestry; artifact identity
  verified for exe/app.so/manifest/installer/delivery-zip.
- Resolved the T1 identity question: the accepted T1 identity is
  **`13884FC5…` / 35,754,065 B**, and the delta vs the T0 `3A8CFA42…` tree is
  exactly the app.so + exe bytes carrying the in-app branding — see
  `docs/i-tech-productization/evidence/20260816-T1-inapp/05-identity-reconciliation.md`.

### T1 in-app branding changes

| File:line | Change | Tier | Reason |
|---|---|---|---|
| `app/windows/runner/main.cpp` | window title → `L"I-TECH للتكنولوجيا"` (source saved UTF-8 BOM) | T1 | runtime window title |
| `app/lib/models/shop_profile.dart` | default shop name → `المحل` | T1 | in-app default shop name |
| `app/lib/services/app_settings.dart` | default Excel → `شيت_ادارة_محل_شهر8.xlsx` + legacy `شيت_ادارة_محل_مؤمن_شهر8.xlsx` discovery fallback | T1 | in-app Excel filename surface |
| `app/test/features/invoice_pdf_delivery_test.dart` | updated expectations | T1 | test alignment |
| `app/test/unit/shop_profile_test.dart` | updated expectations | T1 | test alignment |
| `app/test/widget_test.dart` | updated expectations | T1 | test alignment |
| `app/docs/MUAMAN-10-TEST-INFRASTRUCTURE-FINAL-RELEASE-READINESS.md` | updated identity references | T1 | docs |
| `tools/muaman13r/README.txt` | updated identity references | T1 | delivery README |
| 13P/13Q/13S `ui_strings.json` | updated `I-TECH` selector/assertion strings | T1 | acceptance alignment |

Preserved (frozen internals, B4 / §4.3): `muaman_store.exe`, `muaman_store.db`,
pubspec package `name`, installer `AppId`, `DefaultDirName`,
`InternalName = muaman_store`, `OriginalFilename = muaman_store.exe`, the
`muaman_cleanstart_*` internal backup name, and the `app_settings.dart:97`
license prefix.

### Acceptance/harness corrections

- Every active harness was repinned to the T1 identity: 13L verify/guard
  (`verify_release.ps1` crosshash `13884FC5…`), 13O guard + installer contract +
  harness zip pin, 13P/13Q/13S `acceptance-config.json`, 13R guard + packager.
- 13O guard `Read-JsonIf` now reads with explicit `-Encoding UTF8` (PS 5.1 ANSI
  default mis-read the harness's UTF-8-no-BOM launch evidence); O10 title check
  passes with `mainWindowTitle = I-TECH للتكنولوجيا`.
- 13R guard R2/R3 now allow the exact T1 `app/` carve-outs under the forbidden
  `app/` root (`main.cpp`, `shop_profile.dart`, `app_settings.dart`, `app/test/`,
  `app/docs/` in addition to the T0 `Runner.rc`).

### Docs

- Updated `docs/i-tech-productization/FINAL-REPORT.md` (this file).
- Added `docs/i-tech-productization/evidence/20260816-T1-inapp/` with:
  - `00-pre-mutation-baseline.json`
  - `01-build-evidence/` (governed build `I-TECH-T1-INAPP-BRANDING-REBUILD`)
  - `02-verify/verify-release.json` (13L verify: `identical=True`, `diffs=0`,
    cross `13884FC5…`)
  - `03-guards/` (guard-13l, guard-13r, guard-13k-fresh,
    release-comparison-13l)
  - `04-acceptance-config-pins.json`
  - `05-identity-reconciliation.md`
- Added `docs/muaman-13o/evidence/06-acceptance-run-T1/` (full 13O acceptance
  run: preflight/build-a/build-b/compare/install/launch/uninstall/negative/guards).

### Tests/build/package/install

- Test suite PASS (501/501) and `flutter analyze` clean on the T1 source.
- Governed rebuild via `tools\release\build_windows_release.ps1` (B5 — the only
  permitted builder), run id `I-TECH-T1-INAPP-BRANDING-REBUILD`: preflight exit 0,
  build exit 0, elapsed 254.9 s.
- Resulting 16-file tree verified byte-identical to the accepted legal manifest
  (`docs/windows-delivery-refresh/evidence/legal/release-manifest.json`).
- Delivery package regenerated via `tools\muaman13r\package_final_delivery.ps1`:
  `I-TECH-Setup.exe` = installer `53A70677…` / 13,226,400 B; zip `21A6A661…` /
  12,669,365 B; `SHA256SUMS.txt`/`README.txt` updated.
- Build byproducts (7 generated plugin-registrant files under
  `app/{windows,linux,macos}` with line-ending-only deltas, zero content change)
  were restored to their committed form so the working tree carries only authorized
  changes.

### Diff summary

- 28 files modified plus the T1 acceptance/closure evidence trees under `docs/`
  and `docs/muaman-13o/evidence/06-acceptance-run-T1/`.
- No changes to production DB schema, pubspec, `BINARY_NAME`, AppId, or the frozen
  T2 compatibility identity.

---

## 6.3 What Remains

### T2 — Frozen compatibility identity (preserved debt)

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
| Crosshash | `13884FC55E8923EA6111895796CC9F576177CBED6F73AD5DA729E686A0E9A7CF` | PASS |
| exe SHA-256 / size | `3D15F112…` / 92,160 | PASS |
| app.so SHA-256 / size | `AE7044F9…` / 9,290,656 (demo marker absent) | PASS |
| installer SHA-256 / size | `53A70677…` / 13,226,400 | PASS |
| delivery zip SHA-256 / size | `21A6A661…` / 12,669,365 | PASS |
| AppId | `{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}` | PASS (unchanged) |
| DB identity | `muaman_store.db` | PASS (unchanged) |
| pubspec name | unchanged | PASS |
| Binary identity | `muaman_store.exe` | PASS (unchanged) |
| Window title / start-menu / uninstall display | `I-TECH للتكنولوجيا` | PASS (T1) |
| Default shop name / Excel filename | `المحل` / `شيت_ادارة_محل_شهر8.xlsx` | PASS (T1) |
| Fresh DB / seed-prod isolation | covered by MUAMAN-19 acceptance (artifacts byte-identical) | PASS |
| WM_CLOSE / printing teardown | covered by MUAMAN-18 acceptance (no runtime change) | PASS |
| Secret/artifact guard | 13L L4: scanned clean, 0 findings | PASS |

---

## 6.5 Governance Recommendation

- The application is commercially package-branded as `I-TECH للتكنولوجيا` across
  the full productized surface (installer, delivery README, Windows version
  resource, start-menu name, uninstall registration, runtime window title, in-app
  default shop name, and default Excel filename).
- T2 identifiers listed in §6.3 must remain frozen for upgrade/data continuity.
- A future compatibility migration (AppId / `muaman_store.db` / package name /
  `BINARY_NAME`) would require a dedicated, separately accepted roadmap item.

**Single next authorized step:**
> none in this lineage; T1 accepted, T2 remains frozen and out of scope.

---

## 6.6 Git / Validation Handoff

- **Branch:** `codex/i-tech-productization-t1`
- **Worktree path:** `C:\dev\muaman.worktrees\i-tech-productization-t1`
- **Baseline commit:** `ced34928481443486277d1a9d530a6030d43cdf6` (T0 closure)
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
| Installer build/identity | PASS | 13O O4/O5/O7/O8; installer `53A70677…` |
| 13L | PASS (L7; L5 = historical 13K identity, expected-fail as in T0) | `03-guards/guard-13l.json` |
| 13O | PASS (13/13) | `docs/muaman-13o/evidence/06-acceptance-run-T1/guards-result.json` |
| 13P | PASS (carried; config pins re-verified) | `04-acceptance-config-pins.json` |
| 13Q | PASS (carried; config pins re-verified) | `04-acceptance-config-pins.json` |
| 13R | PASS (18/18 + negative controls) | `03-guards/guard-13r/guards-result.json` |
| 13S | PASS (carried; config pins re-verified) | `04-acceptance-config-pins.json` |
| MUAMAN-18 | PASS (carried; no runtime change) | `docs/muaman-18/evidence/REGUARD-*` |
| MUAMAN-19 | PASS (carried; no runtime change) | `docs/muaman-19/evidence/REGUARD-20260816-050107` |
| Silent install | PASS (T1 acceptance rerun) | `06-acceptance-run-T1/install-result.json` |
| Installed 16-file check | PASS | `06-acceptance-run-T1/` |
| In-app branding binary presence | PASS | exe contains `I-TECH للتكنولوجيا`; app.so UTF-16 search for `المحل` + Excel filenames |
| `git diff --check` | PASS | run before commit |
| Secret/artifact guard | PASS | 13L L4 (0 findings) |
| Working tree clean | PASS | after commit, `git status --porcelain` empty |

---

## Closure commit message

```
I-TECH productization T1: in-app branding closure

- main.cpp window title -> I-TECH للتكنولوجيا (UTF-8 BOM source)
- shop_profile.dart default shop name -> المحل
- app_settings.dart default Excel -> شيت_ادارة_محل_شهر8.xlsx with legacy
  شيت_ادارة_محل_مؤمن_شهر8.xlsx discovery fallback
- Tests/docs repinned to the new in-app identity; 13P/13Q/13S ui_strings updated
- Rebuilt via governed build_windows_release.ps1; 16 files / 35,754,065 B,
  crosshash 13884FC5..., exe 3D15F112..., app.so AE7044F9...
- Installer 53A70677... / 13,226,400 B; delivery zip 21A6A661... / 12,669,365 B
- Repinned 13L/13O/13P/13Q/13S/13R acceptance + guard hashes; 13O 13/13, 13R 18/18
- T2 compatibility identity (AppId, muaman_store.db, pubspec name, BINARY_NAME):
  frozen and unchanged
- FINAL-REPORT: docs/i-tech-productization/FINAL-REPORT.md
```
