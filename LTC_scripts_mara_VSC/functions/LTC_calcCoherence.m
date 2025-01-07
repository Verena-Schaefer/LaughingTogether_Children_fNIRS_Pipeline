function coherences = LTC_calcCoherence(hbo_1, hbo_2, badChannels_1, badChannels_2, t, fs)

    % This function calculates the wavelet transform coherence (WTC) for every
    % combination of channels between two participants for the study Laughing Together Children.
    %
    % Inputs:
    %   - hbo_1, hbo_2: Matrices containing oxygenated hemoglobin time series for each participant.
    %   - badChannels_1, badChannels_2: Vectors listing bad channels for each participant.
    %   - t: Time vector representing the time points of the data.
    %   - fs: Sampling frequency in Hz.
    %
    % Output:
    %   - coherences: A cell array containing WTC results for each channel combination.
    %       1. Matrix of WTC values for each time point and period (excluding periods not of interest).
    %       2. One vector per channel combination repesenting WTC averaged across time points for each period.
    %       3. One value per channel combination representing average WTC across all periods and time points.
    %
    % Author: Carolina Pletti (carolina.pletti@gmail.com). Based on a script by Trinh Nguyen.
    
    % Initialize error flag and define period of interest based on data duration.
    error = 0;
    max = round(length(t) / fs/4); %trial duration divided by 4
    ts = 1/fs; %time step
    poi=[8 max]; %limits period of interest from greater than 4 times the filter to smaller than trial duration/4
    poi_index = zeros(2,1); %in which columns does the perios of interest starts/ends?
    
    % Identify the first good channel available for both participants.  
    for i = 1:4
        if ~ismember(i, badChannels_1) && ~ismember(i, badChannels_2)
            firstGoodChannel = i;
            break;
        end
    end
    
    % Check if a valid channel was found, otherwise exit.
    if exist('firstGoodChannel', 'var')
        sigPart1 = hbo_1(:,firstGoodChannel);
        sigPart2 = hbo_2(:,firstGoodChannel);
    else
        fprintf('No good channels found.\n');
        return
    end

    % Attempt to calculate the wavelet coherence to define the periods of interest.
    try    
        [~,~,period] = wcoherence(sigPart1,sigPart2,seconds(ts)); %already calculates wtc and extracts period (that is, all "frequences" that are calculated)
        poi_index(1) = find(period > seconds(poi(1)), 1, 'first'); %finds the first column in period which is greater than the maximum period of interest
        poi_index(2) = find(period < seconds(poi(2)), 1, 'last'); %finds the last column in period which is lower than the minimum period of interest
    catch exception
        error = 1;
        fprintf('<strong>Impossible to calculate period for some reason. Trial too short?</strong>\n');

        msgText = getReport(exception);
        fprintf(msgText);
    end 

    % Proceed only if no error occurred during period calculation.
    if error ~=1
        
        % -------------------------------------------------------------------------
        % Memory Allocation
        % -------------------------------------------------------------------------
        %calculate how many combinations of channels there are (e.g. rTPJ1 x
        %rTPJ2, lTPJ1 x rTPJ2, etc)
        numOfChan = size(hbo_1, 2)*size(hbo_2, 2);
        %create 1xnumOfChan cell of cells. this will contain all the final
        %values for this participant pair
        coherences{numOfChan}  = []; 
        %fill each subcell with NaNs. The size is: one row per period of
        %interest, one column per time point
        coherences(:,:) = {NaN(poi_index(2)-poi_index(1)+1, length(hbo_1)+3)};  %+ 3 columns because the first one is for the period, the second for channel number sub 1, the third for channel number sub 2
        
        %this variable will store the wavelet transform coherence values
        %calculated for each combination of channel and the content changes
        %for every iteration of the loop 
        Rsq{numOfChan} = [];
        Rsq(:) = {NaN(length(period), length(t))};

        % -------------------------------------------------------------------------
        % Coherence Calculation Loop
        % -------------------------------------------------------------------------
        fprintf('<strong>Estimation of the wavelet transform coherence for all channels...</strong>\n');
        Ch_Sub1 = 0; % Counter for participant 1 channels.
        Ch_Sub2 = 0; % Counter for participant 2 channels.
        
        % Iterate through all channel combinations.
        for i=1:1:numOfChan
            if mod(i,4) == 1
                Ch_Sub1 = Ch_Sub1 + 1;
            end
            Ch_Sub2 = mod(i - 1, 4) + 1;
            
            % Store period and channel indices in results.
            coherences{i}(:,1)  = seconds(period(poi_index(1):poi_index(2)));
            coherences{i}(:,2)  = repelem(Ch_Sub1, length(coherences{i}(:,2)));
            coherences{i}(:,3)  = repelem(Ch_Sub2, length(coherences{i}(:,2)));
            
            % Check if current channels are valid (not marked as bad).
            if ~any(badChannels_1 == Ch_Sub1) && ~any(badChannels_2 == Ch_Sub2)
                sigPart1 = hbo_1(:,Ch_Sub1);
                sigPart2 = hbo_2(:,Ch_Sub2);
                try
                    [Rsq{i}, ~, ~, coi] =wcoherence(sigPart1,sigPart2,seconds(ts)); % r square - measure for coherence
                catch exception
                    msgText = getReport(exception);
                    fprintf(msgText);
                end
                
                % Mask regions outside the cone of influence (COI) with NaN.
                for j=1:1:length(coi)
                    Rsq{i}(period >= coi(j), j) = NaN;
                end
				
                % Store coherence results within the period of interest.
                coherences{i}(:,4:length(coherences{i})) = Rsq{i}(poi_index(1):poi_index(2), :);
                
            end
        end
    end
end