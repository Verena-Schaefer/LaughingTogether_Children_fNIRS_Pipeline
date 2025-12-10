function coherences = LTC_interaction(data_sub1, data_sub2, cfg)
    %prepare structure to save the output
    coherences = [];  
    coherences_all = [];
    coherences_avgTime = [];
    coherences_avgAll = [];
    time = [];
    try
        [coherences_all,coherences_avgTime,coherences_avgAll, time] = LTC_prep_WTC(data_sub1, data_sub2, cfg.ROI);
    catch
        fprintf('<strong>WTC did not work and was not saved!</strong>\n');
        problem = {'error in WTC'};
        cfg.problems = [cfg.problems, problem];
    end
    coherences.coherences_all = coherences_all;
    coherences.coherences_avgTime = coherences_avgTime;
    coherences.coherences_avgAll = coherences_avgAll;
    coherences.time = time;
end