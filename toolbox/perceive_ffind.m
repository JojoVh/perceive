function [files, folder, fullfname] = perceive_ffind(string, cellmode, rec)

% perceive_ffind - cross-platform file finder
% 
% inputs:
%   string   - pattern to match, e.g., '*.mat' or fullfile(folder, '*BSL*.mat')
%   cellmode - 1 (default): return cell array; 0: return char if only one file
%   rec      - 1: recursive search; 0 (default): current folder only
%
% outputs:
%   files      - list of filenames
%   folder     - corresponding folder(s)
%   fullfname  - full path(s)

% --- defaults ---
if ~exist('cellmode','var') || isempty(cellmode), cellmode = 1; end
if ~exist('rec','var') || isempty(rec), rec = 0; end

% --- non-recursive mode ---
if ~rec
    % handle relative paths
    if startsWith(string, './') || startsWith(string, '.\')
        string = fullfile(pwd, string(3:end));
    elseif startsWith(string, '*') || startsWith(string, filesep)
        string = fullfile(pwd, string);
    end

    % use dir (instead of ls)
    d = dir(string);
    if isempty(d)
        files = {};
        folder = {};
        fullfname = {};
        return
    end

    files  = {d.name}';
    folder = {d.folder}';
    
% --- recursive search ---
else
    rdirs = find_folders;
    outfiles   = {};
    outfolders = {};
    for i = 1:length(rdirs)
        d = dir(fullfile(rdirs{i}, string));
        if ~isempty(d)
            outfiles   = [outfiles;   {d.name}'];
            outfolders = [outfolders; repmat(rdirs(i), numel(d), 1)];
        end
    end
    files  = outfiles;
    folder = outfolders;
end

% --- clean results ---
% remove '.' and '..'
keep   = ~ismember(files, {'.','..'});
files  = files(keep);
folder = folder(keep);

% remove duplicates
[files, uniq_idx] = unique(files, 'stable');
folder = folder(uniq_idx);

% --- custom sort (TASK number + underscore priority) ---
[files, sort_idx] = sort_underscore_priority(files);
folder = folder(sort_idx);

% --- full filenames ---
if isempty(files)
    fullfname = [];
elseif ~cellmode && numel(files) == 1
    files     = files{1};
    fullfname = fullfile(folder{1}, files);
else
    fullfname = cell(numel(files), 1);
    for a = 1:length(files)
        fullfname{a,1} = fullfile(folder{a}, files{a});
    end
end

end


function [files, idx] = sort_underscore_priority(files)
% SORT_UNDERSCORE_PRIORITY
% Sort BIDS-like filenames by TASK number (natural order),
% and for equal TASK numbers, treat '_' as the lowest character.

    if isstring(files)
        files = cellstr(files);
    end

    n = numel(files);
    idx = (1:n)';

    % 1) Extract TASK numbers (NaN if no match)
    tokens = regexp(files, 'TASK(\d+)', 'tokens', 'once');
    nums   = cellfun(@(t) iff(isempty(t), NaN, str2double(t)), tokens);

    % 2) Build secondary lexicographic key with '_' as lowest
    maxLen = max(cellfun(@length, files));
    padded = cellfun(@(s) pad(s, maxLen, 'right', char(255)), ...
                     files, 'UniformOutput', false);
    keys   = cellfun(@(s) regexprep(s, '_', char(0)), ...
                     padded, 'UniformOutput', false);

    % 3) Sort by TASK number first (NaNs last), then by underscore-aware key
    T = table(nums(:), keys(:), idx, files(:), ...
              'VariableNames', {'num','key','idx','file'});
    T = sortrows(T, {'num','key'});  % NaNs naturally go to the end

    files = T.file;
    idx   = T.idx;
end


function out = iff(cond, a, b)
% simple inline if
    if cond
        out = a;
    else
        out = b;
    end
end