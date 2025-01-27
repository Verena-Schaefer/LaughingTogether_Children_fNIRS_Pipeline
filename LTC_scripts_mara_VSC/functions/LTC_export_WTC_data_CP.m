function LTC_export_WTC_data_CP(phase, cfg)
    
    num_labels = length(cfg.labels);

    for id = 1:cfg.numOfSources
        %retrieve unmodified cfg info
        cfg_part = cfg;
        cfg_part.currentPair = cfg_part.sources{id};
        group_pair = strsplit(cfg_part.currentPair, '_');
        cfg_part.currentPrefix = group_pair{1};
        if cfg_part.currentPrefix == 'L'
            cfg_part.currentGroup = 'Lachen';
        elseif cfg_part.currentPrefix == 'K'
            cfg_part.currentGroup = 'Kontrolle';
        end
            
        cfg_part.srcDir = strcat(cfg_part.dataDir, cfg_part.currentGroup, '\', cfg_part.currentSegment, '\preprocessed\Coherence_ROIs');
        fprintf('processing participant %s \n', cfg_part.currentPair)
        filename = sprintf('%s\\%s.mat',cfg_part.srcDir, cfg_part.currentPair);
        % load coherence data
        try
            load(filename);             
        catch
            fprintf('no coherence file avaliable for pair %s \n', cfg_part.currentPair)
            continue
        end
        
        try
            if contains(cfg.currentSegment, 'tangram')
                % Access the field using the name
                fieldData = coherences.(phase);
                if contains(cfg.avg, 'all')
                    coherence_data = fieldData.coherences_avgAll;
                    num_rows = 1;
                elseif contains(cfg.avg, 'time')
                    coherence_data = fieldData.coherences_avgTime;
                    num_rows = length(coherence_data{1,1}{1,1});
                    periods = zeros(num_rows,num_labels^2);
                end
            else
                if contains(cfg.avg, 'all')
                    coherence_data = coherences.coherences_avgAll;
                    num_rows = 1;
                elseif contains(cfg.avg, 'time')
                    coherence_data = coherences.coherences_avgTime;
                    if isempty(coherence_data{1,1})
                        continue
                    elseif length(coherence_data{1,1}) > num_labels^2
                        num_rows = length(coherence_data{1,1});
                    else
                        num_rows = length(coherence_data{1,1}{1,1});
                    end
                    periods = zeros(num_rows,num_labels^2);
                end
            end
        catch
            sprintf('data of participant %s, segment %s, don''t have the expected format', cfg_part.currentPair, cfg.currentSegment);
            continue
        end
        
        coherence_values = zeros(num_rows, num_labels^2);
        
        if contains(cfg.currentSegment, 'interaction')
            trials = 1;
        else
            trials = length(coherence_data);
        end
        
        for int = 1:trials
            try
                if contains(cfg.currentSegment, 'interaction')
                    coherence_interval = coherence_data;
                else
                    coherence_interval = coherence_data{1, int};
                end
                
                variable_names = cell(1, num_labels^2);

                % Extract coherence values and variable names using loops
                idx = 1;
                for i = 1:num_labels
                    for j = 1:num_labels
                        if contains(cfg.avg, 'all')
                            coherence_values(idx) = coherence_interval{1, idx}(3);
                        elseif contains(cfg.avg, 'time')
                            coherence_values(:,idx) = coherence_interval{1, idx}(:,4);
                            periods(:,idx) = coherence_interval{1, idx}(:,1);
                        end
                        variable_names{idx} = strcat(cfg.labels{i}, '_', cfg.labels{j});
                        idx = idx + 1;
                    end
                end


                pairData = array2table(coherence_values, 'VariableNames', variable_names);
                pairData.Interval = repelem(int, num_rows)';
                pairData.Pair = repelem(string(group_pair{2}), num_rows)';
                pairData.Group = repelem(string(cfg_part.currentGroup), num_rows)';
                pairData.Segment = repelem(string(cfg.currentSegment), num_rows)';
                if contains(cfg.currentSegment, 'tangram')
                    pairData.Phase = repelem(string(phase), num_rows)';
                end
                if contains(cfg.avg, 'time')
                    pairData.Period = periods(:,1);
                end

                % Initialize or append to the data table
                if ~exist('data', 'var')
                    data = pairData;
                else
                    data = [data; pairData];
                end
            catch
                sprintf('exporting data of participant %s, segment %s, did not work', cfg_part.currentPair, cfg.currentSegment)
                continue
            end
        end
    end
    desFile = sprintf('%s\\Data_ROI_%s_%s.csv', cfg.desDir, phase, cfg.avg);
    writetable(data,desFile,'Delimiter',',','QuoteStrings',true)
end