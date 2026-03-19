[![GitHub top language](https://img.shields.io/github/languages/top/neuromodulation/perceive)](https://matlab.mathworks.com/)  [![Perceive CI/CD](https://github.com/neuromodulation/perceive/actions/workflows/main.yml/badge.svg)](https://github.com/neuromodulation/perceive/actions/workflows/main.yml) [![GitHub issues by-label](https://img.shields.io/github/issues-raw/neuromodulation/perceive/bug)](https://github.com/neuromodulation/perceive/issues?q=is%3Aissue+is%3Aopen+label%3Abug) ![GitHub Repo stars](https://img.shields.io/github/stars/neuromodulation/perceive?style=social)

[![Codecov](https://img.shields.io/codecov/c/github/neuromodulation/perceive)](https://app.codecov.io/gh/neuromodulation/perceive/tree/hackathonretune) ![MATLAB Code Issues](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fneuromodulation%2Fperceive%2Fhackathonretune%2Freports%2Fbadge%2Fcode_issues.json) ![MATLAB Versions Tested](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fneuromodulation%2Fperceive%2Fhackathonretune%2Freports%2Fbadge%2Ftested_with.json) 


# Perceive (MATLAB)

https://github.com/neuromodulation/perceive 
v0.2 Contributors Tomas Sieger, Wolf-Julian Neumann, Gerd Tinkhauser
v0.3 Contributor Jojo Vanhoecke
This is an open research tool that is not intended for clinical purposes. 

# INPUT

perceiveModular(files, sub, ses, extended, gui, localsettings_name)

## files:
All input is optional, you can specify files as cell or character array
(e.g. `files = 'Report_Json_Session_Report_20200115T123657.json'`) 
if files isn't specified or remains empty, it will automatically include
all files in the current working directory
if no files in the current working directory are found, a you can choose
files via the MATLAB uigetdir window.

## sub:
SubjectID: you can specify a subject ID for each file in case you want to follow an IRB approved naming scheme for file export

e.g.
```perceiveModular('Report_Json_Session_Report_20200115T123657.json',80)```
-> creates sub-080

```perceiveModular('Report_Json_Session_Report_20200115T123657.json','080')```
-> also creates sub-080

```perceiveModular('Report_Json_Session_Report_20200115T123657.json','Charite001')```
-> creates sub-Charite001

if unspecified or left empy, the subjectID will be created from
ImplantDate, first letter of disease type and target (e.g. sub-2020110DGpi)

## ses:
session:
input e.g.
```['','MedOff','MedOn','MedDaily','MedOff01','MedOn01','MedOff02','MedOn02','MedOff03','MedOn03','MedOffOn01','MedOffOn02','MedOffOn03','MedOnPostOpIPG','MedOffPostOpIPG','Unknown', 'PostOp']```
    

## extended:
'yes' or ''
If 'yes': saves all created files in between and in different formats
default: ''

## gui:
'yes' or ''
If 'yes': use gui for renaming and concatenation at end of perceive output
default: ''

## localsettings: (still in dev)
default is '', which is default

alternative: Charite Duesseldorf Wuerzburg or custom naming

names refer to the perceive\toolbox\config or any other file in your matlab folder which contains

perceive_localsettings_default.json
perceive_localsettings_charite.json
perceive_localsettings_duesseldorf.json
perceive_localsettings_wuerzburg.json
perceive_localsettings_"custom name".json with custom name to be

filled in, together with custom settings. Needs to be in matlab path, needs start with perceive_localsettings_*json, but does not need to be in the perceive\toolbox\config folder
possible datafields from Medtronic Percept are  ```["","BrainSenseLfp","BrainSenseSurvey","BrainSenseTimeDomain","CalibrationTests","DiagnosticData","EventSummary","Impedance","IndefiniteStreaming","LfpMontageTimeDomain","MostRecentInSessionSignalCheck","PatientEvents"])} ='';```

# INPUT examples
```matlab
perceiveModular() % run all files in current directory or if none open explorer to select file

perceiveModular('Report_Json_Session_Report_20200115T123657.json') % run this file

perceiveModular({'Report_Json_Session_Report_20200115T123657.json','Report_Json_Session_Report_20200115T123658.json'}) % run these files

perceiveModular('',5) % name subject sub-005

perceiveModular('','23') % name subject sub-023

perceiveModular('','') % automatic name subject based on ImplantDate, first letter of disease type and target (e.g. sub-2020110DGpi)

perceiveModular('','','MedOff') % name session ses-MedOff

perceiveModular('','','PostOp') % name session ses-PostOp input e.g. ['','MedOff','MedOn','MedDaily','MedOff01','MedOn01','MedOff02','MedOn02','MedOff03','MedOn03','MedOffOn01','MedOffOn02','MedOffOn03','MedOnPostOpIPG','MedOffPostOpIPG','Unknown', 'PostOp']

perceiveModular('','','') % automatic name session based on the session date

perceiveModular('','','','yes') % gives an extensive output of chronic, calibration, lastsignalcheck, diagnostic, impedance and snapshot data

perceiveModular('','','','') % regular output (default)

perceiveModular('','','','', 'yes') %use gui for renaming and concatenation at end of perceive output

perceiveModular('','','','', '') % no gui (default)

perceiveModular('','','','', '', '') % localsettings (default)
```

# OUTPUT

The script generates BIDS bids.neuroimaging.io/ inspired subject and session folders with the
ieeg format specifier. 
All time series data are being exported as FieldTrip '.mat' files, as these require no additional dependencies for creation.
You can reformat with FieldTrip and SPM to MNE python and other formats (e.g. using fieldtrip2fiff([fullname '.fif'],data))

## Recording type output naming
Each of the FieldTrip data files correspond to a specific aspect of the Recording session:

LMTD = LFP Montage Time Domain - BrainSenseSurvey

IS = Indefinite Streaming - BrainSenseStreaming

CT = Calibration Testing - Calibration Tests

BSL = BrainSense LFP (2 Hz power average + stimulation settings)




# Extra Note on use of GUI


# Stream concatenation (stitching 2 or more streams together for interruption)


Background:
In order to concatenate 2 streams of the same modality within the same file, the GUI can be used or manually, the function
`perceive_stitch_interruption_together(recording_basename, optional_time_addition_ms, save_file)`

the "new" definition of the sampleinfo (by current perceive - latest version) is used, which is a sample information based on the MSecTicks.
The sampleinfotime is now the sample number of the FirstPackageTime of the absolute time, computed from midnight, with a length of the sample frequency x the trial length (no further correction).
2 recordings are concatenated by compute the sample difference between the last sample of the first part, and the first sample of the next part. (iteratively for multiple parts). This amount are the NaN values when concatenating.
 
Now:
The NaN interval is computed. You can add or substract ms from this NaN interval by a custom number.
 
Examples how to use this:
 
First run perceive, concatenate the 2 or more files over the GUI, just as normal.
Then go to the folder with the PARTS. The regular part will be saved already as normal, with a NAN interval based on the timestamps.
Modify this NAN interval by calling the parts (indicated by '_part-' at the end) and indicate your additional time in ms (or with negative time to shorten it).
 
Base function, no saving. This is implemented in perceive. you do not need to run this.
Add 250ms of additional NaNs in between recordings, save true.
Add 496ms of additional NaNs in between recordings, save true.
Decrease 100ms of additional NaNs in between recordings, save true.
 

BSTD = BrainSense Time Domain (250 Hz raw data corresponding to the BSL file)

