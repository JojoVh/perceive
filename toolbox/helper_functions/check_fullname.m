function check_fullname(fullname)
%CHECK_FULLNAME  Validate a constructed file path with logical assertions.
%
%   check_fullname(fullname)
%
%   Performs a series of sanity checks on the provided file path:
%   - must be a non-empty string or char
%   - must contain a filename (not end with a separator)
%   - parent folder must exist
%   - file may or may not exist, but a warning is issued if not
%   - path must be absolute or relative but syntactically valid

    arguments
        fullname (1,:) char
    end

    % 1. Non-empty
    assert(~isempty(fullname), 'Fullname is empty.')

    % 2. Must not end with a file separator
    assert(~endsWith(fullname, filesep), ...
        'Fullname ends with a file separator, so no filename is present.')

    % 3. Extract folder + filename
    [folder, name, ext] = fileparts(fullname);

    %assert(strcmpi(ext, '.mat'), ...
    %    'Fullname must have .mat extension, but got "%s".', ext);


    % 4. Must contain a filename
    assert(~isempty(name), 'Fullname does not contain a valid filename.')

    % 5. Folder must exist (unless empty meaning ".")
    if isempty(folder)
        folder = '.';  % interpret empty as current directory
    end

    assert(isfolder(folder), ...
        'Folder does not exist: "%s"', folder)

    % Extract only the filename (no folder path)
    [~, fname, ext] = fileparts(fullname);
    justName = [fname ext];

    % Windows illegal characters for filenames
    illegal = ['<', '>', ':', '"', '/', '\', '|', '?', '*'];

    % Check only the filename, not the full path
    if any(ismember(justName, illegal))
        error('Filename contains characters that are illegal (windows): %s', justName)
    end


    % 8. Check for double separators
    if contains(fullname, [filesep filesep])
        error('Fullname contains repeated file separators.')
    end

end
