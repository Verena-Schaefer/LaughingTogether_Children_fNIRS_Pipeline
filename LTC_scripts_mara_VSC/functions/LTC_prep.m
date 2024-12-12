function [hbo, hbr, badChannels, SCIList, fs]= LTC_prep(t, y, SD)
    
	%this function performs the following preprocessing steps:
    %1: convert the wavelength data to optical density
    %2: identifies motion artifacts and performs spline interpolation
    %3: applies wavelet-based artifact correction
    %4: applies bandpass filtering
    %5: manual rejection of bad channels through visual inspection
    %6: converts changes in optical density to changes in HbO, HbR and HbT
    %concentration
	
	%t: vector of time points
	%d: cell structure containing segmented raw fNIRS data
	%SD: file containing source and detectors configuration
    
    %Output:
	%hbo: preprocessed oxygenated hemoglobin time series
	%hbr: preprocessed deoxygenated hemoglobin time series
	%badChannels: vector of channels to be excluded from further analyses
	%SCIList: list of scalp coupling index by channel
	%fs: sampling frequency
    
    %author: Carolina Pletti (carolina.pletti@gmail.com). Adapted from a script by Trinh Nguyen
	
    %calculate sampling rate and sampling period
    ts = t(2)-t(1);
    fs = 1/ts;
    
    % convert the wavelength data to optical density
    dod = hmrIntensity2OD(y);

    %plot optical density
    figure(1)
    set(gcf, 'WindowState', 'maximized');
    for j = 1:16
        subplot(4,4,j);
        plot(dod(:,j))
    end
    legend('raw_OD')

    %apply MARA algorythm to correct for motion artifacts
    mara_cfg = []; % prepare cfg structure containing settings for MARA
    %mara_cfg.chs = which channels???
    mara_cfg.L = 1; %Length of the moving-window to calculate the moving standard deviation (MSD)
    %1 (second) is the default value according to Nguyen et al., 2021
    
    mask = ones(1, 16); 
    ch_roi = find(mask ~= 0); 
    mara_cfg.chs = ch_roi; %index of channels to be analyzed - why 16???
    mara_cfg.th = 3; %Threshold for artifact detection. 3 is the default value according to Nguyen et al., 2021
    mara_cfg.alpha = 5; %Parameter that defined how much high-frequency information should 
            %           be preserved by the removal of the artifact (i.e., it corresponds 
            %           to the length of the LOESS smoothing window) -
            %           5 is the default value according to Nguyen et al., 2021
     mara_cfg.fs = fs;       
     
    dod_prep = LTC_spmfnirs_MARA(dod, mara_cfg);

    % bandpass filtering
    lpf = 0.5; % in Hz
    hpf = 0.01; % in Hz
    dod_corr_filt = hmrBandpassFilt(dod_prep, fs, hpf, lpf);

    %plot corrected and filtered data
    figure(2)
    set(gcf, 'WindowState', 'maximized');
    for j = 1:16
        subplot(4,4,j)
        ch = [dod_corr_filt(:,j)];
        plot(ch)
    end
    legend('corr_filt_OD')

    % Identify bad channels
    % plot all raw signals in the heart rate band for both
    % wavelengths, and save SCI in a table
    sz = [16, 4];
    varTypes = {'double','double','double','double'};
    varNames = {'Channel','R', 'Threshold', 'Bad'};
    SCIList = table('Size',sz,'VariableNames', varNames, 'VariableTypes', varTypes);

    figure(4)
    for i = 1:16
        %first wavelength
        x1 = d(:,i);
        y1 = bandpass(x1,[1/2 1+1/2],fs);
        %second wavelength
        x2 = d(:,i+16);
        y2 = bandpass(x2,[0.5 1.5], fs);
        %cut the first and last 200 time points to leave out artifacts. Then normalize.
        y1 = y1(200:length(y1)-200);
        normy1 = y1/max(y1);
        y2 = y2(200:length(y2)-200);
        normy2 = y2/max(y2);
        %calculate cross-correlation at 0 lag
        r = xcorr(normy1,normy2,0,'coeff');
        SCIList.Channel(i) = i;
        SCIList.R(i) = r;
        SCIList.Threshold(i) = 0.75;
        if r < 0.75
            SCIList.Bad(i) = 1;
        end
        %plot
        set(gcf, 'WindowState', 'maximized');
        subplot(8,2,i)
        plot([normy1,normy2])
    end
    disp(SCIList)

	
	%plot the continuous wavelet transform  power spectrum for each channel in order to visually check signal quality
	%convert unfiltered signal from optical density to concentration for plotting purposes.
    ppf = [6 6]; % partial pathlength factors for each wavelength.
    dod_check = hmrOD2Conc(dod_prep, SD, ppf);
    hbo = squeeze(dod_check(:,1,:));
    figure(5)
    for i = 1:1:size(hbo, 2)
        subplot(4,4,i);
        if ~isnan(hbo(:,i))
            sig = hbo(:,i);
            sigma2=var(sig); % estimate signal variance
            
            [wave,period,coi] = cwt(sig,seconds(ts));
            power = (abs(wave)).^2;

            for j=1:1:length(coi)
                wave(period >= coi(j), j) = NaN; % set values below cone of interest to NAN
            end

            h = imagesc(t , log2(seconds(period)), log2(abs(power/sigma2)));
            colorbar;
            Yticks = 2.^(fix(log2(min(seconds(period)))):fix(log2(max(seconds(period)))));
            set(gca,'YLim',log2([min(seconds(period)),max(seconds(period))]), ...
                'YDir','reverse', 'layer','top', ...
                'YTick',log2(Yticks(:)), ...
                'YTickLabel',num2str(Yticks'), ...
                'layer','top')
            title(sprintf('Channel %d', i));
            ylabel('Period in seconds');
            xlabel('Time in seconds');
            set(h, 'AlphaData', ~isnan(wave));

            colormap jet;
        end
    end
    set(gcf,'units','normalized','outerposition',[0 0 1 1]) % maximize figure

	%open box to manually mark bad channels
    badChannels = channelCheckbox();

    %convert changes in OD (filtered signal) to changes in concentrations (HbO, HbR, and HbT)
    ppf = [6 6]; % partial pathlength factors for each wavelength.
    dc = hmrOD2Conc(dod_corr_filt, SD, ppf);

    % extract hbo and hbr
    hbo = squeeze(dc(:,1,:));
    hbr = squeeze(dc(:,2,:));

end