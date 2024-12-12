function data_out = LTC_epoch_laughter(data_in)

    %this function cuts the fNIRS time series and saves the part of the time series
    %corresponding to when the participants were
	%watching the videos in the experiment Laughing Together Children.
    
    %data_in: path to .mat file containing time series, time vector and triggers
    
    %Output: structure with the same format as data_in, but containing only data
    % corresponding to the time period of interest
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).
	
	%laughter video start trigger: 4; laughter video end trigger: 5.
    %There are two laughter videos. Data are cut from the first video to
    %the end of the last video
    
    fprintf('time stamp laughter video beginnings');
    evtLaughter  = find(data_in.s(:, 4) > 0)
    fprintf('time stamp laughter video ends');
    evtLaughterEnd  = find(data_in.s(:, 5) > 0)

    if size(evtLaughter,1)==2 && size(evtLaughterEnd,1)==2
        %cut out laughter data
        %check if trials are long enough
        for m = 1:length(evtLaughter)
            if evtLaughterEnd(m)-evtLaughter(m) < 2329 %5 min with 7.8 sampling rate = 2340 points. 2330 to be on the safe side
                fprintf('Too short trial!\n');
            elseif evtLaughterEnd(m)-evtLaughter(m) > 2390 %left "spielraum" in case delays in triggers
                fprintf('Too long trial!\n');
            end
        end
        data_out.y = data_in.y(evtLaughter(1):evtLaughterEnd(2),:);
        data_out.s = data_in.s(evtLaughter(1):evtLaughterEnd(2),:);
        data_out.t = data_in.t(evtLaughter(1):evtLaughterEnd(2),:);
        data_out.SD = data_in.SD;
    else
        fprintf('Trial number is different than expected!\n');
    end

    
end