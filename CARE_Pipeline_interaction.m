%% CARE Hyperscanning Pipeline Data preparation

% -------------------------------------------------------------------------
% Path settings
% ------------------------------------------------------------------------- 
srcPath = 'X:/hoehl/projects/LT/LTC/Analyses/Verena_analyses/fNIRS/MARA_preprocessing/rawData/';        % location of raw data
desPath = 'X:/hoehl/projects/LT/LTC/Analyses/Verena_analyses/fNIRS/MARA_preprocessing/procData/';      % memory space for processed data
gsePath = 'X:/hoehl/projects/LT/LTC/Analyses/Verena_analyses/fNIRS/MARA_preprocessing/';  % location of SD file

%% 
% % Build subfolders if not yet created
% if ~exist(strcat(desPath, '00_settings'), 'dir')
%   mkdir(strcat(desPath, '00_settings'));
% end
% if ~exist(strcat(desPath, '01_nirs'), 'dir')
%   mkdir(strcat(desPath, '01_nirs'));
% end
% if ~exist(strcat(desPath, '02a_preproc'), 'dir')
%   mkdir(strcat(desPath, '02a_preproc'));
% end
% if ~exist(strcat(desPath, '02b_trial'), 'dir')
%   mkdir(strcat(desPath, '02b_trial'));
% end
% if ~exist(strcat(desPath, '03a_xcorr'), 'dir')
%   mkdir(strcat(desPath, '03a_xcorr'));
% end
% if ~exist(strcat(desPath, '03b_wtc'), 'dir')
%   mkdir(strcat(desPath, '03b_wtc'));
% end
% if ~exist(strcat(desPath, '04a_rpa'), 'dir')
%   mkdir(strcat(desPath, '04a_rpa'));
% end
% if ~exist(strcat(desPath, '05_nirs_interaction'), 'dir')
%   mkdir(strcat(desPath, '05_nirs_interaction'));
% end
% 



%% -------------------------------------------------------------------------
% Generate SD file if needed - VSC deleted


% %% -------------------------------------------------------------------------
% % Data conversion
% % -------------------------------------------------------------------------
% % -------------------------------------------------------------------------
% % Specific selection of dyads
% % -------------------------------------------------------------------------
prefix        = 'L'; %insert name of the project/files
sourceList    = dir([srcPath, prefix, '_*']);
sourceList    = struct2cell(sourceList);
sourceList    = sourceList(1,:);
numOfSources  = length(sourceList);
numOfPart       = zeros(1, numOfSources);

for i=1:1:numOfSources
  numOfPart(i)     = sscanf(sourceList{i}, [prefix, '_%d']);
end

for i = numOfPart
  srcFolder   = strcat(srcPath, sprintf([prefix, '_%02d/'], i)); % select source folder of where raw data is saved, file names are for example MCARE_02, change this part if your files are named differently
  srcNirsSub1 = sprintf(['Subject1/', prefix, '_%02d.mat'], i);
  srcNirsSub2 = sprintf(['Subject2/', prefix, '_%02d.mat'], i);
  fileSub1    = strcat(srcFolder, srcNirsSub1);
  fileSub2    = strcat(srcFolder, srcNirsSub2);
  desFolder   = strcat(desPath, '01_nirs/'); 
  
    cfg = [];
    cfg.dyadNum     = i;
    cfg.prefix      = prefix;
    cfg.srcPath     = srcPath;
    cfg.desPath     = desFolder;
    cfg.SDfile      = strcat(gsePath, prefix, '.SD');    
    CARE_spmfnirs_NIRxtoSPM_VSC( cfg );

% Segmentation after conversion
  segmentation_interaction(strcat(desFolder, sprintf([prefix, '_%02da_spm_fnirs.mat'], i)), desPath);
  segmentation_interaction(strcat(desFolder, sprintf([prefix, '_%02db_spm_fnirs.mat'], i)), desPath);
 
end
% 
% 
clear cfg i desFolder srcFolder srcNirsSub1 srcNirsSub2 fileSub1 ...
      fileSub2 fileDesSub1 fileDesSub2
  

%% -------------------------------------------------------------------------
% Data processing
% ------------------------------------------------------------------------- 
  prefix='L';%VSC changed 
  sourceDir = strcat(desPath, '05_nirs_interaction/');
  sourceList    = dir([strcat(desPath, '05_nirs_interaction/'), ...
                  strcat('L_*_spm_fnirs.mat')]);    %original version strcat('*_a_spm_fnirs.mat')]);
 
  
  
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                       strcat(prefix, '_%02da_spm_fnirs', '.mat'));%from original code: strcat(prefix, '_d%da_01_spm_fnirs','.mat')); 
                    
  end  
    numOfPart=unique(numOfPart);
    
%     
%% 
% preprocessing
for i = numOfPart
  fprintf('<strong>Dyad %d</strong>\n', i);
  
  % load raw data of subject 1
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '05_nirs_interaction/');
  cfg.filename    = sprintf([prefix, '_%02da_spm_fnirs'], i);
  
  load( strcat(cfg.srcFolder, cfg.filename, '.mat'));
  
  data_raw.sub1.SD            = SD;
  data_raw.sub1.SD.sub        = 1;
  data_raw.sub1.y             = y;
  data_raw.sub1.s             = s;
  data_raw.sub1.aux           = aux;
  data_raw.sub1.t             = t;
  
  clear SD d s aux t 
  
  % load raw data of subject 2
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '05_nirs_interaction/');
  cfg.filename    = sprintf([prefix, '_%02db_spm_fnirs'], i);
  
  load( strcat(cfg.srcFolder, cfg.filename, '.mat'));

  data_raw.sub2.SD            = SD;
  data_raw.sub2.SD.sub        = 2;
  data_raw.sub2.y             = y;
  data_raw.sub2.s             = s;
  data_raw.sub2.aux           = aux;
  data_raw.sub2.t             = t;
  
  clear SD d s aux t 
  
  % preprocess raw data of both subjects

  data_preproc = CARE_spmfnirs_preproc_original_script(cfg, data_raw);
  
  
  % save preprocessed data
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '02a_preproc/');
  cfg.filename    = sprintf([prefix, '_d%02d_02a_preproc'], i);
  
  file_path = strcat(cfg.desFolder, cfg.filename, ...
                     '.mat');

  save(file_path, 'data_preproc');
  clear data_raw file_path
  
  % extract data of conditions from continuous data stream
  cfg = [];
  cfg.prefix = prefix;

  data_trial = CARE_getTrl(cfg, data_preproc);
  
  
  % save trial-based data
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '02b_trial/');
  cfg.filename    = sprintf([prefix, '_d%02d_02b_trial'], i);
  
  file_path = strcat(cfg.desFolder, cfg.filename, ...
                     '.mat');

  save(file_path, 'data_trial');
  clear data_preproc data_trial file_path 
  
end

clear cfg i file_path pulse pulseCfg 
fprintf('Pipeline execution completed.\n');%VSC added
  