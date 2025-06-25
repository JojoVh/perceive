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

% Start recursive search
[timestamps, labels] = searchFields(data, "", timestamps, labels);

% Recursive function with inputs and outputs
function [timestamps, labels] = searchFields(structure, parentPath, timestamps, labels)
    if isstruct(structure)
        fields = fieldnames(structure);
        for i = 1:numel(fields)
            field = fields{i};
            fullPath = strjoin([parentPath, field], '.');
            value = structure.(field);
            if strcmp(field, 'FirstPacketDateTime') && ischar(value)
                dt = datetime(value, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC');
                timestamps(end+1) = {dt};
                labels{end+1} = parentPath;
            else
                [timestamps, labels] = searchFields(value, fullPath, timestamps, labels);
            end
        end
    elseif iscell(structure)
        for j = 1:numel(structure)
            [timestamps, labels] = searchFields(structure{j}, parentPath, timestamps, labels);
        end
    end
end


% Plot results
figure;
plot(timestamps, 1:numel(timestamps), 'o');
yticks(1:numel(timestamps));
yticklabels(labels);
xlabel('Time');
title('FirstPacketDateTime Timeline');
grid on;

% Recursive function to explore fields
