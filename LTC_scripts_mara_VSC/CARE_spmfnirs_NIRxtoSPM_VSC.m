function CARE_spmfnirs_NIRxtoSPM(cfg)
%aktuelle Version mit Caros Hilfe
% care_spmfnirs_NIRxtoSPM creates a *.mat file for use in spm-fnirs from NIRx output
% data files (*.hdr, *.wl1, *.wl2) and a previously build SD file (*.SD), 
% which matches the source-detector layout used in the NIRx acquisition.
%
% To use this script, the user must first create an SD file. This can be
% done using CARE_CREATESDFILE.
%
% Use as:
%   care_spmfnirs_NIRxtoSPM( cfg )
%
% The configuration options are
%   dyadNum     = dyad description (i.e. 1)
%   prefix      = MCARE, defines raw data file prefix (default: MCARE)
%   srcPath     = location of NIRx output for both subjects of the dyad 
%   desPath     = memory location for the NIRS file (ex: '/data/pt_01867/fnirsData/DualfNIRS_CARE_processedData/01_raw_nirs')
%   SDfile      = memory location of the *.SD file (ex: '/data/pt_01867/fnirsData/DualfNIRS_CARE_generalSettings/CARE.SD')
%
% See also CARE_CREATESDFILE

% Copyright (C) 2020, Trinh Nguyen, univie; 2017, Daniel Matthes, MPI CBS
% 
% Most of the code is taken from a function called NIRx2nirs from Rob J 
% Cooper, University College London, August 2013  and an edited version 
% by NIRx Medical Technologies, Apr2016 called NIRx2nirs_probeInfo_rotate.

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------

dyadNum = cfg.dyadNum;
prefix = cfg.prefix;
srcPath = cfg.srcPath;
desPath = cfg.desPath;
SDfile = cfg.SDfile;
% -------------------------------------------------------------------------
% Build filenames
% -------------------------------------------------------------------------
Sub1SrcDir  = strcat(srcPath, sprintf([prefix, '_%02d'], dyadNum), '/Subject1/');
Sub2SrcDir  = strcat(srcPath, sprintf([prefix, '_%02d'], dyadNum), '/Subject2/');
Sub1DesFile = strcat(desPath, sprintf([prefix, '_%02da_spm_fnirs'], ...
                      dyadNum),'.mat');
Sub2DesFile = strcat(desPath, sprintf([prefix, '_%02db_spm_fnirs'], ...
                      dyadNum),'.mat');

% -------------------------------------------------------------------------
% Load SD file
% -------------------------------------------------------------------------
load(SDfile, '-mat', 'SD');

% -------------------------------------------------------------------------
% Check if NIRx output exist
% -------------------------------------------------------------------------
if ~exist(Sub1SrcDir, 'dir')
  error('Directory: %s does not exist', Sub1SrcDir);
else
  Sub1_wl1File = strcat(Sub1SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.nosatflags_wl1');
  Sub1_wl2File = strcat(Sub1SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.nosatflags_wl2');
  Sub1_hdrFile = strcat(Sub1SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.hdr');
  
  if ~exist(Sub1_wl1File, 'file')
      Sub1_wl1File = strcat(Sub1SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.wl1');

  end
  if ~exist(Sub1_wl2File, 'file')
      Sub1_wl2File = strcat(Sub1SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.wl2');
  end
  if ~exist(Sub1_hdrFile, 'file')
    error('hdr file: %s does not exist', Sub1_hdrFile);
  end
end
                   
if ~exist(Sub2SrcDir, 'dir')
  error('Directory: %s does not exist', Sub2SrcDir);
else
  Sub2_wl1File = strcat(Sub2SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.nosatflags_wl1');
  Sub2_wl2File = strcat(Sub2SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.nosatflags_wl2');
  Sub2_hdrFile = strcat(Sub2SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.hdr');
  if ~exist(Sub2_wl1File, 'file')
      Sub2_wl1File = strcat(Sub2SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.wl1');
  end
  if ~exist(Sub2_wl2File, 'file')
    Sub2_wl2File = strcat(Sub2SrcDir, sprintf([prefix, '_%02d'], dyadNum), '.wl2');
  end
  if ~exist(Sub2_hdrFile, 'file')
    error('hdr file: %s does not exist', Sub2_hdrFile);
  end
end

% -------------------------------------------------------------------------
% Convert and export data
% -------------------------------------------------------------------------
fprintf('<strong>Converting data from NIRx to spmfnirs for dyad %d, subject 1...</strong>\n',...
        dyadNum);
convertData(Sub1DesFile, Sub1_wl1File, Sub1_wl2File, Sub1_hdrFile, SD,...
            prefix, dyadNum);
fprintf('<strong>Converting data from NIRx to spmfnirs for dyad %d, subject 2...</strong>\n',...
        dyadNum);
convertData(Sub2DesFile, Sub2_wl1File, Sub2_wl2File, Sub2_hdrFile, SD,...
            prefix, dyadNum);

end

% -------------------------------------------------------------------------
% SUBFUNCTION data convertion
% -------------------------------------------------------------------------
function convertData (desFile, wl1File, wl2File, hdrFile, SD, pf, num)
wl1 = load(wl1File);                                                        % load .wl1 file
wl2 = load(wl2File);                                                        % load .wl2 file

y = [wl1 wl2];                                                       % load .wl2 file

fid = fopen(hdrFile);
tmp = textscan(fid,'%s','delimiter','\n');                                  % this just reads every line
hdr_str = tmp{1};
fclose(fid);

keyword = 'Sources=';                                                       % find number of sources
tmp = hdr_str{strncmp(hdr_str, keyword, length(keyword))};
NIRxSources = str2double(tmp(length(keyword)+1:end));

keyword = 'Detectors=';                                                     % find number of detectors
tmp = hdr_str{strncmp(hdr_str, keyword, length(keyword))};
NIRxDetectors = str2double(tmp(length(keyword)+1:end));

if NIRxSources < SD.nSrcs || NIRxDetectors < SD.nDets                       % Compare number of sources and detectors to SD file
   error('The number of sources and detectors in the NIRx files does not match your SD file...');
end

keyword = 'SamplingRate=';                                                  % find Sample rate
tmp = hdr_str{strncmp(hdr_str, keyword, 13)};
fs = str2double(tmp(length(keyword)+1:end));

% find Active Source-Detector pairs
keyword = 'S-D-Mask="#';
ind = find(strncmp(hdr_str, keyword, length(keyword))) + 1;
ind2 = find(strncmp(hdr_str(ind+1:end), '#', 1)) - 1;
ind2 = ind + ind2(1);
sd_ind = cell2mat(cellfun(@str2num, hdr_str(ind:ind2), 'UniformOutput', 0));
sd_ind = sd_ind';
sd_ind = logical([sd_ind(:);sd_ind(:)]);
y = y(:, sd_ind);

% find NaN values in the recorded data -> channels should be pruned as 'bad'
for i=1:size(y,2)
    if nonzeros(isnan(y(:,i)))
        SD.MeasListAct(i) = 0;
    end
end

% find event markers and build s vector
keyword = 'Events="#';
ind = find(strncmp(hdr_str, keyword, length(keyword))) + 1;
ind2 = find(strncmp(hdr_str(ind+1:end), '#', 1)) - 1;
ind2 = ind + ind2(1);
events = cell2mat(cellfun(@str2num, hdr_str(ind:ind2), 'UniformOutput', 0));
events = events(:,2:3);
if strcmp(pf, 'CARE')
  if num < 7                                                                %  correction of markers for dyads until number 6
    events = correctEvents( events );
  end
end
markertypes = unique(events(:,1));
s = zeros(length(y),length(markertypes));
for i = 1:length(markertypes)
    s(events(events(:,1) == markertypes(i), 2), i) = 1;
end

% create t, aux varibles
aux = ones(length(y),1);                                                    %#ok<NASGU>
t = 0:1/fs:length(y)/fs - 1/fs;
t = t';                                                                     %#ok<NASGU>

fprintf('Saving spm fnirs file: %s...\n', desFile);
save(desFile, 'y', 's', 't', 'aux', 'SD');
fprintf('Data stored!\n\n');

clear y s t aux SD
end