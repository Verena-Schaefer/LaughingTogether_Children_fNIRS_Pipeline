function cfg = LTC_WTC(cfg)
	%this function calls a subfunction to calculate the wavelet transform coherence for every
    %participant pair. Then, it saves wtc data as a structure containing the following:
    % 1 - one matrix per channel combination with one value per each time
    % point and period, excluding periods not of interest (i.e. from 
    %greater than 4 times the filter to smaller than minimal trial duration/4)
    % 2 - one vector per channel combination with one value per period
    % (excluding periods not of interest), averaged across timepoints
    % 3 - one value per channel combination representing average WTC across
    % timepoints and periods of interest
	
	%cfg: structure containing all necessary info on where to find the data and where to save them
    
    %Output: updated cfg containing all necessary info on where to find wavelet coherence transform data
    
    %author: Carolina Pletti (carolina.pletti@gmail.com). Based on a script by Trinh Nguyen
    
    if cfg.ROI == 1
        cfg.desDir = strcat(cfg.srcDir, 'Coherence_ROIs\');
    else
        cfg.desDir = strcat(cfg.srcDir, 'Coherence_single_channels\');
    end

    if ~exist(cfg.desDir, 'dir')
        mkdir(cfg.desDir);
    end
    
    out_path = strcat(cfg.desDir, cfg.currentPair, '.mat');
    if ~exist(out_path, 'file')
        try
            [data_sub1, data_sub2] = LTC_load_prep(cfg);
        catch
            problem = {'file for WTC can''t be opened'};
            cfg.problems = [cfg.problems, problem];
            return
        end

        %extract number of trials, numer of channels, and prepare
        %coherence cell. The data structure differs based on segments
        if contains(cfg.currentSegment,'tangram')
            coherences = LTC_tangram(data_sub1, data_sub2, cfg);
        elseif contains(cfg.currentSegment,'laughter')
            coherences = LTC_laughter(data_sub1, data_sub2, cfg);
        elseif contains(cfg.currentSegment,'interaction')
            coherences = LTC_interaction(data_sub1, data_sub2, cfg);
        end
        
        %save data
        try
            fprintf('The wtc data of dyad %s will be saved in \n %s \n', cfg.currentPair, out_path)
            save(out_path, 'coherences');
            fprintf('Data stored!\n\n');
            clear coherences
        catch
            fprintf('Couldnt save data\n'); 
            problem = {'couldn''t save coherence data'};
            cfg.problems = [cfg.problems, problem];
        end
    end
end