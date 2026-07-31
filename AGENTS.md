# Guidelines and Tips for Agents

Read this file first when joining a session in this repository. It defines the product boundary, active runtime, source-control rules, and documentation workflow. Generic treaty mechanics live in [`treaty_conventions.md`](treaty_conventions.md); keep this file focused on this MATLAB application.

## Startup Rule

At the beginning of a new chat or agent session, read this file before opening other Markdown files. Use the [Documentation](#documentation) map to choose only the additional context relevant to the task.

## Product Boundary

The maintained product is the MATLAB App Designer application in `app.mlapp`, its ordinary MATLAB helpers, and the supporting documentation/workflow files.

Do not inspect, edit, stage, or commit experimental recordings, generated results, or local data unless the user explicitly authorizes it. Preserve unrelated local scripts and dependencies, including untracked files, even when they appear in the repository root.

## Runtime Environment

- Primary runtime: MATLAB R2025a on Windows.
- Installed executable: `C:\Program Files\MATLAB\R2025a\bin\matlab.exe`.
- No project Conda or Python environment is required to run the app.
- The downloaded `bfmatlab/` folder is a local, untracked dependency used by alternate reader helpers.
- The treaty CLI is not on `PATH`; use `C:\Users\yzhao\python_projects\agent_collab_treaty\.venv\Scripts\treaty.exe`.

Keep the app relocatable. Do not add workstation-specific absolute paths to active product code.

## Common Tasks

Open the authoritative app for editing or manual testing:

```powershell
matlab -r "open('app.mlapp')"
```

Generate and verify the GitHub-review companion:

```powershell
matlab -batch "export_app_source"
matlab -batch "export_app_source('verify')"
```

Enable the repository-local hook after a fresh clone:

```powershell
matlab -batch "setup_version_control"
```

Run static and treaty checks:

```powershell
matlab -batch "checkcode('export_app_source.m'); checkcode('setup_version_control.m')"
C:\Users\yzhao\python_projects\agent_collab_treaty\.venv\Scripts\treaty.exe validate .
git diff --check
```

Before committing, inspect `git status --short`, `git diff`, and `git diff --cached --name-only`; stage only the requested source/docs. There is no automated runtime test suite or committed experimental fixture set.

## App Designer Source Contract

`app.mlapp` is the only editable and runnable source of truth. `app_exported.m` is generated for readable GitHub diffs and review; never hand-edit it.

When `app.mlapp` changes:

1. Regenerate `app_exported.m`.
2. Run `export_app_source('verify')`.
3. Inspect the exported callbacks/helpers for the concrete requested behavior; synchronization alone is not a behavior test.
4. Commit `app.mlapp` and `app_exported.m` together.

Use MATLAB `visdiff` or the Comparison Tool for authoritative package/layout review. Keep UI-layout branches short and avoid concurrent layout edits.

## When To Update Treaty Docs

At the end of substantive work, prepend a decision-focused entry to `work_log.md` and keep `next_steps.md` actionable unless the user asks not to document the work. Follow [Work Log Discipline](treaty_conventions.md#work-log-discipline); remove completed items rather than keeping a permanent history in `next_steps.md`.

## Branch Handoff Discipline

`dev` is the active work/staging branch; `main` is the integration/release branch. Do not open a pull request unless the user explicitly asks. Before switching or merging, confirm the current branch is committed, pushed or intentionally parked, and compare `main...HEAD` as described in [Branch Handoff](treaty_conventions.md#branch-handoff).

## Release / Tag Checklist

Treat commit + push + tag, or any request to publish a version, as a release. Before tagging, update `change_log.txt` and user-facing documentation as applicable, record verification and branch/tag state in `work_log.md`, merge/synchronize the requested branches, then verify remote branch and tag refs. See [Release Gate](treaty_conventions.md#release-gate).

## Updating The Treaty

Only update the installed treaty when the user asks. Use the direct CLI path above with `treaty diff`, `treaty update . --dry-run`, and `treaty update .`; start from a clean tracked worktree and resolve any merge conflicts before treating the update as complete. Do not hand-edit upstream-managed `treaty_conventions.md`.

## Documentation

- `README.md` - user-facing installation, usage, App Designer workflow, and data boundary.
- `project_overview.md` - active runtime path, source layout, active/secondary files, and authored/derived map.
- `next_steps.md` - unfinished work; read `## Currently Hot` first.
- `work_log.md` / `work_log_archive/` - recent decisions, verification evidence, and rotated history.
- `treaty_conventions.md` - upstream-maintained collaboration procedures.
- `change_log.txt` - existing release notes; reconcile it before future version tags.

## Commit Message Guidelines

Use a short title. If a commit contains several requested changes, add a short body with flat bullets describing high-level behavior. Do not mention tests, docs, or implementation details unless that internal work is the purpose of the commit.

## Git Ownership Note

This checkout can report dubious ownership or `.git/index.lock` permission errors. Prefer repo-scoped commands such as:

```powershell
git -c safe.directory=C:/Users/yzhao/matlab_projects/vessel_diameter_pulsatility_analysis_app status
```

Escalate only the narrow Git metadata operation that fails; do not change OS ownership or disturb unrelated files.

## Pre-commit Note

The active hook is `.githooks/pre-commit`, enabled by `setup_version_control.m`. It runs only when `app.mlapp` or `app_exported.m` is staged, rejects staged/unstaged split versions, regenerates and stages the export when the app is staged, and verifies exact synchronization. Do not bypass it merely because MATLAB startup is slow; diagnose failures by separating app/export errors from MATLAB/environment shutdown errors.

## Project-Specific Reminders

- The app currently accepts `.lif`, `.tif`, and `.mat`; a MAT input must contain `img`.
- The active LIF callback uses parser functions under `util/`. The active TIFF path uses `imread_big.m` with an `imread` loop fallback.
- The private `readTif` method and local `bfmatlab/` dependency are alternate paths, not the main TIFF callback.
- `func/find_img_edges.m` is the monolithic algorithm reference. Keep `findEdges`, `makeMask`, `makeCaps`, and `makeSeg` aligned when that algorithm changes.
- Put reusable non-UI logic in ordinary `.m` helpers under `func/` when practical; do not turn focused tasks into broad app refactors.
- Export synchronization does not clear the app's existing Code Analyzer warnings or prove runtime behavior. Inspect concrete code and use authorized local data for manual smoke tests.
