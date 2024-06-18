function lifVersion = GetLifVersion(xmlList)
% return version of header
index  =SearchTag(xmlList,'LMSDataContainerHeader');
value  =GetAttributeVal(xmlList,index,'Version');
lifVersion = str2double(cell2mat(value(1)));
return