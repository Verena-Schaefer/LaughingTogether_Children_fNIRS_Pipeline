function cfg = LTC_NIRxtoSPM(cfg)
    % LTC_NIRxtoSPM creates a *.mat file for use in spm-fnirs from NIRx output
    % data files (*.hdr, *.wl1, *.wl2) and a previously build SD file (*.SD), 
    % which matches the source-detector layout used in the NIRx acquisition.
    %
    % To use this script, the user must first create an SD file.
    %
    %
    % The configuration options are
    %   dyadNum     = dyad description (i.e. L_1)
    %   prefix      = L or K, defines raw data file prefix, which is based
    %   on group (e.g. Lachen, Kontrolle
    %   srcPath     = location of NIRx files for both subjects of the dyad 
    %   desPath     = memory location for the converted NIRS file
    %   SDfile      = memory location of the *.SD file (ex: '/data/pt_01867/fnirsData/DualfNIRS_CARE_generalSettings/CARE.SD')
    %
    % Based on the function CARE_spmfnirs_NIRxtoSPM created by Trinh
    % Nguyen, univie, 2020 and Daniel Matthes, MPI CBS, 2017
    % 
    % Most of the code is taken from a function called NIRx2nirs from Rob J 
    % Cooper, University College London, August 2013  and an edited version 
    % by NIRx Medical Technologies, Apr2016 called NIRx2nirs_probeInfo_rotate.

    % -------------------------------------------------------------------------
    % Get and check config options
    % -------------------------------------------------------------------------

    dyadNum = cfg.currentPair;
    prefix = cfg.currentPrefix;
    srcPath = cfg.rawGrDir;
    SDfile = cfg.SDFile;
    desDir = cfg.srcDir;
    cfg.desDir = desDir;
   
    % -------------------------------------------------------------------------
    % Make folders for converted data, if they don't exist
    % -------------------------------------------------------------------------
    if ~exist (desDir, 'dir')
        mkdir(desDir)
    end
    
    % -------------------------------------------------------------------------
    % Load SD file
    % -------------------------------------------------------------------------
    load(SDfile, '-mat', 'SD');
    
    
    % Loop through each participant
    
    for sub = 1:2
        
        % -------------------------------------------------------------------------
        % Build filenames
        % -------------------------------------------------------------------------
        SubSrcDir  = strcat(srcPath, dyadNum, '\Subject', int2str(sub), '\');
        SubDesFile = strcat(desDir, dyadNum,'_sub', int2str(sub), '.mat');
        
        % -------------------------------------------------------------------------
        % Check if NIRx data exist
        % -------------------------------------------------------------------------
        if ~exist(SubSrcDir, 'dir')
            problem = {'raw data directory does not exist'};
            cfg.problems = [cfg.problems,problem];
            return
        else
            if ~exist(SubDesFile, 'file')
                Sub_wl1File = strcat(SubSrcDir, dyadNum, '.nosatflags_wl1');
                Sub_wl2File = strcat(SubSrcDir, dyadNum, '.nosatflags_wl2');
                Sub_hdrFile = strcat(SubSrcDir, dyadNum, '.hdr');

                % -------------------------------------------------------------------------
                % Convert and export data
                % -------------------------------------------------------------------------
                fprintf('<strong>Converting data from NIRx to spmfnirs for dyad %s, subject %d...</strong>\n', dyadNum, sub);
                try
                    convertData(SubDesFile, Sub_wl1File, Sub_wl2File, Sub_hdrFile, SD,...
                        prefix, dyadNum);
                catch
                    Sub_wl1File = strcat(SubSrcDir, dyadNum, '.wl1');
                    Sub_wl2File = strcat(SubSrcDir, dyadNum, '.wl2');
                    try
                        convertData(SubDesFile, Sub_wl1File, Sub_wl2File, Sub_hdrFile, SD,...
                        prefix, dyadNum);
                    catch
                        problem = {'can''t convert data'};
                        cfg.problems = [cfg.problems,problem];
                        return
                    end
                end
            end
        end
    end
        
    cfg.steps = [cfg.steps, {'conversion'}];
    
    % -------------------------------------------------------------------------
    % SUBFUNCTION data convertion
    % -------------------------------------------------------------------------
    function convertData (desFile, wl1File, wl2File, hdrFile, SD, pf, num)
        wl1 = load(wl1File);                                                        % load .wl1 file
        wl2 = load(wl2File);                                                        % load .wl2 file

        y = [wl1 wl2];                                                       % load .wl2 file

        fid = fopen(hdrFile);
        tmp = textscan(fid,'%s','delimiter','\n');                                  % this just reads every line
        hdr_str = tmp{1};
        fclose(fid);

        keyword = 'Sources=';                                                       % find number of sources
        tmp = hdr_str{strncmp(hdr_str, keyword, length(keyword))};
        NIRxSources = str2double(tmp(length(keyword)+1:end));

        keyword = 'Detectors=';                                                     % find number of detectors
        tmp = hdr_str{strncmp(hdr_str, keyword, length(keyword))};
        NIRxDetectors = str2double(tmp(length(keyword)+1:end));

        if NIRxSources < SD.nSrcs || NIRxDetectors < SD.nDets                       % Compare number of sources and detectors to SD file
           error('The number of sources and detectors in the NIRx files does not match your SD file...');
        end

        keyword = 'SamplingRate=';                                                  % find Sample rate
        tmp = hdr_str{strncmp(hdr_str, keyword, 13)};
        fs = str2double(tmp(length(keyword)+1:end));

        % find Active Source-Detector pairs
        keyword = 'S-D-Mask="#';
        ind = find(strncmp(hdr_str, keyword, length(keyword))) + 1;
        ind2 = find(strncmp(hdr_str(ind+1:end), '#', 1)) - 1;
        ind2 = ind + ind2(1);
        sd_ind = cell2mat(cellfun(@str2num, hdr_str(ind:ind2), 'UniformOutput', 0));
        sd_ind = sd_ind';
        sd_ind = logical([sd_ind(:);sd_ind(:)]);
        y = y(:, sd_ind);

        % find NaN values in the recorded data -> channels should be pruned as 'bad'
        for i=1:size(y,2)
            if nonzeros(isnan(y(:,i)))
                SD.MeasListAct(i) = 0;
            end
        end

        % find event markers and build s vector
        keyword = 'Events="#';
        ind = find(strncmp(hdr_str, keyword, length(keyword))) + 1;
        ind2 = find(strncmp(hdr_str(ind+1:end), '#', 1)) - 1;
        ind2 = ind + ind2(1);
        events = cell2mat(cellfun(@str2num, hdr_str(ind:ind2), 'UniformOutput', 0));
        events = events(:,2:3);
        if strcmp(pf, 'CARE')
          if num < 7                                                                %  correction of markers for dyads until number 6
            events = correctEvents( events );
          end
        end
        markertypes = unique(events(:,1));
        s = zeros(length(y),length(markertypes));
        for i = 1:length(markertypes)
            s(events(events(:,1) == markertypes(i), 2), i) = 1;
        end

        % create t, aux varibles
        aux = ones(length(y),1);                                                    %#ok<NASGU>
        t = 0:1/fs:length(y)/fs - 1/fs;
        t = t';                                                                     %#ok<NASGU>

        fprintf('Saving spm fnirs file: %s...\n', desFile);
        save(desFile, 'y', 's', 't', 'aux', 'SD');
        fprintf('Data stored!\n\n');

        clear y s t aux SD
    end

end