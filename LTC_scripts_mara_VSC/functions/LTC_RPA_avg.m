function cfg = LTC_RPA_avg(cfg) 
    
    %this function loads all wavelet transform coherence files calculated
    %for one pair of Laughing Together Children participants, averages all of them
    %and saves the resulting average of all randomly permuted pairs
    %coherence
    
    %cfg: structure containing all necessary info on the data (e.g. in which folder to find it, which is the pair number)

    %Output:
	%cfg:  structure containing all necessary info on the data (e.g. in which folder to find it, which is the pair number)
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).
    
    out_path = strcat(cfg.desDir, cfg.currentPair, '_avg.mat');
    if ~exist(out_path, 'file')
        mat = dir([cfg.desDir, '*.mat']);
        fprintf('loading...')
        if length(mat) == 100
            if contains(cfg.currentSegment, 'tangram')
                phases = ['alone', 'together'];
                alone_coherences = cell(1, 100); %create cell that contains data for each of the 100 pairings
                alone_avgTime = cell(1, 100);
                alone_avgAll = cell(1,100);
                together_coherences = cell(1, 100); %create cell that contains data for each of the 100 pairings
                together_avgTime = cell(1, 100);
                together_avgAll = cell(1,100);
                for q = 1:length(mat)
                    path = strcat(mat(q).folder, '\', mat(q).name);
                    load(path);
                    alone_coherences{q} = coherences.alone.coherences_all;
                    alone_avgTime{q} = coherences.alone.coherences_avgTime;
                    alone_avgAll{q} = coherences.alone.coherences_avgAll;
                    together_coherences{q} = coherences.together.coherences_all;
                    together_avgTime{q} = coherences.together.coherences_avgTime;
                    together_avgAll{q} = coherences.together.coherences_avgAll;
                end
                fprintf('all loaded!')
                
                % for each phase again:
                for pn = 1:2
                    if pn == 1
                        all_coherences = alone_coherences;
                        all_avgTime = alone_avgTime;
                        all_avgAll = alone_avgAll;
                    else
                        all_coherences = together_coherences;
                        all_avgTime = together_avgTime;
                        all_avgAll = together_avgAll;
                    end
                    % For each trial
                    for tr = 1:2
                        data = cellfun(@(x) x{tr}, all_coherences, 'UniformOutput', false);
                        data_avgTime = cellfun(@(x) x{tr}, all_avgTime, 'UniformOutput', false);
                        data_avgAll = cellfun(@(x) x{tr}, all_avgAll, 'UniformOutput', false);  

                        % Get the number of sensors
                        numSensors = numel(data{1});   % Should be 16

                        % Initialize the output structure
                        average_trial = cell(1, numSensors);
                        average_trial_Time = cell(1, numSensors);
                        average_trial_All = cell(1, numSensors);

                        % Loop through each sensor
                        for sensorIdx = 1:numSensors

                            %for the non-averaged WTC data
                            % Extract the matrices for all participants for this sensor
                            all_matrices = cellfun(@(participant) participant{sensorIdx}, data, 'UniformOutput', false);

                            % Convert the cell array to a 3D matrix (periods x time points + headers x numParticipants)
                            all_matrices = cat(3, all_matrices{:});

                            % Compute the average across the third dimension (participants)
                            average_matrix = mean(all_matrices, 3, "omitnan");

                            % Store the result in the output structure
                            average_trial{sensorIdx} = average_matrix;

                            %for the data averaged through time
                            all_matrices_time = cellfun(@(participant) participant{sensorIdx}, data_avgTime, 'UniformOutput', false);

                            % Convert the cell array to a 3D matrix (periods x headers x numParticipants)
                            all_matrices_time = cat(3, all_matrices_time{:});

                            % Compute the average across the third dimension (participants)
                            average_matrix_time = mean(all_matrices_time, 3, "omitnan");

                            % Store the result in the output structure
                            average_trial_Time{sensorIdx} = average_matrix_time;

                            %for the data averaged through all
                            all_matrices_all = cellfun(@(participant) participant{sensorIdx}, data_avgAll, 'UniformOutput', false);

                            % Convert the cell array to a 3D matrix (line x headers x numParticipants)
                            all_matrices_all = cat(3, all_matrices_all{:});

                            % Compute the average across the third dimension (participants)
                            average_matrix_all = mean(all_matrices_all, 3, "omitnan");

                            % Store the result in the output structure
                            average_trial_All{sensorIdx} = average_matrix_all;

                        end
                        % The variable "temp" now contains the averaged data
                        temp_all{tr} = average_trial;
                        temp_Time{tr} = average_trial_Time;
                        temp_All{tr} = average_trial_All;
                   end
                   if pn == 1
                        average_coherences.alone.coherences_all = temp_all;
                        average_coherences.alone.coherences_avgTime = temp_Time;
                        average_coherences.alone.coherences_avgAll = temp_All;
                   else
                        average_coherences.together.coherences_all = temp_all;
                        average_coherences.together.coherences_avgTime = temp_Time;
                        average_coherences.together.coherences_avgAll = temp_All;
                   end
                   clear temp_all temp_Time temp_All 
                end
                
                
            else
                all_coherences = cell(1, 100); %create cell that contains data for each of the 100 pairings
                all_avgTime = cell(1, 100);
                all_avgAll = cell(1,100);
                for q = 1:length(mat)
                    path = strcat(mat(q).folder, '\', mat(q).name);
                    load(path);
                    all_coherences{q} = coherences.coherences_all;
                    all_avgTime{q} = coherences.coherences_avgTime;
                    all_avgAll{q} = coherences.coherences_avgAll;
                end
                fprintf('all loaded!')    
                
                % Check how many trials coherences contain based on how deep
                % the cell is
                cellDepth = celldepth(all_coherences);
                if cellDepth == 2 %only one trial
                    trialNum = 1;
                elseif cellDepth == 3 %more than one trial
                    trialNum = numel(all_coherences{1}); %trial number correspond to the dimension of the cell inside of the first participant cell
                else
                    fprintf('Data of participant %s does not correspond to the expected format. Check the function LT_RPA_avg and modify it!', cfg.currentPair)
                    %structure of cell does not correspond to the ones this script works on
                end

                % For each trial
                for tr = 1:trialNum
                    if trialNum == 1
                        data = all_coherences;
                        data_avgTime = all_avgTime;
                        data_avgAll = all_avgAll;
                    else
                        data = cellfun(@(x) x{tr}, all_coherences, 'UniformOutput', false);
                        data_avgTime = cellfun(@(x) x{tr}, all_avgTime, 'UniformOutput', false);
                        data_avgAll = cellfun(@(x) x{tr}, all_avgAll, 'UniformOutput', false);
                    end    

                    % Get the number of sensors
                    numSensors = numel(data{1});   % Should be 16

                    % Initialize the output structure
                    average_trial = cell(1, numSensors);
                    average_trial_Time = cell(1, numSensors);
                    average_trial_All = cell(1, numSensors);

                    % Loop through each sensor
                    for sensorIdx = 1:numSensors

                        %for the non-averaged WTC data
                        % Extract the matrices for all participants for this sensor
                        all_matrices = cellfun(@(participant) participant{sensorIdx}, data, 'UniformOutput', false);
                        
                        % since the signal for some participants does not have the
                        %same length (1 timepoint more or less)
                        % Find minimum size in 2nd dimension
                        minCols = min(cellfun(@(m) size(m, 2), all_matrices));

                        % Truncate all matrices to have same 2nd dimension
                        all_matrices = cellfun(@(m) m(:, 1:minCols), all_matrices, 'UniformOutput', false);
                        
                        % Convert the cell array to a 3D matrix (periods x time points + headers x numParticipants)
                        all_matrices = cat(3, all_matrices{:});

                        % Compute the average across the third dimension (participants)
                        average_matrix = mean(all_matrices, 3, "omitnan");

                        % Store the result in the output structure
                        average_trial{sensorIdx} = average_matrix;

                        %for the data averaged through time
                        all_matrices_time = cellfun(@(participant) participant{sensorIdx}, data_avgTime, 'UniformOutput', false);

                        % Convert the cell array to a 3D matrix (periods x headers x numParticipants)
                        all_matrices_time = cat(3, all_matrices_time{:});

                        % Compute the average across the third dimension (participants)
                        average_matrix_time = mean(all_matrices_time, 3, "omitnan");

                        % Store the result in the output structure
                        average_trial_Time{sensorIdx} = average_matrix_time;

                        %for the data averaged through all
                        all_matrices_all = cellfun(@(participant) participant{sensorIdx}, data_avgAll, 'UniformOutput', false);

                        % Convert the cell array to a 3D matrix (line x headers x numParticipants)
                        all_matrices_all = cat(3, all_matrices_all{:});

                        % Compute the average across the third dimension (participants)
                        average_matrix_all = mean(all_matrices_all, 3, "omitnan");

                        % Store the result in the output structure
                        average_trial_All{sensorIdx} = average_matrix_all;

                    end
                    % The variable "average_coherences" now contains the averaged data
                    if trialNum > 1
                        average_coherences.coherences_all{tr} = average_trial;
                        average_coherences.coherences_avgTime{tr} = average_trial_Time;
                        average_coherences.coherences_avgAll{tr} = average_trial_All;
                    else
                        average_coherences.coherences_all = average_trial;
                        average_coherences.coherences_avgTime = average_trial_Time;
                        average_coherences.coherences_avgAll = average_trial_All;
                    end
                end
                
            end
            
            %save data
            try
                fprintf('The average random permutation coherence data of dyad %s  will be saved in \n %s \n', cfg.currentPair, out_path)
                save(out_path, 'average_coherences');
                fprintf('Data stored!\n\n');
            catch
                fprintf('Couldnt save data \n'); 
                return
            end
        else
            sprintf('Participant %s does not have 100 permutation files! \n', cfg.currentPair);
            return
        end
    end
