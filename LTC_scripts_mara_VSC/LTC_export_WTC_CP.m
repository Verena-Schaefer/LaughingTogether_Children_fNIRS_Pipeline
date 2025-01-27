%%%%%%%%%%%%%%%%%% LT Project - Export script for group data %%%%%%%%%%%%%%%%%%%%%%%
% this script opens and exports aggregated wavelet transform coherence data and saves
% them in an appropriate format for future analyses (as a .csv file).

%the final dataframe should look like this in case of WTC values aggregated through time points and periods:
%channel1 channel2 channel3 ... Subject Interval Group (one line per
%participant)

%the final dataframe should look like this in case of WTC values aggregated through time points:
%channel1 channel2 channel3 ... Period Subject Interval Group (one line per
%each combination of participant and period)

%the function "LT_config_paths" needs to be in the Matlab current folder for this script to run! 

%author: Carolina Pletti (carolina.pletti@gmail.com)

clear all

%---------------------------------------------------------

% create empty structure that will contain all necessary parameters

cfg = [];
cfg.groups = {'Lachen','Kontrolle'}; % Names of participant groups; should match subfolder names in the raw data directory.
cfg.segments = {'interaction', 'laughter', 'tangram'}; % Experiment segments to be analyzed.
cfg.labels = {'IFGr', 'IFGl', 'TPJr', 'TPJl'}; %ROIs

%decide what you want the analysis to do
sel_export = false;

while sel_export == false
    fprintf('\nPlease select one option:\n');
    fprintf('[1] - Export coherences averaged through time and frequencies\n');
    fprintf('[2] - Export coherences averaged through time\n');
    fprintf('[3] - Quit\n');

    x = input('Option: ');

    switch x
        case 1
            sel_export = true;
            cfg.avg = 'all';
        case 2
            sel_export = true;
            cfg.avg = 'time';
        case 3
            fprintf('\nProcess aborted.\n');
        return;
        otherwise
            cprintf([1,0.5,0], 'Wrong input!\n');
    end
end


% --------------------------------------------------------------------
%set all paths for loading and saving data, add folder with functions to the path. Change paths in the config_paths
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


%set the loop that run the functions through all data
%create a list of all sources, for all groups
cfg.sources = [];

for g = cfg.groups
    cfg.currentGroup = g{:};
    cfg.currentPrefix = cfg.currentGroup(1);
    cfg.rawGrDir = strcat(cfg.rawDir,cfg.currentGroup,'\');

    %identify all file in the group subdirectory
    sourceList    = dir([cfg.rawGrDir, '*_*']);
    sourceList    = struct2cell(sourceList);
    sourceList    = sourceList(1,:);
    cfg.sources = [cfg.sources, sourceList];

end

cfg.numOfSources = length(cfg.sources);
cfg.dataDir = cfg.desDir;

for s = cfg.segments
    cfg.currentSegment = s{:};
    
    if contains(cfg.currentSegment, 'tangram')
        cfg.fields = {'alone', 'together', 'rest'};
        phases = numel(cfg.fields);
        for i = 1:phases
            % Get the field name
            fieldName = cfg.fields{i};   
            LTC_export_WTC_data_CP(fieldName, cfg);
        end
    else
        LTC_export_WTC_data_CP(cfg.currentSegment, cfg);
    end
end


