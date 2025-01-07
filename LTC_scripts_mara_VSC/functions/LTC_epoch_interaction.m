function data_out = LTC_epoch_interaction(data_in, fs)

    %this function cuts the fNIRS time series and saves the part of the time series corresponding to when the participants were
	%freely interacting in the experiment Laughing Together Children.
    %One 3 minutes segment will be extracted from a ~5 minutes interaction
    %(excluding the first and the last minutes, in which the experimenters
    %might have still interacted a lot with the children
    
    %data_in: fNIRS data containing time series, time vector and triggers
    %fs: sampling rate in Hz
    
    %Output: structure with the same format as data_in, but containing only data corresponding to the time period of interest
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).

	%interaction start trigger = 6; interaction end trigger = 7
    fprintf('time stamp interaction begins');
    evtInteraction  = find(data_in.s(:, 6) > 0)
    fprintf('time stamp interaction ends');
    evtInteractionEnd  = find(data_in.s(:, 7) > 0)

    if size(evtInteraction,1)==1 && size(evtInteractionEnd,1)==1
    %cut out interaction data

    % first calculate if there are enough samples to sum
    % up to 5 minutes. Also check that this part is not longer than 8
    % minutes, since this could indicate that something went wrong
        if evtInteractionEnd - evtInteraction > (5*60*fs) && evtInteractionEnd - evtInteraction < (8*60*fs)
            Starts = evtInteraction + round(60*fs); %first sampling point of the part to analyze
            Ends = Starts + round(3*60*fs); %last sampling point of the part to analyze
            data_out.y = data_in.y(Starts:Ends,:);
            data_out.s = data_in.s(Starts:Ends,:);
            data_out.t = data_in.t(Starts:Ends,:);
            data_out.SD = data_in.SD;
        else
            fprintf('Interaction duration is different than expected!\n');
        end
    else
        fprintf('Trial number is different than expected!\n');
    end
end