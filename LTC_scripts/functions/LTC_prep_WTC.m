function [coherences_all,coherences_avgTime,coherences_avgAll, time] = LTC_prep_WTC(data_sub1, data_sub2, ROI)
    %calculate ROIs
    if iscell(data_sub1.hbo)
        hbo_1 = data_sub1.hbo{:};
        badChannels_1 = data_sub1.badChannels{:};
        t = data_sub1.t{:};
        hbo_2 = data_sub2.hbo{:};
        badChannels_2 = data_sub2.badChannels{:};
        t_2 = data_sub2.t{:};
    else
        hbo_1 = data_sub1.hbo;
        badChannels_1 = data_sub1.badChannels;
        t = data_sub1.t;
        hbo_2 = data_sub2.hbo;
        badChannels_2 = data_sub2.badChannels;
        t_2 = data_sub2.t;
    end
    
    
    
    %the time vectors for both participants should be identical.
    %check if that's the case
    if length(t) ~= length(t_2)
        fprintf('the time vectors of the two participants don''t correspond!')
        shortest_duration = min(length(t), length(t_2));
        t = t(1:shortest_duration);
        hbo_1 = hbo_1(1:shortest_duration, :);
        hbo_2 = hbo_2(1:shortest_duration, :);
    end
    if ROI == 1
        %average all channels by ROI
        [hbo_1, badChannels_1] = LTC_calcROI(hbo_1, badChannels_1);
        [hbo_2, badChannels_2] = LTC_calcROI(hbo_2, badChannels_2);
    end
    
    %calculate sampling rate and sampling period
    ts = t(2)-t(1);
    fs = 1/ts;
			
    

    %calculate coherences

    try
        coherences_all = LTC_calcCoherence(hbo_1, hbo_2, badChannels_1, badChannels_2, t, fs);
    catch exception
        fprintf('couldnt calculate coherence for this part!\n');
        msgText = getReport(exception);
        fprintf(msgText);
        problem = {'couldn''t calculate coherence'};
        cfg.problems = [cfg.problems, problem];
        return;
    end
            
    % calculate the averages
            
    for i = 1:length(coherences_all)
        %average through time, one value per period
        headers = coherences_all{i}(:,1:3);
        avgTime = nanmean(coherences_all{i}(:,4:end),2);
        %average through period as well. One value per channel.
        avgAll = nanmean(avgTime);
        coherences_avgTime{i} = [headers, avgTime];
        coherences_avgAll{i} = [headers(1,2:3),avgAll];
    end
        time = t;
    end