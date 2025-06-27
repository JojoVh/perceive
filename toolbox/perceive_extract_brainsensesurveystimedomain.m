function alldata = perceive_extract_brainsensesurveystimedomain(data, hdr)

% extraction of BrainSenseSurveysTimeDomain data (BSTD) into FieldTrip-like format
%
% inputs:
%   data - input data struct from Percept JSON
%   hdr - header struct with fields like hdr.d0, hdr.chan, hdr.fpath, etc.
%
% output:
%   alldata

alldata={};
ElectrodeSurvey=data{1};
ElectrodeIdentifier=data{2};
assert(strcmp(ElectrodeSurvey.SurveyMode,'ElectrodeSurvey'))
assert(strcmp(ElectrodeIdentifier.SurveyMode,'ElectrodeIdentifier'))

if ~isfield(hdr.js, 'LfpMontageTimeDomain') %ElectrodeSurvey is the same as LMTD
    data=ElectrodeSurvey.ElectrodeSurvey;

    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
    runs = unique(FirstPacketDateTime);

    [tmp1]=split({data(:).Channel}', regexpPattern("(_AND_)|((?<!.*_.*)_(?!.*_AND_.*))"));
    ch1 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,1),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_A','A'),'_B','B'),'_C','C'); % ch1 replaces ZERO to int 0 etc of first part before AND (tmp1(:,1))
    ch2 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,2),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'LEFTS','L'),'RIGHTS','R'),'_A','A'),'_B','B'),'_C','C'); % ch2 replaces ZERO to int 0 etc of second part after AND (tmp1(:,1))

    % side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
    % Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
    Channel = strcat(hdr.chan,'_', ch1,'_', ch2); % taken out "side" so RIGHT and LEFT will stay the same, no transformation to R and L

    fsample = data.SampleRateInHz;

    if length(runs)>1 %assert that data is not empty
        for c = 1:length(runs)
            i=perceive_ci(runs{c},FirstPacketDateTime);
            d=[];
            d.hdr = hdr;
            d.datatype = 'BrainSenseSurveysTimeDomain';
            d.fsample = fsample;
            tmp = [data(i).TimeDomainDatainMicroVolts]';
            d.trial{1} = [tmp];
            d.label=Channel(i);
            d.hdr.label = d.label;
            d.hdr.Fs = d.fsample;
            d.time=linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
            d.time={d.time};
            mod = 'mod-ES';
            mod_ext=perceive_check_mod_ext(d.label);
            mod = [mod mod_ext];
            d.fname = [hdr.fname '_' mod];
            d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss')), '_',num2str(c)];
            % TODO: set if needed:
            %d.keepfig = false; % do not keep figure with this signal open
            %d=call_ecg_cleaning(d,hdr,d.trial{1});
            perceive_plot_raw_signals(d);
            perceive_print(fullfile(hdr.fpath,d.fname));
            alldata{length(alldata)+1} = d;
        end
    end
end
data=ElectrodeIdentifier.ElectrodeIdentifier;
for c = 1:length(data)
    str=data(c).Channel;
    str=strrep(str, 'ELECTRODE_', '');
    data(c).Channel = [str '_' upper(data(c).Hemisphere) ];
end

FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
runs = unique(FirstPacketDateTime);

[tmp1]=split({data(:).Channel}', regexpPattern("(_AND_)|((?<!.*_.*)_(?!.*_AND_.*))"));
ch1 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,1),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_A','A'),'_B','B'),'_C','C'); % ch1 replaces ZERO to int 0 etc of first part before AND (tmp1(:,1))
ch2 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,2),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'LEFTS','L'),'RIGHTS','R'),'_A','A'),'_B','B'),'_C','C'); % ch2 replaces ZERO to int 0 etc of second part after AND (tmp1(:,1))

% side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
% Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
Channel = strcat(hdr.chan,'_', ch1,'_', ch2); % taken out "side" so RIGHT and LEFT will stay the same, no transformation to R and L

fsample = data.SampleRateInHz;
if length(runs)>1 %assert that data is not empty
    for c = 1:length(runs)
        i=perceive_ci(runs{c},FirstPacketDateTime);
        d=[];
        d.hdr = hdr;
        d.datatype = 'BrainSenseSurveysTimeDomain';
        d.fsample = fsample;
        tmp = [data(i).TimeDomainDatainMicroVolts]';
        d.trial{1} = [tmp];
        d.label=Channel(i);
        d.hdr.label = d.label;
        d.hdr.Fs = d.fsample;
        d.time=linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
        d.time={d.time};
        mod = 'mod-EI';
        mod_ext=perceive_check_mod_ext(d.label);
        mod = [mod mod_ext];
        d.fname = [hdr.fname '_' mod];
        d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss')), '_',num2str(c)];
        % TODO: set if needed:
        %d.keepfig = false; % do not keep figure with this signal open
        %d=perceive_call_ecg_cleaning(d,hdr,d.trial{1});
        perceive_plot_raw_signals(d);
        perceive_print(fullfile(hdr.fpath,d.fname));
        alldata{length(alldata)+1} = d;
    end
end
end