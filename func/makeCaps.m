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

app.bw_caps = extend_caps_local(app.bw_caps); % extend caps to edges of image
app.closePopup()
app.CappingPanel.Visible = 'off';
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
    
    stats = regionprops(new_caps, "Centroid", "Orientation", "Area"); % get centroids, angles, and areas of detected caps regions
    stats = table2struct(sortrows(struct2table(stats), "Area", "descend")); % sorts regionprops results by descending area

    if length(stats) > 1 % only runs if there are multiple regions
        for i = length(stats) : -1 : 2 % iterate through regions backwards
            if (stats(i).Area < 0.2*stats(1).Area)
                % it's possible that the erosion can leave the regions disconnected 
                % and result in undesired little regions. this conditional filters 
                % and deletes any regions whose areas are less than 20% of the largest 
                % region's area. the 20% is completely arbitary and can be changed 
                stats(i) = [];
            end
        end
    end

    centroids = cat(1, stats.Centroid); % separate centroids into separate matrix

    [y_max, x_max] = size(bw_caps); % get max x and y of image
    
    new_caps = im2double(new_caps); % convert new_caps to double for use with insertShape

    for i = 1 : size(stats) % run for every region detected
        % yf and xf are the projected lines of the caps based on the stats from regionprops and are algebraically equivalent
        yf = @(x) (1/tand(stats(i).Orientation - 90))*(x - centroids(i, 1)) + centroids(i, 2);
        xf = @(y) tand(stats(i).Orientation - 90)*(y - centroids(i, 2)) + centroids(i, 1);
        
        endpoints = calculate_endpoints(yf, xf, x_max, y_max); % get intersection points between image borders and current projected line
        endpoints(sub2ind(size(endpoints), find(endpoints == 0))) = 2; % insertShape seems to not like positions at 0 or 1, so change them to 2

        new_caps = insertShape(new_caps, 'line', endpoints); % add current extended cap to new_caps
    end

    new_caps = mean(new_caps, 3); % combine new_caps back into a 2D image
    new_caps = imbinarize(new_caps); % convert new_caps back into a binary image
    new_caps = imdilate(new_caps, SE); % dilate extended caps back to being 3px wide

end

%% calculate where the given line will intersect the edges of the image
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