function images = makeCaps(app, images)

% seg=imclose(seg,strel('disk',4)); % this doesn't work as well as the
% correction that starts with the code: "if sum(seg(:,:,i),'all')<2*sum(e(:,:,i),'all')"

%% cap off the ends
% only show a maximum of 100 images
numskip=max(round(size(images, 3)/100), 1);
showind=1:numskip:size(images, 3);
if isempty(app.mask) || size(app.mask, 1)==1
    imagei({images(:,:,showind) images(:,:,showind) images(:,:,showind)},{app.seg(:,:,showind)}), axis equal
else
    imagei({images(:,:,showind) images(:,:,showind) images(:,:,showind)},{repmat(app.mask,[1 1 length(showind)]) app.seg(:,:,showind)}), axis equal
end

app.CappingPanel.Visible = 'on'; 

disp('Click and drag to draw a line to cap off the ends')
roi = drawline();
morelines='Yes';
app.bw_caps=false(size(images,[1 2]));
while strcmp(morelines,'Yes')
    bw_line=false(size(images,[1 2]));
    disp('Move the line and dbl click when satisfied. (Depending on the version of Matlab, you might have to move the end points)')
    wait(roi)
    linelength=((roi.Position(1,1)-roi.Position(2,1)).^2 + (roi.Position(1,2)-roi.Position(2,2)).^2).^0.5;
    xind=round(linspace(roi.Position(1,1),roi.Position(2,1),linelength));
    yind=round(linspace(roi.Position(1,2),roi.Position(2,2),linelength));
    hold on, plot(xind,yind,'g')
    for i=1:length(xind)
        bw_line(yind(i),xind(i))=1; % there's got to be a better way to do this
    end
    bw_line = imdilate(bw_line,strel('disk',1));
    app.bw_caps = app.bw_caps | bw_line;    
    morelines=questdlg('Do you want to add more caps?','capping ends','Yes');
end

app.closePopup()
app.CappingPanel.Visible = 'off';
end