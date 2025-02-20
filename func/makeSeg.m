function images = makeSeg(app, images)

%app.SliceProgressPanel.Visible = 'on';
fillmethod = 'holes';
app.bw_caps = extend_caps_local(app.bw_caps); % extend caps to edges of image
app.seg = app.seg | repmat(app.bw_caps,[1 1 size(app.seg, 3)]);

if ~strcmp(fillmethod,'holes') && ~strcmp(fillmethod,'original')
    stats=regionprops(app.bw_caps,'Centroid');
    cp(1)=mean([stats(1).Centroid(1,1),stats(2).Centroid(1,1)]);
    cp(2)=mean([stats(1).Centroid(1,2),stats(2).Centroid(1,2)]);
end

caps_convhull = bwconvhull(app.bw_caps); % convex hull of caps

% fill in center
h = waitbar(0, 'Processing...');
nSlices = size(app.e,3);
for i=1:nSlices
    waitbar(i/nSlices, h, ['processing slice ' num2str(i) ' of ' num2str(nSlices)])
    if mod(i,100)==0
        message = ['on slice ' num2str(i) ' of ' num2str(nSlices)];
        disp(['on slice ' num2str(i) ' of ' num2str(nSlices)])
        app.SliceProgressPanel_TextArea.Value = [app.SliceProgressPanel_TextArea.Value(:)', {message}];
    end

    app.e(:,:,i) = caps_convhull .* app.e(:, :, i); % remove all pixels not inside convex hull of caps
    if strcmp(fillmethod,'holes')
        app.seg(:,:,i)=logical(imfill(app.seg(:,:,i),'holes'));    
        app.seg(:,:,i)=logical(app.seg(:,:,i) .* ~app.bw_caps); % remove the caps from the segmentation  
        it=1;
        L=bwlabel((app.seg(:,:,i).*~app.e(:,:,i)) | app.bw_caps);
        badseg=length(nonzeros(unique(L.*app.bw_caps)))>1; % make sure the segmentation is touching both caps
        
        if badseg
            % check for a mask error
            mask2=app.mask;
%             seg_original=seg(:,:,i);
            while badseg
                mask2=imdilate(mask2,strel('disk',1)); 
                app.e(:,:,i)=(app.e_original(:,:,i).*mask2);
                app.seg(:,:,i)=logical(imfill(app.e(:,:,i)|app.bw_caps,'holes'));
                app.seg(:,:,i)=logical(app.seg(:,:,i) .* ~app.bw_caps); % remove the caps from the segmentation
                it=it+1;
                L=bwlabel((app.seg(:,:,i).*~app.e(:,:,i)) | app.bw_caps);
                badseg=length(nonzeros(unique(L.*app.bw_caps)))>1;
                if it>5 && badseg
%                     disp(['image # ' num2str(i) ': not a mask error alone'])
                    it=1;
%                     seg(:,:,i)=seg_original;
                    break
                end
            end
        
            while badseg      
                app.seg(:,:,i)=imdilate(app.seg(:,:,i),strel('disk',it)); % dilate to fill in some holes
                app.seg(:,:,i)=logical(app.seg(:,:,i) | app.bw_caps); % add the caps back in
                app.seg(:,:,i)=logical(imfill(app.seg(:,:,i),'holes')); % fill in
                app.seg(:,:,i)=imerode(app.seg(:,:,i),strel('disk',it)); % erode back to original size
                app.seg(:,:,i)=imfill(app.seg(:,:,i) | app.bw_caps,'holes'); % fill in gaps between the segmentation and the caps, if created by erosion
                app.seg(:,:,i)=logical(app.seg(:,:,i).*~app.bw_caps); % remove the caps 
                it=it+1;
                L=bwlabel((app.seg(:,:,i).*~app.e(:,:,i)) | app.bw_caps);
                badseg=length(nonzeros(unique(L.*app.bw_caps)))>1;
                if it>10 
                    disp(['image # ' num2str(i) ': couldnt fill the edges enough'])
                    break
                end
            end
        end % if badseg
        
    elseif strcmp(fillmethod,'cp')
        app.seg(:,:,i)=logical(imfill(app.seg(:,:,i),round([cp(2) cp(1)]))); % could let the cp change if the center drifts, but this causes a problem if you get an erroneous area.
        app.seg(:,:,i)=logical(app.seg(:,:,i) .* ~app.bw_caps); % remove the caps from the segmentation  
        it=1;
        while sum(app.seg(:,:,i),'all')>sum(bwconvhull(app.bw_caps),'all')        
            app.seg(:,:,i)=imdilate(app.e(:,:,i),strel('disk',it)); % dilate to fill in some holes
            app.seg(:,:,i)=logical(app.seg(:,:,i) | app.bw_caps); % add the caps back in
            app.seg(:,:,i)=logical(imfill(app.seg(:,:,i),round([cp(2) cp(1)]))); % fill in
            app.seg(:,:,i)=imerode(app.seg(:,:,i),strel('disk',it)); % erode back to original size
            app.seg(:,:,i)=logical(app.seg(:,:,i).*~app.bw_caps); % remove the caps 
            it=it+1;
            if it>10 
                disp(['image # ' num2str(i) ': couldnt fill the edges enough'])
                break
            end
        end
    elseif strcmp(fillmethod,'original')
        app.seg(:,:,i)=logical(imfill(app.seg(:,:,i),'holes'));    
        app.seg(:,:,i)=logical(app.seg(:,:,i) .* ~app.bw_caps); % remove the caps from the segmentation  
        it=1;
        while sum(app.seg(:,:,i),'all')<2*sum(app.e(:,:,i),'all')  % dilate seg until it's larger than 2 times e      
            app.seg(:,:,i)=imdilate(app.seg(:,:,i),strel('disk',it)); % dilate to fill in some holes
            app.seg(:,:,i)=logical(app.seg(:,:,i) | app.bw_caps); % add the caps back in
            app.seg(:,:,i)=logical(imfill(app.seg(:,:,i),'holes')); % fill in
            app.seg(:,:,i)=imerode(app.seg(:,:,i),strel('disk',it)); % erode back to original size
            app.seg(:,:,i)=logical(app.seg(:,:,i).*~app.bw_caps); % remove the caps 
            it=it+1;
            if it>10 
                disp(['image # ' num2str(i) ': couldnt fill the edges enough'])
                break
            end
        end
    else
        disp('not a valid fillmethod')
    end
    
    app.seg(:,:,i)=bwareafilt(app.seg(:,:,i),1); % keep only the largest area
end
close(h)
app.SliceProgressPanel_TextArea.Value = '';
imagei({images images images},{app.seg app.e})

%app.RunComputationPanel.Visible = 'on'; % gather the user input from panel_2

end

%% caps extension
function new_caps = extend_caps_local(bw_caps)
% extend_caps - extends bw_caps to the edges of the image
%
% inputs:
%    - bw_caps - binary image with linear regions as vessel end caps
%              - bw_caps is expected to come from find_img_edges()
% outputs:
%    - new_caps - binary image with caps extended to the edges of the image

    SE = strel("disk", 1); % structuring element for erosion and dilation
    new_caps = imerode(bw_caps, SE); % intialize new_caps as bw_caps eroded down to 1px
    
    stats = regionprops(new_caps, "Centroid", "Orientation"); % get centroids and angles of two caps
    centroids = cat(1, stats.Centroid); % separate centroids into separate matrix

    [y_max, x_max] = size(bw_caps); % get max x and y of image
    
    new_caps = im2double(new_caps); % convert new_caps to double for use with insertShape

    for i = 1 : size(stats) % run for every region detected
        % yf and xf are the projected lines of the caps based on the stats from regionprops and are algebraically equivalent
        yf = @(x) (1/tand(stats(i).Orientation - 90))*(x - centroids(i, 1)) + centroids(i, 2);
        xf = @(y) tand(stats(i).Orientation - 90)*(y - centroids(i, 2)) + centroids(i, 1);
        
        endpoints = calculate_endpoints(yf, xf, x_max, y_max); % get intersection points between image borders and current projected line
    
        new_caps = insertShape(new_caps, 'line', endpoints); % add current extended cap to new_caps
    end

    new_caps = mean(new_caps, 3); % combine new_caps back into a 2D image
    new_caps = imbinarize(new_caps); % convert new_caps back into a binary image
    new_caps = imdilate(new_caps, SE); % dilate extended caps back to being 3px wide

end

% calculate where the given line will intersect the edges of the image
function endpoints = calculate_endpoints(yf, xf, x_max, y_max)
    endpoints = [];

    % math is done based on origin at bottom left

    % left vertical, x = 0 {0 <= y <= y_max}
    v1_limits = [0, y_max];
    if (yf(0) >= v1_limits(1) && yf(0) <= v1_limits(2))
        endpoints(size(endpoints, 1)+1, :) = [0, yf(0)];
        %disp("v1");
    end

    % right vertical, x = x_max {0 <= y <= y_max}
    v2_limits = [0, y_max];
    if (yf(x_max) >= v2_limits(1) && yf(x_max) <= v2_limits(2))
        endpoints(size(endpoints, 1)+1, :) = [x_max, yf(x_max)];
        %disp("v2");
    end
    

    % bottom horizontal, y = 0 {0 <= x <= x_max}
    h1_limits = [0, x_max];
    if (xf(0) >= h1_limits(1) && xf(0) <= h1_limits(2))
        endpoints(size(endpoints, 1)+1, :) = [xf(0), 0];
        %disp("h1");
    end

    % top horizontal, y = y_max {0 <= x <= x_max}
    h2_limits = [0, x_max];
    if (xf(y_max) >= h2_limits(1) && xf(y_max) <= h2_limits(2))
        endpoints(size(endpoints, 1)+1, :) = [xf(y_max), y_max];
        %disp("h2");
    end
end