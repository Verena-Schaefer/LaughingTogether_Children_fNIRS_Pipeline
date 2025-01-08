%%%% work in progress!!!%%%

%%%%%%%%%%%%%%%%%% LT Project - Export script for group data %%%%%%%%%%%%%%%%%%%%%%%
% this script opens and exports wavelet transform coherence data and saves
% them in an appropriate format for future analyses (as a single .csv file
% in case of averaged WTCs, as a series of .csv files - one per participant pair
% - in case of WTC matrixes with one value per time point and channel).

%the final dataframe should look like this in case of WTC values aggregated through time points and periods:
%channel1 channel2 channel3 ... Subject Interval Group (one line per
%participant)

%the final dataframe should look like this in case of WTC values aggregated through time points:
%channel1 channel2 channel3 ... Period Subject Interval Group (one line per
%each combination of participant and period)

%the final dataframes should look like this in case of non-aggregated WTC values:
%channel1 channel2 channel3 ... Period Subject Interval Group (one file per
%participant, one line per time point)

%the function "LT_config_paths" needs to be in the Matlab current folder for this script to run! 

%author: Carolina Pletti (carolina.pletti@gmail.com)

clear all

%---------------------------------------------------------

% create empty structure that will contain all necessary parameters

cfg = [];
cfg.groups = {'IC','IL','NIC','NIL'}; %names of the groups to be analyzed. Should correspond to subfolder names inside the raw data folder below
cfg.segment = 'interaction_long'; %segment of the experiment to be analyzed. Options: laughter, interaction, interaction_long

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
            cfg = LT_config_paths(cfg, 1);
        case 2
            sel = true;
            cfg = LT_config_paths(cfg, 0)
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
sel_export = false;

while sel_export == false
    fprintf('\nPlease select one option:\n');
    fprintf('[1] - Export coherences averaged through time and frequencies\n');
    fprintf('[2] - Export coherences averaged through time\n');
    fprintf('[3] - Export non-averaged coherences\n');
    fprintf('[4] - Quit\n');

    x = input('Option: ');

    switch x
        case 1
            sel_export = true;
            cfg.avgTime = 1;
            cfg.avgFreq = 1;
        case 2
            sel_export = true;
            cfg.avgTime = 1;
            cfg.avgFreq = 0;
        case 3
            sel_export = true;
            cfg.avgTime = 0;
            cfg.avgFreq = 0;
        case 4
            fprintf('\nProcess aborted.\n');
        return;
        otherwise
            cprintf([1,0.5,0], 'Wrong input!\n');
    end
end


%parte dello script presa da "LT_RPA_main" da modificare
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

numOfSources = length(cfg.sources);
cfg.dataDir = cfg.desDir;

for i = 1:numOfSources
    %retrieve unmodified cfg info
    cfg_part = cfg;
    cfg_part.currentPair = cfg_part.sources{i};
    temp = strsplit(cfg_part.currentPair, '_');
    cfg_part.currentGroup = temp{1};
    cfg_part.srcDir = strcat(cfg_part.dataDir, cfg_part.currentGroup, '\', cfg_part.segment, '\preprocessed\');
    fprintf('processing participant %s \n', cfg_part.currentPair)
    %random permutation wavelet transform coherence
    try
        cfg_part = LT_RPA(cfg_part);
    catch
        fprintf('couldn''t calculate random pairs for participant %s \n', cfg_part.currentPair)
        continue
    end
    
    %average all RPA files for this participant
    try
        cfg_part = LT_RPA_avg(cfg_part);
    catch
        fprintf('couldn''t calculate averages for participant %s \n', cfg_part.currentPair)
        continue
    end
end 

%parte "vecchia" dello script

for i = 1:length(grDir)
    for j = 1:length(subDir)
        srcPath = strcat(srcDir, grDir{i}, '\', subDir{j}, '\preprocessed\Coherence_ROIs\');
        sourceList    = dir([srcPath, '*.mat']);
        sourceList    = struct2cell(sourceList);
        sourceList    = sourceList(1,:);
        numOfSources  = length(sourceList);
        numOfPart       = zeros(1, numOfSources);
  
        prefix = grDir{i};
    
        for k=1:1:numOfSources
       
            numOfPart(k)  = sscanf(sourceList{k}, ...
                        strcat(prefix,'_%d_C.mat'));
        end

        for id = numOfPart
            id
            filename = strcat(srcPath, prefix, sprintf('_%02d', id),'.mat');
            % load coherence data
            load(filename);             
            
            % copy info from each file in big dataframe.
                        
            Pair = id;
            Group = string(prefix);
            Condition = string(subDir{j});
            %per ognuno dei due intervalli
            for int = 1:2
                Interval = int;
                IFGr = coherences.avgAll{1,int}{1,1}(1,3);
                IFGl = coherences.avgAll{1,int}{1,6}(1,3);
                TPJr = coherences.avgAll{1,int}{1,11}(1,3);
                TPJl = coherences.avgAll{1,int}{1,16}(1,3);
                
                if ~exist('data', 'var')
                    data = table(IFGr, IFGl, TPJr, TPJl, ...,
                         Condition, Pair, Interval, Group);
                else
                    pairData = table(IFGr, IFGl, TPJr, TPJl, ...,
                         Condition, Pair, Interval, Group);
                    data = [data; pairData];
                end
            end
        end
    end
end


desFile = 'X:\hoehl\projects\LT\LT_adults\Carolina_analyses\fNIRS\data_prep\data\IC_IL_Data_ROI.csv';
writetable(data,desFile,'Delimiter',',','QuoteStrings',true)
fprintf('\nDone!\n');