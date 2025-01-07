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
    
    good_trials = 0;
    
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
            phases = fieldnames(data_sub1);
            %prepare structure to save the output
            phases = phases(1:3);
            temp = cell(length(phases),1);
            coherences = cell2struct(temp, phases);  
            for pn = 1:length(phases)
                phase_data_1 = data_sub1.(phases{pn});
                phase_data_2 = data_sub2.(phases{pn});
                numOfTrials = length(phase_data_1.hbo);
                %space to save coherence for each combination of time and
                %period(frequency)
                coherences_all{numOfTrials}  = [];
                coherences_avgTime{numOfTrials} = [];
                coherences_avgAll{numOfTrials} = [];
                time{numOfTrials} = [];
                good_trials = numOfTrials;
                for tn = 1:numOfTrials
                    fieldNames = fieldnames(phase_data_1);
                    % Create a new structure containing only data of trial
                    % tn
                    trial_data_1 = cell2struct(cellfun(@(field) phase_data_1.(field)(tn), ...
                                      fieldNames, 'UniformOutput', false), ...
                                      fieldNames, 1);
                    trial_data_2 = cell2struct(cellfun(@(field) phase_data_2.(field)(tn), ...
                                      fieldNames, 'UniformOutput', false), ...
                                      fieldNames, 1);
                    try
                        [coherences_all{tn},coherences_avgTime{tn},coherences_avgAll{tn}, time{tn}] = LTC_prep_WTC(trial_data_1, trial_data_2, cfg.ROI);
                    catch
                        good_trials = good_trials -1;
                        fprintf('<strong>WTC did not work for trial %i!</strong>\n', tn);
                        problem = {'error in WTC'};
                        cfg.problems = [cfg.problems, problem];
                    end
                end
                coherences.(phases{pn}).coherences_all = coherences_all;
                clear coherences_all
                coherences.(phases{pn}).coherences_avgTime = coherences_avgTime;
                clear coherences_avgTime
                coherences.(phases{pn}).coherences_avgAll = coherences_avgAll;
                clear coherences_avgAll
                coherences.(phases{pn}).time = time;
                clear time
            end
        elseif contains(cfg.currentSegment,'laughter')
            %prepare structure to save the output
            coherences = [];          
            numOfTrials = length(data_sub1.hbo);
            coherences_all{numOfTrials}  = [];
            coherences_avgTime{numOfTrials} = [];
            coherences_avgAll{numOfTrials} = [];
            time{numOfTrials} = [];
            good_trials = numOfTrials;
            for tn = 1:numOfTrials
                fieldNames = fieldnames(data_sub1);
                % Create a new structure containing only data of trial
                % tn
                trial_data_1 = cell2struct(cellfun(@(field) data_sub1.(field)(tn), ...
                                  fieldNames, 'UniformOutput', false), ...
                                  fieldNames, 1);
                trial_data_2 = cell2struct(cellfun(@(field) data_sub2.(field)(tn), ...
                                  fieldNames, 'UniformOutput', false), ...
                                  fieldNames, 1);
                try
                    [coherences_all{tn},coherences_avgTime{tn},coherences_avgAll{tn}, time{tn}] = LTC_prep_WTC(trial_data_1, trial_data_2, cfg.ROI);
                catch
                    good_trials = good_trials - 1;
                    fprintf('<strong>WTC did not work and was not saved!</strong>\n');
                    problem = {'error in WTC'};
                    cfg.problems = [cfg.problems, problem];
                end
            end
            coherences.coherences_all = coherences_all;
            clear coherences_all
            coherences.coherences_avgTime = coherences_avgTime;
            clear coherences_avgTime
            coherences.coherences_avgAll = coherences_avgAll;
            clear coherences_avgAll
            coherences.time = time;
            clear coherences_time
        elseif contains(cfg.currentSegment,'interaction')
            %prepare structure to save the output
            coherences = [];  
            good_trials = 1;
            coherences_all = [];
            coherences_avgTime = [];
            coherences_avgAll = [];
            time = [];
            try
                [coherences_all,coherences_avgTime,coherences_avgAll, time] = LTC_prep_WTC(data_sub1, data_sub2, cfg.ROI);
            catch
                good_trials = good_trials -1;
                fprintf('<strong>WTC did not work and was not saved!</strong>\n');
                problem = {'error in WTC'};
                cfg.problems = [cfg.problems, problem];
            end
            coherences.coherences_all = coherences_all;
            clear coherences_all
            coherences.coherences_avgTime = coherences_avgTime;
            clear coherences_avgTime
            coherences.coherences_avgAll = coherences_avgAll;
            clear coherences_avgAll
            coherences.time = time;
            clear time
        end
        
        %save data
        if good_trials > 0
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
end