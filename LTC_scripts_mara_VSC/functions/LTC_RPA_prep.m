function [coherences] = LTC_RPA_prep(cfg, data_sub1) 
    
    %load preprocessed fNIRS data of randomly selected participant 2 for
    %the experiment Laughing Together Children
    %prepare empty cells to save coherences, check that time vectors of 2 participants correspond, calculate
    %coherences and return raw coherences and coherences averages
    
    %cfg: structure containing all necessary info on the data (e.g. in which folder to find it, which is the pair number)
    %data_sub1: data of participant 1
    
    %Output:
	%coherences: structure containing following cells:
        %coherences_all: coherence values per each channel, time point and
        %period
        %coherences_avgTime: coherence values averaged across time points
        %coherences_avgAll: coherence values averaged across time points
        %and periods
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).
    
    % load preprocessed data
    fprintf('Load preprocessed data...\n');
        
    %randomly determine Subject 2

    r=randi(length(cfg.sources));
    randPart = strsplit(cfg.sources{r}, '_');
    if randPart{1} == 'L'
        group = 'Lachen';
    elseif randPart{1} == 'K'
        group = 'Kontrolle';
    end
    file_path_sub2 = strcat(cfg.dataDir, group,'\', cfg.currentSegment, '\preprocessed\', cfg.sources{r}, '_sub2.mat');
    temp=load(file_path_sub2);
    data_sub2 = temp.data_prep;
    
    if contains(cfg.currentSegment,'tangram')
        coherences = LTC_tangram(data_sub1, data_sub2, cfg);
    elseif contains(cfg.currentSegment, 'laughter')
        if randPart{1} == cfg.currentPrefix
            coherences = LTC_laughter(data_sub1, data_sub2, cfg);
        else
            return
        end
    elseif contains(cfg.currentSegment, 'interaction')
        coherences = LTC_interaction(data_sub1, data_sub2, cfg);
    end
end


    