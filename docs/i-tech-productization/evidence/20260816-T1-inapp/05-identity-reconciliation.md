# Identity Reconciliation — T1 In-App Branding Productization

Evidence captured for the I-TECH Productization T1 closure (in-app branding).

## Question

Why does the current accepted T1 productized release tree differ from the T0
accepted tree, and is the delta fully explained and governed?

## Proven facts

| Item | T0 productized (baseline `ced3492`) | T1 productized (current accepted) |
|---|---|---|
| Reference manifest | `docs/windows-delivery-refresh/evidence/legal/release-manifest.json` (runId `I-TECH-T0-RUNNERRC-REBUILD`) | same file (runId `I-TECH-T1-INAPP-BRANDING-REBUILD`) |
| File count | 16 | 16 |
| Total bytes | 35,754,065 | 35,754,065 |
| Crosshash | `3A8CFA42656EABC8B06EEF835FB9222F95006E5B490D9B837AE76673A87794B0` | `13884FC55E8923EA6111895796CC9F576177CBED6F73AD5DA729E686A0E9A7CF` |
| exe size | 92,160 | 92,160 |
| exe SHA-256 | `134918133777C779890CA3BD4EC9CFFFD990AE04B48BE3A71DE8142B2F2FAEA1` | `3D15F1123EC9CBBAF051AA7DFDF1D526C2BBB88096733D981EEF05A2A08D2881` |
| app.so size | 9,290,656 | 9,290,656 |
| app.so SHA-256 | `86369AA8DFD530AD15C90F394FFB7D9F29A5AA67AB06A6C7F5A42516B212ED93` | `AE7044F9107430FE0F10CA81890721E49D45485808483D9D5FC4CBFEC11499C5` |
| Installer | `94BD1559CFE01281714D7EB137E931FAC75DE44C115EE5FBD27B00A772C8A831` / 13,223,003 | `53A706774CF30CA28CDBC7D7DF29A091F38EF974E0EC4FFDA3693ABF84D53B2C` / 13,226,400 |
| Delivery ZIP | `4258E9105116D0D73281C4CD5027ECC478517D662FCA3E6D70F25418E7204C8A` / 12,665,973 | `21A6A661FF4931FCC8849192EFE0BBA9C8C8A152AC66151C5FCBF5255B726C41` / 12,669,365 |

## Delta analysis

- All file sizes are identical between T0 and T1 (16 files / 35,754,065 bytes).
- Exactly **2 of 16 files** changed bytes: `muaman_store.exe` and `data/app.so`.
  The other 14 files are byte-identical (verified by `verify_release.ps1`:
  `diffCount=2`, `onlyInLegal=0`, `onlyInNew=0`).
- `verify_release.ps1` against the T0 legal manifest: exit 1, `diffCount=2`
  (exactly app.so + exe) — the only permitted divergence.
- `verify_release.ps1` against the T1 legal manifest: exit 0, `identical=True`,
  `crossNew=13884FC5…`.
- **Conclusion: the T1 delta is entirely and exclusively the Dart AOT snapshot
  (`data/app.so`) plus the runner exe**, both carrying the authorized in-app
  branding:
  - Window title → `I-TECH للتكنولوجيا` (`app/windows/runner/main.cpp`).
  - Default shop name → `المحل` (`app/lib/models/shop_profile.dart`).
  - Excel filename → `شيت_ادارة_محل_شهر8.xlsx` (new default) with legacy
    `شيت_ادارة_محل_مؤمن_شهر8.xlsx` discovery fallback
    (`app/lib/services/app_settings.dart`).
  - Binary confirmation: exe contains `I-TECH للتكنولوجيا`; app.so (UTF-16LE
    Dart AOT snapshot) contains `المحل`, `شيت_ادارة_محل_شهر8.xlsx` and
    `شيت_ادارة_محل_مؤمن_شهر8.xlsx`.

## Why the T1 identity is authoritative

1. The active legal manifest
   (`docs/windows-delivery-refresh/evidence/legal/release-manifest.json`, runId
   `I-TECH-T1-INAPP-BRANDING-REBUILD`) is 16 files / 35,754,065 / `13884FC5…`.
2. Every active harness pins the T1 identity: 13L verify, 13O installer
   contract + guards, 13P/13Q/13S acceptance-configs, 13R packaging/delivery.
3. Build determinism: the governed rebuild
   (`build_windows_release.ps1`, run `I-TECH-T1-INAPP-BRANDING-REBUILD`, 254.9s)
   reproduced the same 16-file tree used by the acceptance run.
4. The 2-file delta is exactly the authorized in-app branding edit set.

Per the governing prompt §2.5: "If actual current evidence contradicts the known
handoff values, stop treating the handoff values as canonical and document the
discrepancy." This file is that documentation. The T0 `3A8CFA42…` manifest
remains immutable as historical evidence (`20260816-T0-runnerrc\`); the current
accepted identity is `13884FC5…`.

## In-app branding edits (this closure)

- `app/windows/runner/main.cpp`: window title
  `L"I-TECH للتكنولوجيا"` (source saved with UTF-8 BOM so MSVC reads the
  literal correctly); `muaman_cleanstart_*` internal backup name unchanged.
- `app/lib/models/shop_profile.dart`: default shop name `المحل`.
- `app/lib/services/app_settings.dart`: default Excel filename
  `شيت_ادارة_محل_شهر8.xlsx`; legacy `شيت_ادارة_محل_مؤمن_شهر8.xlsx`
  discovery fallback; `muaman_store.db` and license prefix unchanged.
- Tests updated to match: `app/test/features/invoice_pdf_delivery_test.dart`,
  `app/test/unit/shop_profile_test.dart`, `app/test/widget_test.dart`.
- Docs updated: `app/docs/MUAMAN-10-TEST-INFRASTRUCTURE-FINAL-RELEASE-READINESS.md`,
  `tools/muaman13r/README.txt`, `docs/i-tech-productization/FINAL-REPORT.md`.
- Acceptance/guard configs repinned: 13O O10 expects title `I-TECH للتكنولوجيا`;
  13P/13Q/13S/13R/13L allow the T1 app path set and pin the new identity.

## Frozen internals intentionally retained

`muaman_store.exe`, `muaman_store.db`, pubspec package `name`, installer
`AppId`, `DefaultDirName {localappdata}\Programs\muaman_store`, `InternalName`,
`OriginalFilename`, exe size 92,160, app.so size 9,290,656 — all unchanged.

## Acceptance coverage

- 13O full acceptance (installer build A/B determinism, install, launch,
  uninstall, negative controls, guards): **13/13 PASS** after the O10
  UTF-8 JSON read fix (`Read-JsonIf` now reads with `-Encoding UTF8`; launch
  evidence `mainWindowTitle = I-TECH للتكنولوجيا`).
- 13R delivery guard: **18/18 PASS** (R2/R3 now allow the exact T1 app
  carve-outs under the forbidden `app/` root).
- 13L release guard: L1/L2/L3/L4/L7/L8 PASS; L5 (historical 13K guard against
  the superseded MUAMAN-19-era identity) FAIL as expected — identical to the
  recorded T0 13L evidence pattern.
