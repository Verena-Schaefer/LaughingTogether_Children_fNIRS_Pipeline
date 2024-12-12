function data_out = LTC_epoch_tangram(data_in,fs)

    %this function cuts the fNIRS time series and saves the part of the time series corresponding to when the participants were
	%doing the tangram puzzle in the experiment Laughing Together Children.
    
    %data_in: path to .mat file containing time series, time vector and triggers
    
    %fs: sampling frequency in Hz
    
    %Output: structure with the same format as data_in, but containing only data
    %corresponding to the time period of interest
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).
	
	%tangram alone start trigger: 1; tangram together trigger: 2.
    %rangram rest trigger: 3: There are two trials each for alone and
    %together, and three rests in between all trials. The first trial is
    %an "alone" trials and the last trial is a "together" trial. Data are
    %cut from the first "alone" trial to the end of the last "together" trial
    
    fprintf('time stamp tangram alone');
    evtAlone  = find(data_in.s(:, 1) > 0)
    fprintf('time stamp tangram together');
    evtTogether  = find(data_in.s(:, 2) > 0)
    fprintf('time stamp tangram rest');
    evtRest  = find(data_in.s(:, 3) > 0)

    if size(evtAlone,1)==2 && size(evtTogether,1)==2 && size(evtRest,1) ==3
        %cut out tangram data
        data_out.y = data_in.y(evtAlone(1):round(evtTogether(2)+120*fs),:); %cut data from first alone trigger to two minutes after last together trigger
        data_out.s = data_in.s(evtAlone(1):round(evtTogether(2)+120*fs),:);
        data_out.t = data_in.t(evtAlone(1):round(evtTogether(2)+120*fs),:);
        data_out.SD = data_in.SD;
    else
        fprintf('Trial number is different than expected!\n');
    end
end