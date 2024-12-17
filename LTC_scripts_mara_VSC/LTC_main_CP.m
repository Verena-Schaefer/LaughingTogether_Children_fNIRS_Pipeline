%%%%%%%%%%%%%%%%%% LTC Project - Main script %%%%%%%%%%%%%%%%%%%%%%%
% this script takes raw fNIRS data in the NIRX specific format, converts them so they can be preprocessed using Homer2 and spmfnirs functions, extracts
% segments of interest based on markers in the data, cleans and
% preprocesses the data, and calculates synchrony between pairs of participants
% using wavelet transform coherence

%the function "LTC_config_paths" needs to be in the Matlab current folder for this script to run! 

%author: Carolina Pletti (carolina.pletti@gmail.com)

clear all

%---------------------------------------------------------

% create empty structure that will contain all necessary parameters for
% preprocessing

cfg = [];
cfg.overwrite = 0; %set to 1 if you want to overwrite all data (converted data will not be overwritten, all other steps will)
cfg.groups = {'Lachen','Kontrolle'}; %names of the groups to be analyzed. Should correspond to subfolder names inside the raw data folder below
cfg.segments = {'tangram', 'laughter', 'interaction'}; %segments of the experiment to be analyzed. Options: tangram, laughter, interaction


% --------------------------------------------------------------------
%set all paths for loading and saving data, add folder with functions and Homer2 to the path. Change paths in the config_paths
%function and following part of the script based on necessity 

sel = false;

while sel == false
    fprintf('\nPlease select one option:\n');
    fprintf('[1] - Carolina''s workspace at the uni\n');
    fprintf('[2] - Carolina''s workspace at home\n');
    fprintf('[3] - None of the above\n');

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
            fprintf('please change this script and the config_path function so that the paths match with where you store data, toolboxes and scripts!');
        return;
        otherwise
            cprintf([1,0.5,0], 'Wrong input!\n');
        return
    end
end

sel_ROI = false;

while sel_ROI == false
    fprintf('\nPlease select one option:\n');
    fprintf('[1] - Calculate coherence by channel\n');
    fprintf('[2] - Calculate coherence by ROI\n');
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


%set the loop that run the functions through all data
for g = cfg.groups
    cfg.currentGroup = g{:};
    cfg.currentPrefix = cfg.currentGroup(1);
    cfg.rawGrDir = strcat(cfg.rawDir,cfg.currentGroup,'\');
    cfg.srcDir = strcat(cfg.desDir, cfg.currentGroup, '\');

    %identify all file in the group subdirectory
    sourceList    = dir([cfg.rawGrDir, '*_*']);
    sourceList    = struct2cell(sourceList);
    sourceList    = sourceList(1,:);
    numOfSources  = length(sourceList);
    
    for i = 1:numOfSources
        %retrieve unmodified cfg info
        cfg_part = cfg;
        cfg_part.currentPair = sourceList{i};
        cfg_part.problems = {};
        cfg_part.steps = {};
        
        %convert data
        
        cfg_part = LTC_NIRxtoSPM(cfg_part);

        
        %now loop through for every relevant segment of the task (laughter, interaction)
        for s = cfg_part.segments
            cfg_part.currentSegment = s{:};
            
            %segment data
            cfg_part = LTC_segment(cfg_part);
            
            %preprocess data
            cfg_part = LTC_preprocess(cfg_part);
            
            %wavelet transform coherence
            %cfg_part = LT_WTC(cfg_part);
            
            cfg_part.srcDir = cfg.srcDir;
        end 
        
        %save participant's cfg file, which contains a log of all the steps
        %that were ran
        try
            out_path = strcat(cfg.srcDir, cfg_part.currentPair, '.mat');
            fprintf('The cfg file of pair %s will be saved in/n %s /n', cfg_part.currentPair, out_path);
            save(out_path, 'cfg_part');
            fprintf('Data stored!\n\n');
        catch
            fprintf('Couldnt save data \n');
        end
        
    end
end