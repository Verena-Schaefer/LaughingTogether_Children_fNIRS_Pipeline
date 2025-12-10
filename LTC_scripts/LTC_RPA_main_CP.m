%%%%%%%%%%%%%%%%%% LT Project - RPA main script %%%%%%%%%%%%%%%%%%%%%%%
% this script takes preprocessed fNIRS data (see LTC_main_CP for information
% about preprocessing steps), calculates wavelet transform coherence
% between x random pairs per each pair (value can be set in permnum), and calculates the average
% between these random pairs so that for each pair we have a randomly
% created control pair

%added parts to also export RPA data

%the function "LTC_config_paths" needs to be in the Matlab current folder for this script to run! 

%author: Carolina Pletti (carolina.pletti@gmail.com)

clear all

%---------------------------------------------------------

% create empty structure that will contain all necessary parameters

cfg = [];
cfg.overwrite = 0; %set to 1 if you want to overwrite all data (converted data will not be overwritten, all other steps will)
cfg.groups = {'Lachen','Kontrolle'}; %names of the groups to be analyzed. Should correspond to subfolder names inside the raw data folder below
cfg.segments = {'tangram', 'laughter', 'interaction'}; %segment of the experiment to be analyzed
cfg.permnum = 100; %how many random pairs should be calculated?


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
            cfg = LTC_config_paths(cfg, 0);
        case 3
            sel = true;
            fprintf('please change this script and the config_path function so that the paths match with where you store data, toolboxes and scripts!');
        return;
        otherwise
            cprintf([1,0.5,0], 'Wrong input!\n');
        return
    end
end



%decide what you want the analysis to do
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
%create a list of all sources, for all groups
cfg.sources = [];

for g = cfg.groups
    cfg.currentGroup = g{:};
    cfg.rawGrDir = strcat(cfg.rawDir,cfg.currentGroup,'\');

    %identify all file in the group subdirectory
    sourceList    = dir([cfg.rawGrDir, '*_*']);
    sourceList    = struct2cell(sourceList);
    sourceList    = sourceList(1,:);
    cfg.sources = [cfg.sources, sourceList];

end

%loop through all file and calculate 100 wavelet transform coherence
%between randomly extracted pairs

numOfSources = length(cfg.sources);
cfg.dataDir = cfg.desDir;

for i = 1:numOfSources
    for s = cfg.segments
        cfg.currentSegment = s{:}
        %retrieve unmodified cfg info
        cfg_part = cfg;
        cfg_part.currentPair = cfg_part.sources{i};
        temp = strsplit(cfg_part.currentPair, '_');
        cfg_part.currentPrefix = temp{1};
        if temp{1} == 'L'
            cfg_part.currentGroup = 'Lachen';
        elseif temp{1} == 'K'
            cfg_part.currentGroup = 'Kontrolle';
        end
        cfg_part.srcDir = strcat(cfg_part.dataDir, cfg_part.currentGroup, '\', cfg_part.currentSegment, '\preprocessed\');
        fprintf('processing participant %s \n', cfg_part.currentPair)
        %random permutation wavelet transform coherence
        try
            cfg_part = LTC_RPA(cfg_part);
        catch
            fprintf('couldn''t calculate random pairs for participant %s \n', cfg_part.currentPair)
            continue
        end
    
        %average all RPA files for this participant
        try
            cfg_part = LTC_RPA_avg(cfg_part);
        catch
            fprintf('couldn''t calculate averages for participant %s \n', cfg_part.currentPair)
            continue
        end
    end
end