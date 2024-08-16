function [dist_caps] = find_dist_caps(bw_caps,mask,seg)
%find_dist_caps Calculates the distance between the endcaps which can then be
%used to convert the area into an average diameter; meant to be used with
%the output of find_img_edges.m
% INPUTS:
%   bw_caps: binary 2D array showing the location of the caps
%   mask: bindary 2D array showing the location of the mask (optional)
%   seg: binary array, can be 2 or 3D showing the segmented region
% OUTPUTS:
%   dist_caps--scalar indicating the distance between the end caps in
%   bw_caps; can be used to calcuate the average diameter from the area
%   with diam=A/dist_caps

% Kimberly Boster, kboster@ur.rochester.edu, 3/6/24
% notes:
% This corrects for the fact that the endcap centroid's might not be lined
% up (the original approach, still used if no segmentation is provided)
% It only works if the segmentation is generally (>50% of the time)
% touching the endcaps all the way along; also it requires a segmentation
% be loaded. Could use the downsampled one for hashmats stuff.
% If you're not satisfied with the results, you can use
% avg_seg=SegmentStack(mean(seg,3)) to adjust the threshold, and use that
% instead of the original segmenation. Alternatively, you could just use
% the segmentation from a single frame. 

% ideas to improve
% 1.) could let the user adjust the threshold, so that it's usually
% touching (use SegmentStack outside of the function?)
% 2.) could base it on the size of the area between the mask and bw_caps,
% but that would require there to be a hole in the middle
% 3.) find the center points of the average segmentation, find a
% polynomial, then take the distance to be the intersection of the
% polynomial with bw_caps. This would be best for curved vessels or noisy
% results. See code for this in old ideas, below.

if isempty(mask)
    mask=zeros(size(bw_caps));
end

if isempty(seg) || ~exist('seg','var')
    stats=regionprops(bw_caps,'Centroid');
    dist_caps=((stats(1).Centroid(1)-stats(2).Centroid(1)).^2+(stats(1).Centroid(2)-stats(2).Centroid(2)).^2).^0.5;
    dist_caps=dist_caps-3; % this is b/c bw_caps, which is 3 pixels wide, is outside of the segmented region. So it's off by 1.5 pixels on either end, or 3 pixels total

    % visualize
    imagei({bw_caps,bw_caps,bw_caps},{mask bw_caps zeros(size(bw_caps))}), axis equal, 
    hold on, plot([stats(1).Centroid(1) stats(2).Centroid(1)]-1,[stats(1).Centroid(2) stats(2).Centroid(2)]-1,'y','LineWidth',4)

else
     caps_trim=bw_caps & imdilate(imbinarize(mean(seg,3),0.5),strel('disk',1)); 
     stats=regionprops(caps_trim,'Centroid');
     dist_caps=((stats(1).Centroid(1)-stats(2).Centroid(1)).^2+(stats(1).Centroid(2)-stats(2).Centroid(2)).^2).^0.5; 
     dist_caps=dist_caps-1; % this is b/c the line goes from one pixel outside of the segmented region on either end. (This is because we dilated seg by 1 pixel.) But it goes from the center of the pixel, so it's only off by half a pixel on each end. You could make the trimmed caps be the intersection of a dilated mask and the non-dilated segmented region, but then you'd have to add a pixel because the centroid goes from the center of the pixel. 
     
     % visualize
     imagei({mean(seg,3) mean(seg,3) mean(seg,3)},{mask bw_caps caps_trim}), axis equal, 
     hold on, plot([stats(1).Centroid(1) stats(2).Centroid(1)]-1,[stats(1).Centroid(2) stats(2).Centroid(2)]-1,'y','LineWidth',4) % subtract 1 from the x and y coordinates for the visualization b/c the indexing for imagei starts from 0


end

%% old ideas
% stats=regionprops(logical(bw_caps | mask),'Centroid','Orientation');
% [xctr,yctr]=FindCntrPts(seg(:,:,1));
% [line_x, line_y, xc, yc] = FindSpanningLinesOnly(xctr,yctr,numlines,numpts,linelength,polyord);
end

%% code graveyard
 % Modified version -----------------
    % caps_trim=bw_caps & imdilate(imbinarize(mean(seg,3),0.5),strel('disk',1)); 
    % stats=regionprops(caps_trim,'Centroid');
    % centroid1=[stats(1).Centroid(1), stats(1).Centroid(2)];
    % centroid2=[stats(2).Centroid(1), stats(2).Centroid(2)];
    
    % Finding the direction vector
    % dir_vec=centroid2-centroid1;

    % Normalizing the direction vector
    % unit_vec=dir_vec/norm(dir_vec);

    % Extension vector (extending by 1 pixel)
    % extension=unit_vec*1;

    % New endpoints
    % end_point1=centroid1-extension;
    % end_point2=centroid2;

    % dist_caps=((end_point1(1)-end_point2(1))^2+(end_point1(2)-end_point2(2))^2)^0.5;

    % visualize
    % imagei({mean(seg,3) mean(seg,3) mean(seg,3)},{mask bw_caps caps_trim}), axis equal, 
    % hold on, 
    % plot([end_point1(1),end_point2(1)],[end_point1(2),end_point2(2)],'y','LineWidth',4)
    % hold off