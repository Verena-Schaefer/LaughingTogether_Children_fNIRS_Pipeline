function cfg = LTC_config_paths(cfg, uni)

    %this function sets in the "cfg" variables all the paths where to find
    %the data and save the data for the fNIRS analyses, and adds Homer2, spmfnirs and all
    %necessary functions to the Matlab path
    %Adapt this function as necessary based on your own workplace!
    
    %cfg: structure containing info about the data (none of the info is
    %used in this function yet, but the function modifies the structure)
    %uni: 0 (Carolina's workplace at home) or 1 (Carolina's workplace
    %at the uni)
    
    %output:
    %the following fields are added to the cfg structure:
    %cfg.rawDir: raw data folder
    %cfg.desDir: destination folder
    %cfg.SDFile: path to the SD file
    
    %author: Carolina Pletti (carolina.pletti@gmail.com)

    if uni == 1

        %project folder is here:
        project_folder = 'X:\hoehl\projects\LT\LT_adults\'; %change this!!

        %Homer2 is here:
        toolbox_folder = 'Z:\Documents\matlab_toolboxes\';
        
        %raw data folder is here:
        %add raw data folder!!!

    else
        %project folder is here:
        project_folder = '\\fs.univie.ac.at\plettic85\Documents\Projects\LaughingTogether_Children_fNIRS_Pipeline\';

        %Homer2 is here:
        toolbox_folder = '\\fs.univie.ac.at\plettic85\Documents\matlab_toolboxes\';
        
        %raw data folder is here:
        raw_folder = '\\share.univie.ac.at\A474\hoehl\projects\LT\LTC\NIRX\';
        
    end

    %scripts are here:
    data_prep_folder = [project_folder '\LTC_scripts_mara_VSC\'];

    cfg.rawDir = raw_folder; % raw data folder
    cfg.desDir = [project_folder 'Data\']; % destination folder
    cfg.SDFile = [raw_folder 'LT.SD']; % SD file
    
    
    addpath([data_prep_folder 'functions']); %add path with functions
    
    addpath([toolbox_folder 'spm_fnirs']); %add spm_fnirs toolbox to the path
    
    %if we are calling this function from "LTC_main", 
    %add Homer2 to the path using its own function
%     if ~isfield(cfg, 'permnum') %the field "permnum" shouldn't exist if we are calling this from "LTC_main"
%         cd ([toolbox_folder 'homer2'])
%         setpaths
%         cd(data_prep_folder)
%     end

end