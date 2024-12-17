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
    %together, and three rests in between all trials.
    
    fprintf('time stamp tangram alone');
    evtAlone  = find(data_in.s(:, 1) > 0)
    fprintf('time stamp tangram together');
    evtTogether  = find(data_in.s(:, 2) > 0)
    fprintf('time stamp tangram rest');
    evtRest  = find(data_in.s(:, 3) > 0)

    if size(evtAlone,1)==2 && size(evtTogether,1)==2 && size(evtRest,1) ==3
        %cut out tangram data
        for m = 1:size(evtAlone,1)
            data_out.alone.y{m} = data_in.y(evtAlone(m):round(evtAlone(m)+120*fs),:); %cut data from alone trigger to two minutes after trigger
            data_out.alone.s{m} = data_in.s(evtAlone(m):round(evtAlone(m)+120*fs),:);
            data_out.alone.t{m} = data_in.t(evtAlone(m):round(evtAlone(m)+120*fs),:);
        end    
        for m = 1:size(evtTogether,1)
            data_out.together.y{m} = data_in.y(evtTogether(m):round(evtTogether(m)+120*fs),:); %cut data from together trigger to two minutes after trigger
            data_out.together.s{m} = data_in.s(evtTogether(m):round(evtTogether(m)+120*fs),:);
            data_out.together.t{m} = data_in.t(evtTogether(m):round(evtTogether(m)+120*fs),:);
        end    
        for m = 1:size(evtRest,1)
            data_out.rest.y{m} = data_in.y(evtRest(m):round(evtRest(m)+80*fs),:); %cut data from rest trigger to 80 sec after trigger
            data_out.rest.s{m} = data_in.s(evtRest(m):round(evtRest(m)+80*fs),:);
            data_out.rest.t{m} = data_in.t(evtRest(m):round(evtRest(m)+80*fs),:);
        end    
        data_out.SD = data_in.SD;
    else
        fprintf('Trial number is different than expected!\n');
    end
end