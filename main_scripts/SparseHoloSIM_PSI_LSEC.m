%% ========================================================================
% MATLAB script:
% QPM / Sparse QPM / HoloSIM / Sparse HoloSIM on the synthetic LSEC target.
% Four PSI frames share one SIM calibration. No quantitative metrics.
%% ========================================================================
clear all; close all; clc;
task_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(task_dir);
addpath(genpath(fullfile(project_root, 'function')));
addpath(fullfile(project_root, 'function', 'SIM'), '-begin');


try
    parallel.gpu.enableCUDAForwardCompatibility(true);
    gpuDevice;
    fprintf('CUDA forward compatibility enabled.\n');
catch ME
    warning('GPU forward compatibility failed: %s', ME.message);
end



%% 1. Parameters
fprintf('>>> Step 1: define parameters for PSI-only LESC comparison\n');
params.N = 1024;
params.dx = 32.5e-9;
params.dy = 32.5e-9;
params.lambda = 405e-9;
params.SIM_lambda = 488e-9;
params.NA_SIM = 1.2;
params.NA_WF = 1.2;
params.z_sample = 10e-9;
params.noise_level = 0.3;
params.save_path = fullfile(task_dir, 'results', 'SparseHoloSIM_PSI_LSEC');

% Synthetic LESC target parameters copied from EXP2_5.
params.lesc.phase_model = 'synthetic LESC phase-amplitude target';
params.lesc.background_amp = 0.5;
params.lesc.cell_amp = 0.8;
params.lesc.rim_amp = 0.95;
params.lesc.phase_smooth_sigma_px = 0.5;
params.lesc.sem_grain_noise = 0.08;
params.lesc.wrinkle_height_factor = 0.45;
params.lesc.amp_noise_level = 0.02;
params.lesc.sieve_pore_radius_px = [3.0 3.0];

% Reconstruction controls for LESC-like phase-amplitude targets.
params.recon.use_reference_masks = true;
params.recon.bg_dilate_px = 14;
params.recon.use_unwrap = false;
params.recon.phase_frame_balance = false;
params.recon.robust_background_fit = true;
params.recon.set_outer_background_to_zero = true;
params.recon.background_fit_order = 'plane';
params.recon.holo_denoise_sigma_px = 0.20;
params.recon.destripe_SIM_holograms = true;
params.recon.holo_destripe_strength = 0.85;
params.recon.holo_destripe_smooth_px = 61;
params.recon.destripe_SIM_phase = true;
params.recon.phase_destripe_strength = 0.80;
params.recon.phase_destripe_smooth_px = 71;

% Sparse refinement controls. Sparse is applied only to demodulated complex
% carriers/object waves, never to the raw PSI frames or raw off-axis holograms.
% WF is kept unsparsified as the wide-field baseline.
params.sparse.enable_WF = false;
params.sparse.enable_PSI = true;
params.sparse.enable_offaxis = false; % off-axis branch disabled
params.sparse.fidelity = 30;
params.sparse.fidelity_z = 1;
params.sparse.sparsity = 5;
params.sparse.backg = 0;
params.sparse.iter = 20;
params.sparse.sigma_low_psi_px = 1.0;      % PSI: low-pass scale for complex residual sparse refinement
params.sparse.sigma_low_offaxis_px = 1.0;  % Off-axis: use an independent residual low-pass scale
params.sparse.blend_psi = 1;
params.sparse.blend_offaxis = 1;
params.sparse.debug = false;

% Export intermediate Sparse-HoloSIM workflow materials for manual figure assembly.
% These are saved only for the four-step PSI Sparse-HoloSIM branch.
params.sparse.save_workflow_materials = true;
params.sparse.workflow_export_branch = 'PSI sparse';
params.sparse.workflow_dir = fullfile(params.save_path, 'Sparse_HoloSIM_workflow_materials');
params.sparse.workflow_export_png = true;
params.sparse.workflow_export_pdf = false;
params.sparse.workflow_export_fig = false;

% SIM settings for the active four-step PSI HoloSIM branch.
params.sim.illum_period_nm = 250;
params.sim.snr = 20;

% Display and ROI parameters copied from EXP2_5.
params.display.roi_center_um = [-4.6, 8.7];
params.display.roi_halfwidth_um = 4.0;
params.display.show_scalebar = false;
params.display.full_scalebar_um = 10;
params.display.roi_scalebar_um = 2;
params.display.overlay_color = [1 1 1];
params.display.show_colorbar = true;
params.display.phase_clim_mode = 'manual';
params.display.phase_clim_percentile = [0.5 99.5];
params.display.phase_clim_manual = [-0.10 1.60];

% Figure style.
params.plot.font_name = 'Times New Roman';
params.plot.font_size_axis = 11;
params.plot.font_size_label = 12;
params.plot.font_size_title = 13;
params.plot.font_size_sgtitle = 14;
params.plot.font_size_legend = 10;
params.plot.line_width = 2.0;
params.plot.line_width_light = 1.4;
params.plot.line_width_heavy = 2.4;
params.plot.axis_line_width = 1.1;
params.plot.grid_alpha = 0.16;
params.plot.export_dpi = 600;
params.plot.export_png = true;
params.plot.export_pdf = false;
params.plot.export_fig = false;
% Large composite 1024x1024 tiled figures are not auto-exported by default.
% Individual phase PNGs and the common colorbar are still exported.
params.plot.auto_export_figures = false;
params.plot.make_diagnostic_figures = false; % skip large before/after/error/improvement tiled figures

% Export each key result as a clean standalone phase image for manual layout.
% The exported maps contain only the full-cell phase image itself (no axes, no
% embedded colorbar). A single unified phase colorbar is exported separately.
params.plot.export_individual_results = true;
params.plot.individual_export_png = true;
params.plot.individual_export_pdf = false;
params.plot.individual_export_fig = false;


% Four-step PSI settings.
params.phase_shifts = [0, pi/2, pi, 3*pi/2];
phase_shift_names = {'0', '90', '180', '270'};
params.psi.theta_deg = 180;
params.psi.alpha = 0;

% Off-axis settings retained only for archival reproducibility.
% The off-axis reconstruction branch is disabled in this fast PSI-only version.
params.offaxis.enable = false;
params.offaxis.theta_deg = 110;
params.offaxis.alpha_list = [0, pi/2];
params.offaxis.alpha_names = {'Off-axis alpha 0^\circ', 'Off-axis alpha 90^\circ'};
params.offaxis.filter_multi0 = 0.8;
params.offaxis.filter_multi = 2;

if ~exist(params.save_path, 'dir')
    mkdir(params.save_path);
end
if isfield(params, 'sparse') && isfield(params.sparse, 'save_workflow_materials') && params.sparse.save_workflow_materials
    if ~exist(params.sparse.workflow_dir, 'dir')
        mkdir(params.sparse.workflow_dir);
    end
end

set(groot, ...
    'defaultFigureVisible', 'on', ...
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
    'defaultAxesBox', 'on', ...
    'defaultAxesLayer', 'top');

%% 2. Four-step PSI SIM-QPM branch on LESC
fprintf('>>> Step 2: run four-step PSI SIM-QPM pipeline on LESC\n');
params_psi = params;
params_psi.alpha = params.psi.alpha;
params_psi.fx_ref = sin(deg2rad(params.psi.theta_deg)) / params.lambda;
if abs(params_psi.fx_ref) < 1e-6
    params_psi.fx_ref = 0;
end
[I_phase4, GT_ref, I_trad_phase4] = GetFringeSet_FourPhase2(params_psi);

% Provide reference masks to reconstruction/background fitting. These masks are
% used only for background estimation and display cleanup, not for overwriting
% internal pores or LESC structures.
params_psi.recon.mask_cell = GT_ref.mask_cell;
% Use a hole-filled cell mask for background fitting. This prevents internal
% pores from being treated as external background.
params_psi.recon.bg_fit_mask = ~imdilate(imfill(GT_ref.mask_cell, 'holes'), strel('disk', params_psi.recon.bg_dilate_px));

norm_factor_phase4 = max(I_phase4(:));
% Calibrate once on the actual 0-degree SIM raw stack; reuse its separation
% coefficients, frequency shifts, object-power parameters and merge weights.
[Dsum_phase4, simParams] = SIM_ReconstructPSISharedParams( ...
    I_phase4 / norm_factor_phase4, params_psi);
for kk = 1:4
    Dsum_phase4(:,:,kk) = SIM_PostprocessSIMHologram(Dsum_phase4(:,:,kk), params_psi);
end
% Run PSI demodulation twice to keep an explicit sparse-before/sparse-after pair.
params_psi_raw = params_psi;
params_psi_raw.recon.enable_complex_sparse = false;
params_psi_raw.sparse = params.sparse;
params_psi_raw.sparse.sigma_low_px = params.sparse.sigma_low_psi_px;
params_psi_raw.sparse.branch = 'PSI raw';

params_psi_sparse = params_psi;
params_psi_sparse.recon.enable_complex_sparse = params.sparse.enable_PSI;
params_psi_sparse.sparse = params.sparse;
params_psi_sparse.sparse.blend = params.sparse.blend_psi;
params_psi_sparse.sparse.sigma_low_px = params.sparse.sigma_low_psi_px;
params_psi_sparse.sparse.branch = 'PSI sparse';

[phase_SIM_PSI_raw, amplitude_SIM_PSI_raw, object_wave_SIM_PSI_raw] = PSI_DemodulatePhaseShift4(Dsum_phase4, params_psi_raw);
[phase_SIM_PSI, amplitude_SIM_PSI, object_wave_SIM_PSI] = PSI_DemodulatePhaseShift4(Dsum_phase4, params_psi_sparse);
%% 3. Wide-field PSI baseline
fprintf('>>> Step 3: run wide-field four-step QPM baseline\n');
I_trad_65nm_phase4 = zeros(params.N/2, params.N/2, 4);
for kk = 1:4
    I_trad_65nm_phase4(:,:,kk) = imresize(I_trad_phase4(:,:,kk), 0.5, 'bicubic', 'Antialiasing', true);
end
params_65nm = params_psi;
params_65nm.dx = params.dx * 2;
params_65nm.dy = params.dy * 2;
params_65nm.N = params.N / 2;
params_65nm.recon.mask_cell = imresize(double(params_psi.recon.mask_cell), [params.N/2, params.N/2], 'nearest') > 0.5;
params_65nm.recon.mask_cell = imresize(double(params_psi.recon.mask_cell), [params.N/2, params.N/2], 'nearest') > 0.5;
params_65nm.recon.bg_fit_mask = imresize(double(params_psi.recon.bg_fit_mask), [params.N/2, params.N/2], 'nearest') > 0.5;
params_65nm.recon.enable_complex_sparse = false;
params_65nm.sparse = params.sparse;
params_65nm.sparse.sigma_low_px = params.sparse.sigma_low_psi_px;
params_65nm.sparse.blend = params.sparse.blend_psi;
params_65nm.sparse.branch = 'Conventional QPM';

params_65nm_sparse = params_65nm;
params_65nm_sparse.recon.enable_complex_sparse = true;
params_65nm_sparse.sparse.branch = 'Sparse QPM';

[phase_WF_65nm, amplitude_WF_65nm, object_wave_WF_65nm] = PSI_DemodulatePhaseShift4(I_trad_65nm_phase4, params_65nm);
[phase_WF_sparse_65nm, amplitude_WF_sparse_65nm, object_wave_WF_sparse_65nm] = PSI_DemodulatePhaseShift4(I_trad_65nm_phase4, params_65nm_sparse);
phase_WF = imresize(phase_WF_65nm, [params.N, params.N], 'bicubic');
amplitude_WF = imresize(amplitude_WF_65nm, [params.N, params.N], 'bicubic');
phase_WF_sparse = imresize(phase_WF_sparse_65nm, [params.N, params.N], 'bicubic');
amplitude_WF_sparse = imresize(amplitude_WF_sparse_65nm, [params.N, params.N], 'bicubic');

%% 4. Background alignment
fprintf('>>> Step 4: align zero background for QPM and HoloSIM branches\n');
bg_ref_mask = params_psi.recon.bg_fit_mask;
mask_cell = GT_ref.mask_cell;

GT_phi              = GT_ref.phi - mean(GT_ref.phi(bg_ref_mask), 'omitnan');
phase_WF            = phase_WF - mean(phase_WF(bg_ref_mask), 'omitnan');
phase_WF_sparse     = phase_WF_sparse - mean(phase_WF_sparse(bg_ref_mask), 'omitnan');
phase_SIM_PSI_raw   = phase_SIM_PSI_raw - mean(phase_SIM_PSI_raw(bg_ref_mask), 'omitnan');
phase_SIM_PSI       = phase_SIM_PSI - mean(phase_SIM_PSI(bg_ref_mask), 'omitnan');

% Optional stripe correction is retained only for the HoloSIM PSI maps.
if params.recon.destripe_SIM_phase
    phase_SIM_PSI_raw = PSI_RemoveColumnStripeBias_Sparse(phase_SIM_PSI_raw, bg_ref_mask, ...
        params.recon.phase_destripe_smooth_px, params.recon.phase_destripe_strength);
    phase_SIM_PSI = PSI_RemoveColumnStripeBias_Sparse(phase_SIM_PSI, bg_ref_mask, ...
        params.recon.phase_destripe_smooth_px, params.recon.phase_destripe_strength);
    phase_SIM_PSI_raw = phase_SIM_PSI_raw - mean(phase_SIM_PSI_raw(bg_ref_mask), 'omitnan');
    phase_SIM_PSI = phase_SIM_PSI - mean(phase_SIM_PSI(bg_ref_mask), 'omitnan');
end

if params.recon.set_outer_background_to_zero
    % Only zero true external background; preserve pores inside the cell.
    outer_bg_mask = PSI_GetOuterBackgroundOnlyMask(GT_ref.mask_cell);
    GT_phi(outer_bg_mask) = 0;
    phase_WF(outer_bg_mask) = 0;
    phase_WF_sparse(outer_bg_mask) = 0;
    phase_SIM_PSI_raw(outer_bg_mask) = 0;
    phase_SIM_PSI(outer_bg_mask) = 0;
end


%% 5. Crop phase maps for display
fprintf('>>> Step 5: crop phase maps for display\n');
[GT_roi, crop_rect, cx_roi, cy_roi] = PSI_CropWindowByCenterUm(GT_phi, params, params.display.roi_center_um, params.display.roi_halfwidth_um);
[WF_roi, ~, ~, ~] = PSI_CropWindowByCenterUm(phase_WF, params, params.display.roi_center_um, params.display.roi_halfwidth_um);
[WF_sparse_roi, ~, ~, ~] = PSI_CropWindowByCenterUm(phase_WF_sparse, params, params.display.roi_center_um, params.display.roi_halfwidth_um);
[PSI_raw_roi, ~, ~, ~] = PSI_CropWindowByCenterUm(phase_SIM_PSI_raw, params, params.display.roi_center_um, params.display.roi_halfwidth_um);
[PSI_roi, ~, ~, ~] = PSI_CropWindowByCenterUm(phase_SIM_PSI, params, params.display.roi_center_um, params.display.roi_halfwidth_um);

%% 6. Compact phase-map comparison figure
fprintf('>>> Step 6: generate compact PSI/QPM map comparison figure\n');
[cmin, cmax] = PSI_DeterminePhaseDisplayCLim(GT_phi, phase_WF, phase_SIM_PSI, params);

map_full = {GT_phi, phase_WF, phase_WF_sparse, phase_SIM_PSI_raw, phase_SIM_PSI};
map_roi = {GT_roi, WF_roi, WF_sparse_roi, PSI_raw_roi, PSI_roi};
col_titles = {'Ground truth', 'Conventional QPM', 'Sparse QPM', 'HoloSIM', 'Sparse HoloSIM'};
title_colors = {'k', 'k', '#777777', '#c44e52', '#c44e52'};

h_map = figure('Name', 'LESC PSI/QPM map comparison', ...
               'Color','w','Position',[20 50 1600 760], 'InvertHardcopy','off');
colormap(h_map, "jet");
T_map = tiledlayout(2,5,'Padding','compact','TileSpacing','compact');
title(T_map, 'Four-step PSI HoloSIM and baseline comparison on synthetic LESC target', ...
    'FontName', params.plot.font_name, 'FontSize', params.plot.font_size_sgtitle, ...
    'FontWeight', 'bold', 'Color', 'k');

for rr = 1:2
    for cc = 1:5
        ax = nexttile(T_map);
        if rr == 1
            img_to_show = map_full{cc};
        else
            img_to_show = map_roi{cc};
        end
        imagesc(ax, PSI_ClipPhaseForDisplay(img_to_show, cmin, cmax, params));
        axis(ax, 'image');
        caxis(ax, [cmin cmax]);
        PSI_FormatImageAxes(ax, params.plot);
        hold(ax, 'on');
        if rr == 1
            title(ax, col_titles{cc}, 'FontName', params.plot.font_name, ...
                'FontSize', params.plot.font_size_title, ...
                'FontWeight', PSI_ternary(ismember(cc,[3 5]), 'bold', 'normal'), ...
                'Color', title_colors{cc}, 'Interpreter', 'tex');
            PSI_OverlayCropRectangle(ax, crop_rect, params.display.overlay_color, params.plot.line_width_light);
        end
        if cc == 1
            if rr == 1
                ylabel(ax, 'Full FOV', 'FontName', params.plot.font_name, ...
                    'FontSize', params.plot.font_size_label, 'FontWeight', 'bold');
            else
                ylabel(ax, 'Selected ROI', 'FontName', params.plot.font_name, ...
                    'FontSize', params.plot.font_size_label, 'FontWeight', 'bold');
            end
        end
    end
end

if params.display.show_colorbar
    cb_map = colorbar;
    try, cb_map.Layout.Tile = 'east'; catch, end
    ylabel(cb_map, 'Phase (rad)', 'FontName', params.plot.font_name, 'FontSize', params.plot.font_size_label);
    PSI_FormatNatureColorbar(cb_map, params.plot);
end
PSI_ApplyPublicationStyle_Sparse(h_map, params.plot);
set(h_map, 'Visible', 'on'); figure(h_map);
drawnow limitrate nocallbacks;

%% 6b. Optional lightweight diagnostic figures
% Disabled by default because the former 12/13-column 1024x1024 tiled figures
% consume substantial graphics memory and are the main source of UI stalls.
h_sparse = gobjects(0); h_err = gobjects(0); h_improve = gobjects(0);
if isfield(params.plot, 'make_diagnostic_figures') && params.plot.make_diagnostic_figures
    fprintf('>>> Step 6b: generate reduced four-method sparse diagnostics\n');
    sparse_full = {phase_WF, phase_WF_sparse, phase_SIM_PSI_raw, phase_SIM_PSI};
    sparse_roi = {WF_roi, WF_sparse_roi, PSI_raw_roi, PSI_roi};
    sparse_titles = {'QPM', 'Sparse QPM', 'HoloSIM', 'Sparse HoloSIM'};

    h_sparse = figure('Name','LESC four-method sparse comparison','Color','w','Position',[20 80 1900 720]);
    colormap(h_sparse,'jet');
    Ts = tiledlayout(2,4,'Padding','compact','TileSpacing','compact');
    for rr = 1:2
        for cc = 1:4
            ax = nexttile(Ts);
            if rr == 1, tmp = sparse_full{cc}; else, tmp = sparse_roi{cc}; end
            imagesc(ax, PSI_ClipPhaseForDisplay(tmp,cmin,cmax,params)); axis(ax,'image'); caxis(ax,[cmin cmax]);
            PSI_FormatImageAxes(ax,params.plot);
            if rr == 1, title(ax,sparse_titles{cc},'Interpreter','none'); end
        end
    end
    drawnow limitrate nocallbacks;
end

%% 7. Save reconstruction results
fprintf('>>> Step 7: save reconstruction maps\n');
result_mat = fullfile(params.save_path, 'PSI_LESC_reconstruction_results.mat');
save(result_mat, ...
    'params', 'simParams', 'GT_phi', 'GT_ref', ...
    'phase_WF', 'phase_WF_sparse', 'phase_SIM_PSI_raw', 'phase_SIM_PSI', ...
    'amplitude_SIM_PSI_raw', 'amplitude_SIM_PSI', 'amplitude_WF', 'amplitude_WF_sparse', ...
    'object_wave_SIM_PSI_raw', 'object_wave_SIM_PSI', 'object_wave_WF_65nm', 'object_wave_WF_sparse_65nm', ...
    'Dsum_phase4', 'I_phase4', 'I_trad_phase4', ...
    'GT_roi', 'WF_roi', 'WF_sparse_roi', 'PSI_raw_roi', 'PSI_roi', ...
    'mask_cell', 'bg_ref_mask', 'crop_rect', 'cx_roi', 'cy_roi', 'cmin', 'cmax', '-v7.3');
fprintf('    saved MAT: %s\n', result_mat);

% Export clean standalone phase panels. Raster phase maps are written as PNG;
% The same phase range and standalone colorbar are retained.
if isfield(params.plot, 'export_individual_results') && params.plot.export_individual_results
    individual_dir = fullfile(params.save_path, 'Individual_result_panels');
    if ~exist(individual_dir, 'dir'), mkdir(individual_dir); end
    individual_full_maps = {GT_phi, phase_WF, phase_WF_sparse, phase_SIM_PSI_raw, phase_SIM_PSI};
    individual_names = {'GroundTruth', 'Conventional_QPM', 'Sparse_QPM', 'HoloSIM', 'Sparse_HoloSIM'};
    individual_titles = {'Ground truth', 'Conventional QPM', 'Sparse QPM', 'HoloSIM', 'Sparse HoloSIM'};
    PSI_ExportIndividualPhasePanels(individual_full_maps, individual_names, individual_titles, ...
        cmin, cmax, params, individual_dir);
    PSI_ExportStandalonePhaseColorbar(fullfile(individual_dir, 'Unified_phase_colorbar'), cmin, cmax, params);
end

% Do not auto-export the large composite map by default. If explicitly enabled,
if isfield(params.plot, 'auto_export_figures') && params.plot.auto_export_figures
    PSI_ExportPublicationFigure(h_map, fullfile(params.save_path, 'PSI_LESC_map_comparison'), params.plot);
    if ~isempty(h_sparse) && isgraphics(h_sparse)
        PSI_ExportPublicationFigure(h_sparse, fullfile(params.save_path, 'PSI_LESC_sparse_comparison'), params.plot);
    end
else
    fprintf('    large composite auto-export disabled to avoid MATLAB graphics stalls.\n');
end

fprintf('>>> Done. PSI-only LESC comparison finished.\n');

%% ========================================================================
% Helper functions
%% ========================================================================




function [I_phase4, ground_truth, I_traditional_QPM_phase4] = GetFringeSet_FourPhase2(p)
    rng(1024);
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
    mask_cell = mask_cell & ~all_holes_final;

    phi_object = zeros(p.N);
    phi_object(mask_cell) = phi_combined(mask_cell);

    sem_grain_noise = p.lesc.sem_grain_noise * randn(p.N);
    phi_object(mask_cell) = phi_object(mask_cell) + sem_grain_noise(mask_cell);

    noise_base = imgaussfilt(randn(p.N), 8.0);
    turbulence = imgaussfilt(randn(p.N), 3.0);
    wrinkle_pattern = abs(noise_base + 0.2*turbulence);
    wrinkle_pattern = max(wrinkle_pattern(:)) - wrinkle_pattern;
    wrinkle_pattern(wrinkle_pattern < 0.6 * max(wrinkle_pattern(:))) = 0;
    modulation = imgaussfilt(rand(p.N), 10.0);
    wrinkle_pattern = wrinkle_pattern .* modulation;
    wrinkle_layer = wrinkle_pattern * p.lesc.wrinkle_height_factor;
    phi_object(mask_cell) = phi_object(mask_cell) + wrinkle_layer(mask_cell);

    dist_cell_edge = bwdist(~mask_cell);
    is_outer_rim = (dist_cell_edge > 0) & (dist_cell_edge <= 3);
    phi_object(is_outer_rim) = phi_object(is_outer_rim) * 1.1 + 0.1;
    phi_object = imgaussfilt(phi_object, p.lesc.phase_smooth_sigma_px);
    phi_object(~mask_cell) = 0;

    fprintf('>>> LESC Ground Truth phase range: [%.4f, %.4f] rad\n', min(phi_object(:)), max(phi_object(:)));

    fprintf('   - [LESC Step 6] Generating four phase-shifted holograms...\n');
    background_amp = p.lesc.background_amp;
    cell_amp = p.lesc.cell_amp;
    rim_amp = p.lesc.rim_amp;

    amp_gt = ones(p.N) * background_amp;
    amp_gt(mask_cell) = cell_amp;
    amp_gt(is_outer_rim) = rim_amp;
    amp_gt(~mask_cell) = background_amp;
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
    Pupil = double(sqrt(FX.^2 + FY.^2) <= f_cutoff_QPM);

    % f_cutoff_QPM = p.NA_SIM / p.lambda;
    % Pupil = double(sqrt(FX.^2 + FY.^2) <= f_cutoff_QPM);
    U_obj_traditional = ifft2(fft2(U_obj_sample) .* fftshift(Pupil));

    I_film_clean = zeros(p.N,p.N,4);
    I_phase4 = zeros(p.N, p.N, 4);
    I_traditional_QPM_phase4 = zeros(p.N, p.N, 4);
    for idx_ps = 1:4
        delta = p.phase_shifts(idx_ps);
        U_ref_shifted = U_ref_base .* exp(1i * delta);

        I_perfect = abs(U_obj_film + U_ref_shifted).^2;
        I_film_clean(:,:,idx_ps)=I_perfect;
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
    ground_truth.I_film_clean=I_film_clean;
    ground_truth.U_film=U_obj_film;
    ground_truth.x = x;
    ground_truth.y = y;
    ground_truth.mask_cell = mask_cell;
    ground_truth.mask_cell = mask_cell;
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
