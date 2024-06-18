function CheckTestValue(value,errorMsg)
switch class(value)
    case 'uint8';  trueVal=hex2dec('2A');
    case 'uint32'; trueVal=hex2dec('70');
    otherwise
        error('Unsupported Error Number: %d',value)
end
if value~=trueVal
    error(errorMsg);
end
return;