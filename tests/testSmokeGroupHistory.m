classdef testSmokeGroupHistory < matlab.unittest.TestCase
    methods (Test)
        function groupHistoryParsesMockAndWritesOutput(tc)
            folderFixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            sourceFile = fullfile('MockData', 'Report_Json_Session_Report_MOCK1.json');
            targetFile = fullfile(folderFixture.Folder, 'Report_Json_Session_Report_MOCK1.json');
            copyfile(sourceFile, targetFile);

            oldPath = addpath(genpath('toolbox'));
            cleanupPath = onCleanup(@() path(oldPath));

            oldDir = pwd;
            cleanupDir = onCleanup(@() cd(oldDir));
            cd(folderFixture.Folder);

            result = perceive_GroupHistory(targetFile);

            tc.verifyTrue(isstruct(result));
            tc.verifyTrue(isfield(result, 'GroupHistory'));
            tc.verifyGreaterThanOrEqual(numel(result.GroupHistory), 1);
            tc.verifyTrue(isfile('Report_Json_Session_Report_MOCK1_GroupHistory.json'));
        end
    end
end
