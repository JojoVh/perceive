function ci_build_startup_standalone(logPrefix)
% CI wrapper for startup standalone build with robust logs.
% Usage:
%   ci_build_startup_standalone("macos")
%   ci_build_startup_standalone("linux")

    if nargin < 1 || isempty(logPrefix)
        logPrefix = "ci";
    end
    if ischar(logPrefix)
        logPrefix = string(logPrefix);
    end

    diaryFile = char(logPrefix + "_build.log");
    errFile = char(logPrefix + "_build_error.txt");

    try
        diary(diaryFile);
        diary on
        build_perceive_gui_startup_standalone();
        diary off
    catch ME
        try
            diary off
        catch %#ok<CTCH>
        end
        report = getReport(ME, "extended", "hyperlinks", "off");
        disp(report);
        fid = fopen(errFile, "w");
        if fid ~= -1
            fprintf(fid, "%s\n", report);
            fclose(fid);
        end
        rethrow(ME);
    end
end
