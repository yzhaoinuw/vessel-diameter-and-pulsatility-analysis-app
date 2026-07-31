# Project Overview

This document is the architecture and source-of-truth map for the vessel diameter and pulsatility analysis application. Keep it current when the active callback path, data contract, or authored/derived boundary changes.

## What This Repo Is

This repository contains a MATLAB App Designer application for interactive vessel-image analysis. A user selects a Leica LIF series, TIFF stack, or MAT file containing an image stack; crops a vessel region; tunes edge segmentation; creates masks and end caps; runs the full-stack calculation; and saves area, diameter, segmentation, timing, and supporting arrays to a MAT file.

The primary product is [`app.mlapp`](app.mlapp), developed with MATLAB R2025a on Windows. Processing helpers are ordinary MATLAB functions under `func/` and `util/` so the interactive workflow can reuse the original vessel-analysis algorithm without placing every operation in UI callbacks.

## Active Runtime Path

### 1. Entrypoint

[`app.mlapp`](app.mlapp)

- Defines the UI, app state, private workflow helpers, callbacks, and result saving.
- Adds `func/` and `util/` to the MATLAB path during `startupFcn`.
- Is the authoritative editable and runnable source.

[`app_exported.m`](app_exported.m) is a generated text representation of the same app for GitHub review; it is not a second runtime source.

### 2. Input selection and loading

The Home callback accepts `.lif`, `.tif`, and `.mat`:

- LIF: `ReadXMLPart`, `XMLtxt2cell`, `GetLifVersion`, `GetImageDescriptionList`, `ReadObjectMemoryBlocks`, `ReadAnImageData`, and `ReconstructImage` under `util/` parse the selected series and image stack.
- TIFF: [`imread_big.m`](imread_big.m) is attempted first; an `imread` frame loop is the fallback.
- MAT: the callback loads the `img` variable from the selected file.

The private `readTif` method uses Bio-Formats, but the current TIFF callback does not call it.

### 3. Interactive segmentation

The user crops the stack and works through four interactive stages adapted from [`func/find_img_edges.m`](func/find_img_edges.m):

1. [`func/findEdges.m`](func/findEdges.m) detects vessel edges.
2. [`func/makeMask.m`](func/makeMask.m) constructs and adjusts the vessel mask.
3. [`func/makeCaps.m`](func/makeCaps.m) defines end caps.
4. [`func/makeSeg.m`](func/makeSeg.m) creates the segmented stack.

[`func/SegmentStack.m`](func/SegmentStack.m), [`func/seg.m`](func/seg.m), [`func/sliderseg.m`](func/sliderseg.m), [`func/imagei.m`](func/imagei.m), and related helpers provide thresholding, segmentation, and visualization support.

### 4. Full-stack calculation and output

The Run callback applies the selected crop and segmentation choices to the full stack. Area is calculated from the segmented frames; [`func/find_dist_caps.m`](func/find_dist_caps.m) provides the cap distance used to calculate vessel diameter.

The Save Results callback writes a user-selected MAT file containing:

- `t`, `fs`, and `umperpix`
- `img` and `rect`
- `area` and `diam`
- `bw_caps`, `mask`, `e`, and `seg`
- `dist_caps`

## Repo Structure Map

```text
vessel_diameter_pulsatility_analysis_app/
|- app.mlapp                 # authoritative App Designer source
|- app_exported.m            # generated review companion
|- export_app_source.m       # generate/verify the companion
|- setup_version_control.m   # enable the repo-local hook
|- .githooks/pre-commit      # app/export synchronization gate
|- func/                     # segmentation and visualization helpers
|- util/                     # active LIF parsing helpers
|- imread_big.m              # active TIFF stack loader
|- bfmatlab/                 # local, untracked alternate reader dependency
|- AGENTS.md                 # project-specific agent guidance
|- treaty_conventions.md     # upstream treaty mechanics
|- project_overview.md       # this architecture map
|- next_steps.md             # active engineering threads
|- work_log.md               # recent decision/verification history
|- work_log_archive/         # rotated work-log history
|- README.md                 # user-facing setup and usage
|- change_log.txt            # existing release notes
```

## What Looks Active vs. Legacy

### Active / relevant now

- [`app.mlapp`](app.mlapp) and its generated [`app_exported.m`](app_exported.m) review companion.
- `findEdges`, `makeMask`, `makeCaps`, and `makeSeg`, plus the segmentation/visualization helpers they call.
- [`imread_big.m`](imread_big.m) for TIFF input.
- The LIF parser functions under `util/` used directly by the Home callback.
- `export_app_source.m`, `setup_version_control.m`, and `.githooks/pre-commit` for source control.

### Likely older or secondary

- [`func/find_img_edges.m`](func/find_img_edges.m) - monolithic algorithm reference whose stages are mirrored by the four interactive helpers.
- [`func/ci_loadLif.m`](func/ci_loadLif.m) - separate tracked LIF loader not called by the current app callback.
- The private `readTif` method in `app.mlapp` - Bio-Formats implementation not called by the current TIFF branch.
- Root-level scratch/test scripts and `func/imagei_dev.m` currently shown as untracked - user-owned local development artifacts, outside normal product work unless explicitly requested.
- `bfmatlab/` - downloaded local dependency, ignored by Git and not added by `startupFcn`.

## Authored vs. Derived

### Authored - hand-edit these

- [`app.mlapp`](app.mlapp) - authoritative App Designer UI and callbacks.
- MATLAB helpers under `func/`, `util/`, and [`imread_big.m`](imread_big.m).
- `README.md`, `AGENTS.md`, `project_overview.md`, `next_steps.md`, and `work_log.md`.
- `export_app_source.m`, `setup_version_control.m`, and `.githooks/pre-commit`.

### Derived - never hand-edit; regenerate instead

- [`app_exported.m`](app_exported.m) - regenerate with `matlab -batch "export_app_source"`; source of truth is `app.mlapp`.
- [`treaty_conventions.md`](treaty_conventions.md) and `work_log_archive/README.md` - installed/upstream-managed treaty content; update with the treaty CLI rather than customizing their mechanics locally.
- Raw recordings, result MAT files, figures, spreadsheets, and videos - experiment artifacts, not maintained source.

## Tests And Fixtures

There is no automated runtime test suite and no committed experimental fixture set.

Available verification:

- `matlab -batch "export_app_source('verify')"` for App Designer synchronization.
- MATLAB `checkcode` for changed ordinary `.m` files.
- The repository hook for app/export staging behavior.
- MATLAB Comparison Tool / `visdiff` for packaged `.mlapp` review.
- Focused manual app runs with local data only when the user authorizes access.

Do not commit a recording merely to create a test. Prefer small synthetic or redistributable fixtures if repeatable tests are introduced later.

## User Data Expectations

- LIF input: the user selects a series; the stack is parsed from Leica metadata and image blocks.
- TIFF input: a multi-frame image stack; the user supplies frequency and microns per pixel.
- MAT input: must contain an `img` array compatible with the app's 3-D image-stack operations.
- The workflow expects a vessel that can be cropped, edge-segmented, masked, and capped interactively.
- Saved output is a MAT file chosen by the user; it remains local and ignored by Git.

Experimental recordings and outputs may be large or sensitive. Do not inspect them without explicit authorization, and never include them in source-control changes by default.

## Practical Mental Model

For product work, read in this order:

1. [`AGENTS.md`](AGENTS.md)
2. [`README.md`](README.md)
3. [`app_exported.m`](app_exported.m) for readable callback/state inspection
4. the relevant helper under `func/` or `util/`
5. [`app.mlapp`](app.mlapp) through App Designer or MATLAB Comparison Tool when authoritative package/layout details matter

## Questions Worth Clarifying Later

- Is Bio-Formats still a required installation dependency when the active LIF and TIFF callbacks use `util/` and `imread_big.m` instead?
- Should `.mat` input become an explicitly supported user-facing format in the README, or remain an internal convenience?
- When `find_img_edges.m` changes, what repeatable check should prove that the four interactive helpers remain behaviorally aligned?
- What small, non-sensitive fixture could support automated loader/segmentation smoke tests?
- Should `change_log.txt`, currently much older than repository tags such as `v1.0`, be reconstructed before the next release?
