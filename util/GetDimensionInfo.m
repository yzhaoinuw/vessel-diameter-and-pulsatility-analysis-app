function [dimType, dimSize]=GetDimensionInfo(dimensions)
ndims=numel(dimensions);
dimType=cell(2*ndims,1);
dimSize=zeros(ndims,1);

for n=1:ndims
    dimSize(n)=str2double(dimensions(n).NumberOfElements);
    switch dimensions(n).DimID
        case '0';dimType{2*n-1}='Not Valied';
        case '1';dimType{2*n-1}='X';
        case '2';dimType{2*n-1}='Y';
        case '3';dimType{2*n-1}='Z';
        case '4';dimType{2*n-1}='T';
        case '5';dimType{2*n-1}='Lambda';
        case '6';dimType{2*n-1}='Rotation';
        case '7';dimType{2*n-1}='XT';
        case '8';dimType{2*n-1}='TSlice';
        otherwise
    end
    dimType{2*n}='-';
end
dimType=strrep(sprintf('%s',char(dimType)'),' ','');
dimType=dimType(1:end-1);% Delete last '-'