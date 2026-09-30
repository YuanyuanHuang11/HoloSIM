% Two-point phase-dip resolution simulation using the full HoloSIM pipeline.
%
% This standalone script intentionally skips the Siemens-star, H_inc
% decomposition, and phase-response curve figures. It only simulates two
% Gaussian phase nanoparticles and reports the final phase reconstruction
% performance:
%   sample phase -> H_tra propagation -> four phase-shifted holograms
%   -> WF / known-operator theoretical SIM readout -> four-step PSI
%   -> final reconstructed phase maps and two-point dip metrics.
%

% Required on MATLAB path:
%   PsfOtf, OTF, SIMimagesF
% The blind PCMseparateF/PCMfilteringF/MergingHeptaletsF reconstruction is
% intentionally not used in this two-point-only script.

clear; close all; clc;
task_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(task_dir);
addpath(genpath(fullfile(project_root, 'function')));


%% Figure style: compact Nature-like output
set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultTextFontName', 'Arial');
set(groot, 'defaultLegendFontName', 'Arial');
set(groot, 'defaultColorbarFontName', 'Arial');
set(groot, 'defaultAxesFontSize', 10);
set(groot, 'defaultTextFontSize', 10);
set(groot, 'defaultLegendFontSize', 9);
set(groot, 'defaultColorbarFontSize', 9);
set(groot, 'defaultLineLineWidth', 1.8);
set(groot, 'defaultFigureColor', 'w');
set(groot, 'defaultAxesColor', 'w');
set(groot, 'defaultAxesXColor', 'k');
set(groot, 'defaultAxesYColor', 'k');
set(groot, 'defaultAxesZColor', 'k');
set(groot, 'defaultTextColor', 'k');

lineWidth = 2.0;
Ccol.sample = PSI_hex2rgb('#252525');
Ccol.htra   = PSI_hex2rgb('#4C78A8');
Ccol.holo   = PSI_hex2rgb('#0072B2');
Ccol.wf     = PSI_hex2rgb('#7B6EA8');
Ccol.qpm    = PSI_hex2rgb('#E69F00');
Ccol.teal   = PSI_hex2rgb('#009E73');
Ccol.red    = PSI_hex2rgb('#D55E00');
Ccol.gray   = PSI_hex2rgb('#7A7A7A');
Ccol.lightgray = PSI_hex2rgb('#D9D9D9');

outdir = fullfile(task_dir, 'results', 'HoloSIM_PSI_TwoPoint');
if ~exist(outdir, 'dir'), mkdir(outdir); end

%% Optical / reconstruction parameters
S.N = 1024;
S.dx = 32.5e-9;
S.dy = S.dx;
S.L = S.N*S.dx;
S.lambda = 405e-9;
S.lambda_eff = S.lambda/2;
S.SIM_lambda = 488e-9;
S.NA_SIM = 1.2;
S.NA_QPM = 1.2;
S.z_sample = 10e-9;

% Four-step PSI reference-field geometry.
% Keep S.ref.lateral_frequency = 0 for pure on-axis four-step PSI.
% In this pure PSI setting, theta = 0 deg and theta = 180 deg give the
% same reconstructed phase because there is no lateral carrier term.
S.ref.theta_deg = 180;                  % in-plane reference azimuth label, deg
S.ref.lateral_frequency = 0;            % cycles/m; zero means no off-axis carrier
S.ref.use_lateral_carrier = false;      % false = pure four-step PSI, no off-axis term
S.phase_shifts = [0 pi/2 pi 3*pi/2];
S.sim.illum_period_nm = 250;
S.sim.snr = 1e6;               % near-deterministic two-point demo; avoids noise dominating sparse objects
S.sim.camera_downsample_scale = 0.5;  % 32.5 nm -> 65 nm camera pixels
S.recon.holo_denoise_sigma_px = 0;

% Output controls. pngscreen avoids print/exportgraphics/savefig timeouts.
S.plot.showFigures = false;
S.plot.closeSavedFigures = true;
S.plot.saveMode = 'pngscreen';  % default for curves; map panels are saved with painters to avoid OpenGL image seams
S.plot.exportScale = 2.5;        % upscale getframe PNG exports for manuscript-quality figures
S.plot.exportDPI = 600;          % used by pngpainters exports
if S.plot.showFigures
    set(groot, 'defaultFigureVisible', 'on');
else
    set(groot, 'defaultFigureVisible', 'off');
end

%% Two-point resolution settings
S.twoPoint.separations_nm = [80 90 100 110 120 130 140 150 160 180 200 240 300];
S.twoPoint.selected_separations_nm = [100 120 150];
% Known-operator SIM readout.
% For a simulation, the illumination period is known; the effective linear SIM
% support is approximated as detection OTF cutoff + illumination spatial
% frequency. This avoids blind SIM-parameter estimation artifacts for sparse
% two-point targets.
S.sim.readout_mode = 'theory_known_operator';
S.sim.theory_otf_shape = 'hard';   % 'soft' = incoherent-OTF-like roll-off, 'hard' = binary support

% Compensation for the known-operator SIM readout.
%   'none'          : forward effective SIM OTF only; conservative but attenuates phase amplitude.
%   'wiener'        : OTF-compensated reconstruction transfer H^2/(H^2+beta).
%   'ideal_support' : upper-bound flat response inside the SIM support.
S.sim.theory_compensation = 'wiener';
S.sim.wiener_beta = 5e-4;          % smaller = stronger compensation; increase if ringing/noise appears
S.sim.min_support = 1e-4;          % suppress numerical tails outside the useful support

% Map overlays. The quantitative dip metric is always measured from the y = 0
% center-line profile; the map overlay is disabled to avoid misleading diagonal
% screen-capture artifacts in MATLAB.
S.twoPoint.show_profile_line_on_maps = false;

% Optional phase-gain calibration for display and absolute peak comparison.
% This does NOT change the two-point dip fraction or the claimed resolution,
% because dip = 1 - valley/peak is invariant under a positive scalar gain.
% It only corrects the global HoloSIM phase-amplitude scale using large-separation
% pairs where the two spots are well resolved.
S.twoPoint.apply_holo_phase_gain = true;
S.twoPoint.gain_reference = 'film';        % 'film' or 'sample'
S.twoPoint.gain_ref_sep_min_nm = 200;      % use large separations for gain estimate
S.twoPoint.max_holo_phase_gain = 3.0;      % safety cap to avoid misleading over-amplification
S.twoPoint.map_display_use_gain_corrected_holo = true;

S.twoPoint.spot_sigma_nm = 25;        % Gaussian sigma of each phase nanoparticle
S.twoPoint.phase_amp = 1.0;           % peak phase per isolated nanoparticle, rad
S.twoPoint.profile_halfwidth_nm = 350;
S.twoPoint.map_halfwidth_nm = 360;
S.twoPoint.peak_window_nm = 55;
S.twoPoint.dip_thresholds = [0.10 0.20 0.265];  % 26.5% is a Rayleigh-like dip criterion

fprintf('Two-point HoloSIM phase-resolution simulation only. Output: %s\n', outdir);
fprintf('Grid dx = %.1f nm, camera pixel = %.1f nm, SIM period = %.0f nm, z = %.1f nm\n', ...
    S.dx*1e9, S.dx*1e9/S.sim.camera_downsample_scale, S.sim.illum_period_nm, S.z_sample*1e9);
fprintf('PSI reference: theta = %.1f deg, lateral carrier = %.3g cycles/um, pure PSI = %d\n', ...
    S.ref.theta_deg, S.ref.lateral_frequency/1e6, ~S.ref.use_lateral_carrier);

[x,y,FX,FY,FR] = NF_makeGrids(S.N,S.dx);
Htra = NF_propagationTF(FX,FY,S.lambda_eff,S.z_sample);
Pupil_QPM = double(FR <= S.NA_QPM/S.lambda);

%% Use known theoretical SIM readout operator
% In the two-point-only simulation, we do not estimate SIM parameters from the
% object. The forward model already defines the illumination period and the
% detection OTF. The HoloSIM readout below therefore uses a deterministic
% known-support SIM operator for each phase-shifted hologram.
fc_det_um = (2*S.NA_SIM/S.SIM_lambda)/1e6;
f_illum_um = (1/(S.sim.illum_period_nm*1e-9))/1e6;
f_sim_um = fc_det_um + f_illum_um;
fprintf('[SIM] Using known theoretical SIM readout operator.\n');
fprintf('[SIM] Detection cutoff = %.2f cycles/um, illumination frequency = %.2f cycles/um, effective SIM cutoff = %.2f cycles/um.\n', ...
    fc_det_um, f_illum_um, f_sim_um);

%% Main two-point simulation loop
sepList_nm = S.twoPoint.separations_nm(:);
methodNames = {'Sample','H{tra}-filtered','QPM','FilmWF','HoloSIM'};
methodLabels = {'Sample GT','H{tra}-filtered','Conventional QPM','WF readout','HoloSIM'};
nSep = numel(sepList_nm);
nMethod = numel(methodNames);

dipFrac = nan(nSep,nMethod);
valleyRatio = nan(nSep,nMethod);
peakMean = nan(nSep,nMethod);
detectedSep_nm = nan(nSep,nMethod);
profileNorm = cell(nSep,nMethod);
xProfile_nm = [];
selectedMaps = struct('sep_nm',{},'phase_sample',{},'phase_film',{},'phase_qpm',{},'phase_wf',{}, ...
    'phase_holo_raw',{},'phase_holo',{},'phase_holo_gainCorrected',{}, ...
    'err_holo_sample',{},'err_holo_sample_gainCorrected',{});

fprintf('\n[Two-point] Running final phase reconstruction for %d separations...\n', nSep);
tAll = tic;
for isep = 1:nSep
    sep_nm = sepList_nm(isep);

    % Sample and film-plane fields.
    phi_sample = makeTwoPointPhase(x,y,sep_nm,S.twoPoint.spot_sigma_nm,S.twoPoint.phase_amp);
    U_sample = exp(1i*phi_sample);
    U_film = NF_propagateField(U_sample,Htra);
    bgMask = sqrt(x.^2 + y.^2) > 1.0e-6;
    phi_film = PSI_phaseFromFieldWithBackground(U_film, bgMask);

    % Conventional coherent QPM baseline.
    U_qpm = ifft2(fft2(U_sample).*fftshift(Pupil_QPM));

    % Four phase-shifted holograms.
    I4_qpm_cam = zeros(S.N/2,S.N/2,4);
    I4_film_raw = zeros(S.N,S.N,4);
    I4_film_wf = zeros(S.N,S.N,4);
    I4_holo = zeros(S.N,S.N,4);

    for kk = 1:4
        ref = NF_makePSIReferenceField(x, y, S, kk);
        Iqpm_hi = abs(U_qpm + ref).^2;
        I4_qpm_cam(:,:,kk) = SIM_cameraPixelIntegrateDownsample_Star(Iqpm_hi, S.sim.camera_downsample_scale);
        I4_film_raw(:,:,kk) = abs(U_film + ref).^2;
    end

    % Shared normalization across the four holograms for this separation.
    I4_film_raw_norm = I4_film_raw / max(max(I4_film_raw(:)), eps);

    for kk = 1:4
        I4_film_wf(:,:,kk) = SIM_applyWFfluor(I4_film_raw_norm(:,:,kk),FR,S);
        I4_holo(:,:,kk) = SIM_applyTheorySIMReadout(I4_film_raw_norm(:,:,kk),FR,S);
    end

    % Four-step PSI final phase reconstructions.
    phi_qpm_cam = PSI_demod4Simple(I4_qpm_cam);
    bg_cam = SIM_cameraPixelIntegrateDownsample_Star(double(bgMask), S.sim.camera_downsample_scale) > 0.5;
    phi_qpm_cam = PSI_subtractBackground(phi_qpm_cam, bg_cam);
    phi_qpm = imresize(phi_qpm_cam, [S.N S.N], 'bicubic');

    phi_wf = PSI_subtractBackground(PSI_demod4Simple(I4_film_wf), bgMask);
    phi_holo = PSI_subtractBackground(PSI_demod4Simple(I4_holo), bgMask);

    phaseSet = {phi_sample, phi_film, phi_qpm, phi_wf, phi_holo};

    for im = 1:nMethod
        M = PSI_twoPointDipMetric(phaseSet{im}, x, sep_nm, S);
        dipFrac(isep,im) = M.dipFraction;
        valleyRatio(isep,im) = M.valleyRatio;
        peakMean(isep,im) = M.peakMean;
        detectedSep_nm(isep,im) = M.detectedPeakSeparation_nm;
        [xProfile_nm, profileNorm{isep,im}] = PSI_twoPointNormalizedProfile(phaseSet{im}, x, S.twoPoint.profile_halfwidth_nm);
    end

    if any(abs(sep_nm - S.twoPoint.selected_separations_nm(:)) < 1e-9)
        ss = numel(selectedMaps) + 1;
        selectedMaps(ss).sep_nm = sep_nm;
        selectedMaps(ss).phase_sample = phi_sample;
        selectedMaps(ss).phase_film = phi_film;
        selectedMaps(ss).phase_qpm = phi_qpm;
        selectedMaps(ss).phase_wf = phi_wf;
        selectedMaps(ss).phase_holo_raw = phi_holo;
        selectedMaps(ss).phase_holo = phi_holo;
        selectedMaps(ss).phase_holo_gainCorrected = phi_holo;
        selectedMaps(ss).err_holo_sample = phi_holo - phi_sample;
        selectedMaps(ss).err_holo_sample_gainCorrected = phi_holo - phi_sample;
    end

    fprintf('[Two-point] d = %4.0f nm | dip: Film %.3f, QPM %.3f, WF %.3f, HoloSIM %.3f\n', ...
        sep_nm, dipFrac(isep,2), dipFrac(isep,3), dipFrac(isep,4), dipFrac(isep,5));
end

%% HoloSIM scalar phase-gain calibration for absolute amplitude display
% The raw HoloSIM phase maps can be globally scaled down by the known readout
% transfer even when the two-point dip is preserved. Estimate one scalar gain
% from large-separation pairs and apply it only to absolute-amplitude maps and
% peak-height reporting. The dip metric remains based on the raw reconstructed
% shape and is unaffected by this scalar multiplication.
holoPhaseGain = 1;
gainReferenceIndex = 2;  % Film plane by default
if isfield(S.twoPoint,'gain_reference') && strcmpi(S.twoPoint.gain_reference,'sample')
    gainReferenceIndex = 1;
end

if isfield(S.twoPoint,'apply_holo_phase_gain') && S.twoPoint.apply_holo_phase_gain
    gainMask = sepList_nm >= S.twoPoint.gain_ref_sep_min_nm & ...
        isfinite(peakMean(:,gainReferenceIndex)) & isfinite(peakMean(:,5)) & peakMean(:,5) > eps;
    if nnz(gainMask) >= 1
        gainVals = peakMean(gainMask,gainReferenceIndex) ./ max(peakMean(gainMask,5), eps);
        holoPhaseGain = median(gainVals, 'omitnan');
        if ~isfinite(holoPhaseGain) || holoPhaseGain <= 0
            holoPhaseGain = 1;
        end
        if isfield(S.twoPoint,'max_holo_phase_gain')
            holoPhaseGain = min(holoPhaseGain, S.twoPoint.max_holo_phase_gain);
        end
    end
end
S.twoPoint.holo_phase_gain = holoPhaseGain;

fprintf('[HoloSIM gain] reference = %s, sep >= %.0f nm, scalar phase gain = %.3f\n', ...
    S.twoPoint.gain_reference, S.twoPoint.gain_ref_sep_min_nm, holoPhaseGain);

% Update selected maps for display.
for ss = 1:numel(selectedMaps)
    selectedMaps(ss).phase_holo_gainCorrected = holoPhaseGain * selectedMaps(ss).phase_holo_raw;
    if isfield(S.twoPoint,'map_display_use_gain_corrected_holo') && S.twoPoint.map_display_use_gain_corrected_holo
        selectedMaps(ss).phase_holo = selectedMaps(ss).phase_holo_gainCorrected;
        selectedMaps(ss).err_holo_sample = selectedMaps(ss).phase_holo_gainCorrected - selectedMaps(ss).phase_sample;
    else
        selectedMaps(ss).phase_holo = selectedMaps(ss).phase_holo_raw;
        selectedMaps(ss).err_holo_sample = selectedMaps(ss).phase_holo_raw - selectedMaps(ss).phase_sample;
    end
    selectedMaps(ss).err_holo_sample_gainCorrected = selectedMaps(ss).phase_holo_gainCorrected - selectedMaps(ss).phase_sample;
end

peakMeanHoloSIM_gainCorrected = holoPhaseGain * peakMean(:,5);

%% Tables
T_twoPoint_metrics = table(sepList_nm, ...
    dipFrac(:,1), dipFrac(:,2), dipFrac(:,3), dipFrac(:,4), dipFrac(:,5), ...
    valleyRatio(:,1), valleyRatio(:,2), valleyRatio(:,3), valleyRatio(:,4), valleyRatio(:,5), ...
    peakMean(:,1), peakMean(:,2), peakMean(:,3), peakMean(:,4), peakMean(:,5), ...
    detectedSep_nm(:,1), detectedSep_nm(:,2), detectedSep_nm(:,3), detectedSep_nm(:,4), detectedSep_nm(:,5), ...
    'VariableNames', {'Separation_nm', ...
    'Dip_Sample','Dip_Film','Dip_QPM','Dip_WF','Dip_HoloSIM', ...
    'ValleyRatio_Sample','ValleyRatio_Film','ValleyRatio_QPM','ValleyRatio_WF','ValleyRatio_HoloSIM', ...
    'PeakMean_Sample','PeakMean_Film','PeakMean_QPM','PeakMean_WF','PeakMean_HoloSIM', ...
    'DetectedSep_Sample_nm','DetectedSep_Film_nm','DetectedSep_QPM_nm','DetectedSep_WF_nm','DetectedSep_HoloSIM_nm'});

T_twoPoint_metrics.HoloSIM_phase_gain = repmat(holoPhaseGain, nSep, 1);
T_twoPoint_metrics.PeakMean_HoloSIM_gainCorrected = peakMeanHoloSIM_gainCorrected;
T_twoPoint_metrics.Dip_HoloSIM_gainCorrected = dipFrac(:,5);
T_twoPoint_metrics.ValleyRatio_HoloSIM_gainCorrected = valleyRatio(:,5);

T_twoPoint_thresholds = PSI_computeTwoPointThresholdTable(sepList_nm, S.twoPoint.dip_thresholds, ...
    methodLabels, dipFrac);

writetable(T_twoPoint_metrics, fullfile(outdir,'TwoPoint_phase_dip_metrics.csv'));
writetable(T_twoPoint_thresholds, fullfile(outdir,'TwoPoint_phase_dip_thresholds.csv'));

disp('Two-point phase-dip thresholds:');
disp(T_twoPoint_thresholds);

%% Figure 1: Nature-style selected phase maps
% Compact map figure for manuscript/PPT use.  The quantitative profile is
% still measured from the y = 0 center line; no overlay line is drawn on the
% maps.  Only one phase scale is used for all phase panels.
if ~isempty(selectedMaps)
    nRows = numel(selectedMaps);
    fig = figure('Color','w','Units','centimeters','Position',[1.2 1.2 21.0 14.2]);
    tl = tiledlayout(fig,nRows,4,'Padding','loose','TileSpacing','compact');
    mapClim = [-0.08 1.08*S.twoPoint.phase_amp];
    phaseTitles = {'Sample','H_{tra}-filtered','QPM','HoloSIM'};
    phaseMapsForCbar = gobjects(1,1);

    for ss = 1:nRows
        thisSep = selectedMaps(ss).sep_nm;
        imgs = {selectedMaps(ss).phase_sample, selectedMaps(ss).phase_film, ...
                selectedMaps(ss).phase_qpm, selectedMaps(ss).phase_holo};
        for cc = 1:4
            ax = nexttile(tl,(ss-1)*4+cc);
            PSI_showTwoPointMapPanel(ax, imgs{cc}, x, y, '', mapClim, ...
                S.twoPoint.map_halfwidth_nm, false);

            if ss == 1
                if cc == 4 && isfield(S.twoPoint,'map_display_use_gain_corrected_holo') && ...
                        S.twoPoint.map_display_use_gain_corrected_holo && abs(holoPhaseGain - 1) > 1e-3
                    title(ax, sprintf('HoloSIM'), 'Interpreter','tex');
                else
                    title(ax, phaseTitles{cc}, 'Interpreter','tex');
                end
                PSI_labelPanel(ax, char('a' + cc - 1));
            end

            if cc == 1
                ylabel(ax, sprintf('d = %.0f nm', thisSep));
            else
                ax.YTickLabel = [];
                ylabel(ax,'');
            end
            if ss == nRows
                xlabel(ax,'x (nm)');
            else
                ax.XTickLabel = [];
                xlabel(ax,'');
            end
            if ss == 1 && cc == 4
                phaseMapsForCbar = ax;
            end
        end
    end
    cb = colorbar(phaseMapsForCbar,'eastoutside');
    cb.Label.String = 'Phase (rad)';
    cb.Label.FontName = 'Arial';
    cb.Label.FontSize = 10;
    PSI_formatFigure_TP(fig);
    Smap = S;
    Smap.plot.saveMode = 'pngpainters';
    PSI_safeSaveFigure_TP(fig, fullfile(outdir,'TwoPoint_phase_maps_main_nature.png'), Smap);
end

%% Figure 2: Nature-style HoloSIM residual maps
% Keep the residual maps, but separate them from the main phase maps.  This
% avoids a very wide 5-column layout and makes the error scale explicit.
if ~isempty(selectedMaps)
    nCols = numel(selectedMaps);
    fig = figure('Color','w','Units','centimeters','Position',[1.2 1.2 17.5 6.6]);
    tl = tiledlayout(fig,1,nCols,'Padding','loose','TileSpacing','compact');
    errClim = [-0.20 0.20];
    errAxForCbar = gobjects(1,1);
    for ss = 1:nCols
        ax = nexttile(tl,ss);
        PSI_showTwoPointMapPanel(ax, selectedMaps(ss).err_holo_sample, x, y, ...
            sprintf('d = %.0f nm', selectedMaps(ss).sep_nm), errClim, ...
            S.twoPoint.map_halfwidth_nm, true);
        if ss == 1
            ylabel(ax,'y (nm)');
            PSI_labelPanel(ax,'a');
        else
            ax.YTickLabel = [];
            ylabel(ax,'');
        end
        xlabel(ax,'x (nm)');
        if ss == nCols
            errAxForCbar = ax;
        end
    end
    cb = colorbar(errAxForCbar,'eastoutside');
    cb.Label.String = 'Error (rad)';
    cb.Label.FontName = 'Arial';
    cb.Label.FontSize = 10;
    PSI_formatFigure_TP(fig);
    Smap = S;
    Smap.plot.saveMode = 'pngpainters';
    PSI_safeSaveFigure_TP(fig, fullfile(outdir,'TwoPoint_holosim_error_maps_nature.png'), Smap);
end

%% Figure 3: selected relative line profiles at 100, 130 and 160 nm
% Final-display profile figure.  Only the relative line profiles are shown,
% because the two-point resolution criterion depends on the central dip shape,
% not on the absolute phase gain.  The HoloSIM gain correction is therefore not
% shown in this profile panel; after per-curve normalization it would have the
% same profile shape as the raw HoloSIM curve.
profileSepList_nm = S.twoPoint.selected_separations_nm(:).';
nProfile = numel(profileSepList_nm);

fig = figure('Color','w','Units','centimeters','Position',[1.0 1.0 24.0 8.4]);
tl = tiledlayout(fig,1,nProfile,'Padding','loose','TileSpacing','compact');

axProfile = gobjects(1,nProfile);
for pp = 1:nProfile
    thisSep = profileSepList_nm(pp);
    [~, idxProfileSep] = min(abs(sepList_nm - thisSep));
    thisSep = sepList_nm(idxProfileSep);

    ax = nexttile(tl,pp); hold(ax,'on');
    axProfile(pp) = ax;

    plot(ax,xProfile_nm,profileNorm{idxProfileSep,1},'-','Color',Ccol.sample,'LineWidth',1.90,'DisplayName','Sample');
    plot(ax,xProfile_nm,profileNorm{idxProfileSep,2},'-','Color',Ccol.htra,'LineWidth',1.90,'DisplayName','H_{tra}-filtered');
    plot(ax,xProfile_nm,profileNorm{idxProfileSep,3},'--','Color',Ccol.qpm,'LineWidth',1.90,'DisplayName','QPM');
    plot(ax,xProfile_nm,profileNorm{idxProfileSep,5},'-','Color',Ccol.holo,'LineWidth',2.65,'DisplayName','HoloSIM');

    xline(ax,-thisSep/2,':','Color',[0.62 0.62 0.62],'HandleVisibility','off','LineWidth',1.00);
    xline(ax, thisSep/2,':','Color',[0.62 0.62 0.62],'HandleVisibility','off','LineWidth',1.00);

    title(ax,sprintf('d = %.0f nm', thisSep));
    xlabel(ax,'x (nm)');
    if pp == 1
        ylabel(ax,'Phase profile (a.u.)');
    else
        ylabel(ax,'');
        ax.YTickLabel = [];
    end
    xlim(ax,[-280 280]);
    ylim(ax,[-0.12 1.10]);
end

% One compact legend for the whole profile figure.  It is kept at the top of
% the canvas to avoid clipping the x-labels at the bottom during export.
lg = legend(axProfile(1),'Location','northoutside','Orientation','horizontal','NumColumns',4);
lg.Box = 'off';
lg.ItemTokenSize = [18 8];

PSI_formatFigure_TP(fig);
Sprofile = S;
Sprofile.plot.saveMode = 'pngpainters';
Sprofile.plot.exportDPI = 600;
Sprofile.plot.closeSavedFigures = false;
PSI_safeSaveFigure_TP(fig, fullfile(outdir,'TwoPoint_profiles_100_130_160_nature.png'), Sprofile);
% Keep the old filename as an alias for compatibility with earlier notes.
SprofileAlias = Sprofile;
SprofileAlias.plot.closeSavedFigures = true;
PSI_safeSaveFigure_TP(fig, fullfile(outdir,'TwoPoint_profiles_metrics_nature.png'), SprofileAlias);

%% Figure 4: two-point metrics across all separations
fig = figure('Color','w','Units','centimeters','Position',[1.2 1.2 18.5 7.6]);
tl = tiledlayout(fig,1,2,'Padding','loose','TileSpacing','compact');

% Left: dip metric
ax = nexttile(tl,1); hold(ax,'on');
plot(ax, sepList_nm, dipFrac(:,1), '-', 'Color', Ccol.sample, 'LineWidth',1.45, 'DisplayName','Sample');
plot(ax, sepList_nm, dipFrac(:,2), '-', 'Color', Ccol.htra, 'LineWidth',1.45, 'DisplayName','Film');
plot(ax, sepList_nm, dipFrac(:,3), '--', 'Color', Ccol.qpm, 'LineWidth',1.45, 'DisplayName','QPM');
plot(ax, sepList_nm, dipFrac(:,5), '-', 'Color', Ccol.holo, 'LineWidth',2.05, 'DisplayName','HoloSIM');
for tt = 1:numel(S.twoPoint.dip_thresholds)
    yline(ax, S.twoPoint.dip_thresholds(tt), '--', 'Color',[0.76 0.76 0.76], ...
        'LineWidth',0.90, 'HandleVisibility','off');
end
text(ax, min(sepList_nm)+4, S.twoPoint.dip_thresholds(end)+0.025, '26.5% dip', ...
    'FontName','Arial','FontSize',9.0,'Color',[0.42 0.42 0.42]);
xlabel(ax,'Center-to-center separation (nm)');
ylabel(ax,'Central dip fraction');
title(ax,'Two-point resolution metric');
xlim(ax,[80 300]);
ylim(ax,[0 1.05]);
legend(ax,'Location','southeast');

% Right: absolute peak amplitude
ax = nexttile(tl,2); hold(ax,'on');
plot(ax, sepList_nm, peakMean(:,1), '-',  'Color', Ccol.sample, 'LineWidth',1.45, 'DisplayName','Sample');
plot(ax, sepList_nm, peakMean(:,2), '-',  'Color', Ccol.htra,   'LineWidth',1.45, 'DisplayName','Film');
plot(ax, sepList_nm, peakMean(:,3), '--', 'Color', Ccol.qpm,    'LineWidth',1.45, 'DisplayName','QPM');
plot(ax, sepList_nm, peakMean(:,5), '-',  'Color', [0.58 0.73 0.96], 'LineWidth',1.25, 'DisplayName','HoloSIM raw');
plot(ax, sepList_nm, peakMeanHoloSIM_gainCorrected, '-', 'Color', Ccol.holo, 'LineWidth',2.05, ...
    'DisplayName', sprintf('HoloSIM gain-corrected (%.2fx)', holoPhaseGain));
xlabel(ax,'Center-to-center separation (nm)');
ylabel(ax,'Mean peak phase (rad)');
title(ax,'Peak phase amplitude');
xlim(ax,[80 300]);
yMaxPeak = 1.10 * max([peakMean(:,1); peakMean(:,2); peakMean(:,3); peakMeanHoloSIM_gainCorrected], [], 'omitnan');
ylim(ax,[0 max(0.15,yMaxPeak)]);
legend(ax,'Location','southeast');

PSI_formatFigure_TP(fig);
PSI_safeSaveFigure_TP(fig, fullfile(outdir,'TwoPoint_metrics_nature.png'), S);

save(fullfile(outdir,'twoPoint_resolution_summary.mat'), 'S', ...
    'sepList_nm','methodNames','methodLabels','dipFrac','valleyRatio','peakMean','detectedSep_nm', ...
    'T_twoPoint_metrics','T_twoPoint_thresholds','selectedMaps','holoPhaseGain','peakMeanHoloSIM_gainCorrected');

fprintf('[Two-point] Done in %.2f s. Results saved to %s\n', toc(tAll), outdir);

%% Local functions



function phi = makeTwoPointPhase(x,y,sep_nm,sigma_nm,phaseAmp)
    % Two Gaussian phase nanoparticles separated along x by sep_nm.
    sep = sep_nm * 1e-9;
    sigma = sigma_nm * 1e-9;
    g1 = exp(-((x + sep/2).^2 + y.^2) / (2*sigma^2));
    g2 = exp(-((x - sep/2).^2 + y.^2) / (2*sigma^2));
    phi = phaseAmp * (g1 + g2);
end
