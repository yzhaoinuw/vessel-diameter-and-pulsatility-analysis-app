function imgLists=ReadObjectMemoryBlocks(fp,lifVersion,imgLists)
% get end of file and return current point
cofp=    ftell(fp);
fseek(fp,0,'eof');
eofp=    ftell(fp);
fseek(fp,cofp,'bof');

nImgLists=length(imgLists);
memoryList=cell(nImgLists,4);
% ID(string), startPoint(uint64), sizeOfMemory, Index(double)
for n = 1:nImgLists
    memoryList{n,1}=imgLists(n).Memory.MemoryBlockID;
end

% read object memory blocks
while ftell(fp) < eofp
    
    CheckTestValue(fread(fp,1,'*uint32'),...        % Test Value 0x70
        'Invalied test value at Object Memory Block');
    
    objMemBlkChunk = fread(fp, 1, '*uint32');%#ok<NASGU> % Size of Description
    
    CheckTestValue(fread(fp,1,'*uint8'),...         % Test Value 0x2A
        'Invalied test value at Object Memory Block');
    
    
    switch uint8(lifVersion)            % Size of Memory (version dependent)
        case 1; sizeOfMemory = double(fread(fp, 1, '*uint32'));
        case 2; sizeOfMemory = double(fread(fp, 1, '*uint64'));
        otherwise; error('Unsupported LIF version. Update this program');
    end
    
    CheckTestValue(fread(fp,1,'*uint8'),...         % Test Value 0x2A
        'Invalied test value at Object Memory Block');
    
    nc = fread(fp,1,'*uint32');                     % Number of MemoryID string
    
    str = fread(fp,nc*2,'*char')';                  % Number of MemoryID string (UTF-16)
    str = char(str(1:2:end));                       % convert UTF-16 to UTF-8
    
    if sizeOfMemory > 0
        for n=1:nImgLists
            if strcmp(char(memoryList{n,1}),str) % NEED CONSIDERATION !!!!!!
                if imgLists(n).Memory.Size ~= sizeOfMemory
                    error('Memory Size Mismatch.');
                end
                imgLists(n).Memory.StartPosition=ftell(fp);
                fseek(fp,sizeOfMemory,'cof');
                break;
            end
        end
    end
end


return;