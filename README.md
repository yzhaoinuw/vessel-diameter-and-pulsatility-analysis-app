# Vessel Diameter Pulsatility Analysis App

[![Agent Collab Treaty](https://raw.githubusercontent.com/yzhaoinuw/agent_collab_treaty/main/assets/treaty-adopted.svg)](https://github.com/yzhaoinuw/agent_collab_treaty)

## Installation

After downloading the repo, you also need to download the [bio-formats toolbox](https://www.openmicroscopy.org/bio-formats/downloads/) to run the app. After downloading it, you will get a folder called **bfmatlab**. Place it inside the app folder and you will be good to go!

The current development runtime is MATLAB R2025a. See `toolbox_requirements.txt` for the MATLAB toolbox requirements. The downloaded `bfmatlab/` folder is a local dependency and is intentionally not tracked by Git.

## Usage

Download the vessel\_diameter\_pulsatility\_analysis\_app folder. Click app.mlapp to run the app. Once the app opens, you will go through the following steps to get the analysis results.

1. Click Select Directory to choose the file you want to process (Only LIF and TIF files are supported for now) and hit continue.
2. In the next page, enter the recording frequency and microns per pixel if you know the values. Otherwise you can leave them as default. For LIF files, enter the series number in the LIF. For example, enter 1 to select the first series in the LIF file. Hit Done.
3. In the pop-up window (it may take several seconds for it to show up especially if the LIF file is very large, in the future, I may be able to add a progress indicator to tell when this process will finish), drag the cursor to select a region of interest to crop the images. Double click the box area when satisfied.
4. Enter a threshold value to preprocess the image so that the lines for the edges of the vessel app stay clear and smooth while the lines for other parts fade. Use the pop-up window and the threshold slider in it to help you choose a good threshold value. Usually a value between 0.3 and 0.6 works well. Hit continue when done.
5. You will see a pop-up dialog window and a pop-up figure. First, in the dialog window select Yes, as it is mostly likely that you will still need to draw a polygon to encapsulate only the vessel of interest and ignore lines from other vessel or noise, despite the previous thresholding step. Next, in the pop-up figure, draw a polygon that encapsulates the edges of the vessel of interest while avoiding the noise. When satisfied, double click the polygon you drew. When prompt whether you would like to adjust more, click No to continue.
6. In the next page, you will enter a dilation factor. With a positive value, it will create a thicker mask around the edges. When you hit continue, you will see that the mask gets updated in the pop-up figure. Hit Play in the pop-up figure and make sure the dilated mask covers the edge in all the sampled frames. If not, keep dilating the mask by entering a positive value and hitting Continue in the current page. When satisfied, enter 0 and hit continue, you will be taken to the next step. Note, the dilation factor here is cumulative, meaning if you enter 5 the first time and enter 5 again and hit Continue, the mask is dilated by 25.
7. In the pop-up figure, draw the caps according to the instructions in the current page. When Done, double click the line you drew. In the pop-up dialog window, click Yes if you need more caps or No if you are done and ready to move on.
8. Next, you will see a pop-up figure, in which you can hit Play to see if your mask and caps work well for all the sampled frames. If it looks good, hit Run.
9. Wait for the analysis to be run on all frames. When done, you will see two figures that show the Area vs frame result and the Diameter vs frame results. Hit Save results to save the results to your desired location.

The results include the following
"t", ...
"fs", ...
'rect', ...
'area', ...
'bw\_caps', ...
'mask', ...
'e', ...
'seg', ...
'diam', ...
'dist\_caps' ...

## Demo

https://github.com/yzhaoinuw/vessel-diameter-and-pulsatility-analysis-app/assets/22312388/7a40e9c5-29ae-49a9-bf9c-43b65c70c032

## Notes For Developers

The core algorithm implemented in find\_img\_edges.m is broken into four functions in func/ to suit the app's purpose of being interactive with the user. The four functions are 1) findEdges, 2) makeMask, 3) makeCaps, and 4) makeSeg. Comments are added to outline the correspondence of the four functions to find\_img\_edges. **Every time find\_img\_edges gets updated, the developer should update the four functions as needed.**

### App Designer and Git

`app.mlapp` is the authoritative editable and runnable application. `app_exported.m` is a generated, tracked text companion for readable GitHub diffs and code review; do not edit it directly or treat it as a second source of truth.

After a fresh clone, enable the repository-local pre-commit hook and generate the initial review copy:

```powershell
matlab -batch "setup_version_control"
```

The normal App Designer workflow is:

1. Edit and run `app.mlapp` in App Designer.
2. Generate the review copy with `matlab -batch "export_app_source"`.
3. Verify exact synchronization with `matlab -batch "export_app_source('verify')"`.
4. Commit `app.mlapp` and `app_exported.m` together.

The pre-commit hook runs only when either app file is staged. It rejects staged/unstaged split versions, regenerates and stages `app_exported.m` when `app.mlapp` is staged, and verifies the pair before allowing the commit. Git treats `.mlapp` and other packaged MATLAB formats as binary; review application code in `app_exported.m` and use MATLAB's Comparison Tool when the packaged app or layout itself must be compared.

Run MATLAB Code Analyzer on the workflow scripts with:

```powershell
matlab -batch "checkcode('export_app_source.m'); checkcode('setup_version_control.m')"
```

### Runtime map and data boundary

- `app.mlapp`: UI layout, state, callbacks, and workflow orchestration.
- `app_exported.m`: generated GitHub review artifact for `app.mlapp`.
- `func/findEdges.m`, `func/makeMask.m`, `func/makeCaps.m`, and `func/makeSeg.m`: interactive stages adapted from `func/find_img_edges.m`.
- `func/SegmentStack.m`, `func/seg.m`, and related helpers: segmentation and visualization support.
- `util/ReadXMLPart.m`, `util/GetImageDescriptionList.m`, `util/ReadObjectMemoryBlocks.m`, `util/ReadAnImageData.m`, and `util/ReconstructImage.m`: the active Leica LIF loading path used by the app callback.
- `imread_big.m`: the active TIFF stack loader, with an `imread` loop fallback in the app callback.
- `func/ci_loadLif.m`: a separate tracked LIF loader that is not called by the current app callback.
- `bfmatlab/`: downloaded Bio-Formats dependency used by alternate reader helpers, kept local and untracked.

Keep callback code focused on UI state and orchestration. Put reusable processing logic in ordinary `.m` helpers under `func/` when practical, without duplicating the app's source of truth.

Raw recordings such as LIF/TIFF files and generated MAT files, results, figures, spreadsheets, and videos are local experiment artifacts, not repository source. The ignore rules protect those formats and common output folders. They do not remove any files that Git already tracks.

## Credits

The underlying algorithms for calculating the vessel diameter and pulsatility are developed by [Dr. Kimberly Boster](https://orcid.org/0000-0001-5178-128X) (@kimst12).

