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
            fprintf('Load data of subject %s \n', fileName)
            try
                load(file_path);
            catch
                problem = {'file to prep can''t be opened'};
                cfg.problems = [cfg.problems, problem]; 
                continue
            end
            
            
            %extract trial data for preprocessing. The data structure
            %differs based on segments
            if contains(cfg.currentSegment,'tangram')
                phases = fieldnames(data_out);
                %prepare structure to save the output
                temp = cell(length(phases),1);
                data_prep = cell2struct(temp,phases);
                phases = phases(1:3);
                
                for pn = 1:length(phases)
                    trial_number = length(data_out.(phases{pn}).y);
                    for tn = 1:trial_number
                        try
                            [hbo, hbr, badChannels] = LTC_prep(data_out.(phases{pn}).t{tn}, data_out.(phases{pn}).y{tn}, data_out.SD);
                            data_prep.(phases{pn}).s{tn} = data_out.(phases{pn}).s{tn};
                            data_prep.(phases{pn}).hbo{tn} = hbo;
                            data_prep.(phases{pn}).hbr{tn} = hbr;
                            data_prep.(phases{pn}).badChannels{tn} = badChannels;
                        catch
                            error = 1;
                            fprintf('<strong>preprocessing did not work and was not saved!</strong>\n');
                            fprintf('check preprocessing of participant %s \n', fileName)
                            problem = {'error in preprocessing'};
                            cfg.problems = [cfg.problems, problem];
                        end
                    end
                end
            elseif contains(cfg.currentSegment,'laughter')
                %prepare structure to save the output
                data_prep = [];          
                trial_number = length(data_out.y);
                    for tn = 1:trial_number
                        try
                            [hbo, hbr, badChannels] = LTC_prep(data_out.t{tn}, data_out.y{tn}, data_out.SD);
                            data_prep.s{tn} = data_out.s{tn};
                            data_prep.hbo{tn} = hbo;
                            data_prep.hbr{tn} = hbr;
                            data_prep.badChannels{tn} = badChannels;
                        catch
                            error = 1;
                            fprintf('<strong>preprocessing did not work and was not saved!</strong>\n');
                            fprintf('check preprocessing of participant %s \n', fileName)
                            problem = {'error in preprocessing'};
                            cfg.problems = [cfg.problems, problem];
                        end
                    end
            elseif contains(cfg.currentSegment,'interaction')
                %prepare structure to save the output
                data_prep = [];          
                try
                    [hbo, hbr, badChannels] = LTC_prep(data_out.t, data_out.y, data_out.SD);
                    data_prep.s = data_out.s;
                    data_prep.hbo = hbo;
                    data_prep.hbr = hbr;
                    data_prep.badChannels = badChannels;
                catch
                    error = 1;
                    fprintf('<strong>preprocessing did not work and was not saved!</strong>\n');
                    fprintf('check preprocessing of participant %s \n', fileName)
                    problem = {'error in preprocessing'};
                    cfg.problems = [cfg.problems, problem];
                end
            end
            
            if ~error
                fprintf('The preprocessed data of dyad %s will be saved in \n %s \n', fileName, out_path)
                save(out_path, 'data_prep');
                fprintf('Data stored!\n\n');
            end
        end
    end
    
    cfg.srcDir = cfg.desDir;
    cfg.steps = [cfg.steps, {'preprocessing'}];
end