function [data] = care_spmfnirs_preproc(cfg, data)
% care_spmfnirs_preproc does the general preprocessing of the fnirs data. The
% function includes the following steps
%   * Conversion from wavelength data to optical density
%   * MARA motion correction
%   * Pulse quality check
%   * Removing of bad channels
%   * Bandpass filtering
%   * Conversion from optical density to changes in concentration (HbO, HbR and HbT)
%
% Use as
%   care_spmfnirs_preproc(cfg, data)
%
% where the input data has to be the result from care_spmfnirs_NIRxtoSPM 
%

cfg.pulseQualityCheck = 'yes';

% Preprocessing for each subject and for each segmented epoch
fprintf('<strong>Preprocessing subject 1...</strong>\n');
data.sub1 = preproc(cfg, data.sub1);

fprintf('<strong>Preprocessing subject 2...</strong>\n');
data.sub2 = preproc(cfg, data.sub2);

end

% -------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function data = preproc(mainCfg, data)
% Loop through each segmented epoch (cell in data.y, data.s, etc.)
num_epochs = length(data.y);  % Assuming data.y, data.s, data.t are cell arrays

for epoch_idx = 1:num_epochs
    fprintf('<strong>Processing epoch %d of %d...</strong>\n', epoch_idx, num_epochs);

    % Load the data for this epoch
    y_epoch = data.y{epoch_idx};
    s_epoch = data.s{epoch_idx};
    t_epoch = data.t{epoch_idx};

    % Convert the wavelength data to optical density for this epoch
    cfg = [];
    cfg.info = 'Wavelength to Optical Density';
    data.cfg = cfg;
    data.fs = 7.8125;
    
    % Store optical density for each epoch
    data.yod{epoch_idx} = spm_fnirs_calc_od(y_epoch);

    % Apply MARA for motion artifact correction on this epoch's data
    mask = ones(1, 16);
    ch_roi = find(mask ~= 0);  % Select channels of interest
    cfg.M.chs = ch_roi;
    cfg.M.L = 1;
    cfg.M.th = 3;
    cfg.M.alpha = 5;
    cfg.fs = 7.8125;
    [data.procd{epoch_idx}, cfg] = CARE_spmfnirs_MARA(data.yod{epoch_idx}, cfg);

    % Convert changes in optical density to changes in concentration (HbO, HbR, and HbT)
    ppf = [6 6];  % partial pathlength factors for each wavelength
    data.conc{epoch_idx} = hmrOD2Conc(data.procd{epoch_idx}, data.SD, ppf);

    % Extract hbo (oxyhemoglobin) for this epoch
    hbo = squeeze(data.conc{epoch_idx}(:, 1, :));
    t = t_epoch;

    % Pulse quality check - estimate and show time-frequency responses
    for ii = 1:size(hbo, 2)
        subplot(4, 4, ii);
        sig = [t, hbo(:, ii)];
        sigma2 = var(sig(:, 2));
        
        [wave, period, ~, coi, ~] = wt(sig);  % compute wavelet power spectrum
        power = (abs(wave)).^2;
        
        for j = 1:length(coi)
            wave(period >= coi(j), j) = NaN;  % set values below cone of interest to NaN
        end
        
        h = imagesc(t, log2(period), log2(abs(power / sigma2)));
        colorbar;
        Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
        set(gca, 'YLim', log2([min(period), max(period)]), ...
                 'YDir', 'reverse', 'layer', 'top', ...
                 'YTick', log2(Yticks(:)), ...
                 'YTickLabel', num2str(Yticks'), ...
                 'layer', 'top');
        title(sprintf('Channel %d', ii));
        ylabel('Period in seconds');
        xlabel('Time in seconds');
        set(h, 'AlphaData', ~isnan(wave));

        colormap jet;
        clear title
    end
    set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1]);

    % Prompt for bad channel selection
    prompt = {'Enter Bad Channels'};
    name = 'Input';
    dims = [1 35];
    definput = {''};
    answer = inputdlg(prompt, name, dims, definput);
    data.badChannels{epoch_idx} = str2num(answer{1});

    close(gcf);

    % Bandpass filtering for the epoch
    cfg = [];
    cfg.info = 'Bandpass filtering';
    cfg.lpf = 0.5;  % Low-pass filter (in Hz)
    cfg.hpf = 0.01;  % High-pass filter (in Hz)
    cfg.fs = 7.8125;
    cfg.previous = data.cfg;
    data.cfg = cfg;
    data.filtd{epoch_idx} = hmrBandpassFilt(data.procd{epoch_idx}, cfg.fs, cfg.hpf, cfg.lpf);

    % Convert filtered data to changes in concentrations (HbO, HbR, and HbT)
    cfg = [];
    cfg.info = 'Optical Density to concentrations (HbO, HbR, and HbT)';
    cfg.wav = [760, 840];
    cfg.ppf = ppf;
    
    % Extract concentrations for this epoch
    [data.hbo{epoch_idx}, data.hbr{epoch_idx}, data.hbt{epoch_idx}] = spm_fnirs_calc_hb(data.filtd{epoch_idx}, cfg);

    % Reject bad channels for this epoch
    data.hbo{epoch_idx}(:, data.badChannels{epoch_idx}) = NaN;
    data.hbr{epoch_idx}(:, data.badChannels{epoch_idx}) = NaN;

    % Clean up aux data
    data = rmfield(data, 'aux');
end

end
