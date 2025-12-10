function [ROIsHbo, badROI] = LTC_calcROI(hbo, badChannels)
    
    %this function averages hbo time series by channel into hbo time series
    %averaged by ROIs for the study Laughing Together Children
	%averages are only calculated if the ROI has at least two good channels. Otherwise, the resulting ROI contains NaNs
	%If the ROI has less than two good channels, its index gets included in the variable "badROI" so it can be excluded for future steps
	%ROIs are: IFGr (channels 9 to 12), IFGl (channels 5 to 8), TPJr (channels 13 to 16) and TPJl (channels 1 to 4)
    
    %hbo: cell containing oxygenated hemoglobin time series
    %badChannels: lists of bad channels
    
    %Output: 
    % ROIsHbo: cell with one time series for each ROI
    % badROI: list of ROIs which had less than two good channels
    
    %author: Carolina Pletti (carolina.pletti@gmail.com).

    badROI = [];
    count = 0;
    %remove values of bad channels
    hbo(:,badChannels) = NaN;
    %check that each ROI has at least two good channels. If not, the ROI
    %becomes NaN
    if sum(ismember(9:12,badChannels)) < 3
        %only average the columns that are not NaN
        IFGr = nanmean(hbo(:,9:12),2);
    else
        IFGr = NaN(length(hbo),1);
        count = count +1;
        badROI(count) = 1;
    end

    if sum(ismember(5:8,badChannels)) < 3
        %change so that bad channels are not included!!
        IFGl = nanmean(hbo(:,5:8),2);
    else
        IFGl = NaN(length(hbo),1);
        count = count + 1;
        badROI(count) = 2;
    end

    if sum(ismember(13:16,badChannels)) < 3
        %change so that bad channels are not included!!
        TPJr = nanmean(hbo(:,13:16),2);
    else
        TPJr = NaN(length(hbo),1);
        count = count + 1;
        badROI(count) = 3;
    end

    if sum(ismember(1:4,badChannels)) < 3
        %change so that bad channels are not included!!
        TPJl = nanmean(hbo(:,1:4),2);
    else
        TPJl = NaN(length(hbo),1);
        count = count + 1;
        badROI(count) = 4;
    end
    
    ROIsHbo = [IFGr, IFGl, TPJr, TPJl];