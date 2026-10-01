%% ========================================================================
% MATLAB script: HoloSIM vs conventional QPM on multi-pattern phase board
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
%   1) Generate a multi-pattern phase/amplitude board.
%   2) Propagate sample field to film plane through H_tra.
%   3) Generate four phase-shifted holograms: 0, pi/2, pi, 3pi/2.
%   4) Conventional QPM baseline: pupil-limited coherent imaging + four-step PSI.
%   5) HoloSIM: estimate SIM reconstruction parameters once from one PSI frame,
%      apply the same fixed SIM operator to all four PSI frames, then four-step PSI.
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

% Fixed simulation conditions.
params.noise_level = 0.05;
params.siemens.phase_step = 1.5;     % retained field name for compatibility with existing functions
params.sample.type = 'multipattern_board';

% Output folder.
params.save_path = fullfile(task_dir, 'results', 'HoloSIM_PSI_MultiPattern');
if ~exist(params.save_path, 'dir')
    mkdir(params.save_path);
end

% SIM readout/reconstruction settings.
params.sim.illum_period_nm = 250;
params.sim.snr = 100;
params.sim.mod_factor = 0.8;
params.sim.camera_downsample_scale = 0.5;  % use camera pixel integration, not bicubic resize
params.sim.fixed_ref_mode = 'phase1';      % fixed SIM operator for all four PSI frames
params.recon.holo_denoise_sigma_px = 0;

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
params.plot.individual_panel_px = 1800;
params.plot.colorbar_px_h = 1800;
params.plot.colorbar_px_w = 260;
params.plot.curve_export_dpi = 600;

% Nature-style export controls for the main phase-map comparison.
% The full comparison figure is kept, while every panel and every colorbar
% is also exported separately with the same color limits.
params.plot.save_individual_panels = true;
params.plot.save_standalone_colorbars = true;
params.plot.panel_show_titles = false;
params.plot.use_turbo_phase = false;
params.plot.phase_cmap_name = 'nature';
params.plot.phase_colorbar_ticks = [0 0.5 1.0 1.5 2.0];

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

SIM_PlotHoloSIMVsQPMNatureSet(result, params, ...
    fullfile(params.save_path, 'A_HoloSIM_vs_conventional_QPM'));

SIM_PlotHoloSIMVsQPMProfilesMetrics_Multi(result, params, ...
    fullfile(params.save_path, 'B_HoloSIM_vs_conventional_QPM_profiles_metrics'));

SIM_PlotHoloSIMVsQPMLocalZooms_Multi(result, params, ...
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

    bg_ref_mask = false(params.N, params.N);
    bg_ref_mask(1:100, end-99:end) = true;

    GT_phi = PSI_subtractBackground(GT_ref.phi, bg_ref_mask);

    %% Conventional QPM baseline: pupil-limited field + four-step PSI
    norm_qpm = max(I_traditional_QPM_phase4(:));
    if norm_qpm <= 0 || ~isfinite(norm_qpm)
        norm_qpm = 1;
    end
    I_qpm_norm = I_traditional_QPM_phase4 ./ norm_qpm;
    [phase_QPM_raw, amplitude_QPM, object_wave_QPM] = PSI_DemodulatePhaseShift4_LSEC(I_qpm_norm, params);
    phase_QPM = PSI_subtractBackground(phase_QPM_raw, bg_ref_mask);

    %% HoloSIM: SIM-first readout with fixed SIM parameters for all PSI frames
    norm_holo = max(I_phase4(:));
    if norm_holo <= 0 || ~isfinite(norm_holo)
        norm_holo = 1;
    end
    I_phase4_norm = I_phase4 ./ norm_holo;

    ref_idx = 1;
    if isfield(params, 'sim') && isfield(params.sim, 'fixed_ref_mode')
        switch lower(params.sim.fixed_ref_mode)
            case {'phase1','first','0'}
                ref_idx = 1;
            case {'mean','average'}
                ref_idx = 0;
            otherwise
                ref_idx = 1;
        end
    end

    fprintf('    -> Estimating one fixed SIM reconstruction operator for all four PSI frames\n');
    if ref_idx == 0
        I_ref = mean(I_phase4_norm, 3);
    else
        I_ref = I_phase4_norm(:,:,ref_idx);
    end
    simParamsFixed = SIM_estimateSIMFixedParams(I_ref, params);

    Dsum_phase4 = zeros(params.N, params.N, 4);
    SIM_failed = false(1,4);
    SIM_msg = strings(1,4);

    for idx_ps = 1:4
        fprintf('    -> HoloSIM fixed-operator reconstruction for phase shift %s deg (%d/4)\n', ...
                phase_shift_names{idx_ps}, idx_ps);
        I_this = I_phase4_norm(:,:,idx_ps);
        [Dsum_phase4(:,:,idx_ps), SIM_failed(idx_ps), SIM_msg(idx_ps)] = ...
            SIM_realSIMReadoutFixedParams_LSEC(I_this, params, simParamsFixed, false);
    end

    if any(SIM_failed)
        warning('One or more fixed-parameter SIM reconstructions failed in case %s: %s', ...
            case_label, strjoin(cellstr(SIM_msg(SIM_failed)), '; '));
    end

    [phase_HoloSIM_raw, amplitude_HoloSIM, object_wave_HoloSIM] = ...
        PSI_DemodulatePhaseShift4_LSEC(Dsum_phase4, params);
    phase_HoloSIM = PSI_subtractBackground(phase_HoloSIM_raw, bg_ref_mask);

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

    % Focused stripe profiles for journal figures. These do not span the
    % whole FOV; instead they crop around the grating region so the phase
    % oscillations are clearly expanded rather than compressed.
    stripe_profiles = PSI_BuildStripeProfiles(GT_ref, GT_phi, phase_QPM, phase_HoloSIM, params);

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
    result.stripe_profiles = stripe_profiles;
    result.SIM_failed = SIM_failed;
    result.SIM_msg = SIM_msg;
end

function [I_phase4, ground_truth, I_traditional_QPM_phase4] = GetFringeSet_FourPhase2(p)
    rng(1024);

    [x, y] = meshgrid((-p.N/2:p.N/2-1)*p.dx, ...
                      (-p.N/2:p.N/2-1)*p.dy);

    phi_object = zeros(p.N, p.N);

    % Multi-pattern phase/amplitude test board.
    % Phase-step/noise sweeps are preserved through p.siemens.phase_step and
    % p.noise_level, but the object is no longer a Siemens star.
    amp_bg = 1.00;
    amp_obj = 1.00;
    amp_gt = ones(p.N, p.N) * amp_bg;

    max_fov = (p.N / 2) * p.dx;

    if isfield(p, 'siemens') && isfield(p.siemens, 'phase_step')
        phase_step = p.siemens.phase_step;
    else
        phase_step = 1.0;
    end

    period_x = 190e-9;
    period_half_x = 60e-9;

    %% 1. Smooth spherical-cap phase object, upper-left
    cx_sph = -0.6 * max_fov;
    cy_sph =  0.6 * max_fov;
    r_sph  =  0.3 * max_fov;

    R_sph = sqrt((x - cx_sph).^2 + (y - cy_sph).^2);
    mask_sph = R_sph < r_sph;

    phi_object(mask_sph) = phase_step * 1.5 .* ...
        sqrt(1 - (R_sph(mask_sph) / r_sph).^2);

    %% 2. Concentric ring target, upper-right
    cx_ring =  0.65 * max_fov;
    cy_ring =  0.6 * max_fov;
    r_ring_max = 0.3 * max_fov;

    R_ring = sqrt((x - cx_ring).^2 + (y - cy_ring).^2);
    period_ring = 0.018 * max_fov;
    thick_ring  = 0.009 * max_fov;

    mask_ring = (mod(R_ring, period_ring) < thick_ring) & ...
                (R_ring < r_ring_max);

    %% 3. Vertical and horizontal grating bars, upper-middle
    mask_vbar = ...
        (x > -0.2 * max_fov) & (x <  0.0 * max_fov) & ...
        (y >  0.2 * max_fov) & (y <  0.6 * max_fov) & ...
        (mod(x + 0.2 * max_fov, period_x) < period_half_x);

    mask_hbar = ...
        (x >  0.1 * max_fov) & (x <  0.3 * max_fov) & ...
        (y >  0.2 * max_fov) & (y <  0.6 * max_fov) & ...
        (mod(y - 0.2 * max_fov, period_x) < period_half_x);

    %% 4. Multi-size circular phase objects, lower-left
    c1 = sqrt((x + 0.6*max_fov).^2 + (y + 0.7*max_fov).^2) < 0.12*max_fov;
    c2 = sqrt((x + 0.6*max_fov).^2 + (y + 0.4*max_fov).^2) < 0.08*max_fov;
    c3 = sqrt((x + 0.6*max_fov).^2 + (y + 0.2*max_fov).^2) < 0.05*max_fov;
    c4 = sqrt((x + 0.6*max_fov).^2 + (y + 0.05*max_fov).^2) < 0.03*max_fov;

    mask_circles = c1 | c2 | c3 | c4;

    %% 5. Dashed horizontal and vertical structures, lower-middle
    mask_hdash = ...
        (x > -0.25*max_fov) & (x < 0.25*max_fov) & ...
        (y > -0.70*max_fov) & (y < -0.45*max_fov) & ...
        (mod(y + 0.70*max_fov, 0.05*max_fov) < 0.015*max_fov) & ...
        (mod(x + 0.25*max_fov, 0.08*max_fov) < 0.05*max_fov);

    mask_vdash = ...
        (x > -0.25*max_fov) & (x < 0.25*max_fov) & ...
        (y > -0.35*max_fov) & (y < -0.10*max_fov) & ...
        (mod(x + 0.25*max_fov, 0.05*max_fov) < 0.015*max_fov) & ...
        (mod(y + 0.35*max_fov, 0.08*max_fov) < 0.05*max_fov);

    %% 6. Fine dot arrays / checker-like targets, lower-right
    mask_dots1 = ...
        (x > 0.4*max_fov) & (x < 0.8*max_fov) & ...
        (y > -0.7*max_fov) & (y < -0.4*max_fov) & ...
        (mod(x - 0.4*max_fov, 0.018*max_fov) < 0.009*max_fov) & ...
        (mod(y + 0.3*max_fov, 0.018*max_fov) < 0.009*max_fov);

    mask_dots2 = ...
        (x > 0.4*max_fov) & (x < 0.8*max_fov) & ...
        (y > -0.3*max_fov) & (y < -0.05*max_fov) & ...
        (mod(x - 0.4*max_fov, period_x) < period_half_x) & ...
        (mod(y + 0.3*max_fov, period_x) < period_half_x);

    %% Combine all binary phase structures
    mask_binary_shapes = ...
        mask_ring | mask_vbar | mask_hbar | mask_circles | ...
        mask_hdash | mask_vdash | mask_dots1 | mask_dots2;

    phi_object(mask_binary_shapes) = phase_step;

    % Mild edge smoothing to avoid hard single-pixel discontinuities.
    edge_sigma_px = 1.0;
    phi_object = imgaussfilt(phi_object, edge_sigma_px);

    mask_all = mask_binary_shapes | mask_sph;
    amp_gt(mask_all) = amp_obj;
    amp_gt = imgaussfilt(amp_gt, edge_sigma_px);

    %% Ground-truth fields
    ground_truth.amp = amp_gt;
    ground_truth.phi = phi_object;
    ground_truth.x = x;
    ground_truth.y = y;
    ground_truth.object_mask = mask_all;
    ground_truth.full_pitch_m = NaN(p.N, p.N);
    ground_truth.sample_type = 'multipattern_board';
    ground_truth.phase_step_rad = phase_step;

    % Use amplitude + phase board. For a pure phase board, replace this with:
    % U_obj_sample = exp(1i * phi_object);
    U_obj_sample = amp_gt .* exp(1i * phi_object);

    %% Frequency grid
    fx = (-p.N/2:p.N/2-1) / (p.N * p.dx);
    fy = (-p.N/2:p.N/2-1) / (p.N * p.dy);
    [FX, FY] = meshgrid(fx, fy);

    %% Reference wave
    fx_ref = p.fx_ref;
    alpha = p.alpha;
    U_ref_base = exp(1i * 2*pi * ...
        (fx_ref * (x*cos(alpha) + y*sin(alpha))));

    %% Sample-to-film propagation: H_tra
    lambda_eff = p.lambda / 2.0;
    k_eff = 2 * pi / lambda_eff;

    term = 1 - (lambda_eff * FX).^2 - (lambda_eff * FY).^2;

    H_exact = zeros(size(term));
    H_exact(term >= 0) = exp(1i * k_eff * p.z_sample .* ...
        sqrt(term(term >= 0)));

    H_exact(term < 0) = exp(-k_eff * p.z_sample .* ...
        sqrt(-term(term < 0)));

    U_obj_film = ifft2(fft2(U_obj_sample) .* fftshift(H_exact));

    %% Conventional QPM baseline through diffraction-limited pupil
    f_cutoff_QPM = p.NA_SIM / p.lambda;
    FR = sqrt(FX.^2 + FY.^2);
    pupil_soft_width = 0.06 * f_cutoff_QPM;
    Pupil = 0.5 * (1 - tanh((FR - f_cutoff_QPM) / pupil_soft_width));
    U_obj_traditional = ifft2(fft2(U_obj_sample) .* fftshift(Pupil));

    %% Four phase-shifted holograms
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
end
