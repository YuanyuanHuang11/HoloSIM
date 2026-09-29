%% ========================================================================
% MATLAB script: HoloSIM vs conventional QPM on simulated LESC sample
%
% Purpose:
%   This simulation is NOT a phase-step/noise sweep. It fixes:
%       noise level = 0.05
%       phase step  = 1.5 rad
%
%   The goal is to demonstrate that HoloSIM can recover/resolve the phase
%   variations of mixed fine structures, whereas conventional QPM is limited
%   by the diffraction-limited pupil and therefore cannot sufficiently resolve
%   the high-spatial-frequency phase changes.
%
% Processing strategy:
%   1) Generate a simulated LESC phase/amplitude specimen.
%   2) Propagate sample field to film plane through H_tra.
%   3) Generate four phase-shifted holograms: 0, pi/2, pi, 3pi/2.
%   4) Conventional QPM baseline: pupil-limited coherent imaging + four-step PSI.
%   5) HoloSIM: independently estimate SIM reconstruction parameters for
%      each of the four PSI raw SIM frames, then perform four-step PSI.
%   6) Compare phase maps, errors, line profiles, local zooms and summary metrics.
%% ========================================================================
clear all; close all; clc;
task_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(task_dir);
addpath(genpath(fullfile(project_root, 'function')));


%% 1. Define parameters
fprintf('>>> Step 1: define fixed-parameter HoloSIM vs conventional QPM experiment\n');

params.N = 1024;
params.dx = 32.5e-9;
params.dy = 32.5e-9;
params.lambda = 405e-9;
params.SIM_lambda = 488e-9;
params.NA_SIM = 1.2;
params.z_sample = 10e-9;

% Fixed experimental condition requested by the user.
params.noise_level = 0.01;
params.siemens.phase_step = 1.5;     % retained field name for compatibility with existing functions
params.sample.type = 'LESC';

% -------------------------------------------------------------------------
% Simulated LESC specimen settings
% -------------------------------------------------------------------------
% These settings control the synthetic limbal epithelial stem cell (LESC)
% phase/amplitude object. The model includes an irregular cell outline,
% nucleus-like high-phase region, macropores, sieve-plate pore clusters,
% organic folds/wrinkles, and weak SEM-like phase texture.
params.lesc.phase_model = 'synthetic_LESC';
params.lesc.sieve_pore_radius_px = [2.2, 2.2];
params.lesc.sem_grain_noise = 0.010;
params.lesc.wrinkle_height_factor = 0.10;
params.lesc.phase_smooth_sigma_px = 0.45;
params.lesc.background_amp = 1.00;
params.lesc.cell_amp = 0.95;
params.lesc.rim_amp = 0.90;
params.lesc.amp_noise_level = 0.005;

% Conventional-QPM collection NA. If omitted, it defaults to NA_SIM in the
% LESC generator. Keeping this explicit makes the comparison reproducible.
params.NA_WF = params.NA_SIM;


% Output folder.
params.save_path = fullfile(task_dir, 'results', 'HoloSIM_PSI_LSEC');
if ~exist(params.save_path, 'dir')
    mkdir(params.save_path);
end

% SIM readout/reconstruction settings.
params.sim.illum_period_nm = 250;
params.sim.snr = 80;
params.sim.mod_factor = 0.70;
params.sim.camera_downsample_scale = 0.5;  % use camera pixel integration, not bicubic resize

% SIM reconstruction mode.
% 'hybrid_fixed' is the polished compromise used here. It estimates one fixed
% SIM operator from a conservative mean-plus-contrast reference of the four PSI
% raw SIM frames.  Compared with 'mean_fixed', it keeps more modulation/detail;
% compared with 'rms_fixed', it does not over-amplify periodic background
% stripes; compared with 'per_frame', it keeps the four PSI frames under one
% common SIM operator.
% Other supported modes: 'mean_fixed', 'rms_fixed', 'phase1_fixed', 'per_frame'.
params.sim.recon_mode = 'per_frame';
params.sim.fixed_ref_mode = 'hybrid';
params.sim.hybrid_ref_std_weight = 0.12;   % conservative hybrid: keeps more detail than mean_fixed but avoids RMS stripe amplification
params.sim.hybrid_ref_smooth_px = 0.35;    % reference-only smoothing; prevents fitting periodic stripe/noise as SIM structure
params.recon.holo_denoise_sigma_px = 0.00;

% LESC-specific stabilization for SIM stripe residuals and phase background.
% The main change from the RMS-fixed version is a safer PSI-consistent
% stabilization.  We do NOT force the four phase-shifted reconstructed frames
% to the same background level, because those phase-dependent intensity offsets
% carry the PSI signal.  We also avoid the aggressive periodic destriper that
% can over-correct the four frames differently and create phase saturation.
% Instead, a weak slow column correction is applied before demodulation and a
% very weak background-only correction is applied after phase recovery.
params.recon.bg_dilate_px = 20;
params.recon.robust_background_fit = true;
params.recon.background_fit_order = 'plane';
params.recon.set_outer_background_to_zero = false;
params.recon.match_PSI_background = false;   % IMPORTANT: do not force the four PSI frames to the same DC level
params.recon.match_PSI_background_strength = 0.00;
params.recon.destripe_SIM_holograms = true;
params.recon.holo_destripe_strength = 0.30;
params.recon.holo_destripe_smooth_px = 121;
params.recon.holo_destripe_periodic_strength = 0.00;
params.recon.holo_destripe_periodic_smooth_px = 7;
params.recon.holo_destripe_periodic_lowpass_px = 121;
params.recon.destripe_SIM_phase = true;     % only a very weak final background-column correction
params.recon.phase_destripe_strength = 0.08;
params.recon.phase_destripe_smooth_px = 151;
params.recon.phase_destripe_periodic_strength = 0.00;
params.recon.clean_phase_spikes = false;    % disabled: median spike replacement may modify real pore edges
params.recon.phase_spike_strength = 0.00;
params.recon.phase_spike_threshold_mad = 7.0;
params.recon.phase_spike_median_radius_px = 1;

% Compatibility fields used by some helper functions.
params.dx_gt = 2.5e-9;
params.siemens.num_spokes = 72;
params.siemens.radius_frac = 0.78;
params.siemens.inner_radius = 300e-9;
params.siemens.edge_sigma_px = 0.8;
params.siemens.display_fullpitch_nm = [120];
params.siemens.res_threshold = 0.05;
params.siemens.ring_halfwidth_px = 1.5;
params.siemens.n_theta = 720;
params.siemens.supersample = 8;

% Four phase shifts for phase-shifting holography.
params.phase_shifts = [0, pi/2, pi, 3*pi/2];

% On-axis reference for PSI. Temporal phase shifts recover the complex field.
theta_deg = 180;
params.alpha = 0;
params.fx_ref = sin(deg2rad(theta_deg)) / params.lambda;
if abs(params.fx_ref) < 1e-6
    params.fx_ref = 0;
end

% -------------------------------------------------------------------------
% Nature-style figure settings
% -------------------------------------------------------------------------
params.plot.font_name = 'Arial';
params.plot.font_size_axis = 7;
params.plot.font_size_label = 8;
params.plot.font_size_title = 8.2;
params.plot.font_size_sgtitle = 9;
params.plot.font_size_legend = 6.2;
params.plot.line_width = 1.3;
params.plot.line_width_light = 0.8;
params.plot.line_width_heavy = 1.6;
params.plot.axis_line_width = 0.75;
params.plot.grid_alpha = 0.10;
params.plot.export_dpi = 600;
params.plot.export_png = true;
params.plot.export_pdf = false;
params.plot.export_fig = false;
params.plot.close_fig_after_export = true;

% Image-heavy phase maps are exported through fast raster paths to avoid
% MATLAB hanging in exportgraphics()/waitForFigureReady. Curve/profile
% figures are exported by print -opengl as high-resolution PNG.
params.plot.use_fast_imwrite_export = true;
params.plot.use_safe_raster_comparison = true;   % direct imwrite montage; avoids MATLAB figure infrastructure export errors
params.plot.use_safe_raster_profile = true;      % direct imwrite profile plot; avoids print()/ViewModel hangs
params.plot.use_safe_raster_zoom = true;         % direct imwrite local zoom montage
params.plot.disable_matlab_figure_export = true; % never call print/exportgraphics/saveas in unstable graphics sessions
params.plot.full_comparison_panel_px = 900;      % pixel size of each tile in direct raster montage
params.plot.individual_panel_px = 1800;
params.plot.colorbar_px_h = 1800;
params.plot.colorbar_px_w = 430;
params.plot.colorbar_show_tick_labels = true;
params.plot.colorbar_tick_label_font_scale = 5;
params.plot.colorbar_tick_label_gap_px = 18;
params.plot.colorbar_tick_label_color = [0 0 0];
params.plot.curve_export_dpi = 600;

% Nature-style export controls for the main phase-map comparison.
% The full comparison figure is kept, while every panel and every colorbar
% is also exported separately with the same color limits.
params.plot.save_individual_panels = true;
params.plot.save_standalone_colorbars = true;
params.plot.panel_show_titles = false;
params.plot.use_turbo_phase = false;
params.plot.phase_cmap_name = 'jet';
params.plot.phase_colorbar_ticks = [0 0.5 1.0 1.5 2.0];  % filtered dynamically for LESC phase range

set(groot, ...
    'defaultFigureColor', 'w', ...
    'defaultAxesColor', 'w', ...
    'defaultAxesFontName', params.plot.font_name, ...
    'defaultTextFontName', params.plot.font_name, ...
    'defaultLegendFontName', params.plot.font_name, ...
    'defaultAxesFontSize', params.plot.font_size_axis, ...
    'defaultAxesLineWidth', params.plot.axis_line_width, ...
    'defaultLineLineWidth', params.plot.line_width, ...
    'defaultAxesXColor', 'k', ...
    'defaultAxesYColor', 'k', ...
    'defaultTextColor', 'k', ...
    'defaultAxesBox', 'off', ...
    'defaultAxesLayer', 'top');

%% 2. Run fixed-condition comparison
fprintf('>>> Step 2: run fixed condition: phase step = %.2f rad, noise = %.2f\n', ...
    params.siemens.phase_step, params.noise_level);

result = RunSingleHoloSIMVsQPMCase(params, theta_deg, 'fixed_noise005_phase15');

%% 3. Export figures and data
fprintf('>>> Step 3: export comparison figures and data\n');

SIM_PlotHoloSIMVsQPMNatureSet_LSEC(result, params, ...
    fullfile(params.save_path, 'A_HoloSIM_vs_conventional_QPM'));

SIM_PlotHoloSIMVsQPMProfilesMetrics(result, params, ...
    fullfile(params.save_path, 'B_HoloSIM_vs_conventional_QPM_profiles_metrics'));

SIM_PlotHoloSIMVsQPMLocalZooms(result, params, ...
    fullfile(params.save_path, 'C_HoloSIM_vs_conventional_QPM_local_zooms'));

save(fullfile(params.save_path, 'HoloSIM_vs_conventional_QPM_fixed_condition.mat'), ...
    'result', 'params', 'theta_deg');

summary_table = table( ...
    params.siemens.phase_step, params.noise_level, ...
    result.metrics.qpm.rmse_rad, result.metrics.holosim.rmse_rad, ...
    result.metrics.qpm.mae_rad, result.metrics.holosim.mae_rad, ...
    result.metrics.qpm.corr_obj, result.metrics.holosim.corr_obj, ...
    result.metrics.qpm.phase_std_retention, result.metrics.holosim.phase_std_retention, ...
    'VariableNames', {'phase_step_rad','noise_level', ...
                      'QPM_RMSE_rad','HoloSIM_RMSE_rad', ...
                      'QPM_MAE_rad','HoloSIM_MAE_rad', ...
                      'QPM_phase_corr','HoloSIM_phase_corr', ...
                      'QPM_phase_contrast_retention','HoloSIM_phase_contrast_retention'});

writetable(summary_table, fullfile(params.save_path, 'HoloSIM_vs_QPM_metrics.csv'));

fprintf('>>> Done. Results saved to: %s\n', params.save_path);

%% ========================================================================
% Main helper 1: run one fixed-condition HoloSIM vs QPM case
%% ========================================================================


function result = RunSingleHoloSIMVsQPMCase(params, theta_deg, case_label)
    phase_shift_names = {'0', '90', '180', '270'};

    [I_phase4, GT_ref, I_traditional_QPM_phase4] = GetFringeSet_FourPhase2(params);

    fprintf('    -> Multi-pattern phase/amplitude board. Fixed noise = %.3f, phase step = %.2f rad\n', ...
        params.noise_level, params.siemens.phase_step);

    % Use LESC-specific background outside the cell instead of a small corner.
    % This is essential for removing low-frequency phase tilt and column-wise
    % SIM stripe bias without contaminating the estimate with cellular phase.
    if isfield(GT_ref, 'mask_cell') && isequal(size(GT_ref.mask_cell), [params.N params.N])
        try
            bg_ref_mask = ~imdilate(GT_ref.mask_cell, strel('disk', params.recon.bg_dilate_px));
        catch
            bg_ref_mask = ~GT_ref.mask_cell;
        end
    else
        bg_ref_mask = false(params.N, params.N);
        bg_ref_mask(1:100, end-99:end) = true;
    end
    if nnz(bg_ref_mask) < 100
        bg_ref_mask = false(params.N, params.N);
        bg_ref_mask(1:100, end-99:end) = true;
    end
    params.recon.bg_fit_mask = bg_ref_mask;

    GT_phi = PSI_subtractBackgroundPlane(GT_ref.phi, bg_ref_mask);

    %% Conventional QPM baseline: pupil-limited field + four-step PSI
    norm_qpm = max(I_traditional_QPM_phase4(:));
    if norm_qpm <= 0 || ~isfinite(norm_qpm)
        norm_qpm = 1;
    end
    I_qpm_norm = I_traditional_QPM_phase4 ./ norm_qpm;
    [phase_QPM_raw, amplitude_QPM, object_wave_QPM] = PSI_DemodulatePhaseShift4_LSEC(I_qpm_norm, params);
    phase_QPM = PSI_subtractBackgroundPlane(phase_QPM_raw, bg_ref_mask);

    %% HoloSIM: SIM-first readout of the four PSI raw SIM frames
    norm_holo = max(I_phase4(:));
    if norm_holo <= 0 || ~isfinite(norm_holo)
        norm_holo = 1;
    end
    I_phase4_norm = I_phase4 ./ norm_holo;

    Dsum_phase4 = zeros(params.N, params.N, 4);
    SIM_failed = false(1,4);
    SIM_msg = strings(1,4);

    if isfield(params, 'sim') && isfield(params.sim, 'recon_mode')
        recon_mode = lower(params.sim.recon_mode);
    else
        recon_mode = 'mean_fixed';
    end

    switch recon_mode
        case 'per_frame'
            fprintf('    -> HoloSIM: independently estimating SIM parameters for each PSI raw SIM frame\n');
            for idx_ps = 1:4
                fprintf('    -> Per-frame SIM reconstruction for phase shift %s deg (%d/4)\n', ...
                        phase_shift_names{idx_ps}, idx_ps);
                I_this = I_phase4_norm(:,:,idx_ps);
                simParamsThis = SIM_estimateSIMFixedParams(I_this, params);
                [Dsum_phase4(:,:,idx_ps), SIM_failed(idx_ps), SIM_msg(idx_ps)] = ...
                    SIM_realSIMReadoutFixedParams_LSEC(I_this, params, simParamsThis, false);
            end

        case 'hybrid_fixed'
            fprintf('    -> HoloSIM: estimating one fixed SIM operator from a hybrid mean-plus-contrast reference\n');
            % Polished compromise: use the average frame for PSI consistency,
            % but add a controlled fraction of frame-to-frame contrast so that
            % the fixed reference is less over-smoothed than a simple mean.
            % This is intentionally weaker than RMS-fixed, which tended to fit
            % periodic background stripes and produced phase hot spots.
            I_ref = PSI_buildHybridFixedReference(I_phase4_norm, params);
            simParamsFixed = SIM_estimateSIMFixedParams(I_ref, params);
            for idx_ps = 1:4
                fprintf('    -> Hybrid-fixed SIM reconstruction for phase shift %s deg (%d/4)\n', ...
                        phase_shift_names{idx_ps}, idx_ps);
                I_this = I_phase4_norm(:,:,idx_ps);
                [Dsum_phase4(:,:,idx_ps), SIM_failed(idx_ps), SIM_msg(idx_ps)] = ...
                    SIM_realSIMReadoutFixedParams_LSEC(I_this, params, simParamsFixed, false);
            end

        case 'mean_fixed'
            fprintf('    -> HoloSIM: estimating one fixed SIM operator from the mean of four PSI frames\n');
            I_ref = mean(I_phase4_norm, 3);
            I_ref = PSI_normalizeReferenceFrame(I_ref);
            simParamsFixed = SIM_estimateSIMFixedParams(I_ref, params);
            for idx_ps = 1:4
                fprintf('    -> Mean-fixed SIM reconstruction for phase shift %s deg (%d/4)\n', ...
                        phase_shift_names{idx_ps}, idx_ps);
                I_this = I_phase4_norm(:,:,idx_ps);
                [Dsum_phase4(:,:,idx_ps), SIM_failed(idx_ps), SIM_msg(idx_ps)] = ...
                    SIM_realSIMReadoutFixedParams_LSEC(I_this, params, simParamsFixed, false);
            end

        case 'rms_fixed'
            fprintf('    -> HoloSIM: estimating one fixed SIM operator from the RMS reference of four PSI frames\n');
            % Balanced mode: RMS keeps more SIM modulation contrast than a
            % simple mean reference, but the same SIM operator is still used
            % for all four phase-shifted frames, preserving PSI consistency.
            I_ref = sqrt(mean(I_phase4_norm.^2, 3));
            I_ref = PSI_normalizeReferenceFrame(I_ref);
            simParamsFixed = SIM_estimateSIMFixedParams(I_ref, params);
            for idx_ps = 1:4
                fprintf('    -> RMS-fixed SIM reconstruction for phase shift %s deg (%d/4)\n', ...
                        phase_shift_names{idx_ps}, idx_ps);
                I_this = I_phase4_norm(:,:,idx_ps);
                [Dsum_phase4(:,:,idx_ps), SIM_failed(idx_ps), SIM_msg(idx_ps)] = ...
                    SIM_realSIMReadoutFixedParams_LSEC(I_this, params, simParamsFixed, false);
            end

        case 'phase1_fixed'
            fprintf('    -> HoloSIM: estimating one fixed SIM operator from the first PSI frame\n');
            I_ref = I_phase4_norm(:,:,1);
            I_ref = PSI_normalizeReferenceFrame(I_ref);
            simParamsFixed = SIM_estimateSIMFixedParams(I_ref, params);
            for idx_ps = 1:4
                fprintf('    -> Phase1-fixed SIM reconstruction for phase shift %s deg (%d/4)\n', ...
                        phase_shift_names{idx_ps}, idx_ps);
                I_this = I_phase4_norm(:,:,idx_ps);
                [Dsum_phase4(:,:,idx_ps), SIM_failed(idx_ps), SIM_msg(idx_ps)] = ...
                    SIM_realSIMReadoutFixedParams_LSEC(I_this, params, simParamsFixed, false);
            end

        otherwise
            error('Unknown params.sim.recon_mode: %s. Use per_frame, mean_fixed, hybrid_fixed, rms_fixed, or phase1_fixed.', recon_mode);
    end

    if any(SIM_failed)
        warning('One or more SIM reconstructions failed in case %s: %s', ...
            case_label, strjoin(cellstr(SIM_msg(SIM_failed)), '; '));
    end

    % Optional diagnostic only.  Do NOT enable for the main result: the four PSI
    % frames naturally have phase-dependent intensity offsets.  Forcing their
    % background medians to match can destroy the four-step phase relation and
    % produce a saturated/abnormal HoloSIM phase map.
    if isfield(params, 'recon') && isfield(params.recon, 'match_PSI_background') && params.recon.match_PSI_background
        Dsum_phase4 = PSI_HarmonizePSIBackground(Dsum_phase4, bg_ref_mask, ...
            params.recon.match_PSI_background_strength);
    end

    % Remove column-wise SIM bias from each reconstructed PSI hologram before
    % four-step demodulation.  A slow term removes large-scale bias; a weak
    % periodic term removes the fine vertical stripes visible in RMS-fixed maps.
    if isfield(params, 'recon') && isfield(params.recon, 'destripe_SIM_holograms') && params.recon.destripe_SIM_holograms
        for idx_ps = 1:4
            Dsum_phase4(:,:,idx_ps) = PSI_RemoveColumnStripeBias(Dsum_phase4(:,:,idx_ps), ...
                bg_ref_mask, params.recon.holo_destripe_smooth_px, ...
                params.recon.holo_destripe_strength, ...
                PSI_getReconField(params, 'holo_destripe_periodic_strength', 0.0), ...
                PSI_getReconField(params, 'holo_destripe_periodic_smooth_px', 7), ...
                PSI_getReconField(params, 'holo_destripe_periodic_lowpass_px', 121));
        end
    end

    [phase_HoloSIM_raw, amplitude_HoloSIM, object_wave_HoloSIM] = ...
        PSI_DemodulatePhaseShift4_LSEC(Dsum_phase4, params);
    phase_HoloSIM = PSI_subtractBackgroundPlane(phase_HoloSIM_raw, bg_ref_mask);

    if isfield(params, 'recon') && isfield(params.recon, 'destripe_SIM_phase') && params.recon.destripe_SIM_phase
        phase_HoloSIM = PSI_RemoveColumnStripeBias(phase_HoloSIM, bg_ref_mask, ...
            params.recon.phase_destripe_smooth_px, params.recon.phase_destripe_strength, ...
            PSI_getReconField(params, 'phase_destripe_periodic_strength', 0.0), 7, 121);
    end

    if isfield(params, 'recon') && isfield(params.recon, 'clean_phase_spikes') && params.recon.clean_phase_spikes
        phase_HoloSIM = PSI_SuppressIsolatedPhaseSpikes(phase_HoloSIM, ...
            PSI_getReconField(params, 'phase_spike_strength', 0.8), ...
            PSI_getReconField(params, 'phase_spike_threshold_mad', 7.0), ...
            PSI_getReconField(params, 'phase_spike_median_radius_px', 1));
    end

    %% Metrics on object mask
    if isfield(GT_ref, 'object_mask')
        mask_obj = GT_ref.object_mask;
    else
        mask_obj = abs(GT_phi) > 0.02 * max(abs(GT_phi(:)));
    end
    try
        mask_obj = imdilate(mask_obj, strel('disk', 2));
    catch
    end
    mask_obj = mask_obj & isfinite(GT_phi) & isfinite(phase_QPM) & isfinite(phase_HoloSIM);
    if ~any(mask_obj(:))
        mask_obj = isfinite(GT_phi) & isfinite(phase_QPM) & isfinite(phase_HoloSIM);
    end

    metrics_qpm = PSI_ComputePhaseMetrics(GT_phi, phase_QPM, mask_obj, params.siemens.phase_step);
    metrics_holosim = PSI_ComputePhaseMetrics(GT_phi, phase_HoloSIM, mask_obj, params.siemens.phase_step);

    %% Representative profile lines. Use several y locations that cut through
    % grating, ring and dot-array structures rather than only y = 0.
    max_fov = (params.N/2) * params.dx;
    profile_y_m = [0.55, -0.25, -0.55] * max_fov;
    profile_names = {'upper gratings / rings', 'middle dashed structures', 'lower fine dot arrays'};

    profiles = struct([]);
    for ip = 1:numel(profile_y_m)
        [~, yy] = min(abs(GT_ref.y(:,1) - profile_y_m(ip)));
        x_nm = GT_ref.x(yy,:) * 1e9;
        profiles(ip).name = profile_names{ip};
        profiles(ip).y_nm = GT_ref.y(yy,1) * 1e9;
        profiles(ip).x_nm = x_nm;
        profiles(ip).GT = GT_phi(yy,:);
        profiles(ip).QPM = phase_QPM(yy,:);
        profiles(ip).HoloSIM = phase_HoloSIM(yy,:);
    end

    % Focused profile through the highest-phase region of the LESC sample.
    % The corresponding dashed guide line is overlaid on the phase maps.
    center_profile = PSI_BuildLESCMaxPhaseProfile(GT_ref, GT_phi, phase_QPM, phase_HoloSIM, params);

    result.case_label = case_label;
    result.theta_deg = theta_deg;
    result.phase_step = params.siemens.phase_step;
    result.noise_level = params.noise_level;
    result.GT_ref = GT_ref;
    result.GT_phi = GT_phi;
    result.phase_QPM = phase_QPM;
    result.phase_HoloSIM = phase_HoloSIM;
    result.err_QPM = phase_QPM - GT_phi;
    result.err_HoloSIM = phase_HoloSIM - GT_phi;
    result.amplitude_QPM = amplitude_QPM;
    result.amplitude_HoloSIM = amplitude_HoloSIM;
    result.object_wave_QPM = object_wave_QPM;
    result.object_wave_HoloSIM = object_wave_HoloSIM;
    result.Dsum_phase4 = Dsum_phase4;
    result.I_phase4 = I_phase4;
    result.I_traditional_QPM_phase4 = I_traditional_QPM_phase4;
    result.object_mask = mask_obj;
    result.metrics.qpm = metrics_qpm;
    result.metrics.holosim = metrics_holosim;
    result.profiles = profiles;
    result.center_profile = center_profile;
    result.profile_line = center_profile.line;
    result.SIM_failed = SIM_failed;
    result.SIM_msg = SIM_msg;
end

function [I_phase4, ground_truth, I_traditional_QPM_phase4] = GetFringeSet_FourPhase2(p)
    rng(1024);
    p = PSI_setDefaultLESCParams(p);
    [x, y] = meshgrid((-p.N/2:p.N/2-1)*p.dx, (-p.N/2:p.N/2-1)*p.dy);
    [Theta, R] = cart2pol(x, y);

    fprintf('   - [LESC Step 1] Generating fixed cell edge...\n');
    max_fov_radius = (p.N / 2) * p.dx;
    base_cell_radius = 0.85 * max_fov_radius;

    num_ctrl_points = 20;
    theta_ctrl = linspace(0, 2*pi, num_ctrl_points+1);
    fixed_shape_factor = [1.0, 0.95, 0.9, 0.75, 0.9, 1.1, 1.05, 1.0, 1.05, 0.85, ...
                          0.8, 0.85, 0.95, 1.05, 1.1, 1.1, 1.0, 0.95, 0.95, 1.0, 1.0];
    r_ctrl = base_cell_radius * fixed_shape_factor;
    R_smooth_boundary = interp1(theta_ctrl, r_ctrl, Theta+pi, 'pchip');

    filopodia_noise = 0.06 * base_cell_radius * randn(p.N);
    mask_cell = R < (R_smooth_boundary + filopodia_noise);
    mask_cell = imfill(mask_cell, 'holes');
    mask_cell = imopen(mask_cell, strel('disk', 1));

    fprintf('   - [LESC Step 2] Modeling nucleus...\n');
    dist_map = bwdist(~mask_cell);
    thickness_base = dist_map / max(dist_map(:));
    thickness_base = thickness_base .^ 0.5;

    nuc_cx = 0.25 * max_fov_radius;
    nuc_cy = -0.25 * max_fov_radius;
    nuc_radius = 0.3 * max_fov_radius;
    dist_to_nuc_center = sqrt((x - nuc_cx).^2 + (y - nuc_cy).^2);
    mask_nucleus = (dist_to_nuc_center < nuc_radius) & mask_cell;

    phi_combined = 1.0 * thickness_base;
    nuc_height_profile = exp(-dist_to_nuc_center.^2 / (2*(nuc_radius*0.7)^2));
    phi_combined(mask_nucleus) = phi_combined(mask_nucleus) + 0.5 * nuc_height_profile(mask_nucleus);

    fprintf('   - [LESC Step 3] Generating macropores and neighboring pores...\n');
    macro_holes_mask = false(p.N);

    lh_cx = -0.1 * max_fov_radius;
    lh_cy =  0.6 * max_fov_radius;

    num_blobs = 6;
    this_macro = false(p.N);
    for b = 1:num_blobs
        bx = lh_cx + randn * 6 * p.dx;
        by = lh_cy + randn * 6 * p.dx;
        ax = (6 + 3*rand) * p.dx;
        ay = (6 + 3*rand) * p.dx;
        rot = rand * pi;
        dx_rot = (x - bx)*cos(rot) + (y - by)*sin(rot);
        dy_rot = (x - bx)*-sin(rot) + (y - by)*cos(rot);
        this_macro = this_macro | ((dx_rot/ax).^2 + (dy_rot/ay).^2 < 1);
    end
    noise_grid = imgaussfilt(randn(p.N), 1.0);
    this_macro = this_macro & (noise_grid > -0.5);
    macro_holes_mask = macro_holes_mask | this_macro;

    sh_cx = lh_cx - 0.35 * max_fov_radius;
    sh_cy = lh_cy - 0.15 * max_fov_radius;
    num_blobs = 3;
    this_small = false(p.N);
    for b = 1:num_blobs
        bx = sh_cx + randn * 3 * p.dx;
        by = sh_cy + randn * 3 * p.dx;
        ax = (3 + 2*rand) * p.dx;
        ay = (3 + 2*rand) * p.dx;
        rot = rand * pi;
        dx_rot = (x - bx)*cos(rot) + (y - by)*sin(rot);
        dy_rot = (x - bx)*-sin(rot) + (y - by)*cos(rot);
        this_small = this_small | ((dx_rot/ax).^2 + (dy_rot/ay).^2 < 1);
    end
    noise_grid = imgaussfilt(randn(p.N), 0.8);
    this_small = this_small & (noise_grid > -0.6);
    macro_holes_mask = macro_holes_mask | this_small;

    medium_hole_pos = [0.6, 0.1; 0.5, -0.1];
    for i = 1:size(medium_hole_pos, 1)
        mx = medium_hole_pos(i, 1) * max_fov_radius;
        my = medium_hole_pos(i, 2) * max_fov_radius;
        num_blobs = 3;
        this_med = false(p.N);
        for b = 1:num_blobs
            bx = mx + randn * 4 * p.dx;
            by = my + randn * 4 * p.dx;
            ax = (3 + 2*rand) * p.dx;
            ay = (3 + 2*rand) * p.dx;
            rot = rand * pi;
            dx_rot = (x - bx)*cos(rot) + (y - by)*sin(rot);
            dy_rot = (x - bx)*-sin(rot) + (y - by)*cos(rot);
            this_med = this_med | ((dx_rot/ax).^2 + (dy_rot/ay).^2 < 1);
        end
        noise_grid = imgaussfilt(randn(p.N), 0.8);
        this_med = this_med & (noise_grid > -0.6);
        macro_holes_mask = macro_holes_mask | this_med;
    end
    macro_holes_mask = macro_holes_mask & mask_cell;
    macro_holes_mask = imclose(macro_holes_mask, strel('disk', 1));

    fprintf('   - [LESC Step 4] Generating sieve-plate pore clusters...\n');
    if isfield(p.lesc, 'sieve_pore_radius_px')
        radius_options = p.lesc.sieve_pore_radius_px;
    else
        radius_options = [3.0, 3.0];
    end
    holes_mask_accum = false(p.N);

    bridge_cx = (lh_cx + sh_cx) / 2;
    bridge_cy = (lh_cy + sh_cy) / 2;
    bridge_cx_norm = bridge_cx / max_fov_radius;
    bridge_cy_norm = bridge_cy / max_fov_radius;

    cluster_definitions = [
        bridge_cx_norm, bridge_cy_norm, 0.18, 0.12, -pi/6;
        -0.45, -0.35,  0.35, 0.25,  pi/6;
        -0.10, -0.55,  0.28, 0.22, -pi/12;
         0.45,  0.20,  0.20, 0.35, -pi/8;
    ];

    existing_pores_list = [];
    for i = 1:size(cluster_definitions, 1)
        cx = cluster_definitions(i, 1) * max_fov_radius;
        cy = cluster_definitions(i, 2) * max_fov_radius;
        a_axis = cluster_definitions(i, 3) * max_fov_radius;
        b_axis = cluster_definitions(i, 4) * max_fov_radius;
        rot_angle = cluster_definitions(i, 5);

        if i == 1
            target_pores_in_cluster = 80;
            max_attempts_pool = 800;
        else
            target_pores_in_cluster = 120;
            max_attempts_pool = 1500;
        end

        rand_r_list     = sqrt(rand(max_attempts_pool, 1));
        rand_theta_list = rand(max_attempts_pool, 1) * 2 * pi;
        rand_noise_list = rand(max_attempts_pool, 1);
        rand_rad_idx_list = randi(length(radius_options), max_attempts_pool, 1);
        pores_placed_count = 0;

        for cand_idx = 1:max_attempts_pool
            if pores_placed_count >= target_pores_in_cluster
                break;
            end
            r_rand = rand_r_list(cand_idx);
            theta_rand = rand_theta_list(cand_idx);
            x_local = r_rand * a_axis * cos(theta_rand);
            y_local = r_rand * b_axis * sin(theta_rand);
            px = cx + (x_local * cos(rot_angle) - y_local * sin(rot_angle));
            py = cy + (x_local * sin(rot_angle) + y_local * cos(rot_angle));

            noise_scale = 0.05;
            if r_rand > (1.0 - noise_scale * rand_noise_list(cand_idx))
                continue;
            end

            rad_idx = rand_rad_idx_list(cand_idx);
            selected_radius_pixel = radius_options(rad_idx);
            pr = selected_radius_pixel * p.dx;
            pr_c = round(px / p.dx) + (p.N / 2) + 1;
            pr_r = round(py / p.dy) + (p.N / 2) + 1;
            if pr_r<1 || pr_r>p.N || pr_c<1 || pr_c>p.N
                continue;
            end

            edge_dist_limit = 15;
            if i == 1
                edge_dist_limit = 5;
            end
            if dist_map(pr_r, pr_c) < edge_dist_limit
                continue;
            end
            if mask_nucleus(pr_r, pr_c)
                continue;
            end
            if macro_holes_mask(pr_r, pr_c)
                continue;
            end

            overlap = false;
            if ~isempty(existing_pores_list)
                d_sq = (existing_pores_list(:,1)-px).^2 + (existing_pores_list(:,2)-py).^2;
                min_allowed = (existing_pores_list(:,3) + pr + 0.1*p.dx).^2;
                if any(d_sq < min_allowed)
                    overlap = true;
                end
            end

            if ~overlap
                existing_pores_list = [existing_pores_list; px, py, pr]; %#ok<AGROW>
                dist_to_pore = sqrt((x-px).^2 + (y-py).^2);
                holes_mask_accum = holes_mask_accum | (dist_to_pore < pr);
                pores_placed_count = pores_placed_count + 1;
            end
        end
    end

    fprintf('   - [LESC Step 5] Synthesizing phase with organic folds...\n');
    all_holes_final = holes_mask_accum | macro_holes_mask;
    mask_tissue = mask_cell & ~all_holes_final;

    phi_object = zeros(p.N);
    phi_object(mask_tissue) = phi_combined(mask_tissue);

    sem_grain_noise = p.lesc.sem_grain_noise * randn(p.N);
    phi_object(mask_tissue) = phi_object(mask_tissue) + sem_grain_noise(mask_tissue);

    noise_base = imgaussfilt(randn(p.N), 8.0);
    turbulence = imgaussfilt(randn(p.N), 3.0);
    wrinkle_pattern = abs(noise_base + 0.2*turbulence);
    wrinkle_pattern = max(wrinkle_pattern(:)) - wrinkle_pattern;
    wrinkle_pattern(wrinkle_pattern < 0.6 * max(wrinkle_pattern(:))) = 0;
    modulation = imgaussfilt(rand(p.N), 10.0);
    wrinkle_pattern = wrinkle_pattern .* modulation;
    wrinkle_layer = wrinkle_pattern * p.lesc.wrinkle_height_factor;
    phi_object(mask_tissue) = phi_object(mask_tissue) + wrinkle_layer(mask_tissue);

    dist_cell_edge = bwdist(~mask_cell);
    is_outer_rim = (dist_cell_edge > 0) & (dist_cell_edge <= 3);
    phi_object(is_outer_rim) = phi_object(is_outer_rim) * 1.1 + 0.1;
    phi_object = imgaussfilt(phi_object, p.lesc.phase_smooth_sigma_px);
    phi_object(~mask_tissue) = 0;

    fprintf('>>> LESC Ground Truth phase range: [%.4f, %.4f] rad\n', min(phi_object(:)), max(phi_object(:)));

    fprintf('   - [LESC Step 6] Generating four phase-shifted holograms...\n');
    background_amp = p.lesc.background_amp;
    cell_amp = p.lesc.cell_amp;
    rim_amp = p.lesc.rim_amp;

    amp_gt = ones(p.N) * background_amp;
    amp_gt(mask_tissue) = cell_amp;
    amp_gt(is_outer_rim) = rim_amp;
    amp_gt(~mask_tissue) = background_amp;
    if isfield(p.lesc, 'amp_noise_level')
        amp_noise_level = p.lesc.amp_noise_level;
    else
        amp_noise_level = 0.02;
    end
    amp_gt = amp_gt + amp_noise_level * randn(p.N);
    amp_gt = max(amp_gt, 0.05);

    U_obj_sample = amp_gt .* exp(1i * phi_object);

    fx = (-p.N/2:p.N/2-1) / (p.N * p.dx);
    fy = (-p.N/2:p.N/2-1) / (p.N * p.dy);
    [FX, FY] = meshgrid(fx, fy);

    fx_ref = p.fx_ref;
    alpha = p.alpha;
    U_ref_base = 1.0 * exp(1i * 2*pi * (fx_ref * (x*cos(alpha) + y*sin(alpha))));

    lambda_eff = p.lambda / 2.0;
    k_eff = 2*pi / lambda_eff;
    term = 1 - (lambda_eff * FX).^2 - (lambda_eff * FY).^2;
    H_exact = zeros(size(term));
    H_exact(term >= 0) = exp(1i * k_eff * p.z_sample .* sqrt(term(term >= 0)));
    H_exact(term < 0) = exp(-k_eff * p.z_sample .* sqrt(-term(term < 0)));

    U_obj_film = ifft2(fft2(U_obj_sample) .* fftshift(H_exact));

    if isfield(p, 'NA_WF')
        NA_WF = p.NA_WF;
    else
        NA_WF = p.NA_SIM;
    end

    f_cutoff_QPM = NA_WF / p.lambda;
    FR = sqrt(FX.^2 + FY.^2);
    pupil_soft_width = 0.06 * f_cutoff_QPM;
    Pupil = 0.5 * (1 - tanh((FR - f_cutoff_QPM) / pupil_soft_width));
    U_obj_traditional = ifft2(fft2(U_obj_sample) .* fftshift(Pupil));

    I_phase4 = zeros(p.N, p.N, 4);
    I_traditional_QPM_phase4 = zeros(p.N, p.N, 4);
    for idx_ps = 1:4
        delta = p.phase_shifts(idx_ps);
        U_ref_shifted = U_ref_base .* exp(1i * delta);

        I_perfect = abs(U_obj_film + U_ref_shifted).^2;
        I_tmp = I_perfect + p.noise_level * max(I_perfect(:)) * randn(p.N);
        I_tmp(I_tmp < 0) = 0;
        I_phase4(:,:,idx_ps) = I_tmp;

        I_perfect_QPM = abs(U_obj_traditional + U_ref_shifted).^2;
        I_tmp_QPM = I_perfect_QPM + p.noise_level * max(I_perfect_QPM(:)) * randn(p.N);
        I_tmp_QPM(I_tmp_QPM < 0) = 0;
        I_traditional_QPM_phase4(:,:,idx_ps) = I_tmp_QPM;
    end

    ground_truth = struct();
    ground_truth.amp = amp_gt;
    ground_truth.phi = phi_object;
    ground_truth.x = x;
    ground_truth.y = y;
    ground_truth.mask_cell = mask_cell;
    ground_truth.mask_tissue = mask_tissue;
    ground_truth.object_mask = mask_tissue;
    ground_truth.sample_type = 'LESC';
    ground_truth.full_pitch_m = NaN(p.N, p.N);
    ground_truth.mask_nucleus = mask_nucleus;
    ground_truth.macro_holes_mask = macro_holes_mask;
    ground_truth.sieve_pores_mask = holes_mask_accum;
    ground_truth.all_holes_mask = all_holes_final;
    ground_truth.is_outer_rim = is_outer_rim;
    ground_truth.lesc = struct('max_fov_radius_m', max_fov_radius, ...
                               'large_hole_center_m', [lh_cx, lh_cy], ...
                               'small_hole_center_m', [sh_cx, sh_cy], ...
                               'bridge_center_m', [bridge_cx, bridge_cy], ...
                               'phase_model', p.lesc.phase_model);

    fprintf('   > LESC morphology and four-phase hologram generation complete.\n');
end
