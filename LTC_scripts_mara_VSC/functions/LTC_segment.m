function cfg = LTC_segment(cfg)
    %this function calls subfunctions to segment continuous .mat data into different .mat files containing
	%only certain segments of the laughing together children task based on
    %triggers. The relevant segments (defined in the cfg file) can be
    %laughter or interaction
	
	%cfg: structure containing all necessary info on where to find the data and where to save them
    
    %Output: updated cfg containing all necessary info on where to find segmented data
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).
    
    error = 0;
    
    cfg.desDir = strcat(cfg.srcDir, cfg.currentSegment, '\');
    
    % Check if all folders exist and create them
    if ~exist(cfg.desDir, 'dir')
        mkdir(cfg.desDir);
    end

    %loop through both participants of a pair
    for i = 1:2
        fileName = strcat(cfg.currentPair, '_sub', int2str(i));
        fprintf('Load raw nirs data of subject ')
        fprintf(fileName)
        fprintf('\n');
        file_path = strcat(cfg.srcDir, fileName, '.mat');
        

        % Triggers for Laughing Together Children:
        % 1 - Tangram alone
        % 2 - Tangram together
        % 3 - Tangram rest
        % 4 - video beginning
        % 5 - video end
        % 6 - interaction start
        % 7 - interaction end
        % 8 - castle knights start
        % 9 - castle knight end
        % 10 - general function end trigger, used for tangram end


        des_dir = strcat(cfg.desDir, fileName, '.mat');
        
        %check if segmented files already exist and if file to segment can
        %be opened
        if ~exist(des_dir, 'file')
                try
                    data_in = load(file_path);
                catch
                    problem = {'file to segment can''t be opened'};
                    cfg.problems = [cfg.problems, problem];
                    continue
                end
            fprintf('\nSegmenting data.\n Processing segment ')
            fprintf(cfg.currentSegment)
            fprintf('\n');
        
            %calculate sampling rate and sampling period
            ts = data_in.t(2)-data_in.t(1);
            fs = 1/ts;

            if contains(cfg.currentSegment,'tangram');
                try
                    data_out = LTC_epoch_tangram(data_in, fs);
                catch
                    error = 1;
                end
            elseif contains(cfg.currentSegment,'laughter')
                try
                    data_out = LTC_epoch_laughter(data_in);
                catch
                    error = 1;
                end
            elseif contains(cfg.currentSegment,'interaction')
                try
                    data_out = LTC_epoch_interaction(data_in, fs);
                catch
                    error = 1;
                end
            end

            %save cut data
            fprintf('The segmented data of participant ')
            fprintf(fileName)
            fprintf(' will be saved in');
            fprintf('%s ...\n', des_dir);
            try
                save(des_dir, 'data_out');
                fprintf('Data stored!\n\n');
                clear data_out
            catch
                error = 1;
            end
            
            if error == 1
                fprintf('<strong>%s epoching did not work</strong>\n', cfg.currentSegment);
                fprintf('check %s trials of participant %s', cfg.currentSegment, cfg.currentPair)
                problem = {sprintf('error in %s epoching', cfg.currentSegment)};
                cfg.problems = [cfg.problems, problem];
            end
        end    
    end
    cfg.srcDir = cfg.desDir;
    cfg.steps = [cfg.steps, {'segmentation'}];
end