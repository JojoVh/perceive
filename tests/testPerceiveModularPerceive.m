function testPerceiveModularPerceive(testCase, testFile)
%for i = 1:numel(testCase.testFiles)
%    testFile = testCase.testFiles{i};
% Create two temporary folders
fix1 = matlab.unittest.fixtures.TemporaryFolderFixture;
fix2 = matlab.unittest.fixtures.TemporaryFolderFixture;
testCase.applyFixture(fix1);
testCase.applyFixture(fix2);

folder1 = fix1.Folder;
folder2 = fix2.Folder;

% Run your functions
addpath(pwd);
% Go to folder1
cd(folder1);
disp("Now in folder1: " + pwd);
perceive(testFile);  % Perceive

cd(folder2);
disp("Now in folder2: " + pwd);
perceiveModular(testFile);  % Perceive post-hackathon

% Compare folder contents
files1 = dir(fullfile(folder1, '**', '*'));
files2 = dir(fullfile(folder2, '**', '*'));

% Compare folder contents
files1 = dir(fullfile(folder1, '**', '*'));
files2 = dir(fullfile(folder2, '**', '*'));

% Filter out directories
files1 = files1(~[files1.isdir]);
files2 = files2(~[files2.isdir]);

% Extract names and full paths
names1 = {files1.name};
paths1 = fullfile({files1.folder}, names1);

names2 = {files2.name};
paths2 = fullfile({files2.folder}, names2);

% Filter out .csv files % do not check csv files
validIdx1 = ~endsWith(names1, '.csv');
validIdx2 = ~endsWith(names2, '.csv');

filteredNames1 = sort(names1(validIdx1));
filteredPaths1 = sort(paths1(validIdx1));

filteredNames2 = sort(names2(validIdx2));
filteredPaths2 = sort(paths2(validIdx2));

% Perform the comparison
testCase.verifyEqual(filteredNames1', filteredNames2', ...
    'File names differ with Actual=perceive and Expected=Modular');

% Compare file contents
for k = 1:numel(filteredNames1)

    testCase.verifyTrue(isequal(fileread(filteredPaths1{k}), fileread(filteredPaths2{k})), ...
        sprintf('File content mismatch with Actual=perceive and Expected=Modular: %s', filteredNames1{k}));
    [~, ~, ext] = fileparts(filteredPaths1{k});
    if strcmpi(ext, '.mat')
        try
            % Fields to ignore during comparison
            ignoredSubfields = ['hdr.Dataversion', 'hdr.acq', 'hdr.mode', 'hdr.run', 'hdr.task'];

            data1 = load(filteredPaths1{k});
            data2 = load(filteredPaths2{k});

            % If files differ, launch a subtest to explore struct differences
            testCase.assertTrue(isstruct(data1) && isstruct(data2), 'Non-struct content in files');

            % Remove ignored subfields from both structs
            data1 = removeIgnoredFields(data1, ignoredSubfields);
            data2 = removeIgnoredFields(data2, ignoredSubfields);

            data1=data1.fields1;
            data2=data2.fields2;

            testCase.assertEqual(data1, data2, ...
                sprintf('Assertion fails content mismatch with Actual=perceive and Expected=Modular: %s', filteredNames1{k}));
        catch
            % Compare each shared field
            fields1 = fieldnames(data1);
            fields2 = fieldnames(data2);

            testCase.verifyEqual(sort(fields1), sort(fields2), ...
                sprintf('Field mismatch in: %s', filteredNames1{k}));


            sharedFields = intersect(fields1, fields2);
            for i = 1:numel(sharedFields)
                field = sharedFields{i};
                testCase.verifyEqual(data1.(field), data2.(field), ...
                    sprintf('Field "%s" mismatch in file: %s', field, filteredNames1{k}));
            end
        end
    else
        sprintf('Type file of mismatch had extension: %s', ext);
    end
end
end

function s = removeIgnoredFields(s, pathsToIgnore)
for i = 1:numel(pathsToIgnore)
    parts = strsplit(pathsToIgnore(i), '.');
    if isfield(s, parts{1})
        if numel(parts) == 1
            s = rmfield(s, parts{1});
        else
            sub = s.(parts{1});
            if isstruct(sub) && isfield(sub, parts{2})
                sub = rmfield(sub, parts{2});
                s.(parts{1}) = sub;
            end
        end
    end
end
end
