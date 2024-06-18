function [C, D]=MakeImageStruct(xmlList,iid)
% ChannelDescription   DataType="0" ChannelTag="0" Resolution="8"
%                      NameOfMeasuredQuantity="" Min="0.000000e+000" Max="2.550000e+002"
%                      Unit="" LUTName="Red" IsLUTInverted="0" BytesInc="0"
%                      BitInc="0"
% DimensionDescription DimID="1" NumberOfElements="512" Origin="4.336809e-020"
%                      Length="4.558820e-004" Unit="m" BitInc="0"
%                      BytesInc="1"
% Memory ?@?@?@?@?@?@?@  Size="21495808" MemoryBlockID="MemBlock_233"
iidChildren=xmlList{iid,5};
for n=1:numel(iidChildren)
    if strcmp(xmlList{iidChildren(n),2},'Channels')
        id=xmlList{iidChildren(n),5};
        p=xmlList(id,3);
        nid=numel(id);
        tmp=cell(11,nid);
        for m=1:nid
            tmp(:,m)=p{m}(:,2);
        end
        C=cell2struct(tmp,p{1}(:,1),1);
    elseif strcmp(xmlList{iidChildren(n),2},'Dimensions')
        id=xmlList{iidChildren(n),5};
        p=xmlList(id,3);
        nid=numel(id);
        tmp=cell(7,nid);
        for m=1:nid
            tmp(:,m)=p{m}(:,2);
        end
        D=cell2struct(tmp,p{1}(:,1),1);
    else
        error('Undefined Tag')
    end
end