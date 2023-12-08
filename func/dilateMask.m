function [] = dilateMask(app)
% dilate the mask
    app.DilationPanel.Visible = 'on'; % gather the user input from panel_2
    disp('Mask Step 3: dilate the mask to include the edges in all frames')
    numskip=max(round(size(app.img, 3)/100), 1);
    showind=1:numskip:size(app.img, 3);
    sz_dil=1;
    disp('The current mask is in red. The edges are shown in green. Make sure the mask includes all of the edges of interest. I often start by dilating with a structuring element of size 5 pixels. ')
    while sz_dil>0
        imagei({app.img(:,:,showind) app.img(:,:,showind) app.img(:,:,showind)},{repmat(app.mask,[1 1 length(showind)]) app.e(:,:,showind)})
        %sz_dil=input('What size structuring element do you want to use to dilate the mask?  ');
        waitfor(app, 'waitingForInput', false);
        sz_dil = app.DilationPanel_SizeEditField.Value;
        app.waitingForInput = true;
        app.mask=imdilate(app.mask,strel('disk',sz_dil)); 
    end
    
    % apply the mask
    app.e=logical(repmat(app.mask,[1 1 size(app.mask,3)]).*app.e);
    app.closePopup()
    app.DilationPanel.Visible = 'off';
end