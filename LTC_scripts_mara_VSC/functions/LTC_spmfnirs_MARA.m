function [Y] = LTC_spmfnirs_MARA(x,cfg)
    %__________________________________________________________________________
    % This function calls the spm_fnirs_MARA function from fnirs smp, which applies the
    % movement artifact removal algorithm (MARA) presented in Scholkmann et al. (2010).
    % How to detect and reduce movement artifacts in near-infrared imaging using
    % moving standard deviation and spline interpolation. Physiological Measurement, 31, 649-662.

    % The MARA version called (v.1.1) is slightly different to the original approach
    % presented in the paper: Instead of using the spline
    % interpolation this version implements a smoothing based on local 
    % regression using weighted linear least squares and a 2nd degree 
    % polynomial model. This imrproves the reconstruction of the signal parts
    % that are affectes by the artifacts.

    % INPUTS:
    %   x: Input signal (can be multi-dimensional)
    %   cfg: Configuration structure containing parameters such as:
    %        L (moving window length),
    %        alpha (smoothing factor for motion artifact),
    %        th (threshold for artifact detection),
    %        fs (sampling frequency).

    % OUTPUTS:
    %   Y: Corrected (denoised) signal after artifact removal.
        
    % NOTES:
    % (1) If the first sample is already a artifact, the algorithms produces
    % an error. This has to be fixed for the next release.
    % (2) If the treshold value T is below or above the range of the signal,
    % the algorithms stops and an error message is displayed.


    % minor mods for input and output format by Carolina Pletti, 2024

    %_________________________________________________________________________
    
    Y=x;    % put data in Y
    dim = size(Y); % check how many dimensions Y has
    % Check if the signal is 3D; if so, flatten it into a 2D matrix for processing.
    if ndims(Y) == 3
        Y = reshape(Y, [dim(1) dim(2) * dim(3)]);
    else
        dim(3) = 1; % Set the 3rd dimension to 1 for consistency.
    end
    
    % Get the number of measurement channels (columns in Y).
    n = size(Y, 2);

    %--------------------------------------------------------------------------
    % Step i: Motion artifact correction
    indx_m = []; % Initialize list of indices for measurements to correct.
    % Identify the indices of channels to correct for motion artifacts.
    for i = 1:dim(3)
        indx_m = [indx_m cfg.chs+dim(2)*(i-1)];
    end
    
    % Ensure the moving window length (L) is correctly formatted.
    if ~iscell(cfg.L)
        if isscalar(cfg.L)
            L = NaN(1, n); % Initialize L as NaN for all channels.
            L(indx_m) = cfg.L; % Assign the scalar L to relevant channels.
            L = mat2cell(L, 1, dim(2) * ones(1, dim(3))); % Convert to cell array.
            cfg.L = L; % Update cfg.L in the configuration.
        else
            fprintf('Error: parameter L should be scalar or cell array.\n');
        end
    end
    % Convert L from seconds to samples based on sampling frequency.
    L = round(cell2mat(cfg.L) .* cfg.fs);
    
    % Ensure the smoothing factor (alpha) is correctly formatted.
    if ~iscell(cfg.alpha)
        if isscalar(cfg.alpha)
            alpha = NaN(1, n); % Initialize alpha as NaN for all channels.
            alpha(indx_m) = cfg.alpha; % Assign the scalar alpha to relevant channels.
            alpha = mat2cell(alpha, 1, dim(2) * ones(1, dim(3))); % Convert to cell array.
            cfg.alpha = alpha; % Update cfg.alpha in the configuration.
        else
            fprintf('Error: parameter alpha should be scalar or cell array.\n');
        end
    end
    alpha = cell2mat(cfg.alpha);
    
    % Initialize matrix to store statistics for motion detection.
    mstd_y = NaN(3, n); % Rows represent min, mean, and max of moving standard deviation.
    
    % Process each channel to estimate motion statistics.
    nd = size(indx_m, 2); % Total number of channels to process.
    
    for i = 1:nd 
        % Compute the moving standard deviation for the current channel.
        std_y = spm_fnirs_MovStd(Y(:, indx_m(i)), round(L(indx_m(i))./2)); 
        
        % Remove NaN values from the result.
        std_y(isnan(std_y)) = [];
        
        % Store min, mean, and max values of the moving standard deviation.
        mstd_y(1, indx_m(i)) = min(std_y);
        mstd_y(2, indx_m(i)) = mean(std_y);
        mstd_y(3, indx_m(i)) = max(std_y);
    end
    
    % Ensure the threshold (th) for motion detection is correctly formatted.
    if ~iscell(cfg.th)
        if isscalar(cfg.th)
            th = cfg.th * mstd_y(2,:); % Scale threshold by mean standard deviation.
            th = mat2cell(th, 1, dim(2) * ones(1, dim(3))); % Convert to cell array.
            cfg.th = th; % Update M.th in the configuration.
        else
            fprintf('Error: parameter th should be scalar or cell array.\n');
        end
    end
    th = cell2mat(cfg.th);
    
    % Apply MARA to each channel based on calculated thresholds.
    for i = 1:nd 
        % Only apply MARA if the threshold is within the range of standard deviations.
        if th(indx_m(i)) < mstd_y(3, indx_m(i)) && th(indx_m(i)) > mstd_y(1, indx_m(i))
            Y(:, indx_m(i)) = spm_fnirs_MARA(Y(:, indx_m(i)), cfg.fs, th(indx_m(i)), L(indx_m(i)) , alpha(indx_m(i)));
        end
    end
end