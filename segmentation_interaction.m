% SUBFUNCTION data segmentation
% -------------------------------------------------------------------------
function segmentation_interaction(file_path, desPath)
    % Load raw data
    data_in = load(file_path, '-mat');
    
    % Define filename and destination path
    [~, name, ~] = fileparts(file_path);
    desPathI = fullfile(desPath, '05_nirs_interaction', strcat(name, '.mat')); % Save in the 05_segmented folder within desPath
    
    % Triggers for children study:
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


    fprintf('time stamp interaction begins\n');
    evtInteraction = find(data_in.s(:, 6) > 0);
    fprintf('evtInteraction: %d\n', evtInteraction);
    fprintf('time stamp interaction ends\n');
    evtInteractionEnd = find(data_in.s(:, 7) > 0);
    fprintf('evtInteractionEnd: %d\n', evtInteractionEnd);
    
% original version?    
% fprintf('time stamp interaction begins\n');
%     evtInteraction = find(data_in.s(:, 6) > 0);
%     fprintf('time stamp interaction ends\n');
%     evtInteractionEnd = find(data_in.s(:, 7) > 0);
    
    if size(evtInteraction, 1) ~= 1 || size(evtInteractionEnd, 1) ~= 1
        fprintf('Trial number is different than expected!\n');
        weirdtrials = 1;
    else
        fprintf('Trial number is correct!\n');
        weirdtrials = 0;
    end
    
    % Check if not longer than 6 min and shorter than 4 min
    if weirdtrials == 0
        if evtInteractionEnd - evtInteraction > 1972 && evtInteractionEnd - evtInteraction < 2808
            % Eliminate first minute and last minute
            Start = evtInteraction + 468; % first sampling point of the first part to analyze after 1 min. of interaction
            End = Start + 1872; % -> 4 min long
            
            data_out.y = data_in.y(Start:End, :);
            data_out.s = data_in.s(Start:End, :);
            data_out.t = data_in.t(Start:End, :);
            data_out.aux = data_in.aux(Start:End, :);
            data_out.SD = data_in.SD;
        else
            fprintf('Interaction duration is different than expected!\n');
            weirdtrials = 1;
        end
    end
    
    % Save cut data
    if exist('data_out', 'var')
        fprintf('The interaction data will be saved in %s ...\n', desPathI);
        save(desPathI, '-struct', 'data_out');
        fprintf('Data stored!\n\n');
    else
        fprintf('Data was not segmented due to issues with interaction duration or trial numbers.\n');
    end
    
    clear data_out
end