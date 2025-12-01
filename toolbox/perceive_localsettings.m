function localsettings = perceive_localsettings(localsettings_name)
% Load institution-specific localsettings from JSON files with validation.
% Searches both the perceive toolbox config folder and all folders on the MATLAB path.
%
% Usage:
%   localsettings = perceive_localsettings('charite')
%   localsettings = perceive_localsettings('default')
%   localsettings = perceive_localsettings()          % defaults to 'default'
%   localsettings = perceive_localsettings('list')    % returns available institutions

    % --- Default argument handling ---
    if nargin < 1 || isempty(localsettings_name)
        localsettings_name = 'default';
    end

    % --- Special mode: list available institutions ---
    if strcmpi(localsettings_name,'list')
        [~, available, locations] = findPerceiveLocalsettingsFiles();
        localsettings = struct('available', {available}, 'paths', {locations});
        return;
    end

    % --- Normalize requested institution ---
    if strcmpi(localsettings_name,'') || strcmpi(localsettings_name,'default')
        institution = 'default';
    else
        institution = lower(localsettings_name);  % charite, duesseldorf, wuerzburg, etc.
    end

    % --- Find candidate files across config and MATLAB path ---
    [candidateFiles, available, ~] = findPerceiveLocalsettingsFiles();

    if isempty(candidateFiles)
        error('No perceive_localsettings_*.json files found on MATLAB path or config folder.');
    end

    % --- Validate availability ---
    if ~ismember(institution, available)
        error('Unknown institution "%s". Available options: %s', ...
              institution, strjoin(unique(available,'stable'),', '));
    end

    % --- Pick the first match by order of discovery ---
    idx = find(strcmp(available, institution), 1, 'first');
    fname = candidateFiles{idx};

    % --- Load and decode JSON ---
    fid = fopen(fname,'r');
    if fid == -1
        error('Cannot open file %s', fname);
    end
    raw = fread(fid,inf,'char=>char')';
    fclose(fid);

    try
        data = jsondecode(raw);
    catch
        error('Invalid JSON format in file %s', fname);
    end

    % --- Validate structure ---
    requiredFields = {'taskItems','stimItems','check_followup_time', ...
                      'check_gui_tasks','check_gui_med','convert2bids','datafields'};
    for k = 1:numel(requiredFields)
        f = requiredFields{k};
        if ~isfield(data,f)
            error('Missing required field "%s" in %s', f, fname);
        end
    end

    % --- Validate content types ---
    if ~iscell(data.taskItems) || ~all(cellfun(@ischar,data.taskItems))
        error('Field "taskItems" must be a cell array of strings in %s', fname);
    end
    if ~iscell(data.stimItems) || ~all(cellfun(@ischar,data.stimItems))
        error('Field "stimItems" must be a cell array of strings in %s', fname);
    end
    if ~islogical(data.check_followup_time) || ~isscalar(data.check_followup_time)
        error('Field "check_followup_time" must be a logical scalar in %s', fname);
    end
    if ~islogical(data.check_gui_tasks) || ~isscalar(data.check_gui_tasks)
        error('Field "check_gui_tasks" must be a logical scalar in %s', fname);
    end
    if ~islogical(data.check_gui_med) || ~isscalar(data.check_gui_med)
        error('Field "check_gui_med" must be a logical scalar in %s', fname);
    end
    if ~islogical(data.convert2bids) || ~isscalar(data.convert2bids)
        error('Field "convert2bids" must be a logical scalar in %s', fname);
    end
    if ~iscell(data.datafields) || ~all(cellfun(@ischar,data.datafields))
        error('Field "datafields" must be a cell array of strings in %s', fname);
    end

    % --- Cross-field validation: BrainSense pairing ---
    hasTimeDomain = any(strcmpi(data.datafields,'BrainSenseTimeDomain'));
    hasLfp        = any(strcmpi(data.datafields,'BrainSenseLfp'));
    if xor(hasTimeDomain, hasLfp)
        error(['Invalid datafields in %s: "BrainSenseTimeDomain" and "BrainSenseLfp" must either both be present or both absent.'], fname);
    end

    % --- Normalize outputs for consistency ---
    localsettings.name                = institution;
    localsettings.taskItems           = data.taskItems(:)';    % row cellstr
    localsettings.stimItems           = data.stimItems(:)';    % row cellstr
    localsettings.check_followup_time = logical(data.check_followup_time);
    localsettings.check_gui_tasks     = logical(data.check_gui_tasks);
    localsettings.check_gui_med       = logical(data.check_gui_med);
    localsettings.convert2bids        = logical(data.convert2bids);
    localsettings.datafields          = data.datafields(:)';   % row cellstr
end

% ------------------------------------------------------------
% Helper: find all perceive_localsettings_*.json on path + config + current folder
% ------------------------------------------------------------
function [candidateFiles, available, locations] = findPerceiveLocalsettingsFiles()
    candidateFiles = {};
    available      = {};
    locations      = {};

    % 1) Toolbox config folder
    toolboxRoot = fileparts(which('perceive'));
    if ~isempty(toolboxRoot)
        toolboxRoot = fileparts(toolboxRoot); % go up to perceive\toolbox
        configPath  = fullfile(toolboxRoot,'toolbox','config');
        if exist(configPath,'dir')
            files = dir(fullfile(configPath,'perceive_localsettings_*.json'));
            for i = 1:numel(files)
                fullp = fullfile(configPath,files(i).name);
                candidateFiles{end+1} = fullp;
                [instName, locPath] = parseInstitutionFromFilename(fullp);
                available{end+1} = instName;
                locations{end+1} = locPath;
            end
        end
    end

    % 2) Current working folder
    curPath = pwd;
    files = dir(fullfile(curPath,'perceive_localsettings_*.json'));
    for i = 1:numel(files)
        fullp = fullfile(curPath,files(i).name);
        candidateFiles{end+1} = fullp;
        [instName, locPath] = parseInstitutionFromFilename(fullp);
        available{end+1} = instName;
        locations{end+1} = locPath;
    end

    % 3) All folders on MATLAB path
    pathFolders = strsplit(path, pathsep);
    for p = 1:numel(pathFolders)
        pf = pathFolders{p};
        if exist(pf,'dir')
            files = dir(fullfile(pf,'perceive_localsettings_*.json'));
            for i = 1:numel(files)
                fullp = fullfile(pf,files(i).name);
                candidateFiles{end+1} = fullp;
                [instName, locPath] = parseInstitutionFromFilename(fullp);
                available{end+1} = instName;
                locations{end+1} = locPath;
            end
        end
    end

    % Deduplicate by full path (preserves discovery order)
    [candidateFiles, uniqueIdx] = unique(candidateFiles,'stable');
    available = available(uniqueIdx);
    locations = locations(uniqueIdx);
end

% ------------------------------------------------------------
% Helper: parse institution from filename
% perceive_localsettings_<institution>.json → <institution> (lowercase)
% ------------------------------------------------------------
function [institution, locPath] = parseInstitutionFromFilename(fullpath)
    [locPath, name, ~] = fileparts(fullpath);
    parts = split(name,'_');
    if numel(parts) >= 3
        institution = lower(parts{3});
    else
        institution = '';
    end
end