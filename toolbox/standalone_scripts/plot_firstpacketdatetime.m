%create browser for time

%take first package date time, and plot in plot
%across json file

% Load and parse JSON
jsonFile = 'Report_Json_Session_Report_MOCK6.json'; % change this to your file path

fid = fopen(jsonFile);
raw = fread(fid, inf);
str = char(raw');
fclose(fid);
data = jsondecode(str);

% Storage for timestamps and labels
timestamps = [];
labels = {};

% Kick off recursion
% Initialize storage
timestamps = {};
labels = {};
[timestamps, labels] = searchFields(data, '', timestamps, labels);


% Recursive function with inputs and outputs
function [timestamps, labels] = searchFields(data, fullPath, timestamps, labels)
    if isstruct(data)
        % Handle struct arrays (e.g., data.Sensor(1), data.Sensor(2)...)
        if numel(data) > 1
            for i = 1:numel(data)
                indexedPath = sprintf('%s(%d)', fullPath, i);
                [timestamps, labels] = searchFields(data(i), indexedPath, timestamps, labels);
            end
        else
            fields = fieldnames(data);
            for i = 1:numel(fields)
                field = fields{i};
                value = data.(field);
                if isempty(fullPath)
                    newPath = field;
                else
                    newPath = [fullPath '.' field];
                end

                if strcmp(field, 'FirstPacketDateTime') && ischar(value)
                    dt = datetime(value, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC');
                    timestamps{end+1} = dt;
                    labels{end+1} = newPath;
                else
                    [timestamps, labels] = searchFields(value, newPath, timestamps, labels);
                end
            end
        end

    elseif iscell(data)
        for i = 1:numel(data)
            itemPath = sprintf('%s{%d}', fullPath, i);
            [timestamps, labels] = searchFields(data{i}, itemPath, timestamps, labels);
        end
    end
end

% Convert to datetime vector
timestampVec = [timestamps{:}];

% Plot results
figure;
plot(timestampVec, 1:numel(timestampVec), 'o');
yticks(1:numel(timestampVec));
yticklabels(labels);
xlabel('Time');
title('FirstPacketDateTime Timeline');
grid on;
