function [e,seg,bw_caps,mask] = find_img_edges(app, img, bw_caps, mask, varargin)
% Usage: [e,seg,bw_caps,mask] = find_img_edges(img,bw_caps,mask,[edgemethod],[fillmethod])
%FIND_IMG_EDGES Finds the edges of the image, and segements it by filling
%in the space between the edges and user-defined end caps

% INPUTS
% img: time-series intensity image, MXNXS where s is the # of images; you
%   might have to smooth and/or crop the time-series first, but there's
%   already some smoothing incorporated. 
% bw_caps: MXN 2D binary array with  ones where the "caps" for the vessel ought to be. 
%   This allows you to fill in the regions between the edges to segment the vessel. 
%   If you haven't created it yet, leave it empty and it will be created in
%   the function. 
% mask: This allows you to make a mask to remove extraneous edges. You can
%   either supply a 2D array that will serve as the mask, or you can supply a 0
%   to indicate that you don't want to use a mask, or you can supply a 1 to
%   create the mask in the function. 
% edgemethod: this allows you to supply the method to calculate the edges. Here are the options:
%   1. 'Canny': this is the default and the one I usually use unless edges are really difficult to detect.
%   2. 'log': more sensitive to picking up edges than 'Canny', but they tend to be more curvy, rather than straight. 
%   3. If you supply a vector, it will determine the gradient magnitude by dotting the gradient vector with the supplied vector at every point, essentially only looking for edges that are aligned with the vector. 
%       To use this option, supply a 1X2 vector indicating the direction, 
%       e.g. [1 1] for edges oriented at a 45 degree angle. 
%   4. Any other method allowed by edge. See the documentation for the matlab function edge
%   5. 'Both' combines 'Canny' and 'log' and can be a good option when
%   edges are difficult to detect. 
% fillmethod: lets you pick whether to fill in all holes in the edge image ('holes', default) or
% to fill in the region that that contains the centerpoint between the
% caps ('cp'). 'cp' requires cp to be inside the vessel, but it can be helpful when regions
% outside of the vessel are getting filled, and makes a mask unncessary in
% some cases. 

% OUTPUTS
% e: binary array the same size as img with the edges
% seg: binary array the same size as img the segmentation
% bw_caps: MXN binary array with the caps that were used
% mask: MXN binary array with the mask that was used

% ideas for improvement: try edge3
% add more catches in case users supply invalid parameters for fillmethod
% or edgemethod. 
% add a watershed option for segmentation

%% version history
% Written by Kimberly Boster, October 2022
% 2022_10_22: changed the outputs to no longer return the centerline
% 2022_10_27: changed edge method from 'Canny' to 'log'

if nargin == 5
    if ~isempty(varargin{1})
        edgemethod=varargin{1};
    else
        edgemethod='Canny';
    end
else
    edgemethod='Canny';
end
if nargin == 6
    fillmethod=varargin{2};
else
    fillmethod='holes';
end


%% find edges
for i=1:size(img,3)
    if ~isa(edgemethod,'double')
        if strcmp('both',edgemethod)
            e1=edge(imgaussfilt(double(img(:,:,i)),3),'Canny',.005);
            e2=edge(imgaussfilt(double(img(:,:,i)),3),'log',.005);
            e(:,:,i)=e1|e2;
        else
            e(:,:,i)=edge(imgaussfilt(double(img(:,:,i)),3),edgemethod,.005);
        end
    else    
        e(:,:,i)=edge_kasb(imgaussfilt(double(img(:,:,i)),3),.005,edgemethod);
    end
end

%% use the mask to clean up the edges
if numel(mask)>1
    e=logical(repmat(mask,[1 1 size(mask,3)]).*e);
elseif mask==1
    % make a mask from the averaged edges and multiply by the edges to get rid
    % of the extraneous edges. It maes the edges look much cleaner, but it's
    % sometime unnecessary and can cause problems if you're trying to
    % average over too many images where there is too much movement.
    app.ThresholdPanel.Visible = 'on';
    disp('Make a mask that includes the edges in which you are interested.')
    disp('Mask Step 1: Make an initial mask by segmenting the averaged edges. Use the helper function to select parameters to use for the segmentation. Typically you only need to adjust the threshold and size filt and put zeros for everything else. ')
    % make an initial mask using SegmentStack
    [mask,T,sizefilt,sizesmooth,fillcleanopt] = SegmentStack(app, mean(e,3));
    app.waitingForInput = true;
    app.closePopup()

    % manually adjust the mask
    disp('Mask Step 2: manually adjust the mask')
    figure, h = imagesc(mask);
    %close(figure)
    manadjust=questdlg('Do you want to manually adjust the mask? ');
    while strcmp(manadjust,'Yes')
        title({'Click to create a polygonal region that includes the', 'portion you want to keep. Dbl click when satisfied.'})
        roi = drawpolygon();
        wait(roi)
        bw = createMask(roi);
        mask=mask.*bw;
        set(h,'CData',mask)
        delete(roi)          
        manadjust = questdlg('Do you want to adjust more? ');
    end
    app.closePopup()
    
    % dilate the mask
    app.DilationPanel.Visible = 'on'; % gather the user input from panel_2
    app.MaskingPanel.Visible = 'off';
    
    disp('Mask Step 3: dilate the mask to include the edges in all frames')
    numskip=max(round(size(img,3)/100),1);
    showind=1:numskip:size(img,3);
    sz_dil=1;
    disp('The current mask is in red. The edges are shown in green. Make sure the mask includes all of the edges of interest. I often start by dilating with a structuring element of size 5 pixels. ')
    while sz_dil>0
        imagei({img(:,:,showind) img(:,:,showind) img(:,:,showind)},{repmat(mask,[1 1 length(showind)]) e(:,:,showind)})
        %sz_dil=input('What size structuring element do you want to use to dilate the mask?  ');
        waitfor(app, 'waitingForInput', false);
        sz_dil = app.DilationPanel_SizeEditField.Value;
        app.waitingForInput = true;
        mask=imdilate(mask,strel('disk',sz_dil)); 
    end
    
    % apply the mask
    e=logical(repmat(mask,[1 1 size(mask,3)]).*e);
    app.closePopup()
end

seg=e;
% seg=imclose(seg,strel('disk',4)); % this doesn't work as well as the
% correction that starts with the code: "if sum(seg(:,:,i),'all')<2*sum(e(:,:,i),'all')"

%% cap off the ends
if isempty(bw_caps)
    % only show a maximum of 100 images
    numskip=max(round(size(img,3)/100),1);
    showind=1:numskip:size(img,3);
    if isempty(mask) || size(mask,1)==1
        imagei({img(:,:,showind) img(:,:,showind) img(:,:,showind)},{seg(:,:,showind)}), axis equal
    else
        imagei({img(:,:,showind) img(:,:,showind) img(:,:,showind)},{repmat(mask,[1 1 length(showind)]) seg(:,:,showind)}), axis equal
    end
    app.CappingPanel.Visible = 'on'; 
    app.DilationPanel.Visible = 'off';
    disp('Click and drag to draw a line to cap off the ends')
    roi = drawline();
    morelines='Yes';
    bw_caps=false(size(img,[1 2]));
    while strcmp(morelines,'Yes')
        bw_line=false(size(img,[1 2]));
        disp('Move the line and dbl click when satisfied. (Depending on the version of Matlab, you might have to move the end points)')
        wait(roi)
        linelength=((roi.Position(1,1)-roi.Position(2,1)).^2 + (roi.Position(1,2)-roi.Position(2,2)).^2).^0.5;
        xind=round(linspace(roi.Position(1,1),roi.Position(2,1),linelength));
        yind=round(linspace(roi.Position(1,2),roi.Position(2,2),linelength));
        hold on, plot(xind,yind,'g')
        for i=1:length(xind)
            bw_line(yind(i),xind(i))=1; % there's got to be a better way to do this
        end
        bw_line=imdilate(bw_line,strel('disk',1));
        bw_caps=bw_caps | bw_line;    
        morelines=questdlg('Do you want to add more caps?','capping ends','Yes');
    end
    
app.closePopup()
end

app.RunComputationPanel.Visible = 'on'; % gather the user input from panel_2
app.CappingPanel.Visible = 'off';

seg=seg | repmat(bw_caps,[1 1 size(seg,3)]);

if ~strcmp(fillmethod,'holes')
    stats=regionprops(bw_caps,'Centroid');
    cp(1)=mean([stats(1).Centroid(1,1),stats(2).Centroid(1,1)]);
    cp(2)=mean([stats(1).Centroid(1,2),stats(2).Centroid(1,2)]);
end


% fill in center
for i=1:size(e,3)
    if mod(i,100)==0
        message = ['on slice ' num2str(i) ' of ' num2str(size(e,3))];
        disp(['on slice ' num2str(i) ' of ' num2str(size(e,3)) ])
        app.SliceProgressPanel_TextArea.Value = [app.SliceProgressPanel_TextArea.Value(:)', {message}];
    end
    if strcmp(fillmethod,'holes')
        seg(:,:,i)=logical(imfill(seg(:,:,i),'holes'));    
        seg(:,:,i)=logical(seg(:,:,i) .* ~bw_caps); % remove the caps from the segmentation  
        it=1;
        while sum(seg(:,:,i),'all')<2*sum(e(:,:,i),'all')        
            seg(:,:,i)=imdilate(seg(:,:,i),strel('disk',it)); % dilate to fill in some holes
            seg(:,:,i)=logical(seg(:,:,i) | bw_caps); % add the caps back in
            seg(:,:,i)=logical(imfill(seg(:,:,i),'holes')); % fill in
            seg(:,:,i)=imerode(seg(:,:,i),strel('disk',it)); % erode back to original size
            seg(:,:,i)=logical(seg(:,:,i).*~bw_caps); % remove the caps 
            it=it+1;
            if it>10 
                disp(['image # ' num2str(i) ': couldnt fill the edges enough'])
                break
            end
        end
        
    else
        seg(:,:,i)=logical(imfill(seg(:,:,i),round([cp(2) cp(1)]))); % could let the cp change if the center drifts, but this causes a problem if you get an erroneous area.
        seg(:,:,i)=logical(seg(:,:,i) .* ~bw_caps); % remove the caps from the segmentation  
        it=1;
        while sum(seg(:,:,i),'all')>sum(bwconvhull(bw_caps),'all')        
            seg(:,:,i)=imdilate(e(:,:,i),strel('disk',it)); % dilate to fill in some holes
            seg(:,:,i)=logical(seg(:,:,i) | bw_caps); % add the caps back in
            seg(:,:,i)=logical(imfill(seg(:,:,i),round([cp(2) cp(1)]))); % fill in
            seg(:,:,i)=imerode(seg(:,:,i),strel('disk',it)); % erode back to original size
            seg(:,:,i)=logical(seg(:,:,i).*~bw_caps); % remove the caps 
            it=it+1;
            if it>10 
                disp(['image # ' num2str(i) ': couldnt fill the edges enough'])
                break
            end
        end
    end
    seg(:,:,i)=bwareafilt(seg(:,:,i),1); % keep only the largest area
end

%imagei({img img img},{seg e})

end

%% old code pertaining to the centerlines
% Notes: finding the average center point may be better accomplished by feeding seg into FindCnrPts

% bw_avgcp: 2D binary array with the centerpoints from the time-averaged image
% cp: 300 X 2 X S with the x/y locations of the centerpoints in each image.
% can be provided directly as an input to imagei. 

% % find the centerlines
% bw_cp=zeros(size(e));
% for i=1:size(e,3)
%     bw_cp(:,:,i)=bwskel(seg(:,:,i),'MinBranchLength',25); % may need to adjust minbranchlength
% end
% bw_cp=logical(bw_cp);
% % find average centerline of the average segmentation
% bw_avgcp=bwskel(logical(imfill(logical(mean(seg,3)),'holes')),'MinBranchLength',25);
% imagei({img img img},{seg repmat(bw_avgcp,[1 1 size(seg,3)]) bw_cp})

% as an alternative that takes up less sapce, you could return a list of
% centerpoints, rather than the binary image
% cp=zeros(300,2,size(img,3));
% for i=1:size(e,3)
%     [ycoord,xcoord]=find(bw_cp(:,:,i));
%     cp(1:length(ycoord),2,i)=ycoord;
%     cp(1:length(ycoord),1,i)=xcoord;
% end

% imagei({img img img},{repmat(bw_avgcp,[1 1 size(seg,3)]) seg seg},cp-1)
% bw_cp=cp;

% an alternative way of finding the center points. Could just make the
% edges be the centerpoints. 
% for i=1:size(l,3)
%     [ycoord,xcoord]=find(e(:,:,i));
%     p=polyfit(xcoord,ycoord,2);
%     cp(:,2,i)=polyval(p,xlimits(1):xlimits(2));
%     cp(:,1,i)=xlimits(1):xlimits(2);
% end
