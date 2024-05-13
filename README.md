## Usage
Download the vessel_diameter_pulsatility_analysis_app folder. Click app.mlapp to run the app. Once the app opens, you will go through the following steps to get the analysis results.
1) Click Select Directory to choose the file you want to process (Only LIF files are supported for now) and hit continue.
2) In the next page, enter the series number in the LIF. For example, enter 1 to select the first series in the LIF file. Hit Done.
3) In the pop-up window (it may take several seconds for it to show up especially if the LIF file is very large, in the future, I may be able to add a progress indicator to tell when this process will finish), drag the cursor to select a region of interest to crop the images. Double click the box area when satisfied.
4) Enter a threshold value to preprocess the image so that the lines for the edges of the vessel app stay clear and smooth shile the lines for other parts fade. Use the pop-up window and the threshold slider in it to help you choose a good threshold value. Usually a value between 0.3 and 0.6 works well. Hit continue when done.
5) You will see a pop-up dialog window and a pop-up figure. First, in the dialog window select Yes, as it is mostly likely that you will still need to draw a polygon to encapsulate only the vessel of interest and ignore lines from other vessel or noise, despite the previous thrsholding step. Next, in the pop-up figure, draw a polygon that encapsulates the edges of the vessel of interest while avoiding the noise. When satisfied, double click the polygon you drew. When prompt whether you would like to adjust more, click No to continue.
6) In the next page, you will enter a dilation factor. With a positive value, it will create a thicker mask around the edges. WHen you hit continue, you will see that the mask gets updated in the pop-up figure. Hit Play in the pop-up figure and make sure the dilated mask covers the edge in all the sampled frames. If not, keep dilating the mask by entering a positive value and hitting Continue in the current page. When satisfied, enter 0 and hit continue, you will be taken to the next step. Note, the dilation factor here is cumulative, meaning if you enter 5 the first time and enter 5 again and hit Continue, the mask is dilated by 25.
7) In the pop-up figure, draw the caps according to the instuctions in the current page. When Done, double click the line you drew. In the pop-up dialog window, click Yes if you need more caps or No if you are done and ready to move on.
8) Next, you will see a pop-up figure, in which you can hit Play to see if your mask and caps work well for all the sampled frames. If it looks good, hit Run.
9) Wait for the analysis to be run on all frames. When done, you will see two figures that show the Area vs frame result and the Diameter vs frame results. Hit Save results to save the results to your desired location. 

The results include the following
"t", ...
"fs", ...
'rect', ...
'area', ...
'bw_caps', ...
'mask', ...
'e', ...
'seg', ...
'diam', ...
'dist_caps' ...

## Demo
[![Watch the video](https://drive.google.com/file/d/1wuRDR1wWErjcfb5ERfFdfqkCTKhnT4vp/view?usp=sharing)](https://drive.google.com/file/d/1MPTCPYLpDC4qM3oBmI_06qhuHX9Z17kj/view?usp=sharing)