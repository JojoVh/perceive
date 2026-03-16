function perceive_set_dependencies()
    % Get the directory of the current script
    scriptDir = fileparts(mfilename('fullpath'));

    % Define the path to the helper_functions subfolder
    helperFunctionsPath = fullfile(scriptDir, 'helper_functions');

    % Add the helper_functions subfolder to the MATLAB path
    addpath(helperFunctionsPath);

    % List of functions to check
    functionsToCheck = {'set_firstsample', 'check_fullname', 'check_stim', 'onAppClose'};

    % Check each function
    for i = 1:length(functionsToCheck)
        functionName = functionsToCheck{i};
        if exist(functionName, 'file') ~= 2
            % Function does not exist
            error('The function ''%s'' is not found in the specified location.\nPlease ensure the function is in the ''perceive\\toolbox\\helper_functions'' subfolder or provide the full path to the function.\nYou can also check for typos in the function name or ensure the function is correctly saved.', functionName);
        else
            % Function exists
            % fprintf('The function ''%s'' is available.\n', functionName);
        end
    end
end