function index=SearchTag(xmlList,tagName)
% return the row index of given tag name
listLen=size(xmlList,1);
index=[];
for n=1:listLen
    if strcmp(char(xmlList(n,2)),tagName)
        index=[index; n]; %#ok<AGROW>
    end
end