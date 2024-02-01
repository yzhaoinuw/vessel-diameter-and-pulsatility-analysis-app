function images = makeSeg(app, images)

%app.SliceProgressPanel.Visible = 'on';
fillmethod = 'holes';
app.seg = app.seg | repmat(app.bw_caps,[1 1 size(app.seg, 3)]);

if ~strcmp(fillmethod,'holes')
    stats=regionprops(app.bw_caps,'Centroid');
    cp(1)=mean([stats(1).Centroid(1,1),stats(2).Centroid(1,1)]);
    cp(2)=mean([stats(1).Centroid(1,2),stats(2).Centroid(1,2)]);
end

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
    if strcmp(fillmethod,'holes')
        app.seg(:,:,i)=logical(imfill(app.seg(:,:,i),'holes'));    
        app.seg(:,:,i)=logical(app.seg(:,:,i) .* ~app.bw_caps); % remove the caps from the segmentation  
        it=1;
        while sum(app.seg(:,:,i),'all')<2*sum(app.e(:,:,i),'all')        
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
    end
    app.seg(:,:,i)=bwareafilt(app.seg(:,:,i),1); % keep only the largest area
end
close(h)
app.SliceProgressPanel_TextArea.Value = '';
imagei({images images images},{app.seg app.e})

%app.RunComputationPanel.Visible = 'on'; % gather the user input from panel_2

end