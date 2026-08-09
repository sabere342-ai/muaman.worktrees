MUAMAN-13S harness - independent real-user delivery-to-launch acceptance
========================================================================

Purpose
-------
Prove that an actual Windows recipient, represented by the fresh standard local
user `CodexMuaman13S`, can take the governed delivery package
`delivery/Muaman-1.0.0-Windows.zip` through the full journey entirely from their
own machine state, with no repository or developer access:

  receive -> verify SHA-256 -> extract -> verify exact 3-file contents ->
  verify installer/README/manifest identities -> README readiness check ->
  SHA256SUMS cross-check -> silent install from the extracted delivery only ->
  verify installed payload -> first launch -> first-owner setup -> login ->
  dashboard smoke -> clean close -> relaunch -> login directly (owner persisted)
  -> final persisted state.

The consumer workspace is the fresh user's own Downloads area
(`C:\Users\CodexMuaman13S\Downloads\Muaman-13S`). The worker is launched with
CreateProcessWithLogonW under a restricted PATH and is given NO repository path;
independence is proven by gate S01.

Files
-----
- acceptance-config.json      self-contained expected identities (no repo paths)
- ui_strings.json             Arabic UI strings for OCR-driven UI automation
- delivery_validation.ps1     pure, deterministic, fail-closed validation library
- consumer_worker.ps1         runs AS the fresh user; performs the journey S0..S12
                              and writes evidence
- guard_tests_13s.ps1         computes gates S01..S20 from evidence + repo facts
- guard_negative_controls.ps1 NC01..NC08 fail-closed proofs on disposable fixtures
- orchestrator_13s.ps1        controller: preflight, staging, worker launch,
                              guards, negatives, evidence collection
- lib/common.ps1              shared native/OCR/UIA/registry helpers (13Q lineage)

Run
---
1. Bootstrap the fresh account once (elevated):
     powershell -NoProfile -ExecutionPolicy Bypass -File m13s-bootstrap.ps1
2. Run the acceptance (non-elevated, as the developer):
     powershell -NoProfile -ExecutionPolicy Bypass -File tools\muaman13s\orchestrator_13s.ps1
   Optional overrides: -RunId, -ExpectedHead, -ExpectedFinalHead (the second,
   authoritative, post-commit run passes the committed HEAD).

Exit codes (orchestrator)
-------------------------
0  all worker steps + S01..S20 gates + NC01..NC08 passed
1  preflight/staging/credential failure
3  worker steps failed (see evidence/json/worker-done.json)
4  guard gates failed (see guards-result.json)
5  negative controls failed

Evidence
--------
Written to docs/muaman-13s/evidence/<RunId>/ with worker evidence under
evidence/, orchestration record, guards-result.json, negative-controls-result.json
and the worker capture. The frozen ZIP binary and staging area stay OUT of the
worktree.
