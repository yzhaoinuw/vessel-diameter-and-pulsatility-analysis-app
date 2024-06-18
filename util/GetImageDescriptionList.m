function mems = GetImageDescriptionList(xmlList)
%  For the image data type the description of the memory layout is defined
%  in the image description XML node (<ImageDescription>).

% <ImageDescription>
imgIndex  =SearchTag(xmlList,'ImageDescription');
numImgs=numel(imgIndex);

% <Memory Size="21495808" MemoryBlockID="MemBlock_233"/>
memIndex  =SearchTag(xmlList,'Memory');
memSizes  =cellfun(@str2double,GetAttributeVal(xmlList,memIndex,'Size'));
memIndex=memIndex(memSizes~=0);
memSizes=memSizes(memSizes~=0);
if numImgs~=numel(memIndex)
    error('Number of ImageDescription and Memory did not match.')
end

% Matching ImageDescription with Memory
imgParentElmIndex =  zeros(numImgs,1);
for n=1:numImgs
    imgParentElmIndex(n) = SearchTagParent(xmlList,imgIndex(n),'Element');
end
memParentElmIndex =  zeros(numImgs,1);
for n=1:numImgs
    memParentElmIndex(n) = SearchTagParent(xmlList,memIndex(n),'Element');
end
[imgParentElmIndex, sortIndex]=sort(imgParentElmIndex); imgIndex=imgIndex(sortIndex);
[memParentElmIndex, sortIndex]=sort(memParentElmIndex); memIndex=memIndex(sortIndex);memSizes=memSizes(sortIndex);
if ~all(imgParentElmIndex==memParentElmIndex)
    error('Matching ImageDescriptions with Memories')
end

mems=struct('Name',[],'Channels',[],'Dimensions',[],'Memory',[]);
mems(numImgs).Memory.StartPosition=[];
for n=1:numImgs
    mems(n).Name = char(GetAttributeVal(xmlList, imgParentElmIndex(n),'Name'));
    [mems(n).Channels, mems(n).Dimensions]= MakeImageStruct(xmlList,imgIndex(n));
    mems(n).Memory.Size=memSizes(n);
    mems(n).Memory.MemoryBlockID=char(GetAttributeVal(xmlList,memIndex(n),'MemoryBlockID'));
end


return