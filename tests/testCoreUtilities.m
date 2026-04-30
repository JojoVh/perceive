classdef testCoreUtilities < matlab.unittest.TestCase
    methods (Test)
        function parseArgsSupportsNumericSubject(tc)
            config = perceive_parse_args('dummy.json', 7, '', '', '', '');
            tc.verifyEqual(config.subject, 'sub-007');
            tc.verifyEqual(config.files, {'dummy.json'});
            tc.verifyFalse(config.extended);
            tc.verifyFalse(config.gui);
        end

        function parseArgsSupportsAllDatafields(tc)
            config = perceive_parse_args('dummy.json', '', '', '', '', 'all');
            tc.verifyGreaterThan(numel(config.datafields), 0);
            tc.verifyTrue(any(strcmp(config.datafields, 'BrainSenseLfp')));
            tc.verifyTrue(any(strcmp(config.datafields, 'PatientEvents')));
        end

        function parseArgsRejectsInvalidDatafield(tc)
            didThrow = false;
            try
                perceive_parse_args('dummy.json', '', '', '', '', {'Nope'});
            catch
                didThrow = true;
            end
            tc.verifyTrue(didThrow);
        end

        function checkDataVersionParsesKnownVersions(tc)
            cfg = struct();
            cfg = perceive_check_dataversion(struct("DataVersion", "1.2"), cfg);
            tc.verifyEqual(cfg.DataVersion, 1.2);

            cfg = perceive_check_dataversion(struct("DataVersion", "1.3"), cfg);
            tc.verifyEqual(cfg.DataVersion, 1.3);

            cfg = perceive_check_dataversion(struct("DataVersion", "1.4"), cfg);
            tc.verifyEqual(cfg.DataVersion, 1.4);
        end

        function checkDataVersionDefaultsWhenMissing(tc)
            cfg = struct();
            cfg = perceive_check_dataversion(struct(), cfg);
            tc.verifyEqual(cfg.DataVersion, 0);
        end

        function checkFullnameAcceptsValidRelativePath(tc)
            folderFixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            targetPath = fullfile(folderFixture.Folder, 'output.mat');
            tc.verifyWarningFree(@() check_fullname(targetPath));
        end

        function checkFullnameRejectsMissingFolder(tc)
            badPath = fullfile('definitely_missing_folder_for_test', 'output.mat');
            didThrow = false;
            try
                check_fullname(badPath);
            catch
                didThrow = true;
            end
            tc.verifyTrue(didThrow);
        end
    end
end
