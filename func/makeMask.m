function [] = makeMask(app)
    % make a mask from the averaged edges and multiply by the edges to get rid
    % of the extraneous edges. It maes the edges look much cleaner, but it's
    % sometime unnecessary and can cause problems if you're trying to
    % average over too many images where there is too much movement.
    if numel(app.mask)>1
        app.e=logical(repmat(app.mask,[1 1 size(app.mask,3)]).*app.e);
    elseif app.mask==1
        app.ThresholdPanel.Visible = 'on';
        disp('Make a mask that includes the edges in which you are interested.')
        disp('Mask Step 1: Make an initial mask by segmenting the averaged edges. Use the helper function to select parameters to use for the segmentation. Typically you only need to adjust the threshold and size filt and put zeros for everything else. ')
        % make an initial mask using SegmentStack
        [app.mask,T,sizefilt,sizesmooth,fillcleanopt] = SegmentStack(app, mean(app.e,3));
        app.waitingForInput = true;
        app.closePopup()
    
        % manually adjust the mask
        disp('Mask Step 2: manually adjust the mask')
        figure, h = imagesc(app.mask);
        %close(figure)
        manadjust=questdlg('Do you want to manually adjust the mask? ');
        while strcmp(manadjust,'Yes')
            title({'Click to create a polygonal region that includes the', 'portion you want to keep. Dbl click when satisfied.'})
            roi = drawpolygon();
            wait(roi)
            bw = createMask(roi);
            app.mask = app.mask.*bw;
            set(h,'CData', app.mask)
            delete(roi)          
            manadjust = questdlg('Do you want to adjust more? ');
        end
        app.closePopup()
        app.MaskingPanel.Visible = 'off';
    end

app.seg = app.e;
end