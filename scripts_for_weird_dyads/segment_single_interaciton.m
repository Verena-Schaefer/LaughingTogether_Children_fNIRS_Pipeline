%%segment single itneraction updated with correct saving 
clear all

srcPath = 'X:\hoehl\projects\LT\LTC\Analyses\Verena_analyses\fNIRS\MARA_preprocessing\procData\01_nirs\';                        % raw data location
desPathI = 'X:\hoehl\projects\LT\LTC\Analyses\Verena_analyses\fNIRS\MARA_preprocessing\procData\weird_dyads\';                % interaction data location
addpath('X:\hoehl\projects\LT\LTC\Analyses\fNIRS\scripts\functions');

% cut epochs

% load raw data
srcFolder   = strcat(srcPath);
filename    = 'L_35b_spm_fnirs';
fprintf('Load raw nirs data of subject...\n');
fprintf(filename);
file_path = strcat(srcFolder, filename,'.mat'); %hier von .nirs zu .mat geändert

data_in = load(file_path, '-mat');

%triggers for children study:
% 1 - Tangram allein
% 2 - Tangram gemeinsam
% 3 - Tangram rest
% 4 - video beginning
% 5 - video end
% 6 - interaction start
% 7 - interaction end
% 8 - castle knights start
% 9 - castle knight end
% 10 - general function end trigger, used for tangram end

des_pathI = strcat(desPathI, filename, '.mat');

fprintf('time stamp interaction begins');
evtInteraction  = find(data_in.s(:, 6) > 0)
fprintf('time stamp interaction ends');
evtInteractionEnd  = find(data_in.s(:, 7) > 0)

if size(evtInteraction, 1)~=1 || size(evtInteractionEnd, 1)~=1
    fprintf('Trial number is different than expected!\n');
    weirdtrials=1;
else
    fprintf('Trial number is correct!\n');
    weirdtrials=0;
end

%cut out interaction data

% segment again: first calculate if there are enough samples to sum
% up to 4 minutes (with sampling rate 7.8 that would be: 4
% minutes = 240 sec, 7.8 samples per sec means minimum 1872
% samples). Also check that this part is not longer than 6
% minutes, since this could indicate that something went wrong
  
%check if not longer than 6 min and shorter than 4 min
if weirdtrials == 0            
    if evtInteractionEnd - evtInteraction > 1972 && evtInteractionEnd - evtInteraction < 2808

        %eliminate first minute and last minutes.
        Start = evtInteraction + 468; %first sampling point of the first part to analyze after 1 min. of interaction
        End = Start + 1872; % -> 4 min long
        data_out.y = data_in.y(Start:End,:);
        data_out.s = data_in.s(Start:End,:);
        data_out.t = data_in.t(Start:End,:);
        data_out.aux = data_in.aux(Start:End,:);
        data_out.SD = data_in.SD;
        
        % Save cut data in the same structure as segmentation_interaction
        fprintf('The interaction data will be saved in %s ...\n', des_pathI);
        y = data_out.y;
        s = data_out.s;
        t = data_out.t;
        aux = data_out.aux;
        SD = data_out.SD;
        
        save(des_pathI, 'y', 's', 't', 'aux', 'SD');
        fprintf('Data stored!\n\n');
    else
        fprintf('Interaction duration is different than expected!\n');
        weirdtrials = 1;
    end
else
    fprintf('Data was not segmented due to issues with interaction duration or trial numbers.\n');
end

clear data_out
