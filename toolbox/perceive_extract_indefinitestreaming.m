function alldata = perceive_extract_indefinitestreaming(data, hdr, config)

alldata = {};
FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
runs = unique(FirstPacketDateTime);
fsample = data.SampleRateInHz;

Pass = {data(:).Pass};
tmp =  {data(:).GlobalSequences};
for c = 1:length(tmp) %missing
    GlobalSequences{c,:} = str2num(tmp{c});
    missingPackages{c,:} = (diff(str2num(tmp{c}))==2);
    nummissinPackages(c) = numel(find(diff(str2num(tmp{c}))==2));
end
tmp =  {data(:).TicksInMses};
for c = 1:length(tmp)
    TicksInMses{c,:}          = str2num(tmp{c});
    TicksInS_temp             = (TicksInMses{c,:} - TicksInMses{c,:}(1))/1000;
    [TicksInS_temp,~,ci_temp] = unique(TicksInS_temp);
    TicksInS{c,:}             = TicksInS_temp;
    ci{c,:}                   = ci_temp;
end

tmp =  {data(:).GlobalPacketSizes};
for c = 1:length(tmp) %missing
    GlobalPacketSizes_temp = str2num(tmp{c});
    for kk=1:max(ci{c,:})
        GPS_temp(kk)=sum(GlobalPacketSizes_temp(find(ci{c,:}==kk)));
    end
    GlobalPacketSizes{c,:} = GPS_temp;
    isDataMissing(c)       = logical(TicksInS{c,:}(end) >= sum(GlobalPacketSizes{c,:})/fsample);
    time_real{c,:}         = TicksInS{c,:}(1):1/fsample:TicksInS{c,:}(end)+(GlobalPacketSizes{c,:}(end)-1)/fsample;
    time_real{c,:}         = round(time_real{c,:},3);
end

%gain=[data(:).Gain]';
[tmp1,tmp2] = strtok(strrep({data(:).Channel}','_AND',''),'_');
ch1 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');

[tmp1,tmp2] = strtok(tmp2,'_');
ch2 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);

for c = 1:length(runs)
    i=perceive_ci(runs{c},FirstPacketDateTime);
    d=[];
    d.hdr = hdr;
    d.datatype = 'IndefiniteStreaming';
    d.hdr.IS.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
    d.hdr.IS.GlobalSequences=GlobalSequences(i,:);
    d.hdr.IS.GlobalPacketSizes=GlobalPacketSizes(i,:);
    d.hdr.IS.FirstPacketDateTime = runs{c};
    x=find(ismember(i, find(isDataMissing)));
    if ~isempty(x)
        warning('missing packages detected, will interpolate to replace missing data') %missing
        try
            for k=1:numel(x)
                isReceived = zeros(size(time_real{i(k),:}, 2), 1);
                nPackets = numel(GlobalPacketSizes{i(k),:});
                for packetId = 1:nPackets
                    timeTicksDistance = abs(time_real{i(k),:} - TicksInS{i(k),:}(packetId));
                    [~, packetIdx] = min(timeTicksDistance);
                    if isReceived(packetIdx) == 1
                        packetIdx = packetIdx +1;
                    end
                    %                                     if packetIdx+GlobalPacketSizes{i(k),:}(packetId)-1>size(isReceived,1)
                    %                                         cut_sampl=size(isReceived,1)-packetIdx+GlobalPacketSizes{i(k),:}(packetId);
                    %                                         isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-cut_sampl) = isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-cut_sampl)+1;
                    %                                     else
                    isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-1) = isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-1)+1;
                    %             figure; plot(isReceived, '.'); yticks([0 1]); yticklabels({'not received', 'received'}); ylim([-1 10])
                    %                                     end
                end

                %If there are pseudo double-received samples, compensate non-received samples
                %                                 numel(find(logical(isReceived)))+nDoubles
                doublesIdx = find(isReceived == 2);
                nDoubles = numel(doublesIdx);
                for doubleId = 1:nDoubles
                    missingIdx = find(isReceived == 0);
                    [~, idxOfidx] = min(abs(missingIdx - doublesIdx(doubleId)));
                    isReceived(missingIdx(idxOfidx)) = 1;
                    isReceived(doublesIdx(doubleId)) = 1;
                end

                data_temp = NaN(size(time_real{i(k),:}, 2), 1);
                data_temp(logical(isReceived), :) = data(i(k)).TimeDomainData;
                ind_interp=find(diff(isReceived));
                if isReceived(ind_interp(1)+1)==1
                    ind_interp=[1 ind_interp];
                    data_temp(1)=0;
                end
                if isReceived(ind_interp(end)+1)==0
                    ind_interp=[ind_interp size(data_temp,1)-1];
                    data_temp(end)=0;
                end
                for mm=1:2:numel(ind_interp/2)
                    data_temp(ind_interp(mm)+1:ind_interp(mm+1))=...
                        linspace(data_temp(ind_interp(mm)), data_temp(ind_interp(mm+1)+1), ind_interp(mm+1)-ind_interp(mm));
                end
                raw_temp(x(k),:)=data_temp';
            end
            tmp=raw_temp;
        catch
            warning('The missing packages could not be computed. Interpolation failed.') %missing
        end
    else
        tmp=[data(i).TimeDomainData]';
    end

    try
        xchans = perceive_ci({'L_03','L_13','L_02','R_03','R_13','R_02'},Channel(i));
        nchans = {'L_01','L_12','L_23','R_01','R_12','R_23'};
        refraw = [tmp(xchans(1),:)-tmp(xchans(2),:);(tmp(xchans(1),:)-tmp(xchans(2),:))-tmp(xchans(3),:);tmp(xchans(3),:)-tmp(xchans(1),:);
            tmp(xchans(4),:)-tmp(xchans(5),:);(tmp(xchans(4),:)-tmp(xchans(5),:))-tmp(xchans(6),:);tmp(xchans(6),:)-tmp(xchans(4),:)];
        d.trial{1} = [tmp;-refraw;];
    catch
        d.trial{1} = [tmp];
        warning('The calculated packages could not be added. Data for Indefinite Streaming failed.')
    end

    d.label=[Channel(i);strcat(hdr.chan,'_',nchans')];

    % NEW
    d.time{1} = timeofday(datetime(runs{c},'InputFormat','yyyy-MM-dd HH:mm:ss.SSS')) ...
        + seconds( linspace(0, (size(d.trial{1},2)-1)/fsample, size(d.trial{1},2)) );
    % OLD
    %d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));

    %TO DO: replace d.time by timeofday(runs{c})) =>
    %done!. Now I need to write check function for all
    %places where hdr.d0 is replaced by runs(c) or
    %equivalent
    d_run = datetime(runs{c}(1:10));   % nur YYYY-MM-DD
    d_hdr = dateshift(hdr.SessionEndDate, 'start', 'day');


    if ~isequal(d_run, d_hdr)
        error('Header:SessionDateMismatch', ...
            ['SessionDate and SessionEndDate do not match the ', ...
            'FirstPackageDateTime of this run.\n', ...
            'FirstPackage date: %s\n', ...
            'hdr.d0 date:       %s'], ...
            char(d_run), char(d_hdr));
    end


    d.fsample = fsample;
    %firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
    firstsample = set_firstsample(data(c).TicksInMses);
    lastsample = firstsample+size(d.trial{1},2);
    d.sampleinfo(1,:) = [firstsample lastsample];
    d.trialinfo(1) = c;
    d.hdr.label=d.label;
    d.hdr.Fs = d.fsample;
    mod = 'mod-ISRing';
    d.fname = [hdr.fname '_' mod];
    d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss'))];
    % TODO: set if needed:
    %d.keepfig = false; % do not keep figure with this signal open
    if config.ecg_cleaning
        d=call_ecg_cleaning(d,hdr,d.trial{1});
    end
    alldata{length(alldata)+1} = d;
end

end
%function
%end