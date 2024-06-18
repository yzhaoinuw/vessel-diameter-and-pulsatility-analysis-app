function [fp, str, ketPos] = ReadXMLPart(fp)
% Size(bytes) Total(bytes) description (some LAS-AF 3.x version give errors
% here, fixed in LAS-X
CheckTestValue(fread(fp,1,'*uint32'),...        % 4  4 Test Value 0x70
    'Invalid test value at Part: XML.');
xmlChunk = fread(fp, 1, 'uint32');              % 4  8 Binary Chunk length NC*2 + 1 + 4
CheckTestValue(fread(fp,1,'*uint8'),...         % 1  9 Test Value 0x2A
    'Invalid test value at XML Content.');
nc = fread(fp,1,'uint32');                      % 4 13 Number of UTF-16 Characters (NC)
if (nc*2 + 1 + 4)~=xmlChunk
    error('Chunk size mismatch at Part: XML.');
end
str= fread(fp,nc*2,'char');                     % 2*nc - XML Object Description

% UTF-16 -> UTF-8 (cut zeros)
str     = char(str(1:2:end)');
% Insert linefeed(char(10)) for facilitate visualization -----
% str=strrep(str,'><',['>' char(10) '<']);
ketPos =strfind(str,'>'); % find position of ">" for fast search of element
return;