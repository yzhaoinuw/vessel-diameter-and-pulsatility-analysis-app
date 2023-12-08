function [] = findEdges(app)
edgemethod='Canny';
%% find edges
for i=1:size(app.img, 3)
    if ~isa(edgemethod, 'double')
        if strcmp('both', edgemethod)
            e1=edge(imgaussfilt(double(app.img(:,:,i)),3), 'Canny', .005);
            e2=edge(imgaussfilt(double(app.img(:,:,i)),3), 'log', .005);
            app.e(:,:,i)=e1|e2;
        else
            app.e(:,:,i)=edge(imgaussfilt(double(app.img(:,:,i)),3), edgemethod, .005);
        end
    else    
        app.e(:,:,i)=edge_kasb(imgaussfilt(double(app.img(:,:,i)),3), .005, edgemethod);
    end
end