function tagList=XMLtxt2cell(c)
% rank(double) name(string) attributes(cell(n,2)) parant(double) children(double array)
tags  =regexp(c,'<("[^"]*"|''[^'']*''|[^''>])*>','match')';
nTags=numel(tags);
tagList=cell(nTags,5);
tagRank=0;
tagCount=0;
for n=1:nTags
    currentTag=tags{n}(2:end-1);
    if currentTag(1)=='/'
        tagRank=tagRank-1;
        continue;
    end
    tagRank=tagRank+1;
    tagCount=tagCount+1;
    [tagName, attributes]=ParseTagString(currentTag);
    tagList{tagCount,1}=tagRank;
    tagList{tagCount,2}=tagName;
    tagList{tagCount,3}=attributes;
    % search parant
    if tagRank~=1
        if tagRank~=tagList{tagCount-1,1}
            tagRankList=cell2mat(tagList(1:tagCount,1));
            parent=find(tagRankList==tagRank-1,1,'last');
            tagList{tagCount,4}=parent;
        else
            tagList{tagCount,4}=tagList{tagCount-1,4};
        end
    else
        tagList{tagCount,4} = 0;
    end
    if currentTag(end)=='/'
        tagRank=tagRank-1;
    end
end

tagList   =tagList(1:tagCount,:);
parentList=cell2mat(tagList(:,4));
% Make Children List
for n=1:tagCount
    tagList{n,5}=find(parentList==n);
end

return;