function [name, attributes]=ParseTagString(tag)
[name, tmpAttributes]=regexp(tag,'^\w+','match', 'split');
name=char(name);
attributesCell=regexp(char(tmpAttributes(end)),'\w+=".*?"','match');
if isempty(attributesCell)
    attributes={};
else
    nAttributes = numel(attributesCell);
    attributes=cell(nAttributes,2);
    for n=1:nAttributes
        currAttrib=char(attributesCell(n));
        dqpos=strfind(currAttrib,'"');
        attributes{n,1}=currAttrib(1:dqpos(1)-2);
        if dqpos(2)-dqpos(1)==1 % case attribute=""
            attributes{n,2}='';
        else
            attributes{n,2}=currAttrib(dqpos(1)+1:dqpos(2)-1);
        end
    end
end