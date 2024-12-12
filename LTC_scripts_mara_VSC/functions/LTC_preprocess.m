function cfg = LTC_preprocess(cfg)
    %this function calls another function (LTC_prep) containing the following preprocessing steps:
    %1: convert the wavelength data to optical density
    %2: MARA motion correction
    %3: Scalp-coupling index check
    %4: manual rejection of bad channels through visual inspection
    %5: bandpass filtering
    %6: converts changes in optical density to changes in HbO, HbR and HbT
    %concentration
	
	%cfg: structure containing all necessary info on where to find the data and where to save them
    
    %Output: updated cfg containing all necessary info on where to find preprocessed data
    
    %this function calls functions from the toolboxes Homer2 and spmfnirs.
    %These toolboxes should be added to the matlab path for this function
    %to work
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).
    
    cfg.desDir = strcat(cfg.srcDir, 'preprocessed\');
    error = 0;
        
    if ~exist(cfg.desDir, 'dir')
        mkdir(cfg.desDir);
    end
  
    % preprocessing
    
    %for each participant in a pair
    for i = 1:2
    
        % load segment data
        fileName    = strcat(cfg.currentPair, '_sub', int2str(i));
        file_path = strcat(cfg.srcDir, fileName, '.mat');
        out_path = strcat(cfg.desDir, fileName, '.mat');
        
        if ~exist(out_path, 'file')
            fprintf('Load data of subject ')
            fprintf(fileName)
            fprintf('\n');
            try
                load(file_path);
            catch
                problem = {'file to prep can''t be opened'};
                cfg.problems = [cfg.problems, problem]; 
                continue
            end
            
            try
                [hbo, hbr, badChannels, SCIList, fs]= LTC_prep(data_out.t, data_out.y, data_out.SD);   
                t = data_out.t;
                s = data_out.s;
            catch
                error = 1;
                fprintf('<strong>preprocessing did not work and was not saved!</strong>\n');
                fprintf('check preprocessing of participant ')
                fprintf(fileName);
                fprintf('\n')
                problem = {'error in preprocessing'};
                cfg.problems = [cfg.problems, problem];
            end
            
            if ~error
                fprintf('The preprocessed data of dyad ')
                fprintf(fileName)
                fprintf('will be saved in\n'); 
                fprintf('%s ...\n', out_path);
                save(out_path, 'hbo','hbr','s','t', 'fs', 'badChannels');
                outTable = strcat(out_path, '_SCI.mat');
                save (outTable, 'SCIList');
                fprintf('Data stored!\n\n');
            end
        end
    end
    
    cfg.srcDir = cfg.desDir;
    cfg.steps = [cfg.steps, {'preprocessing'}];
end