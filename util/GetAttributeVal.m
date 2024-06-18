function value=GetAttributeVal(xmlList, index, attributeName)
% return cell array of attributes row index of given tag name
value={};
for n=1:length(index)
    currentCell=xmlList{index(n),3};
    for m=1:size(currentCell,1)
        if strcmp(char(currentCell(m,1)),attributeName)
            value=[value; currentCell(m,2)]; %#ok<AGROW>
        end
    end
end