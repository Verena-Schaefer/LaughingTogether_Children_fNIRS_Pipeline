function cfg = LTC_RPA(cfg)
	%this function calls a subfunction to calculate the wavelet transform
    %coherence for 100 random pairs for each Subject 1 of each pair.
    %Then, it saves each of the 100 wtc data as a structure containing the following:
    % 1 - one matrix per channel combination with one value per each time
    % point and period, excluding periods not of interest (i.e. from 
    %greater than 4 times the filter to smaller than trial duration/4)
    % 2 - one vector per channel combination with one value per period
    % (excluding periods not of interest), averaged across timepoints
    % 3 - one value per channel combination representing average WTC across
    % timepoints and periods of interest
	
	%cfg: structure containing all necessary info on where to find the data and where to save them
    
    %Output: updated cfg containing all necessary info on where to find wavelet coherence transform data
    
    %author: Carolina Pletti (carolina.pletti@gmail.com). Based on a script by Trinh Nguyen
    
    if cfg.ROI == 1
        cfg.desDir = strcat(cfg.srcDir, 'Coherence_ROIs_RPA\', cfg.currentPair, '\');
    else
        cfg.desDir = strcat(cfg.srcDir, 'Coherence_single_channels_RPA\', cfg.currentPair, '\');
    end

    if ~exist(cfg.desDir, 'dir')
        mkdir(cfg.desDir);
    end
    
    file_path_sub1 = strcat(cfg.srcDir, cfg.currentPair,'_sub1.mat');
    try
        temp = load(file_path_sub1);
        data_sub1 = temp.data_prep;
    catch
        fprintf('main participant does not have a file\n');
        return
    end
    
    errors = 0; %so that the script knows how many times coherence wasn't calculated for one participant. If this is more than 50 times, likely coherence can't be calculated at all for this participant and the script will exit the loop
    for i = 1:cfg.permnum
        out_path = strcat(cfg.desDir, cfg.currentPair, '_', int2str(i), '.mat');
        if ~exist(out_path, 'file')
            if errors > 50
                fprintf('random pairs can''t be calculated\n');
                break
            else
                done = 0; %so that the script picks another random participant in case one of the steps does not work for one random pair. This way, we will have exactly 100 pairs for each participant            
                while done == 0
                    try
                        %load file of randomly selected participant 2,
                        %prepare empty cells to save coherences, check that
                        %time vectors of 2 participants correspond, calculate
                        %coherences and return raw coherences and coherences
                        %averages
                        coherences = LTC_RPA_prep(cfg, data_sub1);
                    catch
                        errors = errors + 1;
                        if errors > 50
                            break
                        else
                            continue
                        end
                    end



                    %save data
                    try
                        fprintf('The wtc data of dyad %s will be saved in \n %s \n', cfg.currentPair, out_path)
                        save(out_path, 'coherences');
                        fprintf('Data stored!\n\n');
                        clear coherences
                    catch
                        fprintf('Couldnt save data \n'); 
                        continue
                    end
                    done = 1;
                end
            end
        end
    end
end