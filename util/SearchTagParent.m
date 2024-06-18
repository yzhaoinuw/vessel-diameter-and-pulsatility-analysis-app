function pindex=SearchTagParent(xmlList,index,tagName)
% return the row index of given tag name
pindex=xmlList{index,4};

while pindex~=0
    if strcmp(xmlList{pindex,2},tagName)
        return;
    else
        pindex=xmlList{pindex,4};
    end
end
error('Cannot Find the Parent Tag "%s"',tagName);