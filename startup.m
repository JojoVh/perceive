function startup()
    toolboxPath = fileparts(mfilename('fullpath')); % Get toolbox folder
    addpath(genpath(toolboxPath)); % Add all subfolders
    
    % Do not attempt to persist MATLAB path changes in CI/headless runs.
    if isempty(getenv("GITHUB_ACTIONS")) && usejava("desktop")
        savepath; % Save changes persistently for interactive local sessions
    end

    % Set preferences for first-time setup
    if ~ispref('perceive', 'initialized')
        setpref('perceive', 'initialized', true);
        disp('perceive toolbox initialized successfully.');
    end
end