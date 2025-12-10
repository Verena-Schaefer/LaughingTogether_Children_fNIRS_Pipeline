function coherences = LTC_tangram(data_sub1, data_sub2, cfg)
    phases = fieldnames(data_sub1);
    %prepare structure to save the output
    phases = phases(1:2);
    temp = cell(length(phases),1);
    coherences = cell2struct(temp, phases);  
    good_phases = length(phases);
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
                continue
            end
        end
        if good_trials == 0
            good_phases = good_phases - 1;
            fprintf('No good trial for phase %s \n', phases{pn}); 
        else
            coherences.(phases{pn}).coherences_all = coherences_all;
            clear coherences_all
            coherences.(phases{pn}).coherences_avgTime = coherences_avgTime;
            clear coherences_avgTime
            coherences.(phases{pn}).coherences_avgAll = coherences_avgAll;
            clear coherences_avgAll
            coherences.(phases{pn}).time = time;
            clear time
        end
    end
    if good_phases == 0
        fprintf('No good trial for any phase\n');
        return
    end
end