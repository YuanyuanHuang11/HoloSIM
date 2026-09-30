% H_inc and final phase-response analysis using the real SIM pipeline.
%
% This script keeps H_tra separate conceptually but uses film-plane holograms
% to evaluate:
%   1) H_inc-like hologram readout response:
%        I_holo,film -> real SIM reconstruction -> I_holo,SIM
%   2) effective phase response:
%        phi_film -> real SIM reconstructed hologram stack -> four-step PSI -> phi_HoloSIM
%   3) true conventional QPM baseline:
%        U_sample -> coherent pupil -> 65 nm camera sampling -> PSI
%
% Required on MATLAB path:
%   PsfOtf, OTF, SIMimagesF, PCMseparateF, OBJpowerPara,
%   PCMfilteringF, OTFdoubling, MergingHeptaletsF
%
% Important: unlike the debugging script, the four phase-shifted holograms are
% normalized by one shared factor only. They are NOT min-max normalized frame by
% frame before PSI.

clear; close all; clc;
task_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(task_dir);
addpath(genpath(fullfile(project_root, 'function')));


% Main-result version:
%   - Uses fixed-parameter SIM reconstruction for all four phase-shifted holograms.
%   - Uses pixel-integrated camera sampling instead of bicubic downsampling.
%   - Keeps H_tra, H_inc, and final HoloSIM phase-frequency response.
%   - Affine correction and constant phase compensation are removed from main analysis.
%

% Figure style: compact Nature-style display.
% Keep the numerical pipeline unchanged; only the plotting layer is changed.
set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultTextFontName', 'Arial');
set(groot, 'defaultLegendFontName', 'Arial');
set(groot, 'defaultColorbarFontName', 'Arial');
set(groot, 'defaultAxesFontSize', 7);
set(groot, 'defaultTextFontSize', 7);
set(groot, 'defaultLegendFontSize', 6);
set(groot, 'defaultColorbarFontSize', 6);
set(groot, 'defaultLineLineWidth', 1.4);
set(groot, 'defaultFigureColor', 'w');
set(groot, 'defaultAxesColor', 'w');
set(groot, 'defaultAxesXColor', 'k');
set(groot, 'defaultAxesYColor', 'k');
set(groot, 'defaultAxesZColor', 'k');
set(groot, 'defaultTextColor', 'k');

lineWidth = 1.45;
Ccol.sample = PSI_hex2rgb('#252525');
Ccol.htra   = PSI_hex2rgb('#4C78A8');
Ccol.holo   = PSI_hex2rgb('#0072B2');
Ccol.wf     = PSI_hex2rgb('#7B6EA8');
Ccol.qpm    = PSI_hex2rgb('#E69F00');
Ccol.teal   = PSI_hex2rgb('#009E73');
Ccol.red    = PSI_hex2rgb('#D55E00');
Ccol.pink   = PSI_hex2rgb('#CC79A7');
Ccol.gray   = PSI_hex2rgb('#7A7A7A');
Ccol.lightgray = PSI_hex2rgb('#D9D9D9');

% outdir = fullfile(pwd, 'HoloSIM_main_fixedSIM_pixelIntegration_noAffine_results_z10');
outdir = fullfile(task_dir, 'results', 'HoloSIM_PSI_Siemens');
if ~exist(outdir, 'dir'), mkdir(outdir); end

%% Parameters matching the previously stable Siemens SIM reconstruction
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
S.sim.illum_period_nm = 250;   % match stable Siemens code
S.sim.snr = 1e2;               % deterministic debug; set 20 or 60 for noisy synthetic runs
S.sim.camera_downsample_scale = 0.5;  % 32.5 nm -> 65 nm camera pixels
S.recon.holo_denoise_sigma_px = 0;

% Plot/output controls.
% Figure 3 can appear blank in MATLAB while later heavy diagnostics are still
% running. These controls force rendering/saving after each figure.
S.plot.forceDrawNow = false;
S.plot.makeDiagnostics = false;       % skip heavy Fourier diagnostics by default
S.plot.makeSiemensErrorMaps = true;    % keep lightweight Siemens-star phase-error maps
S.plot.makeHincProcessFigure = false;  % set true for H_inc process panels / supplement
S.plot.makeStandaloneHincPlots = false;
S.plot.stopAfterFig3 = false;
S.plot.closeSavedFigures = true;
S.plot.showFigures = false;
% High-resolution export controls.
% Use true DPI export instead of screen capture. This prevents blurred / pixelated
% figures caused by getframe-based pngscreen saving.
S.plot.exportDPI = 1200;              % manuscript-grade raster resolution
S.plot.exportScale = 3.0;             % fallback only, used if pngscreen is selected
S.plot.saveMode = 'pnghighres';       % preferred: exportgraphics/print at exportDPI
S.plot.savePDF = false;               % set true if vector PDF copies are also needed

if S.plot.showFigures
    set(groot, 'defaultFigureVisible', 'on');
else
    set(groot, 'defaultFigureVisible', 'off');
end

% Siemens target similar to previous stable code.
C.num_spokes = 72;
C.num_line_pairs = C.num_spokes/2;
C.radius_frac = 0.78;
C.inner_radius = 300e-9;
C.phase_step = 1.0;
C.edge_sigma_px = 0.8;
C.supersample = 8;  % use 8 to exactly match the older script, 4 is faster

fprintf('H_inc + phase-response analysis. Output: %s\n', outdir);
fprintf('SIM grid dx = %.1f nm, camera pixel = %.1f nm, SIM period = %.0f nm, SNR = %.1f\n', ...
    S.dx*1e9, S.dx*1e9/S.sim.camera_downsample_scale, S.sim.illum_period_nm, S.sim.snr);
fprintf('PSI reference: theta = %.1f deg, lateral carrier = %.3g cycles/um, pure PSI = %d\n', ...
    S.ref.theta_deg, S.ref.lateral_frequency/1e6, ~S.ref.use_lateral_carrier);

[x,y,FX,FY,FR] = NF_makeGrids(S.N,S.dx);

%% 1. Generate Siemens sample phase and film-plane field
[phi_sample, GT] = makeSiemensPhaseAA(x,y,S,C);
U_sample = exp(1i*phi_sample);

Htra = NF_propagationTF(FX,FY,S.lambda_eff,S.z_sample);
U_film = NF_propagateField(U_sample,Htra);
r = sqrt(x.^2 + y.^2);
bgMask = r > (GT.star_radius_m + 0.5e-6);
phi_film = PSI_phaseFromFieldWithBackground(U_film,bgMask);

%% 2. True conventional QPM baseline
Pupil_QPM = double(FR <= S.NA_QPM/S.lambda);
U_qpm = ifft2(fft2(U_sample).*fftshift(Pupil_QPM));

%% 3. Generate four film holograms and run readout
I4_qpm_cam = zeros(S.N/2,S.N/2,4);
I4_film_raw = zeros(S.N,S.N,4);
I4_film_raw_norm = zeros(S.N,S.N,4);
I4_film_wf = zeros(S.N,S.N,4);
I4_holo = zeros(S.N,S.N,4);
SIM_failed = false(1,4);
SIM_msg = strings(1,4);

for k = 1:4
    ref = NF_makePSIReferenceField(x, y, S, k);
    Iqpm_hi = abs(U_qpm + ref).^2;
    I4_qpm_cam(:,:,k) = SIM_cameraPixelIntegrateDownsample_Star(Iqpm_hi, 0.5);
    I4_film_raw(:,:,k) = abs(U_film + ref).^2;
end

norm_holo = max(I4_film_raw(:));
I4_film_raw_norm = I4_film_raw / norm_holo;

% -------------------------------------------------------------------------
% Fixed-parameter SIM reconstruction for four-step PSI
% -------------------------------------------------------------------------
% Four-step PSI assumes that all four phase-shifted holograms are processed
% by the same linear readout operator. Therefore, estimate the SIM pattern /
% order-separation / filtering / merging parameters ONCE from a reference
% hologram, then reuse these parameters for all four phase-shifted holograms.
%
% Reference choice:
%   'phase1' uses I0, which normally has strong hologram modulation.
%   'mean4' uses the average of the four phase shifts, which is less
%           phase-shift-specific but can have weaker modulation.
S.sim.fixed_ref_mode = 'phase1';    % options: 'phase1' or 'mean4'; mean4 is less phase-shift-specific

switch lower(S.sim.fixed_ref_mode)
    case 'phase1'
        I_sim_ref = I4_film_raw_norm(:,:,1);
    case 'mean4'
        I_sim_ref = mean(I4_film_raw_norm,3);
    otherwise
        error('Unknown S.sim.fixed_ref_mode: %s', S.sim.fixed_ref_mode);
end

simParamsFixed = SIM_estimateRealSIMFixedParams(I_sim_ref, S);
fprintf('Fixed SIM parameters estimated from reference mode: %s\n', S.sim.fixed_ref_mode);
fprintf('  kA = [%.4f %.4f], kB = [%.4f %.4f], kC = [%.4f %.4f]\n', ...
    simParamsFixed.kA(1), simParamsFixed.kA(2), ...
    simParamsFixed.kB(1), simParamsFixed.kB(2), ...
    simParamsFixed.kC(1), simParamsFixed.kC(2));

for k = 1:4
    I4_film_wf(:,:,k) = SIM_applyWFfluor(I4_film_raw_norm(:,:,k),FR,S);
    [I4_holo(:,:,k), SIM_failed(k), SIM_msg(k)] = ...
        SIM_realSIMReadoutFixedParams(I4_film_raw_norm(:,:,k), S, simParamsFixed, false);
    fprintf('Fixed-param real SIM Siemens phase shift %d/4 done. failed=%d\n', k, SIM_failed(k));
end

%% 4. H_inc-like hologram readout response: film hologram -> SIM readout
% H_inc is evaluated at the hologram-intensity level, before PSI:
%   I_holo,film  ->  WF fluorescence readout / real SIM reconstruction
% The annular first-harmonic modulation amplitude is measured at each Siemens
% radius and averaged over the four PSI phase shifts. This isolates the
% readout transfer function from the sample-to-film H_tra term and from the
% final phase demodulation.

A_holo_in = cell(1,4);
A_holo_sim = cell(1,4);
A_holo_wf = cell(1,4);
for k = 1:4
    A_holo_in{k} = PSI_analyzeSiemensAnnuli(I4_film_raw_norm(:,:,k), GT, S);
    A_holo_sim{k} = PSI_analyzeSiemensAnnuli(I4_holo(:,:,k), GT, S);
    A_holo_wf{k} = PSI_analyzeSiemensAnnuli(I4_film_wf(:,:,k), GT, S);
end
fp = A_holo_in{1}.full_pitch_nm(:);
Amp_in = mean(cell2mat(cellfun(@(a)a.mod_amp(:), A_holo_in, 'UniformOutput', false)), 2, 'omitnan');
Amp_sim = mean(cell2mat(cellfun(@(a)a.mod_amp(:), A_holo_sim, 'UniformOutput', false)), 2, 'omitnan');
Amp_wf = mean(cell2mat(cellfun(@(a)a.mod_amp(:), A_holo_wf, 'UniformOutput', false)), 2, 'omitnan');
Rinc_sim_raw = Amp_sim ./ max(Amp_in, eps);
Rinc_wf = Amp_wf ./ max(Amp_in, eps);

% Shape-normalize SIM response in a robust low-frequency band to isolate the
% frequency-dependent roll-off from the absolute SIM intensity scale.
refBand = fp >= 350 & fp <= 900 & isfinite(Rinc_sim_raw) & Rinc_sim_raw > 0;
if nnz(refBand) >= 3
    simScale = median(Rinc_sim_raw(refBand), 'omitnan');
elseif any(isfinite(Rinc_sim_raw) & Rinc_sim_raw > 0)
    simScale = median(Rinc_sim_raw(isfinite(Rinc_sim_raw) & Rinc_sim_raw > 0), 'omitnan');
else
    simScale = 1;
end
Rinc_sim_shape = Rinc_sim_raw / max(simScale, eps);
Amp_sim_shape = Amp_sim / max(simScale, eps);

T_Hinc = table(fp, Amp_in, Amp_wf, Amp_sim, Amp_sim_shape, Rinc_wf, Rinc_sim_raw, Rinc_sim_shape, ...
    'VariableNames', {'FullPitch_nm','FilmHologramMod','WFreadoutMod','SIMreadoutMod', ...
    'SIMreadoutMod_shapeNormalized','Rinc_WF','Rinc_SIM_raw','Rinc_SIM_shapeNorm'});
writetable(T_Hinc, fullfile(outdir,'B_Hinc_hologram_readout_response.csv'));

% -------------------------------------------------------------------------
% B1. Main H_inc analysis workflow figure.
% -------------------------------------------------------------------------
if ~isfield(S,'plot') || ~isfield(S.plot,'makeHincProcessFigure') || S.plot.makeHincProcessFigure
    % Show the H_inc readout process at a meaningful high-frequency pitch.
    % The maps are displayed as background-subtracted modulation maps, not raw
    % absolute intensities. This avoids the misleading impression that the
    % Siemens spokes are "low phase"; these panels are hologram-intensity
    % modulation images before PSI.
    kShow = 1;
    targetPitch_nm = 130;
    thetaWindowDeg = [0 80];

    [thetaDeg, profFilm, actualPitch_nm] = PSI_annularProfileAtPitch(I4_film_raw_norm(:,:,kShow), GT, S, targetPitch_nm);
    [~, profWF, ~] = PSI_annularProfileAtPitch(I4_film_wf(:,:,kShow), GT, S, targetPitch_nm);
    [~, profSIM, ~] = PSI_annularProfileAtPitch(I4_holo(:,:,kShow), GT, S, targetPitch_nm);

    profFilmPlot = PSI_normalizeProfileDisplay(profFilm);
    profWFPlot   = PSI_normalizeProfileDisplay(profWF);
    profSIMPlot  = PSI_normalizeProfileDisplay(profSIM);
    thetaMask = thetaDeg >= thetaWindowDeg(1) & thetaDeg <= thetaWindowDeg(2);

    mapFilm = PSI_hincModulationMap(I4_film_raw_norm(:,:,kShow), GT, S);
    mapWF   = PSI_hincModulationMap(I4_film_wf(:,:,kShow), GT, S);
    mapSIM  = PSI_hincModulationMap(I4_holo(:,:,kShow), GT, S);

    fig = figure('Color','w','Units','centimeters','Position',[2 2 18.0 12.6]);
    tl = tiledlayout(fig,2,3,'Padding','compact','TileSpacing','compact');

    ax = nexttile(tl,1);
    PSI_showModulationMapNature(mapFilm, 'Film hologram modulation', [-1 1]);
    PSI_labelPanel(ax,'a');

    ax = nexttile(tl,2);
    PSI_showModulationMapNature(mapWF, 'WF readout modulation', [-1 1]);
    PSI_labelPanel(ax,'b');

    ax = nexttile(tl,3);
    PSI_showModulationMapNature(mapSIM, 'SIM readout modulation', [-1 1]);
    PSI_labelPanel(ax,'c');

    ax = nexttile(tl,4); hold on;
    plot(thetaDeg(thetaMask), profFilmPlot(thetaMask), '-', 'Color', Ccol.sample, 'LineWidth', 2.80, 'DisplayName','Film');
    plot(thetaDeg(thetaMask), profWFPlot(thetaMask), '-', 'Color', Ccol.wf, 'LineWidth', 2.80, 'DisplayName','WF');
    plot(thetaDeg(thetaMask), profSIMPlot(thetaMask), '-', 'Color', Ccol.holo, 'LineWidth', 2.80, 'DisplayName','SIM');
    xlim(thetaWindowDeg);
    ylim([-1.15 1.15]);
    xlabel('Azimuthal angle (deg)');
    ylabel('Zero-mean normalized modulation');
    title(sprintf('Annular profile at %.0f nm period', actualPitch_nm));
    legend('Location','southoutside','Orientation','horizontal','NumColumns',3);
    PSI_labelPanel(ax,'d');

    ax = nexttile(tl,5); hold on;
    plot(fp, Amp_in ./ max(Amp_in,[],'omitnan'), '-', 'Color', Ccol.sample, 'LineWidth', lineWidth, 'DisplayName','Film');
    plot(fp, Amp_wf ./ max(Amp_in,[],'omitnan'), '-', 'Color', Ccol.wf, 'LineWidth', lineWidth, 'DisplayName','WF');
    plot(fp, Amp_sim_shape ./ max(Amp_in,[],'omitnan'), '-', 'Color', Ccol.holo, 'LineWidth', lineWidth, 'DisplayName','SIM');
    xline(targetPitch_nm, ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.45, 'HandleVisibility','off');
    PSI_markCurveAtPitch(fp, Amp_in ./ max(Amp_in,[],'omitnan'), targetPitch_nm, Ccol.sample);
    PSI_markCurveAtPitch(fp, Amp_wf ./ max(Amp_in,[],'omitnan'), targetPitch_nm, Ccol.wf);
    PSI_markCurveAtPitch(fp, Amp_sim_shape ./ max(Amp_in,[],'omitnan'), targetPitch_nm, Ccol.holo);
    xlabel('Spatial period (nm)');
    ylabel('Normalized first-harmonic amplitude');
    title('Hologram modulation amplitude');
    xlim([100 700]); ylim([0 1.12]);
    legend('Location','northoutside','Orientation','horizontal','NumColumns',3);
    PSI_formatCurveAxes(ax);
    PSI_labelPanel(ax,'e');

    ax = nexttile(tl,6); hold on;
    plot(fp, Rinc_wf, '-', 'Color', Ccol.wf, 'LineWidth', lineWidth, 'DisplayName','WF / film');
    plot(fp, Rinc_sim_shape, '-', 'Color', Ccol.holo, 'LineWidth', lineWidth, 'DisplayName','SIM / film');
    yline(1,'-', 'Color', Ccol.lightgray, 'HandleVisibility','off');
    xline(targetPitch_nm, ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.45, 'HandleVisibility','off');
    PSI_markCurveAtPitch(fp, Rinc_wf, targetPitch_nm, Ccol.wf);
    PSI_markCurveAtPitch(fp, Rinc_sim_shape, targetPitch_nm, Ccol.holo);
    xlabel('Spatial period (nm)');
    ylabel('Modulation retention');
    title('Hologram readout transfer');
    xlim([100 700]); ylim([0 1.12]);
    legend('Location','northoutside','Orientation','horizontal','NumColumns',2);
    PSI_formatCurveAxes(ax);
    PSI_labelPanel(ax,'f');

    PSI_formatFigure(fig);
    PSI_safeSaveFigure(fig, fullfile(outdir, 'B_Hinc_analysis_workflow_nature.png'), S);
end

% -------------------------------------------------------------------------
% B2. Optional standalone H_inc response plots.
% These are useful for supplementary material, but are disabled by default
% because MATLAB can hang while exporting many separate figures. The main
% phase-response figures below are usually clearer for manuscript/PPT use.
% -------------------------------------------------------------------------
if isfield(S,'plot') && isfield(S.plot,'makeStandaloneHincPlots') && S.plot.makeStandaloneHincPlots
fig = figure('Color','w','Units','centimeters','Position',[2 2 10.5 7.8]);
plot(fp, Rinc_wf, '-', 'Color', Ccol.wf, 'LineWidth', lineWidth, 'DisplayName','WF readout'); hold on;
plot(fp, Rinc_sim_shape, '-', 'Color', Ccol.holo, 'LineWidth', lineWidth, 'DisplayName','SIM readout');
yline(1,'-', 'Color', Ccol.lightgray, 'HandleVisibility','off');
xlabel('Spatial period (nm)');
ylabel('Phase-modulation retention');
title('Hologram readout transfer');
xlim([100 1200]); ylim([0 1.15]);
legend('Location','southoutside','Orientation','horizontal','NumColumns',2);
PSI_formatCurveAxes(gca);
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir, 'B_Hinc_hologram_response_shapeNorm_nature.png'), S);

fig = figure('Color','w','Units','centimeters','Position',[2 2 10.5 7.8]);
plot(fp, Rinc_sim_raw, '-', 'Color', Ccol.holo, 'LineWidth', lineWidth);
xlabel('Spatial period (nm)');
ylabel('SIM modulation / film modulation');
title('Raw SIM readout gain');
xlim([100 1200]);
PSI_formatCurveAxes(gca);
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir, 'B_Hinc_hologram_response_rawScale_nature.png'), S);
else
    fprintf('Skipping standalone H_inc response PNG panels. Set S.plot.makeStandaloneHincPlots=true to enable.\n');
end

%% 5. Final phase response: film phase vs final reconstructed phase
% Keep the raw PSI phases before background subtraction so that we can check
% whether the displayed phase is shifted by background/ringing bias.
bg_cam = SIM_cameraPixelIntegrateDownsample_Star(double(bgMask), 0.5) > 0.5;

phi_qpm_cam_raw = PSI_demod4Simple(I4_qpm_cam);
phi_qpm_cam_bg_median = median(phi_qpm_cam_raw(bg_cam), 'omitnan');
phi_qpm_cam = PSI_subtractBackground(phi_qpm_cam_raw, bg_cam);
phi_qpm = imresize(phi_qpm_cam, [S.N S.N], 'bicubic');

% Sanity check: direct four-step PSI from the ideal film-plane holograms.
% This should recover phi_film, up to a global background/piston offset.
phi_film_directPSI_raw = PSI_demod4Simple(I4_film_raw_norm);
phi_film_directPSI_bg_median = median(phi_film_directPSI_raw(bgMask), 'omitnan');
phi_film_directPSI = PSI_subtractBackground(phi_film_directPSI_raw, bgMask);
d_film_directPSI = phi_film_directPSI - phi_film;

phi_film_wf_raw = PSI_demod4Simple(I4_film_wf);
phi_film_wf_bg_median = median(phi_film_wf_raw(bgMask), 'omitnan');
phi_film_wf = PSI_subtractBackground(phi_film_wf_raw, bgMask);

phi_holo_raw = PSI_demod4Simple(I4_holo);
phi_holo_bg_median = median(phi_holo_raw(bgMask), 'omitnan');
phi_holo = PSI_subtractBackground(phi_holo_raw, bgMask);

A_sample = PSI_analyzeSiemensAnnuli(phi_sample,GT,S);
A_film = PSI_analyzeSiemensAnnuli(phi_film,GT,S);
A_qpm = PSI_analyzeSiemensAnnuli(phi_qpm,GT,S);
A_filmwf = PSI_analyzeSiemensAnnuli(phi_film_wf,GT,S);
A_holo = PSI_analyzeSiemensAnnuli(phi_holo,GT,S);

Rtra = A_film.mod_amp ./ max(A_sample.mod_amp, eps);
Rqpm = A_qpm.mod_amp ./ max(A_sample.mod_amp, eps);
RfilmWF = A_filmwf.mod_amp ./ max(A_sample.mod_amp, eps);
RholoSample = A_holo.mod_amp ./ max(A_sample.mod_amp, eps);
RholoFilm = A_holo.mod_amp ./ max(A_film.mod_amp, eps);

% HoloSIM/film is only meaningful where film-plane phase modulation is not
% close to zero. Otherwise small residual artifacts divided by a near-zero
% film signal can create artificially large ratios.
validRholoFilm = A_film.mod_amp > 0.03*max(A_film.mod_amp,[],'omitnan') & ...
                 A_sample.mod_amp > 0.03*max(A_sample.mod_amp,[],'omitnan') & ...
                 isfinite(RholoFilm);
RholoFilm_masked = RholoFilm;
RholoFilm_masked(~validRholoFilm) = NaN;

%% 5b. Resolution threshold analysis
% Resolution is defined by a modulation-retention criterion:
%   R(p) = A_recon(p) / A_reference(p)
% The reported pitch is the smallest full pitch p for which R(p) reaches
% the threshold and remains above it for larger pitches. This stable-crossing
% rule is safer than the first crossing when ringing produces oscillations.

thresholds = [0.10 0.20 0.50];

T_threshold_final = PSI_computeThresholdTable( ...
    A_sample.full_pitch_nm(:), thresholds, ...
    {'Film/sample = Htra', 'Conventional QPM/sample', 'Film-WF readout/sample', ...
     'HoloSIM/sample', 'HoloSIM/film valid only'}, ...
    {Rtra(:), Rqpm(:), RfilmWF(:), RholoSample(:), RholoFilm_masked(:)} );

writetable(T_threshold_final, fullfile(outdir, 'D_resolution_thresholds_10_20_50.csv'));

disp('Resolution threshold analysis based on modulation-retention ratio:');
disp(T_threshold_final);

% Main threshold plot: final HoloSIM/sample response.
fprintf('\n[Fig3] Start threshold figure...\n');
tFig3 = tic;

fig = figure('Color','w', ...
    'Units','centimeters', ...
    'Position',[2 2 8.8 6.8]);

ax = axes('Parent', fig, 'Position', [0.18 0.18 0.74 0.68]);
hold(ax, 'on');

plot(ax, A_sample.full_pitch_nm, Rtra, '-', ...
    'Color', Ccol.htra, ...
    'LineWidth', 1.35, ...
    'DisplayName','Film / sample');
plot(ax, A_sample.full_pitch_nm, RfilmWF, '-', ...
    'Color', Ccol.wf, ...
    'LineWidth', 1.35, ...
    'DisplayName','WF / sample');
plot(ax, A_sample.full_pitch_nm, RholoSample, '-', ...
    'Color', Ccol.holo, ...
    'LineWidth', 1.70, ...
    'DisplayName','HoloSIM / sample');

xlim(ax, [100 1200]);
ylim(ax, [0 1.06]);
xlabel(ax, 'Spatial period (nm)');
ylabel(ax, 'Phase retention');
title(ax, 'Resolution criterion');
yline(ax, 1, '-', 'Color', Ccol.lightgray, 'LineWidth', 0.75, 'HandleVisibility','off');

thresholdSummary = strings(numel(thresholds),1);

% Threshold markers and labels
thresholdSummary = strings(numel(thresholds),1);

% Text offset: place 10%, 20%, 50% labels to the right of each marker
dxLabel_nm = 18;
labelColor = [0.28 0.28 0.28];

for tt = 1:numel(thresholds)
    tau = thresholds(tt);
    p_tau = PSI_thresholdPitchStable(A_sample.full_pitch_nm(:), RholoSample(:), tau);

    % Horizontal threshold line
    yline(ax, tau, '--', ...
        'Color', [0.78 0.78 0.78], ...
        'LineWidth', 0.75, ...
        'HandleVisibility','off');

    if isfinite(p_tau)

        % Vertical resolution marker
        xline(ax, p_tau, ':', ...
            'Color', [0.55 0.55 0.55], ...
            'HandleVisibility','off', ...
            'LineWidth', 0.90);

        % Marker point on the HoloSIM/sample curve
        plot(ax, p_tau, tau, 'o', ...
            'MarkerFaceColor','w', ...
            'MarkerEdgeColor',[0.20 0.20 0.20], ...
            'MarkerSize', 4.6, ...
            'LineWidth', 0.95, ...
            'HandleVisibility','off');

        % Put percentage label on the right side of the marker
        text(ax, p_tau + dxLabel_nm, tau, sprintf('%.0f%%', 100*tau), ...
            'FontName','Arial', ...
            'FontSize', 6.4, ...
            'Color', labelColor, ...
            'HorizontalAlignment','left', ...
            'VerticalAlignment','middle', ...
            'BackgroundColor','w', ...
            'Margin', 0.5, ...
            'Clipping','on');

        thresholdSummary(tt) = sprintf('%.0f%%: %.0f nm', 100*tau, p_tau);
    else
        thresholdSummary(tt) = sprintf('%.0f%%: N/A', 100*tau);
    end
end
% Resolution summary box: move upward to avoid overlap with legend
txt = strjoin(cellstr(thresholdSummary), newline);

% Resolution summary box
text(ax, 0.62, 0.43, txt, ...
    'Units','normalized', ...
    'FontName','Arial', ...
    'FontSize', 6.4, ...
    'Color', [0.15 0.15 0.15], ...
    'BackgroundColor','w', ...
    'EdgeColor', [0.78 0.78 0.78], ...
    'LineWidth', 0.75, ...
    'Margin', 3, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle');

% Curve legend
lgd = legend(ax, 'Location','none');
lgd.Box = 'off';
lgd.FontName = 'Arial';
lgd.FontSize = 6.0;
lgd.Units = 'normalized';
lgd.Position = [0.64 0.185 0.23 0.13];

try
    lgd.ItemTokenSize = [8 6];
catch
end
PSI_formatCurveAxes(ax);
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir, 'D_HoloSIM_resolution_thresholds_10_20_50.png'), S);
fprintf('[Fig3] Done in %.2f s.\n', toc(tFig3));

if isfield(S,'plot') && isfield(S.plot,'stopAfterFig3') && S.plot.stopAfterFig3
    fprintf('[Fig3] stopAfterFig3=true, returning after Figure 3.\n');
    return;
end



%% 5a. Phase-map diagnostics: object/background statistics and difference maps
% Heavy diagnostic plots/statistics can be skipped for faster interactive plotting.
if ~isfield(S,'plot') || ~isfield(S.plot,'makeDiagnostics') || S.plot.makeDiagnostics
% These checks distinguish global phase scaling from local edge overshoot,
% background offset, or SIM/reconstruction ringing.
objMask = phi_sample > 0.7*C.phase_step;
starMask = r <= GT.star_radius_m & r >= GT.inner_radius_m;
objMask = objMask & starMask;
if nnz(objMask) < 100
    objMask = phi_sample > 0.5*C.phase_step;
end

phaseNames = ["Sample_GT"; "Film_phase_Htra"; "Film_directPSI"; "Conventional_QPM"; ...
              "Film_WF_readout"; "HoloSIM_fixedSIM"];
phaseImgs = {phi_sample, phi_film, phi_film_directPSI, phi_qpm, phi_film_wf, phi_holo};
T_phase_stats = PSI_phaseMapStats(phaseNames, phaseImgs, objMask, bgMask, C.phase_step);

T_directFilmPSI = PSI_diffStatsTable("Direct film PSI - phi_film", d_film_directPSI, objMask, bgMask, starMask);
T_bg_offsets = table(phi_qpm_cam_bg_median, phi_film_directPSI_bg_median, phi_film_wf_bg_median, phi_holo_bg_median, ...
    'VariableNames', {'QPM_raw_bg_median','FilmDirectPSI_raw_bg_median','FilmWF_raw_bg_median','HoloSIM_raw_bg_median'});

% -------------------------------------------------------------------------
% SIM artifact diagnostics.
% Pixel-integrated camera sampling removes the previous vertical-stripe
% artifact. We keep raw SIM error diagnostics only; no affine correction is
% applied or reported in the main analysis.
% -------------------------------------------------------------------------
err_holo_film = phi_holo - phi_film;
err_holo_sample = phi_holo - phi_sample;

T_SIM_phase_error_stats = [
    PSI_diffStatsTable("HoloSIM - film", err_holo_film, objMask, bgMask, starMask);
    PSI_diffStatsTable("HoloSIM - sample", err_holo_sample, objMask, bgMask, starMask)
];

T_SIM_artifact_spectrum = [
    PSI_artifactSpectrumStats("HoloSIM - film", err_holo_film, S.dx, starMask);
    PSI_artifactSpectrumStats("HoloSIM - sample", err_holo_sample, S.dx, starMask)
];

writetable(T_phase_stats, fullfile(outdir, 'C_phase_map_object_background_stats.csv'));
writetable(T_directFilmPSI, fullfile(outdir, 'C_direct_film_PSI_vs_phi_film_stats.csv'));
writetable(T_bg_offsets, fullfile(outdir, 'C_raw_PSI_background_offsets.csv'));
writetable(T_SIM_phase_error_stats, fullfile(outdir, 'C_SIM_phase_error_stats.csv'));
writetable(T_SIM_artifact_spectrum, fullfile(outdir, 'C_SIM_phase_error_Fourier_directionality_stats.csv'));

disp('Phase-map object/background statistics:');
disp(T_phase_stats);
disp('Direct film PSI sanity check, difference = phi_film_directPSI - phi_film:');
disp(T_directFilmPSI);
disp('Raw PSI background medians before subtraction:');
disp(T_bg_offsets);
disp('SIM phase-error diagnostics:');
disp(T_SIM_phase_error_stats);
disp('SIM phase-error Fourier directionality diagnostics:');
disp(T_SIM_artifact_spectrum);

fig = figure('Color','w','Position',[100 100 1300 700]);
tiledlayout(2,3,'Padding','compact','TileSpacing','compact');
diffClim = [-0.20 0.20];
PSI_showDiffMap(phi_film - phi_sample, 'Film - sample GT', diffClim);
PSI_showDiffMap(d_film_directPSI, 'Direct film PSI - film', diffClim);
PSI_showDiffMap(phi_holo - phi_film, 'HoloSIM - film', diffClim);
PSI_showDiffMap(phi_holo - phi_sample, 'HoloSIM - sample GT', diffClim);
PSI_showDiffMap(phi_film_wf - phi_film, 'Film-WF - film', diffClim);
PSI_showDiffMap(phi_qpm - phi_sample, 'QPM - sample GT', diffClim);
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir, 'C_phase_difference_maps_main_fixedSIM.png'), S);

% Fourier-domain diagnostic for direction-dependent residual artifacts.
fig = figure('Color','w','Position',[100 100 1500 420]);
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
PSI_showDiffMap(err_holo_film, 'HoloSIM - film', diffClim);
PSI_showErrorSpectrum(err_holo_film, S.dx, starMask, 'FFT of HoloSIM - film error');
PSI_showHorizontalAxisPower(err_holo_film, S.dx, starMask, 'Horizontal-axis power');
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir, 'C_SIM_phase_error_Fourier.png'), S);

% Per-phase hologram consistency diagnostic before PSI, without affine correction.
fig = figure('Color','w','Position',[100 100 1350 850]);
tiledlayout(4,3,'Padding','compact','TileSpacing','compact');
for kk = 1:4
    PSI_showImageMap(I4_film_raw_norm(:,:,kk), sprintf('Film hologram I_%d', kk), []);
    PSI_showImageMap(I4_holo(:,:,kk), sprintf('SIM recon I_%d', kk), []);
    PSI_showDiffMap(I4_holo(:,:,kk) - I4_film_raw_norm(:,:,kk), ...
        sprintf('SIM - film, I_%d', kk), [-0.08 0.08]);
end
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir, 'C_SIM_per_phase_hologram_residuals_noAffine.png'), S);

fig = figure('Color','w'); tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
PSI_showDiffMap(d_film_directPSI, 'Direct film PSI - film', [-0.02 0.02]);
PSI_showDiffMap(phi_film_directPSI, 'Direct film PSI phase', [-0.1 C.phase_step+0.1]);
PSI_showDiffMap(phi_film, 'Film phase, H_{tra}', [-0.1 C.phase_step+0.1]);
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir, 'C_direct_film_PSI_sanity_check.png'), S);

fig = figure('Color','w'); hold on;
histogram((phi_film(objMask)-phi_sample(objMask)), 120, 'Normalization','pdf', ...
    'FaceColor', Ccol.htra, 'FaceAlpha', 0.45, 'EdgeColor','none', 'DisplayName','Film - sample');
histogram(d_film_directPSI(objMask), 120, 'Normalization','pdf', ...
    'FaceColor', Ccol.gray, 'FaceAlpha', 0.35, 'EdgeColor','none', 'DisplayName','Direct film PSI - film');
histogram((phi_holo(objMask)-phi_film(objMask)), 120, 'Normalization','pdf', ...
    'FaceColor', Ccol.holo, 'FaceAlpha', 0.45, 'EdgeColor','none', 'DisplayName','HoloSIM - film');
histogram((phi_holo(objMask)-phi_sample(objMask)), 120, 'Normalization','pdf', ...
    'FaceColor', Ccol.pink, 'FaceAlpha', 0.40, 'EdgeColor','none', 'DisplayName','HoloSIM - sample');
xlabel('Phase difference inside object mask (rad)');
ylabel('Probability density');
title('Object-region phase difference histograms');
grid on; legend('Location','best');
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir, 'C_phase_difference_histograms_main_fixedSIM.png'), S);

else
    fprintf('Skipping heavy diagnostic figures/statistics because S.plot.makeDiagnostics=false.\n');

    objMask = phi_sample > 0.7*C.phase_step;
    starMask = r <= GT.star_radius_m & r >= GT.inner_radius_m;
    objMask = objMask & starMask;
    if nnz(objMask) < 100
        objMask = phi_sample > 0.5*C.phase_step;
    end

    err_holo_film = phi_holo - phi_film;
    err_holo_sample = phi_holo - phi_sample;
    T_phase_stats = table();
    T_directFilmPSI = table();
    T_bg_offsets = table();
    T_SIM_phase_error_stats = table();
    T_SIM_artifact_spectrum = table();
end

writetable(table(A_sample.full_pitch_nm(:), A_sample.mod_amp(:), A_film.mod_amp(:), A_qpm.mod_amp(:), ...
    A_filmwf.mod_amp(:), A_holo.mod_amp(:), ...
    'VariableNames', {'FullPitch_nm','SampleGT','Film_Htra','ConventionalQPM','FilmWFreadout','HoloSIM_fixedParamSIM'}), ...
    fullfile(outdir,'C_phase_response_annular_modulation_main_fixedSIM.csv'));

writetable(table(A_sample.full_pitch_nm(:), Rtra(:), Rqpm(:), RfilmWF(:), RholoSample(:), RholoFilm(:), RholoFilm_masked(:), validRholoFilm(:), ...
    'VariableNames', {'FullPitch_nm','Film_over_Sample_Htra','ConventionalQPM_over_Sample','FilmWFreadout_over_Sample','HoloSIM_over_Sample','HoloSIM_over_Film','HoloSIM_over_Film_masked','Valid_HoloSIM_over_Film'}), ...
    fullfile(outdir,'C_phase_response_retention_ratios.csv'));

writetable(table(A_sample.full_pitch_nm(:), Rtra(:), Rqpm(:), RfilmWF(:), RholoSample(:), RholoFilm_masked(:), validRholoFilm(:), ...
    'VariableNames', {'FullPitch_nm','Film_over_Sample_Htra','ConventionalQPM_over_Sample','FilmWFreadout_over_Sample','HoloSIM_over_Sample','HoloSIM_over_Film_validOnly','Valid_HoloSIM_over_Film'}), ...
    fullfile(outdir,'C_phase_response_retention_ratios_main_fixedSIM.csv'));

% -------------------------------------------------------------------------
% Compact phase maps and phase-response figures.
% -------------------------------------------------------------------------
fig = figure('Color','w','Units','centimeters','Position',[2 2 17.2 10.0]);
tiledlayout(fig,2,3,'Padding','compact','TileSpacing','compact');
clim = [-0.1 C.phase_step+0.1];
PSI_showMap(phi_sample, 'Sample phase', clim);
PSI_showMap(phi_film, 'Film-plane phase', clim);
PSI_showMap(phi_qpm, 'Conventional QPM', clim);
PSI_showMap(phi_film_wf, 'Film-WF phase', clim);
PSI_showMap(phi_holo, 'HoloSIM phase', clim);
nexttile; axis off;
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir,'C_phase_maps_main_fixedSIM.png'), S);

% Lightweight Siemens-star error maps. Keep this as a supplementary/diagnostic
% figure even when heavy Fourier diagnostics are disabled.
if ~isfield(S,'plot') || ~isfield(S.plot,'makeSiemensErrorMaps') || S.plot.makeSiemensErrorMaps
    fig = figure('Color','w','Units','centimeters','Position',[2 2 17.2 5.0]);
    tiledlayout(fig,1,4,'Padding','compact','TileSpacing','compact');
    errClim = [-0.20 0.20];
    PSI_showDiffMap(phi_film - phi_sample, 'Film - sample', errClim);
    PSI_showDiffMap(phi_qpm - phi_sample, 'Conventional QPM - sample', errClim);
    PSI_showDiffMap(phi_holo - phi_film, 'HoloSIM - film', errClim);
    PSI_showDiffMap(phi_holo - phi_sample, 'HoloSIM - sample', errClim);
    PSI_formatFigure(fig);
    PSI_safeSaveFigure(fig, fullfile(outdir,'C_siemens_phase_error_maps_nature.png'), S);
end

% Standalone annular phase-amplitude response.
fig = figure('Color','w','Units','centimeters','Position',[2 2 8.8 6.8]);
ax = axes('Parent',fig,'Position',[0.17 0.18 0.76 0.68]); hold(ax,'on');
plot(ax, A_sample.full_pitch_nm,A_sample.mod_amp,'-','Color',Ccol.sample,'LineWidth',1.35,'DisplayName','Sample');
plot(ax, A_film.full_pitch_nm,A_film.mod_amp,'-','Color',Ccol.htra,'LineWidth',1.35,'DisplayName','Film (H_{tra})');
plot(ax, A_qpm.full_pitch_nm,A_qpm.mod_amp,'--','Color',Ccol.qpm,'LineWidth',1.20,'DisplayName','Conventional QPM');
plot(ax, A_filmwf.full_pitch_nm,A_filmwf.mod_amp,'-','Color',Ccol.wf,'LineWidth',1.35,'DisplayName','WF readout');
plot(ax, A_holo.full_pitch_nm,A_holo.mod_amp,'-','Color',Ccol.holo,'LineWidth',1.70,'DisplayName','HoloSIM');
xlabel(ax,'Spatial period (nm)'); ylabel(ax,'Phase amplitude (rad)');
title(ax,'Annular phase response');
xlim(ax,[100 1200]);
yMax = 1.12*max([A_sample.mod_amp(:); A_film.mod_amp(:); A_qpm.mod_amp(:); A_filmwf.mod_amp(:); A_holo.mod_amp(:)], [], 'omitnan');
ylim(ax,[0 max(0.1,yMax)]);
lgd = legend(ax,'Location','southeast','Orientation','vertical','NumColumns',1); lgd.Box='off'; try, lgd.ItemTokenSize=[8 6]; catch, end
PSI_formatCurveAxes(ax); PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir,'C_phase_response_annular_modulation.png'), S);

% Standalone phase-retention ratios.
fig = figure('Color','w','Units','centimeters','Position',[2 2 8.8 6.8]);
ax = axes('Parent',fig,'Position',[0.17 0.18 0.76 0.68]); hold(ax,'on');
plot(ax, A_sample.full_pitch_nm,Rtra,'-','Color',Ccol.htra,'LineWidth',1.35,'DisplayName','Film / sample');
plot(ax, A_sample.full_pitch_nm,Rqpm,'--','Color',Ccol.qpm,'LineWidth',1.20,'DisplayName','QPM / sample');
plot(ax, A_sample.full_pitch_nm,RfilmWF,'-','Color',Ccol.wf,'LineWidth',1.35,'DisplayName','WF / sample');
plot(ax, A_sample.full_pitch_nm,RholoSample,'-','Color',Ccol.holo,'LineWidth',1.70,'DisplayName','HoloSIM / sample');
plot(ax, A_sample.full_pitch_nm,RholoFilm_masked,':','Color',Ccol.teal,'LineWidth',1.20,'DisplayName','HoloSIM / film');
yline(ax,1,'-', 'Color', Ccol.lightgray, 'LineWidth',0.75,'HandleVisibility','off');
xlabel(ax,'Spatial period (nm)'); ylabel(ax,'Phase retention');
title(ax,'Cascaded phase-transfer response');
xlim(ax,[100 1200]); ylim(ax,[0 1.15]);
lgd = legend(ax,'Location','southeast','Orientation','vertical','NumColumns',1); lgd.Box='off'; try, lgd.ItemTokenSize=[8 6]; catch, end
PSI_formatCurveAxes(ax); PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir,'C_phase_response_retention_ratios.png'), S);

% Combined compact summary for manuscript/PPT.
fig = figure('Color','w','Units','centimeters','Position',[2 2 17.2 6.4]);
axW = 0.375; axH = 0.620;
xLeft = 0.090; xRight = 0.585; y0sum = 0.205;

ax1 = axes('Parent', fig, 'Position', [xLeft,  y0sum, axW, axH]); hold(ax1,'on');
plot(ax1, A_sample.full_pitch_nm,A_sample.mod_amp,'-','Color',Ccol.sample,'LineWidth',1.35,'DisplayName','Sample');
plot(ax1, A_film.full_pitch_nm,A_film.mod_amp,'-','Color',Ccol.htra,'LineWidth',1.35,'DisplayName','Film');
plot(ax1, A_filmwf.full_pitch_nm,A_filmwf.mod_amp,'-','Color',Ccol.wf,'LineWidth',1.35,'DisplayName','WF readout');
plot(ax1, A_holo.full_pitch_nm,A_holo.mod_amp,'-','Color',Ccol.holo,'LineWidth',1.70,'DisplayName','HoloSIM');
xlabel(ax1,'Spatial period (nm)'); ylabel(ax1,'Phase amplitude (rad)');
title(ax1,'Annular phase response'); xlim(ax1,[100 1200]); ylim(ax1,[0 max(0.1,yMax)]);
lgd1 = legend(ax1,'Location','northeast','Orientation','vertical','NumColumns',1); lgd1.Box='off'; try, lgd1.ItemTokenSize=[8 6]; catch, end
PSI_formatCurveAxes(ax1);

ax2 = axes('Parent', fig, 'Position', [xRight, y0sum, axW, axH]); hold(ax2,'on');
plot(ax2, A_sample.full_pitch_nm,Rtra,'-','Color',Ccol.htra,'LineWidth',1.35,'DisplayName','Film / sample');
plot(ax2, A_sample.full_pitch_nm,RfilmWF,'-','Color',Ccol.wf,'LineWidth',1.35,'DisplayName','WF / sample');
plot(ax2, A_sample.full_pitch_nm,RholoSample,'-','Color',Ccol.holo,'LineWidth',1.70,'DisplayName','HoloSIM / sample');
yline(ax2,1,'-', 'Color', Ccol.lightgray, 'LineWidth',0.75,'HandleVisibility','off');
xlabel(ax2,'Spatial period (nm)'); ylabel(ax2,'Phase retention');
title(ax2,'Phase-transfer retention'); xlim(ax2,[100 1200]); ylim(ax2,[0 1.06]);
lgd2 = legend(ax2,'Location','southeast','Orientation','vertical','NumColumns',1); lgd2.Box='off'; try, lgd2.ItemTokenSize=[8 6]; catch, end
PSI_formatCurveAxes(ax2);
PSI_formatFigure(fig);
PSI_safeSaveFigure(fig, fullfile(outdir,'C_phase_response_summary_nature.png'), S);

save(fullfile(outdir,'realSIM_summary.mat'), 'S','C','GT','phi_sample','phi_film','phi_holo','phi_qpm', ...
    'I4_film_raw_norm','I4_holo','I4_film_wf','A_sample','A_film','A_holo','A_qpm', ...
    'Rinc_sim_raw','Rinc_sim_shape','Rinc_wf','Rtra','RholoFilm','RholoFilm_masked','validRholoFilm','RholoSample', ...
    'SIM_failed','SIM_msg','T_phase_stats','T_directFilmPSI','T_bg_offsets','T_SIM_phase_error_stats', ...
    'T_SIM_artifact_spectrum','simParamsFixed','phi_film_directPSI','d_film_directPSI','err_holo_film','err_holo_sample');

fprintf('Done. Main-result version: fixed-param SIM + pixel integration, no affine correction, no constComp. Results saved to %s\n', outdir);

%% Local functions


function [phi,GT] = makeSiemensPhaseAA(x,y,S,C)
    r = sqrt(x.^2 + y.^2);
    max_fov = (S.N/2)*S.dx;
    star_radius = C.radius_frac * max_fov;
    SS = max(1, round(C.supersample));
    phi_accum = zeros(S.N,S.N);
    offs = ((0:SS-1)+0.5)/SS - 0.5;
    for ix = 1:SS
        for iy = 1:SS
            xs = x + offs(ix)*S.dx;
            ys = y + offs(iy)*S.dy;
            rs = sqrt(xs.^2 + ys.^2);
            th = mod(atan2(ys,xs)+2*pi, 2*pi);
            sector = floor(th / (2*pi/C.num_spokes));
            bright = mod(sector,2)==0;
            mask = rs <= star_radius & rs >= C.inner_radius;
            tmp = zeros(S.N,S.N);
            tmp(mask & bright) = C.phase_step;
            tmp(rs < C.inner_radius) = 0.5*C.phase_step;
            phi_accum = phi_accum + tmp;
        end
    end
    phi = phi_accum/(SS^2);
    if C.edge_sigma_px > 0
        phi = imgaussfilt(phi, C.edge_sigma_px);
    end
    GT.num_spokes = C.num_spokes;
    GT.num_line_pairs = C.num_line_pairs;
    GT.star_radius_m = star_radius;
    GT.inner_radius_m = C.inner_radius;
    GT.phase_step = C.phase_step;
end
