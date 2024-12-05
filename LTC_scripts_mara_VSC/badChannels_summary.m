% Path to your data files
dataPath = 'X:/hoehl/projects/LT/LTC/Analyses/Verena_analyses/fNIRS/MARA_preprocessing/procData/02a_preproc/';
outputDir = 'X:/hoehl/projects/LT/LTC/Analyses/Verena_analyses/fNIRS/MARA_preprocessing/';
outputFile = fullfile(outputDir, 'badChannels_summary.csv');

% Get list of all .mat files in the directory
dataFiles = dir(fullfile(dataPath, '*.mat'));

% Initialize cell array to store results
results = {'Dyad', 'Subject', 'BadChannels'};

% Loop through each file and extract badChannels
for i = 1:length(dataFiles)
    % Load the .mat file
    filePath = fullfile(dataPath, dataFiles(i).name);
    data = load(filePath);
    
    % Extract dyad number from file name
    [~, fileName, ~] = fileparts(dataFiles(i).name);
    dyadNum = regexp(fileName, 'L_d(\d+)_02a_preproc', 'tokens');
    
    if ~isempty(dyadNum)
        dyadNum = dyadNum{1}{1};
        
        % Extract badChannels for sub1
        if isfield(data.data_preproc, 'sub1') && isfield(data.data_preproc.sub1, 'badChannels')
            badChannelsSub1 = data.data_preproc.sub1.badChannels;
        else
            badChannelsSub1 = 'N/A';
        end
        
        % Extract badChannels for sub2
        if isfield(data.data_preproc, 'sub2') && isfield(data.data_preproc.sub2, 'badChannels')
            badChannelsSub2 = data.data_preproc.sub2.badChannels;
        else
            badChannelsSub2 = 'N/A';
        end
        
        % Convert badChannels to a string
        if isnumeric(badChannelsSub1)
            badChannelsStrSub1 = num2str(badChannelsSub1);
        else
            badChannelsStrSub1 = badChannelsSub1;
        end
        
        if isnumeric(badChannelsSub2)
            badChannelsStrSub2 = num2str(badChannelsSub2);
        else
            badChannelsStrSub2 = badChannelsSub2;
        end
        
        % Append result to cell array
        results = [results; {dyadNum, 'sub1', badChannelsStrSub1}];
        results = [results; {dyadNum, 'sub2', badChannelsStrSub2}];
    end
end

% Write results to a CSV file
fid = fopen(outputFile, 'w');
for i = 1:size(results, 1)
    fprintf(fid, '%s,%s,%s\n', results{i, 1}, results{i, 2}, results{i, 3});
end
fclose(fid);

fprintf('Bad channels summary saved to %s\n', outputFile);
