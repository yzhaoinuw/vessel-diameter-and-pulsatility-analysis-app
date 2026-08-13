# Next Steps

Use this checklist alongside `work_log.md`. Keep only actionable work here; completed work belongs in Git history and the work log.

## Currently Hot

- [Runtime loader contract and smoke coverage](#runtime-loader-contract-and-smoke-coverage-codex-gpt-5) - decide the supported LIF/TIFF/MAT and Bio-Formats contract, then run an authorized end-to-end smoke test.

Other sections are background or paused unless a new request reopens them.

## Runtime loader contract and smoke coverage (Codex, GPT-5)

Status: planned; current source paths are documented, but product intent and data-backed runtime behavior still need maintainer confirmation.

Context:

- The file picker accepts LIF, TIFF, and MAT inputs, while the README advertises only LIF and TIFF.
- The active LIF callback uses `util/`; the active TIFF callback uses `imread_big.m` with an `imread` fallback.
- A private Bio-Formats `readTif` method and the local `bfmatlab/` dependency remain, but the active TIFF callback does not call that method.
- The App Designer source-control workflow is synchronized and validated; that does not replace a runtime test with representative input.

Remaining work:

- Confirm whether Bio-Formats is still required and whether MAT input is a supported public feature.
- With explicit data authorization, smoke-test one suitable non-sensitive input through selection, crop, threshold/mask/caps, full computation, and result saving.
- Confirm the saved MAT fields and basic dimensions against `../project_overview.md`.
- Update installation/usage wording after the supported loader contract is decided.
- Only then consider removing, relocating, or testing secondary loader code; do not delete it based on static reachability alone.

## Background / Paused

### Incrementally separate non-UI logic

The app still contains loading, area/diameter calculation, and result-assembly logic in private methods. Move pure logic into ordinary functions only when a focused behavior change benefits from testable inputs/outputs; avoid a broad rewrite.

### Establish repeatable tests

There is no automated runtime suite. Prefer synthetic or redistributable fixtures and pure helper tests. Do not commit experimental recordings merely to create coverage.

### Address analyzer and release-history debt

The generated app currently reports 38 existing Code Analyzer findings, mostly callback/style/performance suggestions. Fix them opportunistically with behavior checks. Before the next release, reconcile the old `change_log.txt` with the newer Git tags instead of guessing historical release notes during tagging.
