function images = makeSeg(app, images)

%app.SliceProgressPanel.Visible = 'on';
fillmethod = 'holes';
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
            app.e_original(:,:,i) = caps_convhull .* app.e_original(:,:,i); % remove all pixels not inside convex hull of caps

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
