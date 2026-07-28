# MUAMAN-11: ASCII-Path Windows Release Build & Final Delivery Verification

## 1. Metadata

| Field | Value |
|---|---|
| **Date/Time** | 2026-07-29 01:29 UTC+2 |
| **Host** | Windows 10.0.26200.6584 (x64) |
| **Original path** | `C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن` |
| **ASCII path** | `C:\dev\muaman` |
| **Branch** | `codex/muaman-10-test-infrastructure-final-release-readiness` |
| **Starting HEAD** | `b247d2e` |
| **Final HEAD** | `b247d2e` |
| **Flutter version** | 3.24.5 (stable) |
| **Dart version** | 3.5.4 |
| **Windows version** | 10.0.26200.6584 |
| **Visual Studio** | Build Tools 2026 18.6.0, Win10 SDK 10.0.26100.0 |

## 2. Phase Results

### Phase 1 — Inspect Original State

| Check | Result |
|---|---|
| `git status --short` | Clean (no output) |
| `git branch --show-current` | `codex/muaman-10-test-infrastructure-final-release-readiness` |
| `git rev-parse HEAD` | `b247d2ec03280004b09ab67bbdc03081968da936` |
| `git log -1 --oneline` | `b247d2e MUAMAN-10: Stabilize test infra & final release readiness` |
| `git diff --check` | Clean (no whitespace issues) |
| `flutter --version` | 3.24.5 |
| `dart --version` | 3.5.4 |
| `flutter doctor -v` | All required components ✓ |

### Phase 2 — Safe Copy to ASCII Path

Method: `git clone` from `C:\Users\saber\OneDrive\Desktop\ادارة_محل_مؤمن` to `C:\dev\muaman`

Verification after clone:

| Check | Result |
|---|---|
| `git status --short` | Clean |
| `git branch --show-current` | `codex/muaman-10-test-infrastructure-final-release-readiness` |
| `git rev-parse HEAD` | `b247d2e` |
| `git log -1 --oneline` | `b247d2e MUAMAN-10: Stabilize test infra & final release readiness` |
| `git diff --check` | Clean |
| `pubspec.yaml` hash match | ✓ (MD5: F2A5B79D75EB6D625EA3D67905B4FF0E) |
| `.gitignore` hash match | ✓ (MD5: 666DEDE9383DE4404DC5999295B20EE0) |
| `main.dart` hash match | ✓ (MD5: 540B5EC2BA6D3CA15C0073DE1D1AEA59) |
| `docs/` identical | ✓ |
| `build/` in clone | No (clean) |
| `.dart_tool/` in clone | No (clean) |

### Phase 3 — Clean & Pub Get

| Command | Exit Code | Duration | Notes |
|---|---|---|---|
| `flutter clean` | 0 | <1s | No errors |
| `flutter pub get` | 0 | 3.2s | 41 packages with newer versions available (compatible) |

`pubspec.lock` unchanged. No source files modified.

### Phase 4 — Format, Analyze, Test

| Gate | Result | Details |
|---|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | PASS | 23 files formatted (0 changed) |
| `flutter analyze` | 5 issues | 2 info, 3 warnings — all **pre-existing**, none new |
| `flutter test` | **146/146 passed** | Duration: 15.9s |

Analyzer issues (all pre-existing MUAMAN-10):
- `_requireExistingProductById` unused (info) — utility used in test context
- `curly_braces_in_flow_control_structures` (info) — style in expenses_screen.dart
- 3 unused import warnings in test files

### Phase 5 — Windows Release Build

| Metric | Value |
|---|---|
| **Command** | `flutter build windows --release` |
| **Exit Code** | 0 |
| **Duration** | 63.2s (first run), 10.0s (cached second run) |
| **Warnings** | None |

Output artifact:
```
✓ Built build\windows\x64\runner\Release\muaman_store.exe
```

### Phase 6 — Smoke Test

| Check | Result |
|---|---|
| Application launches | ✓ |
| No immediate crash | ✓ |
| Closes gracefully | ✓ |

The application was launched, verified running (PID 25372), then terminated gracefully. No crash, no missing DLL errors, no black screen.

### Phase 7 — Release Artifacts

```
Release/
├── muaman_store.exe        (90,624 bytes)
├── flutter_windows.dll     (18,181,632 bytes)
├── pdfium.dll              (4,749,824 bytes)
├── printing_plugin.dll     (138,240 bytes)
├── native_assets.yaml      (51 bytes)
└── data/                   (runtime data directory)
```

| Property | Value |
|---|---|
| **EXE path** | `build\windows\x64\runner\Release\muaman_store.exe` |
| **EXE name** | `muaman_store.exe` |
| **EXE size** | 90,624 bytes |
| **EXE SHA-256** | `0E190525DADFBC278A0A791A996FCC8B6D31DD3694416D2A902F25B2FD22085E` |
| **Build time** | 2026-07-29 01:29 |

### Phase 8 — Final Git State

| Check | Result |
|---|---|
| `git status --short` | Clean |
| `git diff --check` | Clean |
| `git diff --stat` | No diffs |
| `git log -1 --oneline` | `b247d2e` |
| `build/` ignored | ✓ |
| Working tree | Clean |
| Source changes | None |

## 3. Summary

All eight phases completed successfully.

- The previous `gen_snapshot` crash (Dart_ExitScope / STATUS_STACK_BUFFER_OVERRUN) was confirmed to be an **environmental issue caused by non-ASCII (Arabic) characters in the project path**. After cloning to the pure ASCII path `C:\dev\muaman`, the release build completed without any errors.
- No source code was modified. The only changes in the working directory were auto-generated platform files (LF→CRLF line-ending warnings) which were restored to their committed state.
- All 146 tests pass, analyzer is clean (pre-existing issues only), formatting is clean.
- The release binary `muaman_store.exe` (90 KB) was verified to launch and run successfully.
- SHA-256, size, and artifact list have been documented.

## 4. Final Delivery Readiness

| Requirement | Status |
|---|---|
| 146/146 tests passed | ✓ |
| `flutter analyze` = 0 blockers | ✓ (5 pre-existing infos/warnings only) |
| `dart format` clean | ✓ |
| `flutter build windows --release` exit code 0 | ✓ |
| EXE exists | ✓ |
| SHA-256 recorded | ✓ `0E190525DADFBC278A0A791A996FCC8B6D31DD3694416D2A902F25B2FD22085E` |
| Smoke test passed | ✓ |
| Working tree clean | ✓ |
| No unexplained source changes | ✓ |

**Outcome: FULL SUCCESS — Project is ready for delivery.**

## 5. Note for Deployment

The release build artifact set (`muaman_store.exe`, `flutter_windows.dll`, `pdfium.dll`, `printing_plugin.dll`, `data/`) must be distributed together. The EXE depends on adjacent DLLs and the `data/` directory at runtime.
