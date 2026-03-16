function alldata_bstd = perceive_extract_bstd(data, hdr, config)

% extracts BrainSense Time Domain (BSTD) data into FieldTrip-compatible structures
%
% inputs:
%   data: struct from BrainSenseTimeDomain JSON
%   hdr: metadata header (subject, session, file path, etc.)
%   config: configuration options (e.g. enable ECG cleaning)
%
% outputs:
%   alldata_bstd: cell array of FieldTrip structs, one per BSTD run
%
% description:
%   Parses each BSTD recording run, reconstructs time vectors using TicksInMses and
%   GlobalPacketSizes, builds FieldTrip-compatible trial structs (`d`) with appropriate
%   sampleinfo, labels, timestamps, and metadata. Handles stimulation metadata and
%   optional ECG cleaning (via `call_ecg_cleaning`). Each output `d` is added to `alldata_bstd`.
%
% notes:
%   - Assumes 'runs' are grouped by unique FirstPacketDateTime.
%   - Time is reconstructed relative to hdr.d0 (session reference datetime).


%mod = 'mod-BSTD';
fsample = data.SampleRateInHz;
runs_FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime}, 'T', ' '), 'Z', '');
runs = unique(runs_FirstPacketDateTime);

Pass = {data(:).Pass};
GlobalSequences = cell(size(data));
GlobalPacketSizes = cell(size(data));
TicksInS = cell(size(data));
time_real = cell(size(data));
alldata_bstd = {};

% parse meta fields
for idxData = 1:length(data)
    GlobalSequences{idxData} = str2num(data(idxData).GlobalSequences); %#ok<ST2NM>
    TicksInMs = str2num(data(idxData).TicksInMses); %#ok<ST2NM>
    TicksInS{idxData} = (TicksInMs - TicksInMs(1)) / 1000;
    GlobalPacketSizes{idxData} = str2num(data(idxData).GlobalPacketSizes); %#ok<ST2NM>
    time_real{idxData} = TicksInS{idxData}(1):1/fsample:TicksInS{idxData}(end) + (GlobalPacketSizes{idxData}(end) - 1)/fsample; %time real needs to be updated
    time_real{idxData} = round(time_real{idxData}, 3);
end

% parse channel info
[tmp1, tmp2] = strtok(strrep({data(:).Channel}', '_AND', ''), '_');
ch1 = regexprep(tmp1, {'ZERO', 'ONE', 'TWO', 'THREE'}, {'0', '1', '2', '3'});
[tmp1, tmp2] = strtok(tmp2, '_');
ch2 = regexprep(tmp1, {'ZERO', 'ONE', 'TWO', 'THREE'}, {'0', '1', '2', '3'});
side = strrep(strrep(strtok(tmp2, '_'), 'LEFT', 'L'), 'RIGHT', 'R');
Channel = strcat(hdr.chan, '_', side, '_', ch1, ch2);

already_processed = datetime.empty;   % store timestamps we've already processed

for js_element = 1:numel(runs_FirstPacketDateTime)

    % Convert cell string → datetime
    t = datetime(runs_FirstPacketDateTime{js_element}, 'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');

    % Check if we already processed this timestamp
    if any(t == already_processed)
        continue   % skip duplicates
    end

    % Mark this timestamp as processed
    already_processed(end+1) = t;

    i = perceive_ci(runs_FirstPacketDateTime{js_element}, runs_FirstPacketDateTime); %what does this function do?

    if i > 1
        % Collect TimeDomainData for all indices in i into a cell array
        tdCells = {data(i).TimeDomainData};   % 1 x n cell

        % Compute lengths of each TimeDomainData entry
        tdLengths = cellfun(@numel, tdCells);

        % Check if all lengths are equal
        if numel(unique(tdLengths)) == 1
            % All equal -> proceed normally
            raw1 = [tdCells{:}]';   % concatenate and transpose
        else
            % Lengths differ -> use fallback
            raw1 = NaNfallback(data, i);
        end
    else
        %i is 1 or less
        raw1 = [data(i).TimeDomainData]';
    end

    d = struct();
    d.hdr = hdr;
    d.datatype = 'BrainSenseTimeDomain';
    d.hdr.CT.Pass = strrep(strrep(unique(strtok(Pass(i), '_')), 'FIRST', '1'), 'SECOND', '2');
    d.hdr.CT.GlobalSequences = GlobalSequences(i);
    d.hdr.CT.GlobalPacketSizes = GlobalPacketSizes(i);
    d.FirstPacketDateTime = runs_FirstPacketDateTime{js_element}; %check here the FirstPacketDateTime
    d.label = Channel(i);
    d.trial{1} = raw1;
    d.fsample = fsample;

    t0 = datetime(runs_FirstPacketDateTime{js_element}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');

    % OLD
    %rel_start = seconds(t0 - hdr.d0);
    %d.timeInSecDerivedFromIdealSampleRate{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2));

    % NEW 1 (drop the d0 time, and replace it with the timeofday of the current run)
    rel_start = seconds(timeofday(t0));
    d.time{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2)); %update the time! This cannot be correct
    d.time_real = time_real{i(1)};

    % NEW 2 (replace the linspace time with the times in milliseconds
    % derived from Ticks

    % Compute timestamps
    [d.timeInSecDerivedFromTicks, d.timerealDerivedFromTicks] = computePerceptTimestamps(TicksInS{i(1)}, GlobalPacketSizes{i(1)}, fsample, runs_FirstPacketDateTime{i(1)});

    % NEW 3: keep a linear time, starting at t0 = 0;
    d.timeInSecDerivedFromIdealSampleRate{1} = linspace(0, size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2));

    %% now do assertions:
    %% 1. Basic length checks
    assert(length(d.trial{1}) == length(d.timeInSecDerivedFromTicks), ...
        'Tick-derived timeline length does not match number of samples')

    assert(length(d.trial{1}) == length(d.timeInSecDerivedFromIdealSampleRate{1}), ...
        'Old synthetic timeline length does not match number of samples')

    %% 2. Packet size consistency
    assert(sum(GlobalPacketSizes{i(1)}) == length(d.trial{1}), ...
        'Sum of packet sizes does not match number of samples')

    %% 3. Monotonicity of tick timestamps
    assert(all(diff(TicksInS{i(1)}) >= 0), ...
        'TicksInS is not monotonic — packet timestamp disorder detected')

    %% 4. Check sampling rate from tick-derived timeline
    dt_tick = diff(d.timeInSecDerivedFromTicks);
    fs_tick = 1/median(dt_tick);

    assert(abs(fs_tick - fsample) < 0.5, ...
        sprintf('Tick-derived sampling rate deviates from expected: %.3f Hz', fs_tick))

    %% 5. Check sampling rate from old timeline
    dt_old = diff(d.timeInSecDerivedFromIdealSampleRate{1});
    fs_old = 1/median(dt_old);

    if abs(fs_old - fsample) < 1, ...
            warning('Old synthetic sampling rate deviates from expected: %.3f Hz', fs_old)
    end

    %% 6. Packet gap detection (corrected to use TicksInS{i(1)})
    packetStartSec = TicksInS{i(1)};
    expectedPacketEnd = packetStartSec + (GlobalPacketSizes{i(1)} - 1)/fsample;

    gaps = packetStartSec(2:end) - expectedPacketEnd(1:end-1);

    if any(gaps > 1/fsample)
        warning('Detected gaps between packets — tick-derived timeline is more accurate')
    end

    %% 7. Jitter detection
    jitter = std(dt_tick);
    if jitter > 0.0005
        warning('High jitter detected in tick-derived timestamps')
    end

    %% 8. Drift between old and new timelines
    drift = d.timeInSecDerivedFromIdealSampleRate{1} - d.timeInSecDerivedFromTicks;
    maxDrift = max(abs(drift));

    if maxDrift > 0.002
        warning('Old timeline drifts from tick-derived timeline by %.4f seconds', maxDrift)
    end


    assert(length(d.trial{1}) == length(d.timeInSecDerivedFromTicks))
    assert(length(d.trial{1}) == length(d.timerealDerivedFromTicks))

    %%% fix the position of the time
    timeInSecDerivedFromTicks=d.timeInSecDerivedFromTicks;
    d.timeInSecDerivedFromTicks={};
    d.timeInSecDerivedFromTicks{1}=timeInSecDerivedFromTicks; % just like d.timeInSecDerivedFromIdealSampleRate{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2)); %update the time!
    %%% advance checks for devmode
    if config.devmode
        assert(isequal(length(d.timeInSecDerivedFromIdealSampleRate{1}),length(d.timeInSecDerivedFromTicks{1})))
        len_old = length(d.time_real);
        len_new = length(d.timerealDerivedFromTicks);

        len_old = length(d.time_real);
        len_new = length(d.timerealDerivedFromTicks);

        % Allowed deviation: -1, 0, +1
        if abs(len_old - len_new) > 1
            warning('Length mismatch: old=%d, new=%d (difference=%d > 1)', ...
                len_old, len_new, len_old - len_new);

            % Convert both to seconds relative to first sample
            t_old_sec = seconds(d.time_real - d.time_real(1));
            t_new_sec = seconds(d.timerealDerivedFromTicks - d.timerealDerivedFromTicks(1));
            % do again
            t_new_sec = seconds(t_new_sec - t_new_sec(1));

            % Plot timelines
            %% Plot timelines
            figure;
            subplot(2,1,1)
            plot(t_old_sec, 'LineWidth', 1.2); hold on;
            plot(t_new_sec, 'LineWidth', 1.2);
            legend('Old time\_real', 'New timerealDerivedFromTicks')
            xlabel('Sample index')
            ylabel('Time (s)')
            title(hdr.OriginalFile, 'Interpreter', 'none')   % <-- use original filename as title
            grid on

            % Plot difference
            min_len = min(length(t_old_sec), length(t_new_sec));
            time_diff = t_old_sec(1:min_len) - t_new_sec(1:min_len);

            subplot(2,1,2)
            plot(time_diff, 'LineWidth', 1.2)
            xlabel('Sample index')
            ylabel('Difference (s)')
            title('Time Difference: old - new')
            grid on

            %% Build safe filename

            % Remove illegal filename characters
            safeDate = FirstPacketDateTime{i(1)};
            safeDate = strrep(safeDate, ':', '-');
            safeDate = strrep(safeDate, '.', '-');

            % Construct final filename
            saveName = sprintf('%s_BSTD_run%d_%s.png', hdr.OriginalFile, js_element, safeDate);

            %% Save in current working directory
            saveas(gcf, saveName);
            fprintf('Saved figure as: %s\n', saveName);

        else
            % Passes the tolerance check
            fprintf('Length check passed: old=%d, new=%d (difference=%d)\n', ...
                len_old, len_new, len_old - len_new);
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%% Either way, remove time_real

    d.time_real_old  = d.time_real;
    d.time_real = [];
    d.time = [];
    d.time_fsample = fsample;

    d.timeInSecDerivedFromIdealSampleRate;
    d.timeInSecDerivedFromTicks;
    d.timerealDerivedFromTicks;
    d.timeInfo = "There are time differences between timeInSecDerivedFromIdealSampleRate and timeInSecDerivedFromTicks, as documented in timeEvents. The ideal sample rate is through package lost usually lower. In timeEvents is the cumulative time difference in seconds of timeInSecDerivedFromIdealSampleRate minus timeInSecDerivedFromTicks documented for each sample that a difference is change as in Samplenumber:timeInSec E.g. 1000:-0.25 3050: -1.75 i.e. There is no time difference, then the timeInSecDerivedFromTicks lags 0.25 seconds behind timeInSecDerivedFromIdealSampleRate from sample 1000 onward, and jumps to 1.75 delay from sample 3050 onward";
    d.timeEvents = {};

    
 %% Add explanation text
    d.timeInfo = [
        "There are time differences between timeInSecDerivedFromIdealSampleRate and timeInSecDerivedFromTicks, as documented in timeEvents. " + ...
        "The ideal sample rate is usually lower due to packet loss. " + ...
        "In timeEvents, the cumulative time difference in seconds of ideal minus ticks is listed at each sample where the difference changes. " + ...
        "Example: 1000:-0.25  3050:-1.75 means: no difference initially, then from sample 1000 onward the tick-derived time lags by 0.25 seconds, " + ...
        "and from sample 3050 onward it lags by 1.75 seconds."
        ];

    % compute Time Events
        ideal = d.timeInSecDerivedFromIdealSampleRate{1};
        ticks = d.timeInSecDerivedFromTicks{1};

        % Ensure equal length
        N = length(ideal);
        assert(isequal(length(ticks), N), 'Ideal and tick vectors must match in length');

        threshold = 0.01;   % ±10 ms

        eventIdx    = 1;
        eventValues = ideal(1) - ticks(1);
        lastLag     = eventValues;

        for n = 2:N
            lag = ideal(n) - ticks(n);

            % Register event if lag changes by more than ±10 ms
            if abs(lag - lastLag) > threshold
                eventIdx(end+1,1)    = n;      %#ok<AGROW>
                eventValues(end+1,1) = lag;    %#ok<AGROW>
                lastLag              = lag;
                warning('Time lag change, event created at sample %d (%.3f -> %.3f).', n, lastLag, lag);
            
            end
        end
        % Now finalize: Build d.timeEvents with 3 decimals from eventValues
        d.timeEvents = cell(length(eventIdx), 1);
        for k = 1:length(eventIdx)
            d.timeEvents{k} = sprintf('%d:%.3f', eventIdx(k), eventValues(k));
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%% create more plots
        if config.devmode
            ideal = d.timeInSecDerivedFromIdealSampleRate{1};
            ticks = d.timeInSecDerivedFromTicks{1};

            % Only plot if there are time events
            if length(d.timeEvents)>1

                % Upper plot: ideal vs ticks
                figure;
                subplot(2,1,1)
                plot(ideal, 'LineWidth', 1.2); hold on;
                plot(ticks, 'LineWidth', 1.2);
                legend('Ideal fsample-derived time', 'Tick-derived time')
                xlabel('Sample index')
                ylabel('Time (s)')
                title('Ideal fsample-derived vs Tick-derived Time')
                grid on
                % Compute time difference
                dt = ideal - ticks;

                % Pointwise change of dt
                ddt = [0, diff(dt)];

                % Threshold for stable region (±10 ms)
                threshold = 0.01;

                % Lower plot: colored drift
                subplot(2,1,2)
                hold on

                % Loop through each segment between samples
                for ii = 1:length(dt)-1

                    x = [ii, ii+1];
                    y = [dt(ii), dt(ii+1)];

                    if ddt(ii+1) > threshold
                        % Increasing delay (magenta)
                        plot(x, y, 'Color', [1 0 1], 'LineWidth', 1.2)

                    elseif ddt(ii+1) < -threshold
                        % Decreasing delay (turquoise)
                        plot(x, y, 'Color', [0 1 1], 'LineWidth', 1.2)

                    else
                        % Stable (gray)
                        plot(x, y, 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2)
                    end
                end

                % --- Add event markers from d.timeEvents ---

                % Parse event indices and lag values
                numEvents = numel(d.timeEvents);
                evtIdx = zeros(numEvents,1);
                evtLag = zeros(numEvents,1);

                for k = 1:numEvents
                    parts = split(d.timeEvents{k}, ':');
                    evtIdx(k) = str2double(parts{1});
                    evtLag(k) = str2double(parts{2});
                end

                % Plot vertical event lines
                yLimits = ylim;
                for k = 1:numEvents
                    x = evtIdx(k);

                    % vertical dashed line
                    plot([x x], yLimits, '--', 'Color', [0.2 0.2 0.2 0.4], 'LineWidth', 1);

                    % text label slightly above the line
                    text(x, yLimits(2), sprintf('%.3f', evtLag(k)), ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'bottom', ...
                        'FontSize', 8, ...
                        'Color', [0.2 0.2 0.2]);
                end

                % Restore y-limits (MATLAB auto-expands after text)
                ylim(yLimits);

                hold off
                xlabel('Sample index')
                ylabel('Ideal - Ticks (s)')
                title('Time Delay Drift')
                grid on

                % Construct base filename (without run number)
                baseName = sprintf('%s_BSTD%d_%s', hdr.OriginalFile, js_element, safeDate);

                % Start with run-1
                run = 1;
                saveName = sprintf('%s_run-%d.png', baseName, run);

                % If file exists, increment run number
                while isfile(saveName)
                    run = run + 1;
                    saveName = sprintf('%s_run-%d.png', baseName, run);
                end

                %% Save in current working directory
                saveas(gcf, saveName);
                fprintf('Saved figure as: %s\n', saveName);

            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        d.hdr.Fs = d.fsample;
    d.hdr.label = d.label;


    
    firstsample = set_firstsample(data(i(1)).TicksInMses);
    lastsample = firstsample + size(d.trial{1}, 2) - 1;
    d.sampleinfo(1, :) = [firstsample, lastsample];

    d.BrainSenseDateTime = [t0, t0 + seconds(size(d.trial{1}, 2)/fsample)];
    d.trialinfo(1) = js_element;

    js_element_nr = js_element-1;
    mod = ['mod-BSTD' num2str(js_element_nr)];
    d.fname = [hdr.fname '_' mod];
    d.fname = strrep(d.fname, 'task-Rest', 'task-TASK');
    d.fnamedate = char(datetime(runs_FirstPacketDateTime{js_element}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'Format', 'yyyyMMddHHmmss'));

    % Optional ECG cleaning
    if isfield(config, 'ecg_cleaning') && config.ecg_cleaning
        d = call_ecg_cleaning(d, hdr, raw1);
    end

    alldata_bstd{end+1} = d;

end % for idxRun

end %function


function raw1=NaNfallback(data,i)
% ---- NaN-padding fallback ----
td = {data(i).TimeDomainData};
td = cellfun(@(v) v(:)', td, 'UniformOutput', false);

lens = cellfun(@numel, td);
maxL = max(lens);

raw1 = nan(numel(td), maxL);
for k = 1:numel(td)
    raw1(k, 1:lens(k)) = td{k};
end
end

function [timeInSec, timeReal] = computePerceptTimestamps(TicksInS, GlobalPacketSizes, fsample, runStartDatetime)
% computePerceptTimestamps
% Reconstructs sample-level timestamps from Percept PC packet metadata.
%
% INPUTS:
%   TicksInS           - vector of packet timestamps in seconds
%   GlobalPacketSizes  - vector of packet sizes (usually 62 or 63)
%   fsample            - sampling frequency (e.g., 250 Hz)
%   runStartDatetime   - datetime OR char representing datetime
%
% OUTPUTS:
%   timeInSec          - sample timestamps in seconds (relative to first tick)
%   timeReal           - absolute datetime timestamps for each sample

% Ensure runStartDatetime is a datetime
if ischar(runStartDatetime) || isstring(runStartDatetime)
    runStartDatetime = datetime(runStartDatetime, ...
        'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
end

% Preallocate full sample timeline
totalSamples = sum(GlobalPacketSizes);
timeInSec = zeros(1, totalSamples);

pos = 1;

% Build sample timestamps packet-by-packet
for p = 1:length(GlobalPacketSizes)
    nSamp = GlobalPacketSizes(p);

    % Timestamp of the first sample in this packet
    t0 = TicksInS(p);

    % Timestamps for each sample in this packet
    tPacket = t0 + (0:nSamp-1) / fsample;

    % Store into global timeline
    timeInSec(pos:pos+nSamp-1) = tPacket;

    pos = pos + nSamp;
end

% Convert relative seconds to absolute datetime
timeReal = runStartDatetime + seconds(timeInSec);
end
