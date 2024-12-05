function [Y,cfg] = care_spmfnirs_MARA(x,cfg)
%__________________________________________________________________________
% Function to apply the movement artifact removal algorithm (MARA)
% presented in Scholkmann et al. (2010). How to detect and reduce movement
% artifacts in near-infrared imaging using moving standard deviation and 
% spline interpolation. Physiological Measurement, 31, 649-662.

% This version (v.1.1) is slightly different to the original approach
% presented in the paper: Instead of using the spline
% interpolation this version implements a smoothing based on local 
% regression using weighted linear least squares and a 2nd degree 
% polynomial model. This imrproves the reconstruction of the signal parts
% that are affectes by the artifacts.

%
% INPUT
% x:        Input signal
% fs:       Sampling frequency [Hz]
% L:        Length of the moving-window to calculate the moving standard
%           deviation (MSD)
% T:        Threshold for artifact detection
% k:        half of the centered window length (w = 1 + 2*k)
% alpha:    Parameter that defined how much high-frequency information should 
%           be preserved by the removal of the artifact (i.e., it corresponds 
%           to the length of the LOESS smoothing window)

% OUTPUT:
% y:        Denoised signal

% Example 1: [y] = MARA_NIRSSPM(x1,10,0.0005,100,4);
% (Here, the sampling frequency is 10 Hz, the threshold is 0.0005, the MSD window
% length is 100 and 4 refers to the window for the LOESS smoothing.

% Example 2: [y] = MARA_NIRSSPM(x6,50,25,300,50);
% (Here, the sampling frequency is 50 Hz, the threshold is 25, the MSD window
% length is 300 and 100 refers to the window for the LOESS smoothing.

% NOTES:
% (1) If the first sample is already a artifact, the algorithms produces
% an error. This has to be fixed for the next release.
% (2) If the treshold value T is below or above the range of the signal,
% the algorithms stops and an error message is displayed.

%__________________________________________________________________________
% Dr. Felix Scholkmann, Biomedical Optics Research Laboratory (BORL), 
% Universtiy Hospital Zurich, University of Zurich, Zurich, Switzerland
% Felix.Scholkmann@usz.ch
% Version 1: 30 September 2008. This version: 29 May 2015
%_________________________________________________________________________




%_________________________________________________________________________
Y=x;    
dim = size(Y);
if ndims(Y) == 3,
    Y = reshape(Y, [dim(1) dim(2) * dim(3)]);
else
    dim(3) = 1;
end

n = size(Y, 2);

%--------------------------------------------------------------------------
% i. motion artifact correction
    M = cfg.M;
    indx_m = []; % indices of measurements to be corrected
    for i = 1:dim(3), indx_m = [indx_m M.chs+dim(2)*(i-1)]; end
    
    % L: moving window length
    if ~iscell(M.L) % L: scalar
        if isscalar(M.L)
            L = NaN(1, n);
            L(indx_m) = M.L;
            L = mat2cell(L, 1, dim(2) * ones(1, dim(3)));
            M.L = L;
        else
            fprintf('Error: parameter L should be scalar or cell array.\n');
        end
    end
    L = round(cell2mat(M.L) .* cfg.fs);
    
    % alpha: smoothing factor-motion artifact
    if ~iscell(M.alpha) % L: scalar
        if isscalar(M.alpha)
            alpha = NaN(1, n);
            alpha(indx_m) = M.alpha;
            alpha = mat2cell(alpha, 1, dim(2) * ones(1, dim(3))); 
            M.alpha = alpha; 
        else
            fprintf('Error: parameter alpha should be scalar or cell array.\n');
        end
    end
    alpha = cell2mat(M.alpha);
    
    % threshold for motion detection
    mstd_y = NaN(3, n);
    
    %spm_input('Remove motion artifact from Hb changes:', 1, 'd');
    nd = size(indx_m, 2);
    %spm_progress_bar('Init', nd, 'Std estimation', 'Total number of data');
    
    for i = 1:nd 
        std_y = spm_fnirs_MovStd(Y(:, indx_m(i)), round(L(indx_m(i))./2)); 
        indx_n = find(isnan(std_y) == 1); std_y(indx_n) = [];
        mstd_y(1, indx_m(i)) = min(std_y);
        mstd_y(2, indx_m(i)) = mean(std_y);
        mstd_y(3, indx_m(i)) = max(std_y);
        %spm_progress_bar('Set', i);
    end
    %spm_progress_bar('Clear');
    
    if ~iscell(M.th)
        if isscalar(M.th)
            th = M.th * mstd_y(2,:);
            th = mat2cell(th, 1, dim(2) * ones(1, dim(3)));
            M.th = th; 
        else
            fprintf('Error: parameter th should be scalar or cell array.\n');
        end
    end
    th = cell2mat(M.th);
    
    % apply MARA method
     %spm_progress_bar('Init', nd, 'motion artifact removal', 'Total number of data');
    for i = 1:nd 
        if th(indx_m(i)) < mstd_y(3, indx_m(i)) && th(indx_m(i)) > mstd_y(1, indx_m(i))
            Y(:, indx_m(i)) = spm_fnirs_MARA(Y(:, indx_m(i)), cfg.fs, th(indx_m(i)), L(indx_m(i)) , alpha(indx_m(i)));
        end
        %spm_progress_bar('Set', i); 
    end
    %spm_progress_bar('Clear'); 
    
    % update structure array for MARA
    cfg.M = M;
end