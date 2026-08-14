# Governed Windows Delivery-Package Refresh — Evidence Index

Ticket: none (Roadmap Alignment Check — governance decision B, CONTROLLED DEVIATION REQUIRED)
Branch: `codex/windows-delivery-package-refresh`
Baseline: `697a9f974cf7433dac30fe4f09940076d923fa2f` (MUAMAN-19 accepted production)

All evidence below was produced in this worktree on baseline `697a9f9` before the
single atomic commit.

## Pipeline runs (re-run in-session)

| Step | Artifact | Result |
|---|---|---|
| canonical release zip | `package_windows_release.ps1` | PASS — deterministic `muaman-windows-release.zip`, 15,555,975 B, SHA `FEC8B79BA57FEB01EE12561AD21A32183073BFFFD8054E5AE1CCB62F83683355`, 16 entries |
| installer build | `package_windows_installer.ps1` | PASS — compiler identity OK (ISCC.exe 6.7.3, SHA `0A8757031B...`), staging manifest PASS (16 files), fonts confirmed in compile log |
| installer artifact | `Muaman-Setup.exe` | 13,225,828 B, SHA `9A3AEFDD9188BD9A5D25D1D95324BE48C546DBB78BEC4B6998ECA4D4F1BAE0E1` |
| delivery zip | `Muaman-1.0.0-Windows.zip` | 12,668,785 B, SHA `DD7D335B840676180487B10C5DEC2CEAD9008D5D99192242A886CA4FCBCBC789`, 3 entries, deterministic timestamp; extraction reproduces staged tree byte-identical |

## Legal identity

| Artifact | Result |
|---|---|
| `evidence/legal/release-manifest.json` | runId `WR1`, 16 files, 35,753,553 B, crosshash `7BC418546CABA55A3389C22A277B327D32683ABC91DA6CAF75FDA163E7204D6F` — matches accepted MUAMAN-19 canonical identity |

## Runtime acceptance (in-session, real user, this machine)

Recorded in `evidence/acceptance/01-runtime-acceptance.json` (+ `launch-window.png`).

| Step | Result |
|---|---|
| remove old MUAMAN-13R install | silent uninstall exit 0; app dir gone |
| install new installer | exit 0; 16 files incl. NotoSansArabic-Bold.ttf, NotoSansArabic-Regular.ttf, THIRD_PARTY_NOTICES.txt |
| installed binary identity | `muaman_store.exe` == canonical `9FF10A35BA134412E9070D262D8E723B5F9B56B614ED9998CFF75297A602AC2A`; `data/app.so` == canonical `9BC4C95EA5901C4A8F04E350D8B7060F868B761D22D7B1BB2C2B527E4EFE1113` |
| launch (WorkingDirectory = install dir, Start-Menu-equivalent) | window found, responding, alive after 25 s |
| fresh DB | `{app}\.dart_tool\sqflite_common_ffi\databases\muaman_store.db` (81,920 B): 10 tables; products=0, sales=0, returns=0, expenses=0, invoices=0, import_batches=0, inventory_count=0, users=0, role_permissions=0; app_settings = 4 runtime defaults; demo barcode products = 0 → **production clean start through the real installer: PASS** |
| graceful close | WM_CLOSE → clean exit, twice (MUAMAN-18 path intact) |
| uninstall | exit 0; registry key removed, Start Menu link removed, program files removed; only business DB preserved (`{app}\.dart_tool\...\muaman_store.db`) |

## Delivery tree (committed in `delivery/Muaman-1.0.0-Windows/`)

| File | Size (B) | SHA-256 |
|---|---|---|
| `Muaman-Setup.exe` | 13,225,828 | `9A3AEFDD9188BD9A5D25D1D95324BE48C546DBB78BEC4B6998ECA4D4F1BAE0E1` |
| `README.txt` | 2,267 | unchanged (not touched) |
| `SHA256SUMS.txt` | 84 | records the new installer SHA |

## Notes on evidence integrity

- The canonical release was NOT rebuilt; the refreshed package consumes the
  accepted MUAMAN-19 release payload (16-file canonical tree at
  `muaman-19-safe-demo-data-commissioning-clean-start\app\build\windows\x64\runner\Release`).
- `verify_release.ps1` and `package_windows_installer.ps1` contract constants were
  updated to the new legal manifest identity before the runs.
- No push, no tag, no merge. Evidence and delivery artifacts are part of the single
  atomic commit.
- Recorded limitation: full fresh-user UI acceptance (13P/13Q harness on a new
  account) was not re-run in this session; its `acceptance-config.json` files were
  updated to the new installer identity so a future run validates the new artifact.
