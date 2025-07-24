function cfg = LTC_config_paths(cfg, uni)

    %%%%%%%%%%%%%%%%%% LTC Config Paths function %%%%%%%%%%%%%%%%%%%%%%%
    % This function sets the paths for the fNIRS analysis, including
    % raw data directories, toolbox paths, and output folders. It also
    % adds required toolboxes (Homer2) to the MATLAB path.
    %
    % BEFORE USING: CHECK THAT THE PATHS IN THIS FUNCTION MATCH YOUR SYSTEM
    % SETUP
    %
    % Usage:
    %   cfg = LTC_config_paths(cfg, uni)
    %
    % Inputs:
    %   - cfg: Configuration structure containing analysis settings.
    %   - uni: Set to 1 for university workspace, 0 for home workspace.
    %
    % Outputs:
    %   - cfg.rawDir: Path to raw data folder.
    %   - cfg.desDir: Path to destination folder for processed data.
    %   - cfg.SDFile: Path to the SD file for channel configuration.
    %
    % Author: Carolina Pletti (carolina.pletti@gmail.com)
    
    % Define paths based on the workspace selection.
    if uni == 1

        %project folder is here:
        project_folder = 'Z:\Documents\Projects\LaughingTogether_Children_fNIRS_Pipeline\';

        %Homer2 is here:
        toolbox_folder = 'Z:\Documents\matlab_toolboxes\';
        
        %raw data folder is here:
        raw_folder = 'X:\hoehl\projects\LT\LTC\NIRX\';

    else
        %project folder is here:

        %Homer2 is here:
        
        %raw data folder is here:
        
    end

    %scripts are here:
    data_prep_folder = [project_folder '\LTC_scripts_mara_VSC\'];
    
    % Set paths in the cfg structure.
    cfg.rawDir = raw_folder; % raw data folder
    %cfg.desDir = [project_folder 'Data\']; % destination folder
    cfg.desDir = '\\share.univie.ac.at\A474\hoehl\projects\LT\LTC\Analyses\fNIRS\Nina_analyses\Data\';
    cfg.SDFile = [raw_folder 'LT.SD']; % SD file
    
    % Add necessary folders and toolboxes to MATLAB path.
    addpath([data_prep_folder 'functions']); %add path with functions    
    
    %if we are calling this function from "LTC_main", 
    %add Homer2 to the path using its own function
    if ~isfield(cfg, 'permnum') && ~isfield(cfg, 'avg') %the field "permnum" and the field "avg" shouldn't exist if we are calling this from "LTC_main"
        cd ([toolbox_folder 'homer2'])
        setpaths
        cd(data_prep_folder)
    end

end