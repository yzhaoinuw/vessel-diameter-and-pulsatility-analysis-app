function [imgout] = ci_loadLif(filename, getonlynumberofelements, input_channel, framerange, parallel)
    % ci_loadLif - Load Leica Image File Format
    %
    % Based on CI-ImagingLIF, Access Leica LIF and XLEF Files by Ron Hoebe
    % https://www.mathworks.com/matlabcentral/fileexchange/48774-ci-imaginglif-access-leica-lif-and-xlef-files
    % https://github.com/Cellular-Imaging-Amsterdam-UMC/CI-ImagingLIF
    %
    % [imgout] = loadLif_tb2(filename, getonlynumberofelements, input_channel, framerange, parallel)
    % loads a series of images from a Leica Image File. 
    %
    % Make sure to have xml2structstring.mexa64 (Linux only) on path when running. This function works
    % without it but will run much slower.
    %
    % inputs:
    %   filename - name of .lif file
    %   getonlynumberofelements - returns only the number of elements in file. defaults to 0
    %   input_channel - specific channel to retrieve images from. defaults to 1
    %   framerange - specify the range of frames to retrieve (inclusive). can take 2 element vector and 
    %       single frame inputs. defaults to all frames in channel. can also take '0' to default to all 
    %   parallel - uses parfor loop when true. defaults to false/series for-loop
    % outputs:
    %   imgout - either the series of images or number of elements
    %    imgout =
    %               Image: {[1024x1024x101 uint8]}
    %                Info: [1x1 struct]
    %                Name: 'loc1'
    %                Type: 'X-Y-Z'
    %     NumberOfChannel: 1
    %     AllocatedFrames: '101'
    %         SeriesNames: [1x38 cell]

  

    % History
    % Updated 13 September 2018 by Doug Kelley to include framerange input. 
    % Updated 16 September 2018 to output imgout.Info.Dimensions(3) consistent
    % with framerange. 
    % Updated 17 September 2018 to output total frame count in
    % imgout.AllocatedFrames. 
    % Updated 24 May 2021 to output imgout.Info.SeriesNames.
    % Updated 25 June 2024 by Taylor Bayarerdene: major overhaul. Function
    % runs much faster and no longer needs enough memory to load in the entire .lif file.
    % Updated 3 October 2024 by Doug Kelley for compatibility with files
    % that lack some metadata. Also fixed framerange. 

    % Next: mine more information from iminfo!

    % if no inputs are provided, prompt user to select file from file explorer
    if nargin==0
        [filename, pathname]=uigetfile({'*.lif','Leica Image Format (*.lif)'});
        if filename==0; return; end
        filename=[pathname filename];
        getonlynumberofelements=false;
        input_channel=1;
    end

    % throw error if the provided filename does not have .lif in it
    % matlab throws a more ambiguous error otherwise
    if ~contains(filename, '.lif')
        error('Please make sure filename contains .lif.');
    elseif ~isfile(filename)
        error([filename ' could not be found, check filename or path again.']);
    end

    if ~exist('input_channel', 'var') % defaults first channel
        input_channel = 1; 
    end


    %app.Tree.Enable='off';
    %app.Node.delete
    fileID = fopen(filename,'r','n','UTF-8');
    testvalue=fread(fileID,1,'int32');
    if testvalue~=112; return; end 
    XMLContentLenght=fread(fileID,1,'int32'); %#ok<NASGU> 
    testvalue = fread(fileID,1,'uint8');
    if testvalue~=42; return; end 
    testvalue=fread(fileID,1,'int32');
    uc=reshape(fread(fileID,2*testvalue,'*char'),1,testvalue*2);
    XMLObjDescription=cfUnicode2ascii(uc);
    XMLObjDescription=regexprep(XMLObjDescription,'</',[newline '</']);
    %Remove error from GSD LIF File
    errstrings=extractBetween(XMLObjDescription,'High resolution image created from &quot;','&quot;.');
    XMLObjDescription=replace(XMLObjDescription,errstrings,'');
    
    %Read memory blocks
    lifinfo=struct;
    tel=0;
    while ~feof(fileID)
        tel=tel+1;
        testvalue=fread(fileID,1,'int32');
        if feof(fileID); break; end
        if testvalue ~=112; return; end
        BinContentLenght=fread(fileID,1,'int32'); %#ok<NASGU> 
        testvalue = fread(fileID,1,'uint8');
        if testvalue~=42; return; end 
        MemorySize=fread(fileID,1,'int64');
        testvalue = fread(fileID,1,'uint8');
        if testvalue~=42; return; end 
        testvalue=fread(fileID,1,'int32');
        sBlockID=cfUnicode2ascii(reshape(fread(fileID,2*testvalue,'*char'),1,testvalue*2));
        lifinfo(tel).BlockID=sBlockID;
        lifinfo(tel).MemorySize=MemorySize;
        lifinfo(tel).Position=ftell(fileID);
        if MemorySize>0; fseek(fileID,MemorySize,0); end
    end
    fclose(fileID);
    %setLogD(app,'Opening LIF-File');
    %disp("Opening " + filename);

    if (exist('xml2struct.mexa64', 'file') ~= 0) % checks for the file with the compiled function (linux version)
        %disp('found');
        s=xml2structstring(['<?xml version="1.0" encoding="ISO-8859-1"?>' XMLObjDescription]);
    else % runs using the slower local function
        %disp('not found');
        warning('Using slower local function. Please add xml2struct.mexa64 to path for faster processing');
        s=cfXML2struct(['<?xml version="1.0" encoding="ISO-8859-1"?>' XMLObjDescription]);
    end

    %app.Node = uitreenode(app.Tree,'Text',app.filename,'NodeData',fileparts(app.file), 'Icon','LAS-X.png','Tag','File');
    %setLogD(app,'LAS-X LIF File Opened');
    %disp(filename + " opened");
    cnode=0;
    elements=numel(s.LMSDataContainerHeader.Element.Children.Element);

    if exist('getonlynumberofelements', 'var') && (getonlynumberofelements)
        imgout = elements;
        return;
    end

    filetype = '.lif';
    %setLogD(app,[num2str(elements) ' root nodes found, scanning...']);
    %disp(string(elements) + " root nodes found, scanning...");
    for k = 1:elements
        cnode=cnode+1;
        if elements==1
            thiselement=s.LMSDataContainerHeader.Element.Children.Element;
        else
            thiselement=s.LMSDataContainerHeader.Element.Children.Element{k};
        end
        MemoryBlockID=thiselement.Memory.Attributes.MemoryBlockID;
        lifinfoindex=find(strcmpi({lifinfo.BlockID},MemoryBlockID)==1);
        MemorySize=str2double(thiselement.Memory.Attributes.Size);
        name=thiselement.Attributes.Name;
%                 lifinfo(lifinfoindex).filetype=app.filetype;
%                 lifinfo(lifinfoindex).filepath=app.filepath;
%                 lifinfo(lifinfoindex).LIFFile=app.file;
        lifinfo(lifinfoindex).filetype = filetype;
        lifinfo(lifinfoindex).LIFFile = filename;
        lifinfo(lifinfoindex).name=name;
        if MemorySize==0 && ~contains(name,'iomanagerconfiguation','IgnoreCase',true)
            app.Nodes(cnode)=uitreenode(app.Node,'Text',name,'NodeData',name,'Icon','folder.png','Tag','Folder');
            elements1=numel(thiselement.Children.Element);
            cnode1=cnode;
            for k1 = 1:elements1
                cnode=cnode+1;
                if elements1==1
                    thiselement1 = thiselement.Children.Element;
                else
                    thiselement1 = thiselement.Children.Element{k1};
                end
                MemoryBlockID=thiselement1.Memory.Attributes.MemoryBlockID;
                lifinfoindex=find(strcmpi({lifinfo.BlockID},MemoryBlockID)==1);
                MemorySize=str2double(thiselement1.Memory.Attributes.Size);
                name1=thiselement1.Attributes.Name;
                lifinfo(lifinfoindex).filetype=app.filetype;
                lifinfo(lifinfoindex).filepath=app.filepath;
                lifinfo(lifinfoindex).LIFFile=app.file;
                lifinfo(lifinfoindex).name=name1;
                if MemorySize==0 && ~contains(name,'iomanagerconfiguation','IgnoreCase',true)
                    app.Nodes(cnode)=uitreenode(app.Nodes(cnode1),'Text',name1,'NodeData',name1,'Icon','folder.png','Tag','Folder');
                    elements2=numel(thiselement1.Children.Element);
                    cnode2=cnode;
                    for k2 = 1:elements2
                        cnode=cnode+1;
                        if elements2==1
                            thiselement2 = thiselement1.Children.Element;
                        else
                            thiselement2 = thiselement1.Children.Element{k2};
                        end
                        MemoryBlockID=thiselement2.Memory.Attributes.MemoryBlockID;
                        lifinfoindex=find(strcmpi({lifinfo.BlockID},MemoryBlockID)==1);
                        MemorySize=str2double(thiselement2.Memory.Attributes.Size);
                        name2=thiselement2.Attributes.Name;
                        lifinfo(lifinfoindex).name=name2;
                        if MemorySize==0 && ~contains(name,'iomanagerconfiguation','IgnoreCase',true)
                            app.Nodes(cnode)=uitreenode(app.Nodes(cnode2),'Text',name2,'NodeData',name2,'Icon','folder.png','Tag','Folder');
                            elements3=numel(thiselement2.Children.Element);
                            cnode3=cnode;
                            for k3 = 1:elements3
                                cnode=cnode+1;
                                if elements3==1
                                    thiselement3 = thiselement2.Children.Element;
                                else
                                    thiselement3 = thiselement2.Children.Element{k3};
                                end
                                MemoryBlockID=thiselement3.Memory.Attributes.MemoryBlockID;
                                lifinfoindex=find(strcmpi({lifinfo.BlockID},MemoryBlockID)==1);
                                MemorySize=str2double(thiselement3.Memory.Attributes.Size);
                                name3=thiselement3.Attributes.Name;
                                lifinfo(lifinfoindex).name=name3;
                                if MemorySize==0 && ~contains(name,'iomanagerconfiguation','IgnoreCase',true)
                                    app.Nodes(cnode)=uitreenode(app.Nodes(cnode3),'Text',name3,'NodeData',name3,'Icon','folder.png','Tag','Folder');
                                elseif ~contains(name3,'iomanagerconfiguation','IgnoreCase',true) && ~contains(name3,'environmentalgraph','IgnoreCase',true)
                                    lifinfo(lifinfoindex).filetype=app.filetype;
                                    lifinfo(lifinfoindex).filepath=app.filepath;
                                    lifinfo(lifinfoindex).LIFFile=app.file;
                                    lifinfo(lifinfoindex).name=name3;
                                    if isfield(thiselement3.Data,'Image') 
                                        lifinfo(lifinfoindex).datatype='Image';
                                        lifinfo(lifinfoindex).Image=thiselement3.Data.Image;
                                    elseif isfield(thiselement3.Data,'GISTEventList')
                                        lifinfo(lifinfoindex).datatype='Eventlist';
                                        lifinfo(lifinfoindex).GISTEventList=thiselement3.Data.GISTEventList;
                                    else
                                        lifinfo(lifinfoindex).datatype='unknown';
                                    end
                                    lifinfo(lifinfoindex).Parent=[app.Nodes(cnode3).Parent.Parent.Text '_' app.Nodes(cnode3).Parent.Text '_' app.Nodes(cnode3).Text];
                                    app.Nodes(cnode)=uitreenode(app.Nodes(cnode3),'Text',name3,'NodeData',{name3, lifinfo(lifinfoindex)},'Icon','image.png','Tag',lifinfo(lifinfoindex).datatype,'UserData',cnode);
                                else
                                    cnode=cnode-1;
                                end
                            end
                        elseif ~contains(name2,'iomanagerconfiguation','IgnoreCase',true) && ~contains(name2,'environmentalgraph','IgnoreCase',true)
                            lifinfo(lifinfoindex).filetype=app.filetype;
                            lifinfo(lifinfoindex).filepath=app.filepath;
                            lifinfo(lifinfoindex).LIFFile=app.file;
                            lifinfo(lifinfoindex).name=name2;
                            if isfield(thiselement2.Data,'Image') 
                                lifinfo(lifinfoindex).datatype='Image';
                                lifinfo(lifinfoindex).Image=thiselement2.Data.Image;
                            elseif isfield(thiselement2.Data,'GISTEventList')
                                lifinfo(lifinfoindex).datatype='Eventlist';
                                lifinfo(lifinfoindex).GISTEventList=thiselement2.Data.GISTEventList;
                            else
                                lifinfo(lifinfoindex).datatype='unknown';
                            end
                            lifinfo(lifinfoindex).Parent=[app.Nodes(cnode2).Parent.Text '_' app.Nodes(cnode2).Text];
                            app.Nodes(cnode)=uitreenode(app.Nodes(cnode2),'Text',name2,'NodeData',{name2, lifinfo(lifinfoindex)},'Icon','image.png','Tag',lifinfo(lifinfoindex).datatype,'UserData',cnode);
                        else
                            cnode=cnode-1;
                        end
                    end
                elseif ~contains(name1,'iomanagerconfiguation','IgnoreCase',true) && ~contains(name1,'environmentalgraph','IgnoreCase',true)
                    if isfield(thiselement1.Data,'Image') 
                        lifinfo(lifinfoindex).datatype='Image';
                        lifinfo(lifinfoindex).Image=thiselement1.Data.Image;
                    elseif isfield(thiselement1.Data,'GISTEventList')
                        lifinfo(lifinfoindex).datatype='Eventlist';
                        lifinfo(lifinfoindex).GISTEventList=thiselement1.Data.GISTEventList;
                    else
                        lifinfo(lifinfoindex).datatype='unknown';
                    end
                    lifinfo(lifinfoindex).Parent=app.Nodes(cnode1).Text;
                    app.Nodes(cnode)=uitreenode(app.Nodes(cnode1),'Text',name1,'NodeData',{name1, lifinfo(lifinfoindex)},'Icon','image.png','Tag',lifinfo(lifinfoindex).datatype,'UserData',cnode);
                else
                    cnode=cnode-1;
                end
            end
        elseif ~contains(name,'iomanagerconfiguation','IgnoreCase',true) && ~contains(name,'environmentalgraph','IgnoreCase',true)
            if isfield(thiselement.Data,'Image') 
                lifinfo(lifinfoindex).datatype='Image';
                lifinfo(lifinfoindex).Image=thiselement.Data.Image;
            elseif isfield(thiselement.Data,'GISTEventList')
                lifinfo(lifinfoindex).datatype='Eventlist';
                lifinfo(lifinfoindex).GISTEventList=thiselement.Data.GISTEventList;
            else
                lifinfo(lifinfoindex).datatype='unknown';
            end
            lifinfo(lifinfoindex).Parent='';
            %    app.Nodes(cnode)=uitreenode(app.Node,'Text',name,'NodeData',{name, lifinfo(lifinfoindex)},'Icon','image.png','Tag',lifinfo(lifinfoindex).datatype,'UserData',cnode);
        else
            cnode=cnode-1;
        end
    end
    
    %setLogD(app,'Ready reading LIF file');
    %disp("Ready reading LIF file");
    %app.Tree.Enable='on';
    %expand(app.Tree,'all');


    channel = length(lifinfo) - elements + input_channel; % actual Series number
    
    if (strcmpi(lifinfo(channel).datatype,'Image'))
%             lifinfo(channel).filetype = '.lif';
%             lifinfo(channel).LIFFile = filename;
            [result, serror, iminfo] = cfReadMetaData(lifinfo(channel)); %#ok<ASGLU> 

            num_frames = str2double(lifinfo(channel).Image.ImageDescription.Dimensions.DimensionDescription{1, end}.Attributes.NumberOfElements);
%                     imgout_new = zeros(340, 304, num_frames);
%                     for i = 1 : num_frames
%                         imgout_new(:, :, i) = cfReadIm(lifinfo(channel), iminfo, channel, 1, i, 1);
%                     end

            if ~exist('framerange','var') || isempty(framerange) % default framerange to all frames
                framerange_default=[1 num_frames];
                framerange=framerange_default;
            elseif numel(framerange)==1 % make single input into a two element vector
                framerange=framerange*[1 1];
            end
            framerange(1) = max(framerange(1),1); % no frame before #1
            framerange(2) = min(framerange(2),iminfo.ts); % no frame after end of movie
            Nf = diff(framerange)+1; % number of frames to be read

            imgs = cfReadIm(lifinfo(channel), iminfo, channel, 1, 1, 1);
            imgs = zeros(size(imgs, 1), size(imgs, 2), Nf, class(imgs));
            if exist('parallel', 'var') && (parallel == 1) % only uses parfor if explicitly stated
                parfor i = 1:Nf
                    imgs(:, :, i) = cfReadIm(lifinfo(channel), ...
                        iminfo, channel, 1, framerange(1)+i-1, 1);
                end
            else % defaults to series for-loop
                for i = 1:Nf
                    imgs(:, :, i) = cfReadIm(lifinfo(channel), ...
                        iminfo, channel, 1, framerange(1)+i-1, 1);
                end
            end
            
            imgout = struct;
            imgout.Image = {permute(imgs, [2, 1, 3])};
            imgout.Info = struct;
                imgout.Info.Name = lifinfo(channel).name;
                imgout.Info.Channels = lifinfo(channel).Image.ImageDescription.Channels.ChannelDescription.Attributes;
                for dim = 1 : length(lifinfo(channel).Image.ImageDescription.Dimensions.DimensionDescription)
                    imgout.Info.Dimensions(dim, 1) = lifinfo(channel).Image.ImageDescription.Dimensions.DimensionDescription{1, dim}.Attributes;
                end
                imgout.Info.Memory.Size = lifinfo(channel).MemorySize;
                imgout.Info.Memory.MemoryBlockID = lifinfo(channel).BlockID;
                imgout.Info.Memory.StartPosition = lifinfo(channel).Position;
            imgout.Name = lifinfo(channel).name;
            imgout.Type = GetDimensionInfo(imgout.Info.Dimensions);
            imgout.NumberOfChannel = length(channel);
            imgout.AllocatedFrames = num2str(imgout.Info.Dimensions(end).NumberOfElements);
            for series = (length(lifinfo)-elements) : elements
                imgout.SeriesNames(1, series) = {lifinfo(series+1).name};
            end

%             imgout.lifinfo = lifinfo;
%             imgout.iminfo = iminfo;
            %disp("Loaded " + num_frames + " frames from channel " + input_channel);


            % cfReadIm(lifinfo, iminfo, channel, z, t, tile)
            % cfReadIm3D(lifinfo, iminfo, channel, zstart, zend, t, tile)
            % im=cfReadIm3D(lifinfo,iminfo,ch,1,iminfo.zs,app.TimeSlider.Value,app.TileSlider.Value);
    else
        error(['Series ' num2str(input_channel) ' contains no image data.'])
    end % if (strcmpi(lifinfo(channel).datatype,'Image'))
end % function ci_loadLif


%%
function asciistring = cfUnicode2ascii(utfstring)
    %UNICODE2ASCII Converts unicode endcoded files to ASCII encoded files
    %  ASCIISTRING = UNICODE2ASCII(UTFSTRING)
    %  Converts the UTFSTRING to ASCII and returns the string.

    % check number of arguments and open ustring handles

    ustring = utfstring;

    % read the ustring and delete unicode characters
    unicode = isunicode(ustring);

    % delete header
    switch(unicode)
        case 1
            ustring(1:3) = [];
        case 2
            ustring(1:2) = [];
        case 3
            ustring(1:2) = [];
        case 4
            ustring(1:4) = [];
        case 5
            ustring(1:4) = [];
    end

    % deletes all 0 bytes
    ustring(ustring == 0) = [];
    asciistring = ustring;
    return;
end


%%
function isuc = isunicode(utfstring)
%     ISUNICODE Checks if and which unicode header a string has.
%      ISUC is true if the ustring contains unicode characters, otherwise
%      false. Exact Information about the encoding is also given.
%      ISUC == 0: No UTF Header
%      ISUC == 1: UTF-8
%      ISUC == 2: UTF-16BE
%      ISUC == 3: UTF-16LE
%      ISUC == 4: UTF-32BE
%      ISUC == 5: UTF-32LE

    isuc = false;
    firstLine = utfstring(1:4);

    %assign all possible headers to variables
    utf8header    = [hex2dec('EF') hex2dec('BB') hex2dec('BF')];
    utf16beheader = [hex2dec('FE') hex2dec('FF')];
    utf16leheader = [hex2dec('FF') hex2dec('FE')];
    utf32beheader = [hex2dec('00') hex2dec('00') hex2dec('FE') hex2dec('FF')];
    utf32leheader = [hex2dec('FF') hex2dec('FE') hex2dec('00') hex2dec('00')];

    %compare first bytes with header
    if(strfind(firstLine, utf8header) == 1)
        isuc = 1;
    elseif(strfind(firstLine, utf16beheader) == 1)
        isuc = 2;
    elseif(strfind(firstLine, utf16leheader) == 1)
        isuc = 3;
    elseif(strfind(firstLine, utf32beheader) == 1)
        isuc = 4;
    elseif(strfind(firstLine, utf32leheader) == 1)
        isuc = 5;
    end

    if(~exist('firstLine', 'var'))
        fclose(fin);
    end
end


%%
function [result, serror, iminfo] = cfReadMetaData(lifinfo)
    %Reading MetaData (Leica LAS-X)
    if strcmpi(lifinfo.datatype,'image')
        iminfo.xs=0;                     % imwidth
        iminfo.xbytesinc=0;
        iminfo.ys=0;                     % imheight
        iminfo.ybytesinc=0;
        iminfo.zs=0;                     % slices (stack)
        iminfo.zbytesinc=0;
        iminfo.ts=1;                     % time
        iminfo.tbytesinc=0;
        iminfo.tiles=0;                  % tiles
        iminfo.tilesbytesinc=0;
        iminfo.xres=0;                   % resolution x
        iminfo.yres=0;                   % resolution y
        iminfo.zres=0;                   % resolution z
        iminfo.tres=0;                   % time interval (from timestamps)
        iminfo.timestamps=[];            % Timestamps t
        iminfo.resunit='';               % resulution unit
        iminfo.xres2=0;                  % resolution x in µm
        iminfo.yres2=0;                  % resolution y in µm
        iminfo.zres2=0;                  % resolution z in µm
        iminfo.resunit2='µm';            % resulution unit in µm
        iminfo.lutname=cell(10,1);
        iminfo.channels=1;
        iminfo.isrgb=false;
        iminfo.channelResolution=zeros(1000,1); % was originally zeros(10, 1)
        iminfo.channelbytesinc=zeros(1000,1); % was originally zeros(10, 1)
        iminfo.filterblock=strings(10,1);
        iminfo.excitation=zeros(10,1);
        iminfo.emission=zeros(10,1);
        iminfo.sn=zeros(10,1);
        iminfo.mictype='';
        iminfo.mictype2='';
        iminfo.objective='';
        iminfo.na=0;
        iminfo.refractiveindex=0;
        iminfo.pinholeradius=250;

        serror='';
        
        %Channels
        xmlInfo = lifinfo.Image.ImageDescription.Channels.ChannelDescription;
        iminfo.channels=numel(xmlInfo);
        if iminfo.channels>1
            iminfo.isrgb=(str2double(char(xmlInfo{1}.Attributes.ChannelTag))~=0);
        end
        for k = 1:iminfo.channels
            if iminfo.channels>1
                iminfo.channelbytesinc(k)=str2double(char(xmlInfo{k}.Attributes.BytesInc));
                iminfo.channelResolution(k)=str2double(char(xmlInfo{k}.Attributes.Resolution));
                iminfo.lutname{k}=lower(char(xmlInfo{k}.Attributes.LUTName));
            else
                iminfo.channelbytesinc(k)=str2double(char(xmlInfo.Attributes.BytesInc));
                iminfo.channelResolution(k)=str2double(char(xmlInfo.Attributes.Resolution));
                iminfo.lutname{k}=lower(char(xmlInfo.Attributes.LUTName));
            end
        end
        %Dimensions and size
        iminfo.zs=1;
        xmlInfo = lifinfo.Image.ImageDescription.Dimensions.DimensionDescription;
        for k = 1:numel(xmlInfo)
            dim=str2double(xmlInfo{k}.Attributes.DimID);
            switch dim
                case 1
                    iminfo.xs=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.xres=str2double(xmlInfo{k}.Attributes.Length)/(iminfo.xs-1);
                    iminfo.xbytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
                    iminfo.resunit=char(xmlInfo{k}.Attributes.Unit);
                case 2
                    iminfo.ys=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.yres=str2double(xmlInfo{k}.Attributes.Length)/(iminfo.ys-1);
                    iminfo.ybytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
                case 3
                    iminfo.zs=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.zres=str2double(xmlInfo{k}.Attributes.Length)/(iminfo.zs-1);
                    iminfo.zbytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
                case 4
                    iminfo.ts=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.tres=str2double(xmlInfo{k}.Attributes.Length)/(iminfo.ts-1);
                    iminfo.tbytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
                case 10
                    iminfo.tiles=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.tilesbytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
            end
        end
        
        %TimeStamps
        if iminfo.ts>1
            %Get Timestamps and number of timestamps
            xmlInfo = lifinfo.Image.TimeStampList;
            if isfield(xmlInfo,'Attributes')
                lifinfo.numberoftimestamps=str2double(xmlInfo.Attributes.NumberOfTimeStamps);
                if lifinfo.numberoftimestamps>0
                    %Convert to date and time
                    ts=split(xmlInfo.Text,' ');
                    ts=ts(1:end-1);
                    tsd=datetime(datestr(now()),'TimeZone','Europe/Zurich');
                    for t=1:numel(ts)
                        tsd(t)=datetime(uint64(str2double(['0x' ts{t}])),'ConvertFrom','ntfs','TimeZone','Europe/Zurich');
                    end
                    %??? Timestamps ???
                    if iminfo.ts*iminfo.channels==lifinfo.numberoftimestamps
                        t=tsd(end-(iminfo.channels-1))-tsd(1);
                        iminfo.tres=seconds(t/(iminfo.ts-1));                
                    elseif iminfo.ts*iminfo.channels<lifinfo.numberoftimestamps
                        %Find Average Duration between events;
                        if iminfo.tiles>0
                            [~,a]=findpeaks(histcounts(tsd,iminfo.ts*iminfo.zs*iminfo.tiles));
                            c=numel(tsd)/(iminfo.ts*iminfo.zs*iminfo.tiles);
                            t=tsd(floor(a(end)*c))-tsd(floor(a(1)*c));
                        else
                            [~,a]=findpeaks(histcounts(tsd,iminfo.ts*iminfo.zs));
                            c=numel(tsd)/(iminfo.ts*iminfo.zs);
                            t=tsd(floor(a(end)*c))-tsd(floor(a(1)*c));
                        end
                        iminfo.tres=seconds(t/numel(a));
                    end
                end
            else % SP5??
                if isfield(xmlInfo,'TimeStamp')
                    lifinfo.numberoftimestamps=numel(xmlInfo.TimeStamp);
                end
            end
        end
        
        %Positions
        if iminfo.tiles>1
            if size(lifinfo.Image.Attachment,2)>=1
                if size(lifinfo.Image.Attachment,2)>1
                    for i=1:numel(lifinfo.Image.Attachment)
                        if strcmp(lifinfo.Image.Attachment{i}.Attributes.Name,'TileScanInfo')
                            xmlInfo = lifinfo.Image.Attachment{i};
                            break;
                        end
                    end
                elseif size(lifinfo.Image.Attachment,2)==1
                    if strcmp(lifinfo.Image.Attachment.Attributes.Name,'TileScanInfo')
                        xmlInfo = lifinfo.Image.Attachment;
                    end
                end
                for i=1:iminfo.tiles
                    iminfo.tile(i).num=i;
                    iminfo.tile(i).fieldx=str2double(xmlInfo.Tile{i}.Attributes.FieldX);
                    iminfo.tile(i).fieldy=str2double(xmlInfo.Tile{i}.Attributes.FieldY);
                    iminfo.tile(i).posx=str2double(xmlInfo.Tile{i}.Attributes.PosX);
                    iminfo.tile(i).posy=str2double(xmlInfo.Tile{i}.Attributes.PosY);
                end
                iminfo.tilex=struct;
                iminfo.tilex.xmin=min([iminfo.tile.posx]);
                iminfo.tilex.ymin=min([iminfo.tile.posy]);
                iminfo.tilex.xmax=max([iminfo.tile.posx]);
                iminfo.tilex.ymax=max([iminfo.tile.posy]);
            end
        end
        
        %Mic Type
        if isfield(lifinfo.Image,'Attachment')
            xmlInfo = lifinfo.Image.Attachment;
            for k = 1:numel(xmlInfo)
                if numel(xmlInfo)==1
                    xli=xmlInfo;
                else
                    xli=xmlInfo{k}; 
                end
                name=xli.Attributes.Name; 
                switch name
                    case 'HardwareSetting'
                        if strcmpi(xli.Attributes.DataSourceTypeName,'Confocal')
                            iminfo.mictype='IncohConfMicr';
                            iminfo.mictype2='confocal';
                            %Objective specs
                            thisInfo = xli.ATLConfocalSettingDefinition.Attributes;
                            iminfo.objective=thisInfo.ObjectiveName;  
                            iminfo.na=str2double(thisInfo.NumericalAperture);  
                            iminfo.refractiveindex=str2double(thisInfo.RefractionIndex');  
                            %Channel Excitation and Emission
                            thisInfo = xli.ATLConfocalSettingDefinition.Spectro;
                            for k1 = 1:numel(thisInfo.MultiBand)
                                iminfo.emission(k1)= str2double(thisInfo.MultiBand{k1}.Attributes.LeftWorld)+(str2double(thisInfo.MultiBand{k1}.Attributes.RightWorld)-str2double(thisInfo.MultiBand{k1}.Attributes.LeftWorld))/2;
                                iminfo.excitation(k1)= iminfo.emission(k1)-10;
                            end
                        elseif strcmpi(xli.Attributes.DataSourceTypeName,'Camera')
                            iminfo.mictype='IncohWFMicr';
                            iminfo.mictype2='widefield';
                        else
                            iminfo.mictype='unknown';
                            iminfo.mictype2='generic';
                        end
                        break;
                    case 'HardwareSettingList'
                        if strcmpi(xli.HardwareSetting.ScannerSetting.ScannerSettingRecord{1}.Attributes.Variant,'TCS SP5')
                            iminfo.mictype='IncohConfMicr';
                            iminfo.mictype2='confocal';
                            %Objective specs
                            iminfo.objective='HCX APO L U-V-I 63.0x0.90 WATER UV';  
                            iminfo.na=0.90;  
                            iminfo.refractiveindex=1.33;  
                            %Channel Excitation and Emission
                            for k1 = 1:1
                                iminfo.emission(1)= 520;
                                iminfo.excitation(1)= 488;
                            end
                        else
                            iminfo.mictype='unknown';
                            iminfo.mictype2='generic';
                        end
                        break;
                end
            end 
        else
            iminfo.mictype='unknown';
            iminfo.mictype2='generic';
        end
        %Widefield
        if strcmpi(iminfo.mictype,'IncohWFMicr')
            %Objective specs
            thisInfo = xli.ATLCameraSettingDefinition.Attributes;
            if isfield(iminfo,'ObjectiveName')
                iminfo.objective=thisInfo.ObjectiveName;  
            end
            if isfield(iminfo,'NumericalAperture')
                iminfo.na=str2double(thisInfo.NumericalAperture);  
            end
            if isfield(iminfo,'RefractionIndex')
                iminfo.refractiveindex=str2double(thisInfo.RefractionIndex');  
            end

            %Channel Excitation and Emission
            if isfield(xli.ATLCameraSettingDefinition,'WideFieldChannelConfigurator')
                thisInfo = xli.ATLCameraSettingDefinition.WideFieldChannelConfigurator;
                for k = 1:numel(thisInfo.WideFieldChannelInfo)
                    if numel(thisInfo.WideFieldChannelInfo)==1
                        FluoCubeName=thisInfo.WideFieldChannelInfo.Attributes.FluoCubeName;            
                    else
                        FluoCubeName=thisInfo.WideFieldChannelInfo{k}.Attributes.FluoCubeName;            
                    end
                    if numel(thisInfo.WideFieldChannelInfo)==1
                        if strcmpi(FluoCubeName,'QUAD-S')
                            ExName=thisInfo.WideFieldChannelInfo.Attributes.FFW_Excitation1FilterName;
                            iminfo.filterblock(k)=[FluoCubeName ': ' ExName];
                        elseif strcmpi(FluoCubeName,'DA/FI/TX')
                            ExName=thisInfo.WideFieldChannelInfo.Attributes.LUT;
                            iminfo.filterblock(k)=[FluoCubeName ': ' ExName];
                        else
                            ExName=FluoCubeName;
                            iminfo.filterblock(k)=FluoCubeName;
                        end
                    else
                        if strcmpi(FluoCubeName,'QUAD-S')
                            ExName=thisInfo.WideFieldChannelInfo{k}.Attributes.FFW_Excitation1FilterName;
                            iminfo.filterblock(k)=[FluoCubeName ': ' ExName];
                        elseif strcmpi(FluoCubeName,'DA/FI/TX')
                            ExName=thisInfo.WideFieldChannelInfo{k}.Attributes.UserDefName;
                            iminfo.filterblock(k)=[FluoCubeName ': ' ExName];
                        else
                            ExName=FluoCubeName;
                            iminfo.filterblock(k)=FluoCubeName;
                        end
                    end
                    if strcmpi(ExName,'DAPI') || strcmpi(ExName,'DAP') || strcmpi(ExName,'A') || strcmpi(ExName,'Blue')
                        iminfo.excitation(k)=355;
                        iminfo.emission(k)=460;
                    end
                    if strcmpi(ExName,'GFP') || strcmpi(ExName,'L5') || strcmpi(ExName,'I5') || strcmpi(ExName,'Green') || strcmpi(ExName,'FITC')
                        iminfo.excitation(k)=480;
                        iminfo.emission(k)=527;
                    end
                    if strcmpi(ExName,'N3') || strcmpi(ExName,'N2.1') || strcmpi(ExName,'TRITC')
                        iminfo.excitation(k)=545;
                        iminfo.emission(k)=605;
                    end
                    if strcmpi(ExName,'488')
                        iminfo.excitation(k)=488;
                        iminfo.emission(k)=525;
                    end
                    if strcmpi(ExName,'532')
                        iminfo.excitation(k)=532;
                        iminfo.emission(k)=550;
                    end                
                    if strcmpi(ExName,'642')
                        iminfo.excitation(k)=642;
                        iminfo.emission(k)=670;
                    end                
                    if strcmpi(ExName,'Red')
                        iminfo.excitation(k)=545;
                        iminfo.emission(k)=605;
                    end
                    if strcmpi(ExName,'Y3') || strcmpi(ExName,'I3') || strcmpi(ExName,'CY 3') || strcmpi(ExName,'CY3')
                        iminfo.excitation(k)=545;
                        iminfo.emission(k)=605;
                    end
                    if strcmpi(ExName,'Y5') || strcmpi(ExName,'CY5') || strcmpi(ExName,'CY 5')
                        iminfo.excitation(k)=590;
                        iminfo.emission(k)=670;
                    end
                end
            end
        end

        % Recalculate resolution to micrometer
        if strcmpi(iminfo.resunit,'meter') || strcmpi(iminfo.resunit,'m')
            iminfo.xres2=iminfo.xres*1000000;
            iminfo.yres2=iminfo.yres*1000000;
            iminfo.zres2=iminfo.zres*1000000;
        end
        if strcmpi(iminfo.resunit,'centimeter')
            iminfo.xres2=iminfo.xres*10000;
            iminfo.yres2=iminfo.yres*10000;
            iminfo.zres2=iminfo.zres*10000;
        end
        if strcmpi(iminfo.resunit,'inch')
            iminfo.xres2=iminfo.xres*25400;
            iminfo.yres2=iminfo.yres*25400;
            iminfo.zres2=iminfo.zres*25400;
        end
        if strcmpi(iminfo.resunit,'milimeter')
            iminfo.xres2=iminfo.xres*1000;
            iminfo.yres2=iminfo.yres*1000;
            iminfo.zres2=iminfo.zres*1000;
        end
        if strcmpi(iminfo.resunit,'micrometer')
            iminfo.xres2=iminfo.xres;
            iminfo.yres2=iminfo.yres;
            iminfo.zres2=iminfo.zres;
        end

    %             xmlTiles = xDoc.getElementsByTagName('Tile');
    %             if ~isempty(iminfo.tiles)
    %                 iminfo.tilelist=zeros(iminfo.tiles,2); % posx, posy
    %                 iminfo.tilemax=zeros(2,1);  % maxx and maxy
    %                 for k = 0:xmlTiles.getLength-1
    %                     thisTile = xmlTiles.item(k);
    %                     x=str2double(char(thisTile.getAttribute('FieldX')));
    %                     y=str2double(char(thisTile.getAttribute('FieldY')));
    %                     if x+1>iminfo.tilemax(1); iminfo.tilemax(1)=x+1;end
    %                     if y+1>iminfo.tilemax(2); iminfo.tilemax(2)=y+1;end
    %                     iminfo.tilelist(k+1,1)=x; iminfo.tilelist(k+1,2)=y;
    %                 end
    %                 xmlInfo = xDoc.getElementsByTagName('StitchingSettings');
    %                 thisInfo = xmlInfo.item(0);
    %                 iminfo.overlapprocx=str2double(char(thisInfo.getAttribute('OverlapPercentageX')));
    %                 iminfo.overlapprocy=str2double(char(thisInfo.getAttribute('OverlapPercentageY')));
    %             end
        result=true;
    elseif strcmpi(lifinfo.datatype,'eventlist')
        iminfo.channels=1;
        iminfo.NumberOfEvents=str2double(lifinfo.GISTEventList.GISTEventListDescription.NumberOfEvents.Attributes.NumberOfEventsValue);
        iminfo.Threshold=str2double(lifinfo.GISTEventList.GISTEventListDescription.LocalizationParameters.Attributes.Threshold);
        iminfo.Gain=str2double(lifinfo.GISTEventList.GISTEventListDescription.LocalizationParameters.Attributes.Gain);
        iminfo.FieldOfViewX=str2double(lifinfo.GISTEventList.GISTEventListDescription.LocalizationParameters.Attributes.FieldOfViewX2);
        iminfo.FieldOfViewY=str2double(lifinfo.GISTEventList.GISTEventListDescription.LocalizationParameters.Attributes.FieldOfViewY2);
        %s=cfXML2struct(cfXMLReadString(['<?xml version="1.0" encoding="ISO-8859-1"?>' lifinfo.GISTEventList.GISTEventListDescription.DataAnalysis.Attributes.XML3DCalibration]));
        serror='';  
        result=true;
    end
end


%%
function imdata = cfReadIm(lifinfo, iminfo, channel, z, t, tile)
    if strcmpi(lifinfo.filetype,".lif")
        % LIF
        fid=fopen(lifinfo.LIFFile,'r','n','UTF-8');

        p=iminfo.channelbytesinc(channel);
        p=p+(z-1)*iminfo.zbytesinc;
        p=p+(tile-1)*iminfo.tilesbytesinc;
        p=p+(t-1)*iminfo.tbytesinc;

        LIFOffset=lifinfo.Position;
        p=p+LIFOffset;

        fseek(fid,p,'bof');
        if iminfo.isrgb
            if iminfo.channelResolution(channel)==8
                imdata=fread(fid, iminfo.ys*iminfo.xs*3, '*uint8');
                redChannel = reshape(imdata(1:3:end), [iminfo.xs, iminfo.ys]);
                greenChannel = reshape(imdata(2:3:end), [iminfo.xs, iminfo.ys]);
                blueChannel = reshape(imdata(3:3:end), [iminfo.xs, iminfo.ys]);
                imdata = cat(3, redChannel, greenChannel, blueChannel);                
            else
                imdata=fread(fid, iminfo.ys*iminfo.xs*3, '*uint16');
                redChannel = reshape(imdata(1:3:end), [iminfo.xs, iminfo.ys]);
                greenChannel = reshape(imdata(2:3:end), [iminfo.xs, iminfo.ys]);
                blueChannel = reshape(imdata(3:3:end), [iminfo.xs, iminfo.ys]);
                imdata = cat(3, redChannel, greenChannel, blueChannel);                 
            end
            imdata=permute(imdata,[2 1 3]);
        else
            if iminfo.channelResolution(channel)==8
                imdata=fread(fid, [iminfo.xs,iminfo.ys], '*uint8');
            else
                imdata=fread(fid, [iminfo.xs,iminfo.ys], '*uint16');
            end
            imdata=transpose(imdata);  % correct orientation (for stitching)
        end
        fclose(fid);
    end
    if strcmpi(lifinfo.filetype,".xlef")
        % LOF
        fid=fopen(lifinfo.LOFFile,'r','n','UTF-8');

        p=iminfo.channelbytesinc(channel);
        p=p+(z-1)*iminfo.zbytesinc;
        p=p+(tile-1)*iminfo.tilesbytesinc;
        p=p+(t-1)*iminfo.tbytesinc;

        LIFOffset=62;  %4 + 4 + 1 + 4 + 30 (LMS_Object_File=2*15) + 1 + 4 + 1 + 4 + 1 + 8
        p=p+LIFOffset;

        fseek(fid,p,'bof');

        if iminfo.isrgb
            if iminfo.channelResolution(channel)==8
                imdata=fread(fid, iminfo.ys*iminfo.xs*3, '*uint8');
                redChannel = reshape(imdata(1:3:end), [iminfo.xs, iminfo.ys]);
                greenChannel = reshape(imdata(2:3:end), [iminfo.xs, iminfo.ys]);
                blueChannel = reshape(imdata(3:3:end), [iminfo.xs, iminfo.ys]);
                imdata = cat(3, redChannel, greenChannel, blueChannel);                
            else
                imdata=fread(fid, iminfo.ys*iminfo.xs*3, '*uint16');
                redChannel = reshape(imdata(1:3:end), [iminfo.xs, iminfo.ys]);
                greenChannel = reshape(imdata(2:3:end), [iminfo.xs, iminfo.ys]);
                blueChannel = reshape(imdata(3:3:end), [iminfo.xs, iminfo.ys]);
                imdata = cat(3, redChannel, greenChannel, blueChannel);                 
            end
            imdata=permute(imdata,[2 1 3]);
        else
            if iminfo.channelResolution(channel)==8
                imdata=fread(fid, [iminfo.xs,iminfo.ys], '*uint8');
            else
                imdata=fread(fid, [iminfo.xs,iminfo.ys], '*uint16');
            end
            imdata=transpose(imdata);  % correct orientation (for stitching)
        end
        fclose(fid);
    end
end


%%
function  outStruct  = cfXML2struct(input)
%XML2STRUCT converts xml file into a MATLAB structure
%
% outStruct = cfXML2struct(input)
% 
% xml2struct2 takes either a java xml object, an xml file, or a string in
% xml format as input and returns a parsed xml tree in structure. 
% 
% Please note that the following characters are substituted
% '-' by '_dash_', ':' by '_colon_' and '.' by '_dot_'
%
% Originally written by W. Falkena, ASTI, TUDelft, 21-08-2010
% Attribute parsing speed increase by 40% by A. Wanner, 14-6-2011
% Added CDATA support by I. Smirnov, 20-3-2012
% Modified by X. Mo, University of Wisconsin, 12-5-2012
% Modified by Chao-Yuan Yeh, August 2016

errorMsg = ['%s is not in a supported format.\n\nInput has to be',...
        ' a java xml object, an xml file, or a string in xml format.'];

% check if input is a java xml object
if isa(input, 'org.apache.xerces.dom.DeferredDocumentImpl') ||...
        isa(input, 'org.apache.xerces.dom.DeferredElementImpl')
    xDoc = input;
else
    try 
        if exist(input, 'file') == 2
            xDoc = xmlread(input);
        else
            try
                xDoc = xmlFromString(input);
            catch
                error(errorMsg, inputname(1));
            end
        end
    catch ME
        if strcmp(ME.identifier, 'MATLAB:UndefinedFunction')
            error(errorMsg, inputname(1));
        else
            rethrow(ME)
        end
    end
end

% parse xDoc into a MATLAB structure
outStruct = parseChildNodes(xDoc);
    
end

% ----- Local function parseChildNodes -----
function [children, ptext, textflag] = parseChildNodes(theNode)
% Recurse over node children.
children = struct;
ptext = struct; 
textflag = 'Text';

if hasChildNodes(theNode)
    childNodes = getChildNodes(theNode);
    numChildNodes = getLength(childNodes);

    for count = 1:numChildNodes

        theChild = item(childNodes,count-1);
        [text, name, attr, childs, textflag] = getNodeData(theChild);
        
        if ~strcmp(name,'#text') && ~strcmp(name,'#comment') && ...
                ~strcmp(name,'#cdata_dash_section')
            % XML allows the same elements to be defined multiple times,
            % put each in a different cell
            if (isfield(children,name))
                if (~iscell(children.(name)))
                    % put existsing element into cell format
                    children.(name) = {children.(name)};
                end
                index = length(children.(name))+1;
                % add new element
                children.(name){index} = childs;
                
                textfields = fieldnames(text);
                if ~isempty(textfields)
                    for ii = 1:length(textfields)
                        children.(name){index}.(textfields{ii}) = ...
                            text.(textfields{ii});
                    end
                end
                if(~isempty(attr)) 
                    children.(name){index}.('Attributes') = attr; 
                end
            else
                % add previously unknown (new) element to the structure
                
                children.(name) = childs;
                
                % add text data ( ptext returned by child node )
                textfields = fieldnames(text);
                if ~isempty(textfields)
                    for ii = 1:length(textfields)
                        children.(name).(textfields{ii}) = text.(textfields{ii});
                    end
                end

                if(~isempty(attr)) 
                    children.(name).('Attributes') = attr; 
                end
            end
        else
            ptextflag = 'Text';
            if (strcmp(name, '#cdata_dash_section'))
                ptextflag = 'CDATA';
            elseif (strcmp(name, '#comment'))
                ptextflag = 'Comment';
            end

            % this is the text in an element (i.e., the parentNode) 
            if (~isempty(regexprep(text.(textflag),'[\s]*','')))
                if (~isfield(ptext,ptextflag) || isempty(ptext.(ptextflag)))
                    ptext.(ptextflag) = text.(textflag);
                else
                    % This is what happens when document is like this:
                    % <element>Text <!--Comment--> More text</element>
                    %
                    % text will be appended to existing ptext
                    ptext.(ptextflag) = [ptext.(ptextflag) text.(textflag)];
                end
            end
        end

    end
end
end

% ----- Local function getNodeData -----
function [text,name,attr,childs,textflag] = getNodeData(theNode)
% Create structure of node info.

%make sure name is allowed as structure name
name = char(getNodeName(theNode));
name = strrep(name, '-', '_dash_');
name = strrep(name, ':', '_colon_');
name = strrep(name, '.', '_dot_');
name = strrep(name, '_', 'u_');

attr = parseAttributes(theNode);
if (isempty(fieldnames(attr))) 
    attr = []; 
end

%parse child nodes
[childs, text, textflag] = parseChildNodes(theNode);

% Get data from any childless nodes. This version is faster than below.
if isempty(fieldnames(childs)) && isempty(fieldnames(text))
    text.(textflag) = char(getTextContent(theNode));
end

% This alterative to the above 'if' block will also work but very slowly.
% if any(strcmp(methods(theNode),'getData'))
%   text.(textflag) = char(getData(theNode));
% end
    
end

% ----- Local function parseAttributes -----
function attributes = parseAttributes(theNode)
% Create attributes structure.
attributes = struct;
if hasAttributes(theNode)
   theAttributes = getAttributes(theNode);
   numAttributes = getLength(theAttributes);

   for count = 1:numAttributes
        % Suggestion of Adrian Wanner
        str = char(toString(item(theAttributes,count-1)));
        k = strfind(str,'='); 
        attr_name = str(1:(k(1)-1));
        attr_name = strrep(attr_name, '-', '_dash_');
        attr_name = strrep(attr_name, ':', '_colon_');
        attr_name = strrep(attr_name, '.', '_dot_');
        attributes.(attr_name) = str((k(1)+2):(end-1));
   end
end
end

% ----- Local function xmlFromString -----
function xmlroot = xmlFromString(iString)
import org.xml.sax.InputSource
import java.io.*

iSource = InputSource();
iSource.setCharacterStream(StringReader(iString));
xmlroot = xmlread(iSource);
end


%%
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
end


