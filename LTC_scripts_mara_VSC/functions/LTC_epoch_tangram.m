function data_out = LTC_epoch_tangram(data_in,fs)

    %this function cuts the fNIRS time series and saves the part of the time series corresponding to when the participants were
	%doing the tangram puzzle in the experiment Laughing Together Children.
    
    %data_in: path to .mat file containing time series, time vector and triggers
    
    %fs: sampling frequency in Hz
    
    %Output: structure with the same format as data_in, but containing only data corresponding to the time period of interest
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).
	
	%laughter video start trigger: 3; laughter video end trigger: 4. There are two laughter videos.
    
    fprintf('time stamp tangram alone');
    evtAlone  = find(data_in.s(:, 1) > 0)
    fprintf('time stamp tangram together');
    evtTogether  = find(data_in.s(:, 2) > 0)
    fprintf('time stamp tangram rest');
    evtRest  = find(data_in.s(:, 3) > 0)

    if size(evtAlone,1)~=2 | size(evtTogether,1)~=2 | size(evtRest,1) ~=3
        fprintf('Trial number is different than expected!\n');
        weirdtrials=1;
    else
        fprintf('Trial number is correct!\n');
        weirdtrials=0;
    end

    %cut out tangram data

    if weirdtrials == 0
        for m = 1:length(evtAlone)
            data_out.y.alone{m} = data_in.y(evtAlone(m):round(evtAlone(m)+120*fs),:); %cut data from trigger to two minutes after trigger
            data_out.s.alone{m} = data_in.s(evtAlone(m):round(evtAlone(m)+120*fs),:);
            data_out.t.alone{m} = data_in.t(evtAlone(m):round(evtAlone(m)+120*fs),:);
        end
        for m = 1:length(evtTogether)
            data_out.y.together{m} = data_in.y(evtTogether(m):round(evtTogether(m)+120*fs),:); %cut data from trigger to two minutes after trigger
            data_out.s.together{m} = data_in.s(evtTogether(m):round(evtTogether(m)+120*fs),:);
            data_out.t.together{m} = data_in.t(evtTogether(m):round(evtTogether(m)+120*fs),:);
        end
        for m = 1:length(evtRest)
            data_out.y.rest{m} = data_in.y(evtRest(m):round(evtRest(m)+80*fs),:); %cut data from trigger to 80 seconds after trigger
            data_out.s.rest{m} = data_in.s(evtRest(m):round(evtRest(m)+120*fs),:);
            data_out.t.rest{m} = data_in.t(evtRest(m):round(evtRest(m)+120*fs),:);
        end
        data_out.SD = data_in.SD;
    end
end