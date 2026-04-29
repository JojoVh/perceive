function alldata = perceive_extract_sensechanneltests(data, hdr, config)
% perceive_extract_sensechanneltests Extracts and organizes SenseChannelTests data from input structure
%
% Inputs:
%   data        - Structure array with fields including FirstPacketDateTime, Pass,
%                 GlobalSequences, GlobalPacketSizes, TimeDomainData, SampleRateInHz,
%                 Gain, Channel, TicksInMses, etc.
%   hdr         - Header structure with fields like chan, fname, etc.
%
% Output:
%   alldata     - Cell array of structures, each containing processed trial data and metadata

% Replace 'T' and 'Z' in FirstPacketDateTime strings for datetime conversion
FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime}, 'T', ' '), 'Z', '');
runs = unique(FirstPacketDateTime);

% Initialize header date from first run date
hdr.scd0 = datetime(FirstPacketDateTime{1}(1:10));

% Extract Pass information
Pass = {data(:).Pass};

% Convert GlobalSequences strings to numeric arrays
tmp = {data(:).GlobalSequences};
GlobalSequences = cell(size(tmp));
for c = 1:length(tmp)
    GlobalSequences{c,:} = str2num(tmp{c}); %#ok<ST2NM>
end

% Convert GlobalPacketSizes strings to numeric arrays
tmp = {data(:).GlobalPacketSizes};
GlobalPacketSizes = cell(size(tmp));
for c = 1:length(tmp)
    GlobalPacketSizes{c,:} = str2num(tmp{c}); %#ok<ST2NM>
end

% Extract raw time domain data matrix (rows = trials)
raw = [data(:).TimeDomainData]';

% Sampling frequency (assumed constant across data)
fsample = data(1).SampleRateInHz;

% Gain vector
gain = [data(:).Gain]';

% Channel string processing
[tmp1, tmp2] = strtok(strrep({data(:).Channel}', '_AND', ''), '_');
ch1 = strrep(strrep(strrep(strrep(tmp1, 'ZERO', '0'), 'ONE', '1'), 'TWO', '2'), 'THREE', '3');
[tmp1, tmp2] = strtok(tmp2, '_');
ch2 = strrep(strrep(strrep(strrep(tmp1, 'ZERO', '0'), 'ONE', '1'), 'TWO', '2'), 'THREE', '3');
side = strrep(strrep(strtok(tmp2, '_'), 'LEFT', 'L'), 'RIGHT', 'R');
Channel = strcat(hdr.chan, '_', side, '_', ch1, ch2);

alldata = {}; % Initialize output

for c = 1:length(runs)
    % Get indices for current run
    i = perceive_ci(runs{c}, FirstPacketDateTime);
    
    d = struct();
    d.hdr = hdr;
    d.datatype = 'SenseChannelTests';
    
    % Process Pass strings for current indices
    d.hdr.IS.Pass = strrep(strrep(unique(strtok(Pass(i), '_')), 'FIRST', '1'), 'SECOND', '2');
    
    % Extract GlobalSequences and GlobalPacketSizes for current indices
    d.hdr.IS.GlobalSequences = GlobalSequences(i,:);
    d.hdr.IS.GlobalPacketSizes = GlobalPacketSizes(i,:);
    
    d.hdr.IS.FirstPacketDateTime = runs{c};
    
    % Extract raw data for current indices
    tmpData = raw(i,:);
    d.trial{1} = tmpData;
    
    % Channel labels for current indices
    d.label = Channel(i);
    
    % Calculate time vector for the trial
    runTime = datetime(runs{c}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    d.time{1} = linspace(seconds(runTime - hdr.scd0), ...
                        seconds(runTime - hdr.scd0) + size(d.trial{1}, 2) / fsample, ...
                        size(d.trial{1}, 2));
    
    d.fsample = fsample;
    
    % Determine first and last sample indices based on TicksInMses (assumed helper function)
    firstsample = set_firstsample(data(c).TicksInMses);
    lastsample = firstsample + size(d.trial{1}, 2) - 1;
    d.sampleinfo(1,:) = [firstsample lastsample];
    
    d.trialinfo(1) = c;
    
    d.hdr.label = d.label;
    d.hdr.Fs = d.fsample;
    
    % Construct filename
    d.fname = [hdr.fname '_run-SCT' char(runTime, 'yyyyMMddHHmmss')];
    
    % Append to output cell array
    alldata{end+1} = d;
end

end
