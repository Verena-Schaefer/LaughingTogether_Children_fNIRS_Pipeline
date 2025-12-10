function coherences = LTC_laughter(data_sub1, data_sub2, cfg)
    %prepare structure to save the output
    coherences = [];          
    numOfTrials = length(data_sub1.hbo);
    coherences_all{numOfTrials}  = [];
    coherences_avgTime{numOfTrials} = [];
    coherences_avgAll{numOfTrials} = [];
    time{numOfTrials} = [];
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
            fprintf('<strong>WTC did not work for trial %i!</strong>\n', tn);
            problem = {'error in WTC'};
            cfg.problems = [cfg.problems, problem];
        end
    end
    coherences.coherences_all = coherences_all;
    coherences.coherences_avgTime = coherences_avgTime;
    coherences.coherences_avgAll = coherences_avgAll;
    coherences.time = time;
end