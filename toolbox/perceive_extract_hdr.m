function [hdr, datafields] = perceive_extract_hdr(js, filename, config)

% extract metadata and filenames from a Percept JSON struct and user config

arguments
    js struct
    filename char
    config struct
end

% ----------------------------
% parse top-level info
% ----------------------------
[~, fname, ~] = fileparts(filename);
hdr.OriginalFile = filename;
hdr.fname = fname;
hdr.js = js;

% infofields to copy over if present
infofields = {'SessionDate','SessionEndDate','PatientInformation','DeviceInformation','BatteryInformation', ...
              'LeadConfiguration','Stimulation','Groups','Impedance','PatientEvents','EventSummary','DiagnosticData'};
for i = 1:length(infofields)
    if isfield(js, infofields{i})
        hdr.(infofields{i}) = js.(infofields{i});
    end
end

hdr.SessionEndDate = datetime(strrep(js.SessionEndDate(1:end-1),'T',' ')); %this is the date of the session, do not take startdate
%%%%%%%%%%%%%%%%%%%%%%%% SESSION TIME CHECK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check if hdr.SessionEndDate is valid
if ~isdatetime(hdr.SessionEndDate) || isnat(hdr.SessionEndDate)

    success = false;

    % --- First attempt: js.SessionDate ---
    if isfield(js, 'SessionDate')
        dt = tryParseDate(js.SessionDate);
        if ~isnat(dt)
            hdr.SessionEndDate = dt;
            success = true;
        end
    end

    % --- Second attempt: js.DeviceInformation.Final.DeviceDateTime ---
    if ~success && isfield(js, 'DeviceInformation') ...
               && isfield(js.DeviceInformation, 'Final') ...
               && isfield(js.DeviceInformation.Final, 'DeviceDateTime')

        dt = tryParseDate(js.DeviceInformation.Final.DeviceDateTime);
        if ~isnat(dt)
            hdr.SessionEndDate = dt;
            success = true;
        end
    end

    % --- If everything fails ---
    if ~success
        error('SessionDateError', ...
            ['Unable to determine a valid SessionEndDate. ', ...
             'All available date sources failed.']);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % fix datetime formats
% hdr.SessionDate = datetime(strrep(js.SessionDate(1:end-1),'T',' '));
% hdr.SessionEndDate = datetime(strrep(js.SessionEndDate(1:end-1),'T',' '));
% hdr.d0 = datetime(js.SessionDate(1:10));
% hdr.d1 = datetime(js.SessionDate(1:10));
% 
% % --- small validation check ---
% if ~( isa(hdr.d0,'datetime') && ~isnat(hdr.d0) )
%     error('Header:InvalidDate', ...
%         'hdr.d0 must be a valid datetime with year, month, and day.');
% end
% 
% 
% hdr=checkDateConsistency(js, hdr);

% diagnosis
if isfield(js.PatientInformation, "Final") && ~isempty(js.PatientInformation.Final.Diagnosis)
    parts = strsplit(js.PatientInformation.Final.Diagnosis, '.');
    if numel(parts) > 1
        hdr.Diagnosis = parts{2};
    else
        hdr.Diagnosis = '';
    end
else
    hdr.Diagnosis = '';
end

% implant date
if contains(js.DeviceInformation.Final.ImplantDate(1:end-1), char(9608))
        hdr.ImplantDate = '';
else
        hdr.ImplantDate = strrep(strrep(js.DeviceInformation.Final.ImplantDate(1:end-1), 'T', '_'), ':', '-');
end


% battery %
if isfield(js, 'BatteryInformation')
    hdr.BatteryPercentage = js.BatteryInformation.BatteryPercentage;
else
    hdr.BatteryPercentage = NaN;
end

% lead Location
if isfield(hdr, 'LeadConfiguration')
    loc = hdr.LeadConfiguration.Final(1).LeadLocation;
    hdr.LeadLocation = strsplit(loc, '.');
    hdr.LeadLocation = hdr.LeadLocation{end};
else
    hdr.LeadLocation = 'UNK';
end

% ----------------------------
% subject handling
% ----------------------------
if isempty(config.subject)
    % generate subject from ImplantDate, Diagnosis, LeadLocation
    diagLetter = hdr.Diagnosis(~isempty(hdr.Diagnosis));
    if ~isempty(hdr.ImplantDate) && ~isnan(str2double(hdr.ImplantDate(1)))
        hdr.subject = ['sub-' strrep(strtok(hdr.ImplantDate,'_'),'-','') diagLetter hdr.LeadLocation];
    else
        hdr.subject = ['sub-000' diagLetter hdr.LeadLocation];
    end
else
    hdr.subject = config.subject;
end

% ----------------------------
% session handling
% ----------------------------
if isempty(config.session)
    hdr.session = ['ses-' char(datetime(hdr.SessionEndDate,'format','yyyyMMddhhmmss'))];

else
    % compute follow-up time if needed
    %if isfield(config.localsettings, 'followup')
    %    diffmonths = config.localsettings.followup{1}(3:end-1);
    %else
    d_implant = datetime(strrep(strtok(hdr.ImplantDate,'_'),'-',''), 'InputFormat','yyyyMMdd');
    d_session = hdr.SessionEndDate;
    % rawmonths = between(d_implant, d_session, 'months');
    presetmonths = [0,1,2,3,6,12,18,24,30,36,42,48,60,72,84,96,108,120]; % check this!!! --> different for different diagnoses
    % diffmonths = interp1(presetmonths, presetmonths, rawmonths, 'nearest');
    diffmonths = calmonths(between(d_implant, d_session));
    diffmonths = interp1(presetmonths, presetmonths, diffmonths, 'nearest');

    diffmonths = num2str(diffmonths);
    %end
    hdr.session = ['ses-Fu' pad(diffmonths,2,'left','0') 'm' config.session];
end

% ----------------------------
% output directory and file label
% ----------------------------
hdr.fpath = fullfile(hdr.subject, hdr.session, 'ieeg');
if ~exist(hdr.fpath, 'dir')
    mkdir(hdr.fpath);
end

hdr.task = config.task;
hdr.acq = config.acq;
hdr.mod = config.mod;
hdr.run = config.run;

hdr.fname = sprintf('%s_%s_task-%s_acq-%s', ...
    hdr.subject, hdr.session, hdr.task, hdr.acq);

% run not included in old code, maybe change later to default run 0
% hdr.fname = sprintf('%s_%s_task-%s_acq-%s_run-%d', ...
%     hdr.subject, hdr.session, hdr.task, hdr.acq, hdr.run);

% channel label
hdr.chan = ['LFP_' hdr.LeadLocation];



% ----------------------------
% version check
% ----------------------------
% see function config = perceive_check_dataversion(js, config)
hdr.DataVersion = config.DataVersion;

% ----------------------------
% default datafields if missing
% ----------------------------
if isempty(config.datafields)
    datafields = sort({'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain', ...
        'LfpMontageTimeDomain','IndefiniteStreaming','BrainSenseSurvey','CalibrationTests','PatientEvents','DiagnosticData', ...
        'BrainSenseSurveysTimeDomain','BrainSenseSurveys'});
else
    datafields = config.datafields;
end

end

function hdr = checkDateConsistency(js, hdr)
    % raise an error in case of time differences with abnormal end, or check
    % whether d0 is correct by dummy hdrd0

    if isfield(js, 'AbnormalEnd')
        if js.AbnormalEnd
            warning('This recording had an abnormal end');

            hdrd0 = datetime(js.DeviceInformation.Final.DeviceDateTime(1:10));

            if isempty(js.SessionEndDate)
                hdr.SessionEndDate = datetime(strrep(js.SessionDate(1:end-1), 'T', ' '));
            else
                assert( isa(hdr.SessionEndDate,'datetime') && ...
                        ~isnat(hdr.SessionEndDate) && ...
                        all(~isundefined(hdr.SessionEndDate)), ...
                        'hdr.SessionEndDate must be a valid, non-NaT datetime.');
            end
        else
            hdrd0 = datetime(js.SessionEndDate(1:10));
        end
    else
        hdrd0 = datetime(js.SessionEndDate(1:10));
    end

    hdrd1 = js.SessionDate(1:10);

    hdr.d0 = hdrd0;
    % check d0 must be equal to d1
    % if ~isequal(hdrd0, hdrd1)
    %     error('HeaderMismatch:DateTimeError', ...
    %         'hdr.d0 and hdr.d1 must match.\nValue of d0: %s\nValue of d1: %s', ...
    %         char(hdrd0), char(hdrd1));
    % end
end

function dt = tryParseDate(str)

    dt = NaT;  % default if everything fails

    if isempty(str)
        return
    end

    % Clean ISO formatting
    s = strrep(str, 'T', ' ');
    s = strrep(s, 'Z', '');

    % Try multiple formats
    formats = { ...
        'yyyy-MM-dd HH:mm:ss', ...
        'yyyy-MM-dd HH:mm', ...
        'yyyy-MM-dd', ...
        'dd.MM.yyyy HH:mm:ss', ...
        'dd.MM.yyyy HH:mm', ...
        'dd.MM.yyyy' ...
    };

    for k = 1:numel(formats)
        try
            dtCandidate = datetime(s, 'InputFormat', formats{k});
            if ~isnat(dtCandidate)
                dt = dtCandidate;
                return
            end
        catch
            % try next format
        end
    end
end

