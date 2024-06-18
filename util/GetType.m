function chType=GetType(Channels)
switch str2double(Channels.DataType)
    case 0 % int case
        switch str2double(Channels.Resolution)
            % currently, resolution is constant through the channels
            case 8;   chType='uint8';
            case 16;  chType='uint16';
            case 32;  chType='uint32';
            case 64;  chType='uint64';
            otherwise;error('Unsupported data bit. ')
        end
    case 1 % float case
        switch str2double(Channels.Resolution)
            % currently, resolution is constant through the channels
            case 32;  chType='single';
            case 64;  chType='double';
            otherwise;error('Unsupported data bit. ')
        end
end