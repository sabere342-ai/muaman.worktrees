# Identity Reconciliation — T0 Windows Resource Productization

Evidence captured for the I-TECH Productization T0 closure (Runner.rc).

## Question

Why does the current accepted T0 productized release tree differ from the historical
MUAMAN-19 canonical tree, and is the delta fully explained and governed?

## Proven facts

| Item | MUAMAN-19 canonical (historical) | T0 productized (current accepted) |
|---|---|---|
| Reference manifest | `docs/muaman-19/evidence/release-build/release-manifest.json` (runId `L-20260814-122054-26960`) | `docs/windows-delivery-refresh/evidence/legal/release-manifest.json` (runId `T0`) |
| File count | 16 | 16 |
| Total bytes | 35,753,553 | 35,754,065 |
| Crosshash | `7BC41854…` | `3A8CFA42656EABC8B06EEF835FB9222F95006E5B490D9B837AE76673A87794B0` |
| exe size | 91,648 | 92,160 |
| exe SHA-256 | `9FF10A35…` (MUAMAN-18/19 worktree builds) | `134918133777C779890CA3BD4EC9CFFFD990AE04B48BE3A71DE8142B2F2FAEA1` |
| app.so size | 9,290,656 | 9,290,656 |
| app.so SHA-256 | `9BC4C95E…` | `86369AA8DFD530AD15C90F394FFB7D9F29A5AA67AB06A6C7F5A42516B212ED93` |

## Delta analysis

- Total delta = 35,754,065 − 35,753,553 = **exactly 512 bytes**.
- All 15 non-exe files have identical sizes in both trees.
- The exe grew by exactly 512 bytes: 91,648 → 92,160.
- **Conclusion: the 512-byte delta is entirely and exclusively the exe's PE version
  resource**, which now carries the I-TECH التكنولوجيا strings
  (`CompanyName`, `FileDescription`, `LegalCopyright`, `ProductName`), lengthening the
  UTF-16 resource text.

## Why the T0 identity is authoritative (not the stale 13L handoff)

The handoff lineage in `I-TECH-PRODUCTIZATION-SUPER-PROMPT.md` reported
`9A3AEFDD…` / `7BC41854…` as "current accepted delivery". Repository evidence
supersedes the handoff:

1. The active legal manifest in this worktree
   (`docs/windows-delivery-refresh/evidence/legal/release-manifest.json`, runId `T0`)
   is 16 files / 35,754,065 / `3A8CFA42…`.
2. Every active harness (13L verify, 13O installer contract, 13P/13Q/13S
   acceptance-configs, 13R packaging) pins the `3A8CFA42…` / 35,754,065 /
   exe `13491813…` / installer `94BD1559…` identity.
3. Build determinism is proven: three independent governed builds produced
   byte-identical 16-file trees (Build A `t0-productization-build`,
   Build B `t0-productization-build-b` at 2026-08-15, and this closure run
   `I-TECH-T0-RUNNERRC-REBUILD` at 2026-08-16).
4. The 512-byte exe delta is the version-resource branding change — exactly the
   authorized T0 edit that was pending in the runner resource file.

Per the governing prompt §2.5: "If actual current evidence contradicts the known
handoff values, stop treating the handoff values as canonical and document the
discrepancy." This file is that documentation. The historical `7BC41854…`
manifest remains immutable as MUAMAN-19 evidence; the current accepted identity is
`3A8CFA42…`.

## Runner.rc edit (this closure)

- File: `app/windows/runner/Runner.rc` (committed baseline was `muaman_store` /
  `com.almuaman` since initial commit `04dc868`).
- Changed only four display fields, matching the accepted artifact's VersionInfo:
  - `CompanyName`: `com.almuaman` → `I-TECH للتكنولوجيا`
  - `FileDescription`: `muaman_store` → `I-TECH للتكنولوجيا`
  - `LegalCopyright`: `Copyright (C) 2026 com.almuaman. All rights reserved.` →
    `Copyright (C) 2026 I-TECH للتكنولوجيا. All rights reserved.`
  - `ProductName`: `muaman_store` → `I-TECH للتكنولوجيا`
- Preserved: `InternalName = muaman_store`, `OriginalFilename = muaman_store.exe`,
  `FileVersion/ProductVersion = VERSION_AS_STRING`, `LANGUAGE 040904e4`, icon,
  `#pragma code_page(65001)`.
- Post-rebuild the exe is byte-identical to the accepted artifact
  (`13491813…AEA1` / 92,160 B) and contains 4× UTF-16LE `I-TECH` strings plus the
  Arabic `التكنولوجيا` codepoints — source now matches the accepted artifact.

## Frozen internals intentionally retained

`muaman_store.exe`, `muaman_store.db`, pubspec package `name`, installer `AppId`,
`DefaultDirName {localappdata}\Programs\muaman_store`, `InternalName`,
`OriginalFilename` — all unchanged (B1..B4).
