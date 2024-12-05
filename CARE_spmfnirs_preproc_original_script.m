function [data] = care_spmfnirs_preproc( cfg, data )
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
%   care_spmfnirs_preproc( cfg, data )
%
% where the input data has to be the result from care_spmfnirs_NIRxtoSPM 
%
% The configuration options are
%   cfg.pulseQualityCheck = apply visual pulse quality check, 'yes' or 'no', (default: 'yes')
%
%
% SEE also HMRINTENSITY2OD, ENPRUNECHANNELS, HMRMOTIONCORRECTWAVELET,
% HMRMOTIONARTIFACT, HMRBANDPASSFILT, HMROD2CONC

% Copyright (C) 2017-2018, Daniel Matthes, MPI CBS, Trinh Nguyen, Univie

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
cfg.pulseQualityCheck =  'yes';

% -------------------------------------------------------------------------
% Preprocessing
% -------------------------------------------------------------------------
fprintf('<strong>Preproc subject 1...</strong>\n');
data.sub1 = preproc( cfg, data.sub1 );
fprintf('<strong>Preproc subject 2...</strong>\n');
data.sub2 = preproc( cfg, data.sub2 );

end

% -------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function data = preproc( mainCfg, data )
data.yn(:,:,1)=data.y(:,1:16);
data.yn(:,:,2)=data.y(:,17:32);

% convert the wavelength data to optical density
cfg = [];
cfg.info = 'Wavelength to Optical Density';
data.cfg = cfg;
data.fs  = 7.8125;
data.yod = spm_fnirs_calc_od( data.yn );                           

% checking for bad channels and removing them (SD.MeasListAct has zeros 
% input for bad channels)
% cfg = [];
% cfg.info      = 'Removing bad channels by enPruneChannels()';
% cfg.tInc      = ones(size(data.aux,1),1);                                                 
% cfg.dRange    = [0 10000000];
% cfg.SNRthresh = 2;
% cfg.resetFlag = 0;
% cfg.previous  = data.cfg;
% data.cfg      = cfg;
% data.SD       = enPruneChannels(data.d, data.SD, cfg.tInc, cfg.dRange,...
%                                 cfg.SNRthresh, cfg.resetFlag);

% correcting for motion artifacts using Wavelet-based motion correction.                                
%cfg = [];
%cfg.info            = 'Wavelet-based motion artifact correction';
%cfg.iQr             = 1.5;                                                  % iqr of 0.5 for infant data recommended
%cfg.previous        = data.cfg;
%data.cfg            = cfg;
%[~, data.dod_corr]  = evalc(...                                             % evalc supresses annoying fprintf output of hmrMotionCorrectWavelet
%                'hmrMotionCorrectWavelet(data.dod, data.SD, cfg.iQr);');

% Apply MARA for motion artifact correction
% identify channels of interest 

mask = ones(1, 16); 
ch_roi = find(mask ~= 0); 

% display time series of fNIRS data
% spm_fnirs_viewer_timeseries(Y_ch, P, [], ch_roi);

    chs = ch_roi;
    cfg.M.chs = chs;
    cfg.M.L = 1;
    cfg.M.th = 3;
    cfg.M.alpha = 5;
    %cfg.C.type = 'Band-stop filter';
    %cfg.C.cutoff = [0.12 0.35; 0.7 1.5];                                     % '[0.12 0.35; 0.7 1.5]'
    %cfg.D.type = 'no';
    cfg.fs = 7.8125;


    
[data.procd, cfg] = CARE_spmfnirs_MARA(data.yod,... 
                            cfg); 



% run pulse quality check
% -------------------------------------------------------------------------
% Convert changes in OD to changes in concentrations (HbO, HbR, and HbT)
% -------------------------------------------------------------------------
ppf   = [6 6];                                                              % partial pathlength factors for each wavelength.
data.conc  = hmrOD2Conc(data.procd, data.SD, ppf);

% -------------------------------------------------------------------------
% Extract hbo
% -------------------------------------------------------------------------
hbo = squeeze(data.conc(:,1,:));
t = data.t;
% -------------------------------------------------------------------------
% Estimate and show time-frequency responses of all channels
% -------------------------------------------------------------------------

for ii = 1:1:size(hbo, 2)
  subplot(4,4,ii);
  sig = [t, hbo(:,ii)];
  sigma2=var(sig(:,2));                                                     % estimate signal variance
  
  [wave,period,~,coi,~] = wt(sig);                                          % compute wavelet power spectrum
  power = (abs(wave)).^2 ;
  
  for j=1:1:length(coi)
    wave(period >= coi(j), j) = NaN;                                        % set values below cone of interest to NAN
  end

  h = imagesc(t, log2(period), log2(abs(power/sigma2)));
  colorbar;
  Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
  set(gca,'YLim',log2([min(period),max(period)]), ...
          'YDir','reverse', 'layer','top', ...
          'YTick',log2(Yticks(:)), ...
          'YTickLabel',num2str(Yticks'), ...
          'layer','top')
  title(sprintf('Channel %d', ii));
  ylabel('Period in seconds');
  xlabel('Time in seconds');
  set(h, 'AlphaData', ~isnan(wave));

  colormap jet;
  clear title
end
set(gcf,'units','normalized','outerposition',[0 0 1 1])                     % maximize figure

prompt = {'Enter Bad Channels'};
name = 'Input';
dims = [1 35];
definput = {''};
answer = inputdlg(prompt,name,dims,definput);
data.badChannels = str2num(answer{1});

close(gcf); 




% bandpass filtering
cfg = [];
cfg.info            = 'Bandpass filtering';
cfg.lpf             = 0.5;                                                  % in Hz
cfg.hpf             = 0.01;                                                 % in Hz
cfg.fs              = 7.8125;
cfg.previous        = data.cfg;
data.cfg            = cfg;
data.filtd  = hmrBandpassFilt(data.procd, cfg.fs, cfg.hpf, ...
                                      cfg.lpf);

% convert changes in OD to changes in concentrations (HbO, HbR, and HbT)
cfg = [];
cfg.info      = 'Optical Density to concentrations (HbO, HbR, and HbT)';
%cfg.ppf      = [6 6];                                                       % partial pathlength factors for each wavelength.
cfg.wav= [760 840];
sub=data.SD.sub;
if  sub==1
    cfg.age= 5; 
else 
    cfg.age= 36;
end

cfg.d = 3;

if cfg.age==5
cfg.acoef = [1.4033    3.8547; 2.6694    1.8096];
cfg.dpf = [5.5067 4.6881];
elseif cfg.age==36
cfg.acoef = [1.4033    3.8547; 2.6694    1.8096];
cfg.dpf = [6.4658 5.4036];
end

cfg.previous  = data.cfg;
data.cfg      = cfg;

y_filtd(:,1:16,1)=data.filtd(:,1:16);
y_filtd(:,1:16,2)=data.filtd(:,17:32);
data.y_filtd=y_filtd;
[data.hbo,data.hbr,data.hbt] = spm_fnirs_calc_hb(data.y_filtd, cfg);

%data.dc       = hmrOD2Conc(data.filtd, data.SD, cfg.ppf);

% extract hbo and hbr
%data.hbo = squeeze(data.dc(:,1,:));
%data.hbr = squeeze(data.dc(:,2,:));



% reject bad channels, set all values to NaN
    data.hbo(:, data.badChannels) = NaN;
    data.hbr(:, data.badChannels) = NaN;


data = rmfield(data, 'aux');                                                % remove field aux from data structure

end
