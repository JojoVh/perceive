function [alldata, list_of_BSL] = perceive_extract_bsl(data, hdr)

% extracts BrainSense LFP data into FieldTrip-compatible structures
%
% inputs:
%   data: struct from BrainSenseLfp JSON
%   hdr: metadata header (subject, session, file path, etc.)
%
% outputs:
%   alldata: cell array of FieldTrip structs
%   counterBSL: number of BSL blocks extracted

alldata = {};
counterBSL = 0;
list_of_BSL = {};

runs_FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
assert(isequal(runs_FirstPacketDateTime , unique(runs_FirstPacketDateTime)));
if ~isequal(length(runs_FirstPacketDateTime), length(data))
    error('Amount of unique FirstPackageTimeStamps (runs = %d) is not the same as amount of data entries (data = %d) in BrainSenseLFP.', ...
        length(runs_FirstPacketDateTime), length(data));
    % How to solve this issue: make sure that the iterator c goes over all
    % FirstPacketDateTimes and is not allocating wrong data to cdata.
    % Have c = 1:length(data) instead.
end

for js_element = 1:length(runs_FirstPacketDateTime)

    cdata = data(js_element);
    tmp = strrep(cdata.Channel,'_AND','');
    tmp = strsplit(strrep(strrep(strrep(strrep(strrep(tmp,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''),',');

    if length(tmp)==2
        lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2)], ...
                       [hdr.chan '_' tmp{2}(3) '_' tmp{2}(1:2)]};
    elseif length(tmp)==1
        lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2)]};
    else
        error('Unsupported number of channels in BrainSenseLfp: %d', length(tmp));
    end

    d = [];
    d.hdr = hdr;
    d.FirstPacketDateTime = runs_FirstPacketDateTime{js_element};
    d.hdr.BSL.TherapySnapshot = cdata.TherapySnapshot;
    lfpsettings = cell(2,1);
    stimchannels = cell(2,1);
    acq_stimcontact = '';
    acq_freq = '';
    acq_pulse = '';

    % LEFT
    if isfield(d.hdr.BSL.TherapySnapshot, 'Left')
        tmp = d.hdr.BSL.TherapySnapshot.Left;
        lfpsettings{1} = sprintf('PEAK%dHz_THR%d-%d_AVG%dms', ...
            round(tmp.FrequencyInHertz), tmp.LowerLfpThreshold, ...
            tmp.UpperLfpThreshold, round(tmp.AveragingDurationInMilliSeconds));
        stimchannels{1} = sprintf('STIM_L_%dHz_%dus', tmp.RateInHertz, tmp.PulseWidthInMicroSecond);
        if isfield(tmp, 'ElectrodeState')
            for el = 1:length(tmp.ElectrodeState)
                elstate = tmp.ElectrodeState{el};
                if isfield(elstate,'ElectrodeAmplitudeInMilliAmps') && elstate.ElectrodeAmplitudeInMilliAmps > 0.5

                    acq_stimcontact_number = regexp(elstate.Electrode, '.*_(.+)$', 'tokens'); %take the number of the electrode e.g. 4b
                    acq_stimcontact = [acq_stimcontact , acq_stimcontact_number{1}{1}];
                end
            end
            acq_freq = [num2str(tmp.RateInHertz) 'Hz'];
            acq_pulse = [num2str(tmp.PulseWidthInMicroSecond) 'us'];
        end
    else
        lfpsettings{1} = 'LFP n/a';
        stimchannels{1} = 'STIM n/a';
    end

    % RIGHT
    if isfield(d.hdr.BSL.TherapySnapshot, 'Right')
        tmp = d.hdr.BSL.TherapySnapshot.Right;
        lfpsettings{2} = sprintf('PEAK%dHz_THR%d-%d_AVG%dms', ...
            round(tmp.FrequencyInHertz), tmp.LowerLfpThreshold, ...
            tmp.UpperLfpThreshold, round(tmp.AveragingDurationInMilliSeconds));
        stimchannels{2} = sprintf('STIM_R_%dHz_%dus', tmp.RateInHertz, tmp.PulseWidthInMicroSecond);
        if isfield(tmp, 'ElectrodeState')

            for el = 1:length(tmp.ElectrodeState)
                elstate = tmp.ElectrodeState{el};
                if isfield(elstate,'ElectrodeAmplitudeInMilliAmps') && elstate.ElectrodeAmplitudeInMilliAmps > 0.5
                    acq_stimcontact_number = regexp(elstate.Electrode, '.*_(.+)$', 'tokens'); %take the number of the electrode e.g. 4b
                    acq_stimcontact = [acq_stimcontact , acq_stimcontact_number{1}{1}];
                end
            end
        end
        %overwrite left side, take default of right side
        acq_freq = [num2str(tmp.RateInHertz) 'Hz'];
        acq_pulse = [num2str(tmp.PulseWidthInMicroSecond) 'us'];
        
    else
        lfpsettings{2} = 'LFP n/a';
        stimchannels{2} = 'STIM n/a';
    end

    d.label = [strcat(lfpchannels','_',lfpsettings)' stimchannels'];
    d.hdr.label = d.label;

    d.fsample = cdata.SampleRateInHz;
    d.hdr.Fs = d.fsample;

    tstartInSecs_of_TicksInMs = cdata.LfpData(1).TicksInMs / 1000;
    for e = 1:length(cdata.LfpData)
        d.trial{1}(1:2,e) = [cdata.LfpData(e).Left.LFP; cdata.LfpData(e).Right.LFP];
        d.trial{1}(3:4,e) = [cdata.LfpData(e).Left.mA; cdata.LfpData(e).Right.mA];
        d.time{1}(e) = seconds(timeofday(datetime(runs_FirstPacketDateTime{js_element}))) + ...
               ((cdata.LfpData(e).TicksInMs/1000) - tstartInSecs_of_TicksInMs);
        d.time{1}(e) = (cdata.LfpData(e).TicksInMs - cdata.LfpData(1).TicksInMs) / 1000; %this is a cleaner solution
        
        % OLD
        %d.time{1}(e) = seconds(datetime(runs{c},'InputFormat','yyyy-MM-dd HH:mm:ss.SSS') - hdr.d0) ...
        %              + ((cdata.LfpData(e).TicksInMs/1000) - tstart_TicksInMs);
        %% check the time: subtraction of hdr.d0 should not be necessary and could lead to errors with js.AbnormalEnd = true
        % hdr.d0 = datetime(js.DeviceInformation.Final.DeviceDateTime(1:10))
            % or in case of errors
        % hdr.0 = datetime(js.SessionEndDate(1:10))
            % see further perceive_extract_hdr
        % t = datetime(runs{c}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
        % timeOnly = timeofday(t);
        % secondsValue = seconds(timeOnly);
        % %assert(isequal(secondsValue,seconds(datetime(runs{c},'InputFormat','yyyy-MM-dd HH:mm:ss.SSS') - hdr.d0)))
        % d_run = datetime(runs{c}(1:10));   % nur YYYY-MM-DD
        % d_hdr = dateshift(hdr.d0, 'start', 'day');
        % 
        % if ~isequal(d_run, d_hdr)
        %     error('Header:SessionDateMismatch', ...
        %         ['SessionDate and SessionEndDate do not match the ', ...
        %         'FirstPackageDateTime of this run.\n', ...
        %         'FirstPackage date: %s\n', ...
        %         'hdr.d0 date:       %s'], ...
        %         char(d_run), char(d_hdr));
        % end

        %%
        d.realtime(e) = datetime(runs_FirstPacketDateTime{js_element},'InputFormat','yyyy-MM-dd HH:mm:ss.SSS','Format','yyyy-MM-dd HH:mm:ss.SSS') ...
                + seconds(d.time{1}(e)) - seconds(d.time{1}(1));

        d.TicksInMs(e) = cdata.LfpData(e).TicksInMs; %this is the TicksInMs and is a solid alternative, as it is not (re)calculated, but raw data from js
        d.hdr.BSL.seq(e) = cdata.LfpData(e).Seq;
    end

    d.trialinfo(1) = js_element;
    d.hdr.realtime = d.realtime;

    counterBSL = counterBSL + 1;
    js_element_nr = js_element-1;
    mod = ['mod-BSL' num2str(js_element_nr)];
    d.fname = [hdr.fname '_' mod];
    %d.fname = strrep(d.fname, 'task-Rest', ['task-TASK' num2str(counterBSL)]);
    d.fname = strrep(d.fname, 'task-Rest', 'task-TASK');
    list_of_BSL{end+1} = d.fname;

    if contains(d.label{3}, 'STIM_L')
        LAmp = d.trial{1}(3,:);
    elseif contains(d.label{4}, 'STIM_L')
        LAmp = d.trial{1}(4,:);
    else
        LAmp = 0;
    end

    if contains(d.label{3}, 'STIM_R')
        RAmp = d.trial{1}(3,:);
    elseif contains(d.label{4}, 'STIM_R')
        RAmp = d.trial{1}(4,:);
    else
        RAmp = 0;
    end

    acq = perceive_check_stim(LAmp, RAmp, d.hdr);
    if ~strcmp(acq,'StimOff')
        acq = [acq, acq_stimcontact, acq_freq, acq_pulse];
    end
    assert(ischar(acq));

    d.fname = perceive_updateAcq(d.fname, acq);
    d.fnamedate = char(datetime(runs_FirstPacketDateTime{js_element},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss'));

    alldata{end+1} = d;

end

end

