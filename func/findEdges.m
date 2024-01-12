function images = findEdges(app, images)
edgemethod='Canny';
%% find edges
for i=1:size(images, 3)
    if ~isa(edgemethod, 'double')
        if strcmp('both', edgemethod)
            e1=edge(imgaussfilt(double(images(:,:,i)),3), 'Canny', .005);
            e2=edge(imgaussfilt(double(images(:,:,i)),3), 'log', .005);
            app.e(:,:,i)=e1|e2;
        else
            app.e(:,:,i)=edge(imgaussfilt(double(images(:,:,i)),3), edgemethod, .005);
        end
    else    
        app.e(:,:,i)=edge_kasb(imgaussfilt(double(images(:,:,i)),3), .005, edgemethod);
    end
end