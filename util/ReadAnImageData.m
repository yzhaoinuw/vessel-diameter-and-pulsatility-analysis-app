function imgData=ReadAnImageData(imgInfo,fileName,framerange)
fp = fopen(fileName,'rb');
if fp<0; errordlg('Cannot open file: \n\t%s', fileName); end
inc=str2double(imgInfo.Dimensions(3).BytesInc);
fseek(fp,imgInfo.Memory.StartPosition + (framerange(1)-1)*inc,'bof');
imgData = fread(fp,(diff(framerange)+1)*inc,'*uint8');
fclose(fp);