# Work Log

Prepend new decision-focused session notes. The live log holds at most five unique dates; rotate the oldest five dates together according to [`treaty_conventions.md`](treaty_conventions.md#work-log-rotation-and-dating).

## 2026-08-13

### Upgrade and relocate the collaboration treaty (Codex, GPT-5)

- Upgraded the pinned Agent Collab Treaty from `v0.5.0` to `v0.9.0` on `chore/treaty`, preserving the repository-specific guidance and existing decision history.
- Adopted `treaty_docs/` for the working collaboration documents while keeping `AGENTS.md` and `project_overview.md` at the repository root for discovery.
- Used the treaty's Git-aware relocation command so file history follows the moves and all treaty-owned relative links remain coherent.
- Verification:
  - `treaty validate .` passed for the nested layout.
  - `treaty diff .`, conflict-marker scanning, `git diff --check HEAD`, and a local Markdown-link target scan passed.
  - `matlab -batch "export_app_source('verify')"` confirmed `app_exported.m` matches `app.mlapp`; the sandboxed launch hit the known file-system startup error, and the same verify-only command passed outside the sandbox.

## 2026-07-31

### Adopt Agent Collab Treaty v0.5.0 (Codex, GPT-5)

- Pinned the repository to the stable official `v0.5.0` treaty source with `main` as integration/release and no project-managed environment.
- Kept the install vendor-neutral with no optional agent pointer files; `../AGENTS.md` is the canonical project instruction entry point.
- Chose the App Designer export verification as the primary project check and retained release, repository-hook, Windows ownership, and tri-color adoption-badge guidance.
- Replaced scaffold placeholders with the actual MATLAB runtime, active/secondary source map, authored/derived boundaries, data restrictions, branch policy, and actionable loader follow-up.
- Left upstream-managed `treaty_conventions.md` and archive mechanics unchanged so future treaty updates remain low-conflict.
- Verification:
  - `C:\Users\yzhao\python_projects\agent_collab_treaty\.venv\Scripts\treaty.exe validate .`
  - `matlab -batch "export_app_source('verify')"`
  - placeholder and Markdown-link scans across the installed treaty documents
  - `git diff --check`

### Add App Designer source review and commit safeguards (Codex, GPT-5)

- Kept `app.mlapp` as the sole editable/runnable source and adopted `app_exported.m` only as a generated GitHub-review artifact.
- Chose a repo-local hook that runs only for the app pair, rejects staged/unstaged splits, and regenerates/stages/verifies the export without touching unrelated local files.
- Confirmed the active LIF/TIFF/MAT loader paths and documented that export synchronization does not prove runtime behavior.
- Published commit `25e8c05` to `origin/dev`; local, tracking, and remote refs matched afterward.
- Recorded one MATLAB R2025a shutdown access violation after successful hook verification: Git aborted safely, the processes exited, and an unchanged retry completed normally.
- Verification:
  - `matlab -batch "export_app_source"` and `matlab -batch "export_app_source('verify')"`
  - Code Analyzer: zero findings in `export_app_source.m` and `setup_version_control.m`; 38 pre-existing findings in the generated app
  - isolated temporary-repository hook test covered refresh/staging, unrelated-file fast path, and both split-version rejections while the real index stayed unchanged
  - `git check-attr --all -- app.mlapp app_exported.m export_app_source.m setup_version_control.m .githooks/pre-commit`
  - `git diff --check` and direct remote-ref verification

## Entry Format

```markdown
## YYYY-MM-DD

### Short session title (model/version, effort if surfaced, token budget if surfaced)

- durable decision, reversal, reusable evidence, or shared-state change
- Verification:
  - exact command that ran
  - what passed or was confirmed
```
