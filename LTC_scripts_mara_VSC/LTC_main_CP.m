% This script processes raw fNIRS data in the NIRX specific format. 
% It performs the following steps:
% 1. Converts raw data for compatibility with Homer2 and SPM functions.
% 2. Segments data based on experimental markers.
% 3. Cleans and preprocesses the data.
% 4. Calculates synchrony between participant pairs using wavelet transform coherence.
%
% Note: The function "LTC_config_paths" must be in the MATLAB current folder for this script to run properly.
% Before using: check that the paths in the LTC_config_paths function match
% your system setup!
%

% Author: Carolina Pletti (carolina.pletti@gmail.com)

clear all  % Clear all variables from the workspace

%---------------------------------------------------------

% Initialize an empty configuration structure for preprocessing settings.
cfg = [];
cfg.overwrite = 0; % Set to 1 to overwrite all data except converted data.
cfg.groups = {'Lachen','Kontrolle'}; % Names of participant groups; should match subfolder names in the raw data directory.
cfg.segments = {'tangram', 'laughter', 'interaction'}; % Experiment segments to be analyzed.

% --------------------------------------------------------------------
%set all paths for loading and saving data, add folder with functions and Homer2 to the path.
%Modify the "LTC_config_paths" function as needed to match your system setup 

sel = false;

while sel == false
    fprintf('\nPlease select the workspace environment:\n');
    fprintf('[1] - Carolina''s workspace at the uni\n');
    fprintf('[3] - None of the above (manual setup required)\n');

    x = input('Option: ');

    switch x
        case 1
            sel = true;
            cfg = LTC_config_paths(cfg, 1);
        case 2
            sel = true;
            cfg = LTC_config_paths(cfg, 0)
        case 3
            sel = true;
            fprintf('Please modify this script and the LTC_config_paths function to match your system setup.');
        return;
        otherwise
            cprintf([1,0.5,0], 'Wrong input!\n');
        return
    end
end

% --------------------------------------------------------------------
% Choose coherence calculation method: by channel or by region of interest (ROI).
sel_ROI = false;

while sel_ROI == false
    fprintf('\nPlease coherence calculation method:\n');
    fprintf('[1] - Coherence by channel\n');
    fprintf('[2] - Coherence by ROI\n');
    fprintf('[3] - Quit\n');

    x = input('Option: ');

    switch x
        case 1
            sel_ROI = true;
            cfg.ROI = 0;
        case 2
            sel_ROI = true;
            cfg.ROI = 1;
        case 3
            fprintf('\nProcess aborted.\n');
        return;
        otherwise
            cprintf([1,0.5,0], 'Wrong input!\n');
    end
end

% --------------------------------------------------------------------
% Loop through groups and process each participant's data.
for g = cfg.groups
    cfg.currentGroup = g{:};
    cfg.currentPrefix = cfg.currentGroup(1);
    cfg.rawGrDir = strcat(cfg.rawDir,cfg.currentGroup,'\');
    cfg.srcDir = strcat(cfg.desDir, cfg.currentGroup, '\');

    % Identify all participant pairs in the current group folder.
    sourceList    = dir([cfg.rawGrDir, '*_*']);
    sourceList    = struct2cell(sourceList);
    sourceList    = sourceList(1,:);
    numOfSources  = length(sourceList);
    
    for i = 1:numOfSources
        % Create a copy of the cfg structure for each participant pair.
        cfg_part = cfg;
        cfg_part.currentPair = sourceList{i};
        cfg_part.problems = {}; % Initialize empty error log.
        cfg_part.steps = {}; % Initialize empty step log.
        
        % Convert NIRX data to SPM format.
        cfg_part = LTC_NIRxtoSPM(cfg_part);
        
        %now loop through every relevant segment of the task (tangram, laughter, interaction)
        for s = cfg_part.segments
            cfg_part.currentSegment = s{:};
            
            %segment data based on experimental markers.
            cfg_part = LTC_segment(cfg_part);
            
            %preprocess data (filtering, motion correction, etc.).
            cfg_part = LTC_preprocess(cfg_part);
            
            %wavelet transform coherence
            cfg_part = LTC_WTC(cfg_part);
            
            % Restore original source directory path.
            cfg_part.srcDir = cfg.srcDir;
        end 
        
        %save participant's cfg file, which contains a log of all the steps
        %that were ran and the errors
        try
            out_path = strcat(cfg.srcDir, cfg_part.currentPair, '.mat');
            fprintf('The cfg file of pair %s will be saved in \n %s \n', cfg_part.currentPair, out_path);
            save(out_path, 'cfg_part');
            fprintf('Data stored!\n\n');
        catch
            fprintf('Couldnt save data \n');
        end
        
    end
end