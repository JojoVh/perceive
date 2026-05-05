function build_perceive_standalone()
% Build perceive.m as a standalone app for the current OS.

    entryFile = fullfile(fileparts(mfilename('fullpath')), 'perceive.m');
    if ~exist(entryFile, 'file')
        error('Could not find perceive.m next to this script.');
    end

    fprintf('Building standalone app from: %s\n', entryFile);
    fprintf('This build targets the current OS only.\n');

    compiler.build.standaloneApplication(entryFile, ...
        'ExecutableName', 'perceive', ...
        'OutputDir', fileparts(entryFile));

    fprintf('\nBuild complete.\n');
    fprintf('Distribute the generated app with MATLAB Runtime R2023a or newer.\n');
end
