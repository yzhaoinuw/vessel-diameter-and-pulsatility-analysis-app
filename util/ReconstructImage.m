function imgList=ReconstructImage(imgInfo,imgData,framerange)
% ===================================================================
% imgInfo description
% ===================================================================
% <ChannelDescription>
%%% DataType   [0, 1]               [Integer, Float]
%%% ChannelTag [0, 1, 2, 3]         [GrayValue, Red, Green, Blue]
% Resolution [Unsigned integer]   Bits per pixel if DataType is Float value can be 32 or 64 (float or double)
% NameOfMeasuredQuantity [String] Name
% Min        [Double] Physical Value of the lowest gray value (0). If DataType is Float the Minimal possible value (or 0).
% Max        [Double] Physical Value of the highest gray value (e.g. 255) If DataType is Float the Maximal possible value (or 0).
% Unit       [String] Physical Unit
% LUTName    [String] Name of the Look Up Table (Gray value to RGB value)
% IsLUTInverted [0, 1] Normal LUT Inverted Order
%%% BytesInc   [Unsigned long (64 Bit)] Distance from the first channel in Bytes
% BitInc     [Unsigned Integer]       Bit Distance for some RGB Formats (not used in LAS AF 1..0 ? 1.7)
% <DimensionDescription>
% DimID   [0, 1, 2, 3, 4, 5, 6, 7, 8] [Not valid, X, Y, Z, T, Lambda, Rotation, XT Slices, T Slices]
%%% NumberOfElements [Unsigned Integer] Number of elements in this dimension
% Origin           [Unsigned integer] Physical position of the first element (Left pixel side)
% Length   [String] Physical Length from the first left pixel side to the last left pixel side (Not the right. A Pixel has no width!)
% Unit     [String] Physical Unit
%%% BytesInc [Unsigned long (64 Bit)] Distance from one Element to the next in this dimension
% BitInc   [Unsigned Integer] Bit Distance for some RGB Formats (not used, i.e.: = 0 in LAS AF 1..0 ? 1.7)
% ===================================================================
% imgList info
% ===================================================================
% img

% Get Dimension info
dimension=ones(1,9);
for m=1:numel(imgInfo.Dimensions)
    dimension(str2double(imgInfo.Dimensions(m).DimID)) = ...
        str2double(imgInfo.Dimensions(m).NumberOfElements);
end
dimension(4)=diff(framerange)+1; % dimension(4) is T

% Separate to each channel image
nCh=numel(imgInfo.Channels);
imgList=struct('Image',[],'Info',[]);
imgList.Image = cell(nCh,1);
if nCh > 1
    imgData=reshape(imgData,...
        str2double(imgInfo.Channels(2).BytesInc) - ...
        str2double(imgInfo.Channels(1).BytesInc),[]);
    for m=1:nCh
        tmp=imgData(:,m:nCh:end);
        imgList.Image{m} = reshape(typecast(tmp(:), ...
            GetType(imgInfo.Channels(m))),dimension);
    end
else
    imgList.Image{1} = reshape(typecast(imgData, ...
        GetType(imgInfo.Channels)),dimension);
end
imgList.Info = imgInfo;