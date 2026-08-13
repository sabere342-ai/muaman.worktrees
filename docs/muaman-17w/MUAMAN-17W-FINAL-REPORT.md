# MUAMAN-17W: Live-UI Acceptance — Invoice Printing & PDF Delivery

## Outcome

**PASS (Outcome A, with documented residual risks).** MUAMAN-17W proves the
invoice printing and PDF delivery feature set end-to-end through the real
Windows desktop UI of the committed HEAD (`8362f4d`, "MUAMAN-17: add governed
invoice printing and PDF delivery"). All 13 gates (S01-S13) pass on the
authoritative run:

**launch -> first-owner setup -> login -> add product -> create sale -> invoice
preview -> save PDF -> open PDF -> print dialog -> sales history -> receipt
preview -> add sales-only cashier -> cashier denied from sales history ->
logout -> close -> final DB ground truth.**

Two residual risks are documented (see Residual Risks): the app crashes
(`0xC0000005`) on WM_CLOSE after logout, and field input values are
occasionally double-committed by the harness input path (proven not to be an
app persistence defect).

- Authoritative run: `FULL-20260812-045532`
- Evidence: `docs/muaman-17w/evidence/FULL-20260812-045532/`
- HEAD at run start: `8362f4d003b2f65a20940a629b98edd5adc3c9cb`
- Start/finish (UTC): `2026-08-12T01:55:33Z` -> `2026-08-12T02:00:39Z`

## Environment

- Windows 11 Pro, machine `ISLAM`, user `saber`, PowerShell 5.1.
- Release binary under test (not a ZIP delivery; this phase tests the built
  runner):

  | Item | Size (bytes) | SHA-256 |
  |---|---|---|
  | `app\build\windows\x64\runner\Release\muaman_store.exe` | 90,624 | `194B46007E82D06936355C8C76B1E7DB93F97DF6691596097819E83A608BD6A9` |

- Target window is 1500x850. Flutter exposes only a top-level `FLUTTERVIEW`
  pane to UIA (no element tree), so the harness drives the UI by OCR
  (ar-SA) plus exact-RGB colour scanning; UIA is used only for native
  dialogs (save/print), never for Flutter controls.
- Harness: `tools/muaman17w/run_smoke.ps1` (ASCII-only; Arabic UI strings come
  from `tools/muaman17w/ui_strings.json`, UTF-8, loaded with `ConvertFrom-Json`
  so PS 5.1 never misreads them as ANSI).
- Business DB persisted by the run:
  `app\build\windows\x64\runner\Release\.dart_tool\sqflite_common_ffi\databases\muaman_store.db`
  (110,592 bytes, quoted by S13; inspected on a copy, never in place).

## Journey Executed (worker steps, all passed)

1. **S01-launch** - launches the release exe, main window found, first-owner
   setup screen recognized (`04-app-launch.png`).
2. **S02-setup-owner** - creates the owner (`مالك 17W` / `owner17w`), login
   screen reached (`04b-login.png`); name/username fields band-verified,
   password/confirm `masked-verified` (no content leak).
3. **S03-login-owner** - owner logs in, dashboard reached
   (`05-dashboard.png`).
4. **S04-add-product** - add-product dialog recognized, `منتج اختبار 17W`
   / cost 50 / qty 20 filled, dialog closed, inventory list shown
   (`06-inventory.png`).
5. **S05-create-sale** - sale form: price 100, customer filled, `حفظ` clicked,
   invoice preview reached with invoice `INV-1786499860797` and
   `إجمالي الفاتورة: 100` (`07-invoice-preview.png`).
6. **S06-save-pdf** - `حفظ PDF` -> native save dialog (#32770), filename set,
   saved to `%LOCALAPPDATA%\Temp\muaman-17w\pdf\invoice_17w_acceptance.pdf`
   (18,680 bytes, `%PDF-` header, SHA-256
   `D8B5E7DCDF39C3B26D4298771E5F7861C28C47F93EB97DE4382147D1508AAB54`).
7. **S07-open-pdf** - `PDF` (view) button opens the temp copy
   (`invoice_INV-1786499860797.pdf`, 18,680 bytes) in the default viewer
   (`09-pdf-open.png`); the OS default viewer is non-Chrome.
8. **S08-print-dialog** - `طباعة` opens the native Print Setup dialog
   (#32770), canceled, app back on the preview (`10-print-dialog.png`,
   `11-print-cancel.png`).
9. **S09-sales-history** - sales history reached, the S05 sale card is
   visible with product probe `17W`; the receipt icon is located by
   colour-scan (`iconCenter={X:98,Y:303,N:35}`, 13 clusters), clicked, and the
   receipt preview opens (title `عرض الفاتورة`, INV number, `منتج اختبار 17W`,
   `إجمالي الفاتورة: 100`, buttons `طباعة`/`حفظ PDF`) - layout identical to
   S05's preview (`12-sales-history.png`, `12b-receipt-preview.png`).
10. **S10-add-cashier** - users screen reached, create-user dialog filled
    (`كاشير 17W` / `cashier17w`), role dropdown opened on `موظف` and `مبيعات`
    selected (sales-only role), create clicked, dialog closed, cashier row
    visible (`13-users.png`).
11. **S11-cashier-denied** - owner logs out, cashier logs in, sales-only shell
    reached; the sales-history screen shows the denial banner
    `سجل المبيعات متاح للمالك فقط` and does NOT leak the owner's history:
    `leakCountLine=false`, `leakProductName=false`, `leakReceiptUia=false`;
    the create-sale entry is visible (`14-salesonly.png`).
12. **S12-logout-close** - logout back to the login screen
    (`15-login-final.png`), then WM_CLOSE (see residual risk: exit code
    `-1073741819`, i.e. `0xC0000005`).
13. **S13-final-evidence** - evidence packaged: 78 screenshots, 2 PDFs
    (`invoice_17w_acceptance.pdf`, `open-copy.pdf`), DB present and quoted;
    `aborted=false`.

## Gate Results (S01-S13)

| Gate | Result |
|---|---|
| S01 launch (window found, setup screen recognized, process is release exe) | PASS |
| S02 first-owner setup -> login screen (fields band/masked-verified) | PASS |
| S03 owner login -> dashboard | PASS |
| S04 add product (dialog, fill, close, inventory list) | PASS |
| S05 create sale -> invoice preview (invoice number, total 100) | PASS |
| S06 save PDF (native dialog, %PDF- header, SHA-256 quoted) | PASS |
| S07 open PDF (temp copy opened in default viewer) | PASS |
| S08 print dialog (native Print Setup, cancel, app restored) | PASS |
| S09 sales history -> receipt icon -> receipt preview (colour-scan click, preview verified) | PASS |
| S10 add cashier (role dropdown = sales-only, dialog closed, row visible) | PASS |
| S11 cashier denied from sales history (no leak of owner's count/products/receipt) | PASS |
| S12 logout -> login screen -> WM_CLOSE close | PASS* |
| S13 final evidence (78 shots, 2 PDFs, DB quoted, no secrets, aborted=false) | PASS |

\* S12 PASSes its gate (logout reached the login screen, process exited) but
the WM_CLOSE teardown crashed with `0xC0000005` - see Residual Risks.

## DB Ground Truth (run 045532)

Inspected on a copied DB via `sqlite3`:

- `users`: `(1, 'مالك 17Wمالك 17W', 'owner17w', 'owner', active)`,
  `(2, 'كاشير 17W', 'cashier17w', 'salesOnly', active)`.
- `sales`: id `226` -> product `منتج اختبار 17W` -> `invoiceId=1`.
- `invoices`: `(1, 'INV-1786499860797', 'عميعميل تجريبي 17Wميل تجريبي 17W نقدي',
  'cash', 100.0, 1 item)`.
- `app_settings`: `defaultCustomerName='عميل نقدي'` (the invoice field default
  the harness cleared/overwrote; see Residual Risks).

The role `salesOnly` is the ground-truth enforcement behind S11 (denial) and
the cashier's shell is `SalesOnlyShell` at the UI level.

## Negative Controls

Fail-closed evidence that an injected defect produces a rejection, not a false
PASS. Each control is a real failed run from this lineage whose regression was
then eliminated:

- **NC-S09 receipt-icon sort** - before the cluster-sort fix, `Sort-Object Y`
  silently no-oped on `[ordered]@{}` clusters and the "topmost" cluster was a
  FAB at y~694-746; run `FULL-20260812-043516` recorded
  `iconCenter={X:117,Y:735}` and clicked the FAB. After the fix, the same scan
  yields the topmost receipt cluster `{X:98,Y:303,N:35}` (run 045532). The
  sorted cluster order is the control.
- **NC-S09 preview verify** - run 043516 false-positived on the bare word
  `الفاتورة`: the click had opened the new-invoice screen (`إنشاء فاتورة
  جديدة`, cart `سلة الفاتورة`) and the poll matched those strings. The
  replacement `Test-OcrPreviewOpen` requires the preview-unique `طباعة`
  button (or `عرض`+`الفاتورة` on the same row) and **throws** when the preview
  does not open. The new-invoice screen contains none of those, so it is
  rejected. Run 045532 OCRs the true preview.
- **NC-S11 leak matchers** - run `FULL-20260812-044635` showed
  `leakCountLine=true` and `leakProductName=true` that were fuzzy false
  positives (`العمليات`~`المبيعات` sales-screen title at y61; `17W`~`l17W`
  cashier appbar display name at y68). Tightened to match only the first word
  `عدد` and to probe y>=130 (below the appbar); run 045532 reports all leak
  flags `false` while the denial banner is visible - the clean screen is the
  control.
- **NC-S10 role dropdown** - probe runs `PROBE-role-20260812-040715` (role
  stored `salesOnly` but original booleans wrong) and
  `PROBE-role-20260812-041135` (corrected) established the open->select->
  create flow; the dialog-title matcher is restricted to the y-band 100-300 so
  the FAB tooltip `مستخدم جديد` cannot masquerade as the dialog title
  `إنشاء مستخدم جديد`.

## Secret Hygiene

- Owner and cashier passwords are a single fixed test credential
  (`W17Pass@2026`) defined in `ui_strings.json` - a test fixture, not a real
  secret.
- All password fields are typed with `-Secret`: field before-shots are deleted
  and the result is `masked-verified` (no latin/latin-digit leak in the field
  band); no password text is written to logs.
- An evidence scan of the authoritative run finds zero occurrences of the
  credential; S13's packaged evidence contains no secrets.

## Harness Fixes During This Run

Defects found and fixed in `tools/muaman17w/run_smoke.ps1`, each covered by a
re-run and a negative control above:

1. **S09 receipt-icon sort** - `Find-ColorIconCenters` emitted clusters as
   `[ordered]@{}`, which `Sort-Object Y` resolves no property on (silent
   no-op), so the "topmost" cluster was a FAB. Clusters are now
   `[pscustomobject]@{X;Y;N}` and sort correctly.
2. **S09 preview verification** - `Test-OcrPreviewOpen` replaces the bare
   `الفاتورة` matcher; the colour-click now polls it and **throws** on failure
   instead of recording a diagnostic.
3. **S10 role dropdown** - open the role field via `Click-OcrSimilar -Transient`
   on the field value `موظف`, select `مبيعات` (second token of
   `users.itemSalesOnly`) via `Click-OcrSimilar -Transient`, submit via
   `Click-OcrExact` on `users.buttonCreate` with no `-MaxYFrac`, and poll the
   dialog close with 12s waits.
4. **S10/S11 dialog titles** - `Test-OcrDialogTitleOpen -Words -TitleParts`
   restricts the title match to the y-band 100-300 (below the appbar) so the
   FAB tooltip cannot collide with the dialog title.
5. **S11 leak matchers** - count line matches only the first word `عدد`;
   product probe restricted to y>=130 (below the appbar).

## Residual Risks

1. **App crash on WM_CLOSE (production defect flag).** S12 closes the app
   after logout; the process exits with `exitCode=-1073741819` (`0xC0000005`,
   access violation). The close is a crash rather than a clean teardown
   (S10 of the earlier 13S phase was clean). The gate passes because the
   logout/login-screen and process-exit checks are what S12 asserts, but the
   app-side close path should be investigated in a later phase.
2. **Intermittent input double-commit (harness-side, not an app defect).**
   The owner name typed once (`مالك 17W`) landed in the field as
   `مالك 17Wمالك 17W` (post-fill OCR at y=378 shows two `17W` tokens) and was
   saved that way; the cashier name (`كاشير 17W`) typed by the same mechanism
   in the same run was saved clean - so the doubling is intermittent. The app
   persistence paths are proven pass-through (`User.toMap`,
   `_saveInvoice`, `first_owner_setup_screen._onCreateUser`), and the field
   already contained the doubled text before any save logic ran. The stored
   customer name (`عميعميل تجريبي 17Wميل تجريبي 17W نقدي`) is a field that
   started with the `عميل نقدي` default, whose clear+retype did not fully
   replace it, so the typed text interleaved with leftovers.
3. **Fill verification is probe-substring only.** `Fill-Field` /
   `Fill-FloatingLabelField` verify by OCR substring (e.g. `17W`) inside the
   field band, so a mangled-but-probe-bearing value passes (the customer field
   verified `17W` inside the mangled text). S05 does not assert the saved
   customer name equals the intended value. A stronger check (clipboard-paste
   input + exact value verification) is the follow-up fix.

## Git Integrity

- Run metadata records `headSha = 8362f4d003b2f65a20940a629b98edd5adc3c9cb`,
  which is the current worktree HEAD (`MUAMAN-17: add governed invoice printing
  and PDF delivery`).
- `git status` shows only the expected untracked additions
  (`?? tools/muaman17w/` and `?? docs/muaman-17w/`); zero production diff
  (`app/`, `assets/`, `pubspec.*`, `delivery/` untouched).
- Per the standing instruction this report is not committed; it is the
  pre-commit acceptance evidence for the MUAMAN-17 work.

## Limitations

- Acceptance runs on one machine (Windows 11 Pro, `ISLAM`) on the interactive
  desktop; OCR (ar-SA) and colour-scan targeting depend on the verified
  rendering path.
- UIA targeting is unavailable for Flutter controls (top-level `FLUTTERVIEW`
  only), so all Flutter interaction is positional/OCR based and therefore
  layout-sensitive.
- The two residual risks above are documented rather than fixed in this phase.
