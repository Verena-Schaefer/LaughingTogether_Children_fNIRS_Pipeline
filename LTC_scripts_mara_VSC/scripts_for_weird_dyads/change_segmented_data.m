% Path to the directory containing the segmented .mat files
segmentedPath = 'X:\hoehl\projects\LT\LTC\Analyses\Verena_analyses\fNIRS\MARA_preprocessing\procData\weird_dyads\';

% List all .mat files in the directory
fileList = dir(fullfile(segmentedPath, '*.mat'));

% Loop through each file and convert the structure
for i = 1:length(fileList)
    % Load the file
    filePath = fullfile(segmentedPath, fileList(i).name);
    data = load(filePath);
    
    % Check if the file contains nested data_out structure
    if isfield(data, 'data_out')
        fprintf('Processing %s...\n', fileList(i).name);
        
        % Extract fields from data_out
        y = data.data_out.y;
        s = data.data_out.s;
        t = data.data_out.t;
        aux = data.data_out.aux;
        SD = data.data_out.SD;
        
        % Save fields back to the same file in non-nested format
        save(filePath, 'y', 's', 't', 'aux', 'SD');
        
        fprintf('Updated %s to non-nested format.\n', fileList(i).name);
    else
        fprintf('Skipping %s, no nested data_out structure found.\n', fileList(i).name);
    end
end

fprintf('All files processed.\n');
