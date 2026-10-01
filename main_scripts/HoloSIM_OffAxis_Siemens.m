%% ========================================================================
%  FINAL VERSION: fixed phase colorbar [0,1.2] rad, yellow-green Nature colormap, Arial colorbar
%  ：single-frame offaxis + SIM
% ========================================================================
clear all; close all; clc;
task_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(task_dir);
addpath(genpath(fullfile(project_root, 'function')));


%% 1. parameter
fprintf('>>> Process: Define parameters \n');
params.N = 1024;                 % image pixel
params.dx = 32.5e-9;             % pixel size (m)
params.dy = 32.5e-9;             
params.lambda = 405e-9; 
params.SIM_lambda = 488e-9;
params.save_path = fullfile(task_dir, 'results', 'HoloSIM_Offaixs_Siemens');
params.noise_level = 0.01;       
params.NA_SIM = 1.2;   
params.dx_gt = 2.5e-9;   %only use for generating samples

% -------------------------------------------------------------------------
% Reconstruction / export control
% -------------------------------------------------------------------------
params.recon.bg_fit_order = 'plane';          
params.recon.bg_margin_px = 30;               % 离星靶外边界的背景安全距离
params.recon.carrier_search_radius_px = 6;    % 离轴 +1 级局部寻峰范围
params.recon.remove_debug_figures = true;     % 不再保存调试频谱 figure，避免 MATLAB 图窗卡顿
params.recon.force_positive_core = true;      % 自动修正 off-axis 相位整体符号
params.recon.use_phase_unwrap = false;          % Siemens star phase step < pi; skipping unwrap avoids spoke deformation
params.recon.offaxis_multi_to_dc_SIM = 1.00;    % +1 order filter radius toward DC; must be < 1 to avoid zero-order leakage
params.recon.offaxis_multi_ortho_SIM = 1.80;    % filter extension perpendicular/away from DC for off-axis anisotropic bandwidth
params.recon.offaxis_multi_to_dc_WF  = 0.60;    % conservative WF off-axis extraction
params.recon.offaxis_multi_ortho_WF  = 1.15;

% SIM 重建流程：保留原始 PCMseparateF + PCMfilteringF + MergingHeptaletsF 流程
% 不使用已知 k-vector / 已知频谱直接重建。
params.sim.use_known_params = false;
params.sim.pixel_size_nm = params.dx * 1e9;
params.sim.illum_period_nm = 300;
params.sim.snr = 20;                           % 保留原始代码设置；如需降噪可手动调高到 60
params.sim.mod_factor = 0.8;                   % 保留原始代码设置
params.sim.downsample_scale = 0.5;


params.plot.enable_figure_export = false;
params.plot.save_direct_png_tif = true;
params.plot.save_intermediate_png = true;

% Direct-imwrite analysis panels, following the previous HoloSIM/QPM style.
% These do not call print/exportgraphics/getframe/saveas.
params.plot.make_direct_analysis = true;
params.plot.make_phase_retention_curve = true;
params.plot.retention_thresholds = [0.10, 0.20, 0.50];
params.plot.retention_xmax_nm = 1200;
params.plot.retention_ylim = [0, 1.05];
params.plot.use_figure_for_resolution_curve = true;  % resolution curve uses MATLAB figure + Arial text; image panels still use direct imwrite
params.plot.make_siemens_twotone = true;
params.plot.siemens_dark_color   = [10, 61, 73] / 255;     % dark teal background
params.plot.siemens_bright_color = [252, 239, 196] / 255;  % warm cream Siemens bars
params.plot.phase_cmap_mode = 'nature_teal_cream';              % Nature teal-cream phase map, replacing rainbow jet
params.plot.use_fixed_phase_clim = true;                      % fixed display range for all phase maps and ROI panels
params.plot.fixed_phase_clim = [0, 1.2];                      % Phase colorbar range (rad)
params.plot.fixed_phase_ticks = [0, 0.4, 0.8, 1.2];           % Phase colorbar ticks (rad)
params.plot.use_figure_for_colorbar = true;                   % standalone colorbar uses MATLAB figure + Arial; fallback is raster text
params.plot.roi_fullpitch_nm = 200;      % ROI centered on this Siemens full-pitch ring
params.plot.roi_theta_deg = 0;           % ROI angular position on the ring
params.plot.roi_size_px = 240;           % square ROI size in pixels
params.plot.direct_panel_px = 720;
params.plot.direct_gap_px = 20;

% Siemens star 相位靶标参数：用于分辨率标定
params.siemens.num_spokes = 72;          % 总扇区数，必须为偶数；线对数 = num_spokes/2
params.siemens.radius_frac = 0.78;       % 星靶半径，占半视场比例
params.siemens.inner_radius = 300e-9;    % 中心奇点保护半径，不参与分辨率判读
params.siemens.phase_step = 1.0;         % 相位台阶高度(rad)
params.siemens.supersample = 4;          % GT 生成时的像素内超采样倍数，建议 4 或 8
params.siemens.edge_sigma_px = 0.0;      % supersampling 已抗锯齿，避免额外平滑导致 GT 变钝      % 使用 supersampling 后通常不再需要额外高斯平滑
params.siemens.add_calib_rings = false;  % 标定环只叠加显示，不写入 GT 相位，避免干扰定量
params.siemens.display_fullpitch_nm = [200];  % 手动设置要展示的 full-pitch 分辨率曲线(nm)
params.siemens.res_threshold = 0.10;                 % 推荐 10% modulation retention 作为分辨率阈值                  % full-pitch 可分辨阈值，可手动调整

% -------------------------------------------------------------------------
% Publication-quality figure style
% -------------------------------------------------------------------------
params.plot.font_name = 'Arial';
params.plot.font_size_axis = 11;
params.plot.font_size_label = 12;
params.plot.font_size_title = 13;
params.plot.font_size_sgtitle = 14;
params.plot.font_size_legend = 10;
params.plot.line_width = 2.0;
params.plot.line_width_light = 1.6;
params.plot.line_width_heavy = 2.4;
params.plot.axis_line_width = 1.1;
params.plot.grid_alpha = 0.16;
params.plot.export_dpi = 600;
params.plot.export_png = false;
params.plot.export_pdf = false;
params.plot.export_fig = false;

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
    'defaultAxesBox', 'on', ...
    'defaultAxesLayer', 'top');
% 确保保存路径存在
if ~exist(params.save_path, 'dir')
    mkdir(params.save_path);
end

% -------------------------------------------------------------------------
% Fixed phase display setting shared by all phase maps, ROI panels, and colorbars
% -------------------------------------------------------------------------
cmap_phase = OA_GetPhaseColormap(params);
if isfield(params.plot, 'use_fixed_phase_clim') && params.plot.use_fixed_phase_clim
    clim_phase = params.plot.fixed_phase_clim;
    phase_ticks = params.plot.fixed_phase_ticks;
else
    clim_phase = [0, 1.2];
    phase_ticks = [0, 0.4, 0.8, 1.2];
end

theta_deg = 110; % 固定极角
params.fx_ref = sin(deg2rad(theta_deg)) / params.lambda;

% 定义要自动跑的两个正交离轴参考方向。
% 注意：这里的名称按 "可扩展频带方向" 命名，而不是按 carrier 偏移方向命名。
% alpha = 0 deg: carrier 位于 fx 轴，沿 fx 方向受 0 级限制，fy 方向可扩展更多 -> Y-frequency enhanced。
% alpha = 90 deg: carrier 位于 fy 轴，沿 fy 方向受 0 级限制，fx 方向可扩展更多 -> X-frequency enhanced。
alpha_list = [0, pi/2];
alpha_names = {'alpha0_Yfreq_enhance', 'alpha90_Xfreq_enhance'};
phase_SIM_results = cell(1, 2); % 存储两个方向的解调相位

%% 2. 自动循环跑完两个正交方向
for idx_a = 1:2
    params.alpha = alpha_list(idx_a);
    fprintf('\n======================================================\n');
    fprintf('>>> 正在处理第 %d/2 路：alpha = %.1f 度 (%s)\n', idx_a, rad2deg(params.alpha), alpha_names{idx_a});
    fprintf('======================================================\n');
    
    % --- 2.1 生成靶标与全息图 ---
    params.z_sample = 10e-9; 
    [I_single, ground_truth, I_traditional_QPM] = GetFringeSet_SingleFrame2(params); 
    
    % 如果是第一次循环，保存一份传统 WF 全息图的数据供后续对比
    if idx_a == 1
        I_traditional_QPM_ref = I_traditional_QPM;
        GT_ref = ground_truth;
        OA_PrintSiemensCalibrationInfo(GT_ref);
    end
    
    % --- 2.2 SIM 仿真调制 ---
    w = params.N;
    pixel_size = params.sim.pixel_size_nm;
    illum_period = params.sim.illum_period_nm;
    SNR = params.sim.snr;
    NoiseLevel = 100 / SNR;
    lambda_nm = params.SIM_lambda * 1e9;
    [PSFo,~] = PsfOtf(w, params.NA_SIM);
    fc = pixel_size * (2 * params.NA_SIM * w) / lambda_nm;
    OTFo = OTF(w, w, 0, 0, fc);
    
    Io = zeros(w, w);
    Io(1:w, 1:w) = I_single / max(I_single(:));
    DIo = double(Io);
    
    k2 = w * pixel_size / illum_period;
    ModFac = params.sim.mod_factor;
    [S1a, S2a, S3a, S1b, S2b, S3b, S1c, S2c, S3c, ~, ~] = SIMimagesF(k2, DIo, PSFo, OTFo, ModFac, NoiseLevel, 0);
    
    % --- 2.3 SIM 重建部分 ---
    scale = params.sim.downsample_scale;
    S1a_d = imresize(S1a, scale, 'bicubic', 'Antialiasing', true);
    S2a_d = imresize(S2a, scale, 'bicubic', 'Antialiasing', true);
    S3a_d = imresize(S3a, scale, 'bicubic', 'Antialiasing', true);
    S1b_d = imresize(S1b, scale, 'bicubic', 'Antialiasing', true);
    S2b_d = imresize(S2b, scale, 'bicubic', 'Antialiasing', true);
    S3b_d = imresize(S3b, scale, 'bicubic', 'Antialiasing', true);
    S1c_d = imresize(S1c, scale, 'bicubic', 'Antialiasing', true);
    S2c_d = imresize(S2c, scale, 'bicubic', 'Antialiasing', true);
    S3c_d = imresize(S3c, scale, 'bicubic', 'Antialiasing', true);
    
    OTFo_recon = OTF(w*scale, w*scale, 0, 0, fc);

    fprintf('    -> SIM reconstruction uses original PCMseparateF + PCMfilteringF + MergingHeptaletsF flow.\n');
    [fAo,fAp,fAm,kA] = PCMseparateF(S1a_d, S2a_d, S3a_d, OTFo_recon);
    [fBo,fBp,fBm,kB] = PCMseparateF(S1b_d, S2b_d, S3b_d, OTFo_recon);
    [fCo,fCp,fCm,kC] = PCMseparateF(S1c_d, S2c_d, S3c_d, OTFo_recon);
    fCent = (fAo + fBo + fCo)/3;
    OBJparaA = OBJpowerPara(fCent, OTFo_recon);

    [fAof,fApf,fAmf,~,~,~,Ma,DoubleMatSize] = PCMfilteringF(fAo,fAp,fAm,OTFo_recon,OBJparaA,kA);
    [fBof,fBpf,fBmf,~,~,~,Mb,~]             = PCMfilteringF(fBo,fBp,fBm,OTFo_recon,OBJparaA,kB);
    [fCof,fCpf,fCmf,~,~,~,Mc,~]             = PCMfilteringF(fCo,fCp,fCm,OTFo_recon,OBJparaA,kC);
    OTFo_double = OTFdoubling(OTFo_recon, DoubleMatSize);

    [Fsum,~,~] = MergingHeptaletsF(fAof,fApf,fAmf, fBof,fBpf,fBmf, fCof,fCpf,fCmf,...
                                   Ma,Mb,Mc, 1,1,1, 1,1,1, 1,1,1, kA,kB,kC, OBJparaA, OTFo_double);
    Dsum = real(ifft2(fftshift(Fsum)));

    % --- 2.4 对本路结果进行 QPM 相位解调 ---
    fprintf('    -> 正在解调 %s 的相位...\n', alpha_names{idx_a});
    [phase_SIM, ~] = OA_DemodulatePhase2(Dsum, params, params.recon.offaxis_multi_to_dc_SIM, params.recon.offaxis_multi_ortho_SIM);
    
    % 存入元胞数组
    phase_SIM_results{idx_a} = phase_SIM;
    % --- 2.5 保存当前方向的中间结果 ---
    fprintf('    -> 正在保存 %s 的中间数据...\n', alpha_names{idx_a});
    
    % (1) 保存 Raw SIM 原始全息图
    save(fullfile(params.save_path, sprintf('Raw_SIM_%s.mat', alpha_names{idx_a})), 'I_single');
    if params.plot.save_intermediate_png
        imwrite(mat2gray(I_single), fullfile(params.save_path, sprintf('Raw_SIM_%s.png', alpha_names{idx_a})));
    end
    
    % (2) 保存 Heptalets 重建后的 SIM 全息图
    save(fullfile(params.save_path, sprintf('Recon_Holo_%s.mat', alpha_names{idx_a})), 'Dsum');
    if params.plot.save_intermediate_png
        imwrite(mat2gray(Dsum), fullfile(params.save_path, sprintf('Recon_Holo_%s.png', alpha_names{idx_a})));
    end
    
    % (3) 保存相位解调结果：MAT保存原始相位，PNG只保存显示副本
    save(fullfile(params.save_path, sprintf('Phase_1DSIM_%s.mat', alpha_names{idx_a})), 'phase_SIM');
    if params.plot.save_intermediate_png
        rgb_phase = OA_ScalarToRGB(phase_SIM, clim_phase, cmap_phase);
        imwrite(rgb_phase, fullfile(params.save_path, sprintf('Phase_1DSIM_%s.png', alpha_names{idx_a})));
    end
end

%% 3. 处理传统 WF 作为对比组 (65nm极限)
fprintf('\n>>> 正在解调传统全息图 (Traditional QPM, 65nm limit)...\n');
I_traditional_65nm = imresize(I_traditional_QPM_ref, 0.5, 'bicubic', 'Antialiasing', true);
params_65nm = params;
params_65nm.dx = params.dx * 2;  
params_65nm.dy = params.dy * 2;  
params_65nm.N  = params.N / 2;   
params_65nm.alpha = alpha_list(1); % 即 0 度
[phase_WF_65nm, ~] = OA_DemodulatePhase2(I_traditional_65nm, params_65nm, params.recon.offaxis_multi_to_dc_WF, params.recon.offaxis_multi_ortho_WF);
phase_WF = imresize(phase_WF_65nm, [params.N, params.N], 'bicubic');

%% 4. 执行关键的【频域正交融合】
fprintf('\n>>> 流程步骤：执行 0° 与 90° 的频域加权融合\n');

% 最终方向关系按“可扩展频带方向”定义：
% alpha = 0 deg: carrier 在 fx 轴；滤波窗口在 fy 方向可扩展更多 -> Y-frequency enhanced。
% alpha = 90 deg: carrier 在 fy 轴；滤波窗口在 fx 方向可扩展更多 -> X-frequency enhanced。
phase_Y = phase_SIM_results{1};   % alpha = 0 deg, Y-frequency enhanced
phase_X = phase_SIM_results{2};   % alpha = 90 deg, X-frequency enhanced

% 融合前关键步骤：对齐基准背景相位（消除 piston 差异）
bg_ref_mask = OA_CreateSiemensBackgroundMask(GT_ref, params);

phase_Y = phase_Y - mean(phase_Y(bg_ref_mask), 'omitnan');
phase_X = phase_X - mean(phase_X(bg_ref_mask), 'omitnan');

% --- 4.1 Average Fusion：保留 raw，不做 mat2gray ---
phase_avg_fused_raw = 0.5 * (phase_X + phase_Y);
phase_avg_fused_raw = phase_avg_fused_raw - mean(phase_avg_fused_raw(bg_ref_mask), 'omitnan');

% 仅用于保存显示图；使用固定 phase clim 和黄绿色 Nature colormap
rgb_avg = OA_ScalarToRGB(phase_avg_fused_raw, clim_phase, cmap_phase);
imwrite(rgb_avg, fullfile(params.save_path, 'phase_avg_fused.png'));

% --- 4.2 频域正交融合：保留 raw，不做 mat2gray ---
F_Y = fftshift(fft2(phase_Y));   % alpha=0: carrier along fx, usable bandwidth mainly extended along fy
F_X = fftshift(fft2(phase_X));   % alpha=90: carrier along fy, usable bandwidth mainly extended along fx

[Nx, Ny] = size(phase_X);
[u, v] = meshgrid(linspace(-1, 1, Ny), linspace(-1, 1, Nx));
theta_f = atan2(v, u);

% Frequency-domain weights:
% u is fx axis, v is fy axis.
% Use alpha=90/X-enhanced result near fx axis, and alpha=0/Y-enhanced result near fy axis.
W_X = cos(theta_f).^2;   % high weight near fx axis
W_Y = sin(theta_f).^2;   % high weight near fy axis

% 中心零频点避免奇异
W_X(Nx/2+1, Ny/2+1) = 0.5;
W_Y(Nx/2+1, Ny/2+1) = 0.5;

F_fused = F_X .* W_X + F_Y .* W_Y;

phase_SIM_fused_raw = real(ifft2(ifftshift(F_fused)));
phase_SIM_fused_raw = phase_SIM_fused_raw - mean(phase_SIM_fused_raw(bg_ref_mask), 'omitnan');

% 仅用于保存显示图；使用固定 phase clim 和黄绿色 Nature colormap
rgb_fused = OA_ScalarToRGB(phase_SIM_fused_raw, clim_phase, cmap_phase);
imwrite(rgb_fused, fullfile(params.save_path, 'phase_SIM_fused.png'));

%% 5. 可视化与 Siemens star 环向定量分析
fprintf('>>> 流程步骤：对齐零点并生成最终图表\n');

GT_phi   = GT_ref.phi - mean(GT_ref.phi(bg_ref_mask), 'omitnan');
phase_WF = phase_WF - mean(phase_WF(bg_ref_mask), 'omitnan');

% 仅用于保存GT预览图；使用固定 phase clim 和黄绿色 Nature colormap
rgb_GT = OA_ScalarToRGB(GT_phi, clim_phase, cmap_phase);
imwrite(rgb_GT, fullfile(params.save_path, 'phase_GT.png'));

% -----------------------------
% 为了公平显示，所有2D图统一 color axis
% 注意：这里只影响显示，不影响定量数据
% -----------------------------
all_maps = cat(3, GT_phi, phase_WF, phase_X, phase_Y, phase_avg_fused_raw, phase_SIM_fused_raw);
if isfield(params.plot, 'use_fixed_phase_clim') && params.plot.use_fixed_phase_clim
    clim_phase = params.plot.fixed_phase_clim;
    phase_ticks = params.plot.fixed_phase_ticks;
    cmin = clim_phase(1);
    cmax = clim_phase(2);
else
    [cmin, cmax, phase_ticks] = OA_ComputeRobustClimTicks(all_maps, 0.2, 99.8);
    clim_phase = [cmin, cmax];
end

% --- 2D 全局对比图（在 GT / Fused 上叠加标定圆环） ---
h_comp = figure('Color','w','Position',[50 100 1800 800], 'InvertHardcopy','off');
tiledlayout(2,3,'Padding','compact','TileSpacing','compact');
sgtitle('Quantitative phase reconstruction of a Siemens-star phase target', 'FontSize', 14, 'FontWeight', 'bold');

ax1 = nexttile;
imagesc(GT_phi); axis image;
caxis([cmin cmax]);
OA_ApplyPhaseMapColormapAndColorbar(ax1, cmap_phase, phase_ticks);
title('Ground-truth phase map', 'FontSize', 12, 'Color', 'k');
hold on;
OA_OverlaySiemensCircles(gca, GT_ref, params, 'w--', 0.8);
OA_FormatImageAxes(gca, params.plot);

ax_tmp = nexttile;
imagesc(phase_WF); axis image;
caxis([cmin cmax]);
OA_ApplyPhaseMapColormapAndColorbar(ax_tmp, cmap_phase, phase_ticks);
title('Wide-field QPM (single-frame off-axis holography)', 'FontSize', params.plot.font_size_title, 'Color', 'k');
OA_FormatImageAxes(gca, params.plot);

ax_tmp = nexttile;
imagesc(phase_avg_fused_raw); axis image;
caxis([cmin cmax]);
OA_ApplyPhaseMapColormapAndColorbar(ax_tmp, cmap_phase, phase_ticks);
title('Arithmetic-mean fusion of orthogonal 1D-SIM reconstructions', 'FontSize', params.plot.font_size_title, 'Color', [0.85 0.33 0.10]);
OA_FormatImageAxes(gca, params.plot);

ax_tmp = nexttile;
imagesc(phase_Y); axis image;
caxis([cmin cmax]);
OA_ApplyPhaseMapColormapAndColorbar(ax_tmp, cmap_phase, phase_ticks);
title('1D-SIM QPM reconstruction (alpha = 0^\circ, Y-frequency enhanced)', 'FontSize', params.plot.font_size_title, 'Color', 'k', 'Interpreter','tex');
OA_FormatImageAxes(gca, params.plot);

ax_tmp = nexttile;
imagesc(phase_X); axis image;
caxis([cmin cmax]);
OA_ApplyPhaseMapColormapAndColorbar(ax_tmp, cmap_phase, phase_ticks);
title('1D-SIM QPM reconstruction (alpha = 90^\circ, X-frequency enhanced)', 'FontSize', params.plot.font_size_title, 'Color', 'k', 'Interpreter','tex');
OA_FormatImageAxes(gca, params.plot);

ax6 = nexttile;
imagesc(phase_SIM_fused_raw); axis image;
caxis([cmin cmax]);
OA_ApplyPhaseMapColormapAndColorbar(ax6, cmap_phase, phase_ticks);
title('Frequency-domain isotropic fusion of orthogonal 1D-SIM reconstructions', 'FontSize', 12, 'FontWeight','bold', 'Color', 'r');
hold on;
OA_OverlaySiemensCircles(gca, GT_ref, params, 'w--', 0.8);
OA_FormatImageAxes(gca, params.plot);
OA_ApplyPublicationStyle(h_comp, params.plot);

% --- Siemens star 环向调制定量分析 ---
analysis_GT    = OA_AnalyzeSiemensStarAnnulus(GT_phi,                 GT_ref, params);
analysis_WF    = OA_AnalyzeSiemensStarAnnulus(phase_WF,               GT_ref, params);
analysis_X     = OA_AnalyzeSiemensStarAnnulus(phase_X,                GT_ref, params);
analysis_Y     = OA_AnalyzeSiemensStarAnnulus(phase_Y,                GT_ref, params);
analysis_avg   = OA_AnalyzeSiemensStarAnnulus(phase_avg_fused_raw,    GT_ref, params);
analysis_fused = OA_AnalyzeSiemensStarAnnulus(phase_SIM_fused_raw,    GT_ref, params);

fp_axis_nm = analysis_GT.full_pitch_nm(:);
amp_ref = analysis_GT.mod_amp(:);
amp_ref(amp_ref < 1e-12) = 1e-12;

vis_GT    = analysis_GT.mod_amp(:)    ./ amp_ref;
vis_WF    = analysis_WF.mod_amp(:)    ./ amp_ref;
vis_X     = analysis_X.mod_amp(:)     ./ amp_ref;
vis_Y     = analysis_Y.mod_amp(:)     ./ amp_ref;
vis_avg   = analysis_avg.mod_amp(:)   ./ amp_ref;
vis_fused = analysis_fused.mod_amp(:) ./ amp_ref;

% 适度平滑，便于判读分辨率阈值
vis_GT_s    = movmean(vis_GT,    5);
vis_WF_s    = movmean(vis_WF,    5);
vis_X_s     = movmean(vis_X,     5);
vis_Y_s     = movmean(vis_Y,     5);
vis_avg_s   = movmean(vis_avg,   5);
vis_fused_s = movmean(vis_fused, 5);

res_threshold = params.siemens.res_threshold;   % 可调：0.10~0.20
res_WF_nm    = OA_EstimateResolutionFromVisibility(fp_axis_nm, vis_WF_s,    res_threshold);
res_X_nm     = OA_EstimateResolutionFromVisibility(fp_axis_nm, vis_X_s,     res_threshold);
res_Y_nm     = OA_EstimateResolutionFromVisibility(fp_axis_nm, vis_Y_s,     res_threshold);
res_avg_nm   = OA_EstimateResolutionFromVisibility(fp_axis_nm, vis_avg_s,   res_threshold);
res_fused_nm = OA_EstimateResolutionFromVisibility(fp_axis_nm, vis_fused_s, res_threshold);

fprintf('>>> Siemens star 环向分析（可分辨阈值 = %.2f）:\n', res_threshold);
fprintf('    Wide-field QPM                              : %.1f nm full-pitch\n', res_WF_nm);
fprintf('    1D-SIM QPM X-frequency enhanced (alpha 90)  : %.1f nm full-pitch\n', res_X_nm);
fprintf('    1D-SIM QPM Y-frequency enhanced (alpha 0)   : %.1f nm full-pitch\n', res_Y_nm);
fprintf('    Arithmetic-mean fusion                      : %.1f nm full-pitch\n', res_avg_nm);
fprintf('    Frequency-domain isotropic fusion           : %.1f nm full-pitch\n', res_fused_nm);

% 抽取若干指定 full-pitch 的环向周期结构，用于直接看“圆环上周期变化”
selected_fp_nm = params.siemens.display_fullpitch_nm(:)';
ring_GT    = OA_ExtractSiemensProfilesAtFullPitch(GT_phi,              GT_ref, params, selected_fp_nm);
ring_WF    = OA_ExtractSiemensProfilesAtFullPitch(phase_WF,            GT_ref, params, selected_fp_nm);
ring_X     = OA_ExtractSiemensProfilesAtFullPitch(phase_X,             GT_ref, params, selected_fp_nm);
ring_Y     = OA_ExtractSiemensProfilesAtFullPitch(phase_Y,             GT_ref, params, selected_fp_nm);
ring_avg   = OA_ExtractSiemensProfilesAtFullPitch(phase_avg_fused_raw, GT_ref, params, selected_fp_nm);
ring_fused = OA_ExtractSiemensProfilesAtFullPitch(phase_SIM_fused_raw, GT_ref, params, selected_fp_nm);

% --- 环向分析图：投稿风格，简化为 GT / WF / 最优融合 ---
num_profiles_to_show = min(5, numel(selected_fp_nm));
if num_profiles_to_show <= 1
    ring_rows = 1; 
    ring_cols = 2;
    ring_fig_pos = [120 120 1500 520];
else
    ring_rows = 2; 
    ring_cols = 3;
    ring_fig_pos = [80 60 1800 900];
end

h_ring = figure('Name', 'Siemens Star Full-Pitch Resolution Analysis', ...
                'Color','w', 'InvertHardcopy','off', ...
                'Position', ring_fig_pos);
T = tiledlayout(ring_rows, ring_cols, 'Padding','compact','TileSpacing','compact');
title(T, 'Siemens-star full-pitch resolution analysis', ...
      'FontName', params.plot.font_name, ...
      'FontSize', params.plot.font_size_sgtitle, ...
      'FontWeight', 'bold', ...
      'Color', 'k');

% (1) normalized annular modulation vs full-pitch
ax_mod = nexttile;
plot(fp_axis_nm, vis_GT_s,    '-',  'Color', '#631836', 'LineWidth', params.plot.line_width); hold on;
plot(fp_axis_nm, vis_WF_s,    '-.', 'Color', '#1875ba', 'LineWidth', params.plot.line_width);
plot(fp_axis_nm, vis_fused_s, '-',  'Color', '#e7674a', 'LineWidth', params.plot.line_width_heavy);

yline(res_threshold, 'k--', 'Resolution criterion', ...
    'LineWidth', params.plot.line_width_light, ...
    'LabelVerticalAlignment','bottom', ...
    'FontName', params.plot.font_name, ...
    'FontSize', params.plot.font_size_axis);

OA_FormatPlotAxes(ax_mod, params.plot);
xlabel('Full-pitch (nm)', 'FontName', params.plot.font_name, 'FontSize', params.plot.font_size_label);
ylabel('Normalized annular modulation', 'FontName', params.plot.font_name, 'FontSize', params.plot.font_size_label);
title('Normalized annular modulation versus full-pitch', ...
      'FontName', params.plot.font_name, ...
      'FontSize', params.plot.font_size_title, ...
      'FontWeight','normal');

if ~isnan(res_WF_nm)
    OA_AddResolutionMarker(ax_mod, res_WF_nm, ...
        sprintf('Wide-field QPM: %.0f nm', res_WF_nm), ...
        '#1875ba', 0.80, params.plot);
end
if ~isnan(res_fused_nm)
    OA_AddResolutionMarker(ax_mod, res_fused_nm, ...
        sprintf('Isotropic fusion: %.0f nm', res_fused_nm), ...
        '#e7674a', 0.80, params.plot);
end

lgd = legend(ax_mod, {'Ground truth', 'Wide-field QPM', ...
    'Frequency-domain isotropic fusion'}, ...
    'Location','northeast');
PSI_FormatLegend_OA(lgd, params.plot);
ylim(ax_mod, [0, 1.22]);

% (2~6) angular phase profiles at selected full-pitch rings
for ii = 1:num_profiles_to_show
    ax_prof = nexttile;
    theta_deg = ring_GT(ii).theta_deg;

    plot(theta_deg, ring_GT(ii).profile_centered,    '-',  'Color', '#631836', 'LineWidth', params.plot.line_width); hold on;
    plot(theta_deg, ring_WF(ii).profile_centered,    '-.', 'Color', '#1875ba', 'LineWidth', params.plot.line_width);
    plot(theta_deg, ring_fused(ii).profile_centered, '-',  'Color', '#e7674a', 'LineWidth', params.plot.line_width_heavy);

    OA_FormatPlotAxes(ax_prof, params.plot);
    xlabel('Azimuth angle (deg)', 'FontName', params.plot.font_name, 'FontSize', params.plot.font_size_label);
    ylabel('Phase variation (rad, mean removed)', 'FontName', params.plot.font_name, 'FontSize', params.plot.font_size_label);
    title(sprintf('Angular phase profile at full-pitch %.0f nm (r = %.3f \\mum)', ...
          ring_GT(ii).target_fullpitch_nm, ring_GT(ii).radius_m*1e6), ...
          'Interpreter', 'tex', ...
          'FontName', params.plot.font_name, ...
          'FontSize', params.plot.font_size_title, ...
          'FontWeight', 'normal');
    xlim([0 360]);

    lgd_prof = legend(ax_prof, {'Ground truth', 'Wide-field QPM', ...
        'Frequency-domain isotropic fusion'}, ...
        'Location', 'northeast');
    PSI_FormatLegend_OA(lgd_prof, params.plot);
end

OA_ApplyPublicationStyle(h_ring, params.plot);

fprintf('>>> 处理完成！所有结果已可视化。\n');

%% 6. 保存结果图表
fprintf('>>> 流程步骤：正在保存结果图表至 %s ...\n', params.save_path);

file_comp_base = fullfile(params.save_path, '2D_Global_Comparison_publication');
file_ring_base = fullfile(params.save_path, 'Siemens_Annular_Analysis_publication');

if params.plot.enable_figure_export
    OA_ExportPublicationFigure(h_comp, file_comp_base, params.plot);
    OA_ExportPublicationFigure(h_ring, file_ring_base, params.plot);
else
    fprintf('    -> Figure export disabled. Saving direct PNG/TIF maps by imwrite.\n');
end

if params.plot.save_direct_png_tif
    OA_SaveDirectOffaxisPanels(params.save_path, GT_phi, phase_WF, phase_Y, phase_X, ...
        phase_avg_fused_raw, phase_SIM_fused_raw, [cmin cmax], phase_ticks, GT_ref, params);

    if isfield(params.plot, 'make_direct_analysis') && params.plot.make_direct_analysis
        OA_SaveDirectOffaxisAnalysis(params.save_path, GT_phi, phase_WF, phase_Y, phase_X, ...
            phase_avg_fused_raw, phase_SIM_fused_raw, [cmin cmax], phase_ticks, GT_ref, params, ...
            ring_GT, ring_WF, ring_Y, ring_X, ring_avg, ring_fused, ...
            fp_axis_nm, vis_GT_s, vis_WF_s, vis_Y_s, vis_X_s, vis_avg_s, vis_fused_s, ...
            res_threshold, res_WF_nm, res_fused_nm);
    end
end

% 额外保存 raw phase 数据，便于后续定量分析
save(fullfile(params.save_path, 'quantitative_phase_results.mat'), ...
     'GT_phi', 'GT_ref', 'phase_WF', 'phase_X', 'phase_Y', ...
     'phase_avg_fused_raw', 'phase_SIM_fused_raw', ...
     'analysis_GT', 'analysis_WF', 'analysis_X', 'analysis_Y', ...
     'analysis_avg', 'analysis_fused', ...
     'fp_axis_nm', ...
     'vis_GT', 'vis_WF', 'vis_X', 'vis_Y', 'vis_avg', 'vis_fused', ...
     'vis_GT_s', 'vis_WF_s', 'vis_X_s', 'vis_Y_s', 'vis_avg_s', 'vis_fused_s', ...
     'res_threshold', 'res_WF_nm', 'res_X_nm', 'res_Y_nm', 'res_avg_nm', 'res_fused_nm', ...
     'selected_fp_nm', ...
     'ring_GT', 'ring_WF', 'ring_X', 'ring_Y', 'ring_avg', 'ring_fused');

fprintf('>>> 所有图片与 Siemens star 环向定量数据已成功保存！\n');


%% ========================================================================
% 自定义函数 1：独立封装的相位解调管线 (保证 WF 和 SIM 后处理完全一致)
% ========================================================================


function [I_single, ground_truth, I_traditional_QPM] = GetFringeSet_SingleFrame2(p)
    rng(1024);

    [x, y] = meshgrid((-p.N/2:p.N/2-1)*p.dx, (-p.N/2:p.N/2-1)*p.dy);
    max_fov = (p.N / 2) * p.dx;

    % -----------------------------
    % 1. Siemens star 相位物体
    % -----------------------------
    if ~isfield(p, 'siemens'), p.siemens = struct(); end
    if ~isfield(p.siemens, 'num_spokes'),          p.siemens.num_spokes = 72; end
    if ~isfield(p.siemens, 'radius_frac'),         p.siemens.radius_frac = 0.78; end
    if ~isfield(p.siemens, 'inner_radius'),        p.siemens.inner_radius = 120e-9; end
    if ~isfield(p.siemens, 'phase_step'),          p.siemens.phase_step = 1.2; end
    if ~isfield(p.siemens, 'supersample'),         p.siemens.supersample = 8; end
    if ~isfield(p.siemens, 'edge_sigma_px'),       p.siemens.edge_sigma_px = 0.0; end
    if ~isfield(p.siemens, 'add_calib_rings'),     p.siemens.add_calib_rings = false; end
    if ~isfield(p.siemens, 'display_fullpitch_nm'), p.siemens.display_fullpitch_nm = [100 130 200 300 400]; end
    if ~isfield(p.siemens, 'res_threshold'),        p.siemens.res_threshold = 0.15; end

    num_spokes = p.siemens.num_spokes;
    if mod(num_spokes, 2) ~= 0
        error('params.siemens.num_spokes 必须为偶数，因为 Siemens star 需要明暗交替扇区。');
    end
    num_line_pairs = num_spokes / 2;
    star_radius = p.siemens.radius_frac * max_fov;
    inner_radius = p.siemens.inner_radius;
    phase_step = p.siemens.phase_step;

    r = sqrt(x.^2 + y.^2);
    theta = atan2(y, x);                         % [-pi, pi]

    % ---------------------------------------------------------------
    % Anti-aliased Siemens star GT by pixel supersampling
    % ---------------------------------------------------------------
    % 原先的写法是在 32.5 nm 像素中心点上用 floor(theta) 直接硬切扇区。
    % 在 100~150 nm full-pitch 附近，一个周期只有几个像素，像素中心硬判定
    % 会带来明显 aliasing，导致 GT 本身在中心附近不稳定。
    %
    % 这里改为像素内 SS x SS 子采样：在子像素尺度判断 Siemens star
    % 的高/低相位扇区，然后对每个 32.5 nm 像素做面积平均。
    % 这样得到的是连续相位物体经过像素面积积分后的 GT，更适合做定量标定。
    SS = max(1, round(p.siemens.supersample));
    sub_offsets = ((0:SS-1) + 0.5) / SS - 0.5;
    sub_offsets_x = sub_offsets * p.dx;
    sub_offsets_y = sub_offsets * p.dy;

    phi_accum = zeros(p.N, p.N);
    valid_accum = zeros(p.N, p.N);

    for ix_ss = 1:SS
        for iy_ss = 1:SS
            xs = x + sub_offsets_x(ix_ss);
            ys = y + sub_offsets_y(iy_ss);

            rs = sqrt(xs.^2 + ys.^2);
            ths = atan2(ys, xs);
            ths_0_2pi = mod(ths + 2*pi, 2*pi);

            sector_id = floor(ths_0_2pi / (2*pi/num_spokes));
            star_binary = mod(sector_id, 2) == 0;

            mask_star_sub = (rs <= star_radius) & (rs >= inner_radius);

            phi_sub = zeros(p.N, p.N);
            phi_sub(mask_star_sub & star_binary) = phase_step;

            % 中心奇点区域不参与分辨率判读，设为中间相位，避免角向扇区
            % 在 r -> 0 处汇聚产生虚假高频。
            phi_sub(rs < inner_radius) = 0.5 * phase_step;

            phi_accum = phi_accum + phi_sub;
            valid_accum = valid_accum + double(mask_star_sub);
        end
    end

    phi_object = phi_accum / (SS^2);

    % 在主像素网格上定义有效星靶 mask，用于后续 full-pitch 标定。
    mask_star = (r <= star_radius) & (r >= inner_radius);

    % 标定圆环不再写入 GT 相位，只在图上通过 OverlaySiemensCircles 叠加显示。
    % 如果确实需要把低幅度标定环写入 GT，可手动设 add_calib_rings=true。
    calib = struct();
    calib.num_spokes = num_spokes;
    calib.num_line_pairs = num_line_pairs;
    calib.star_radius_m = star_radius;
    calib.inner_radius_m = inner_radius;
    calib.phase_step_rad = phase_step;
    calib.supersample = SS;
    calib.fullpitch_formula = 'full_pitch = 2*pi*r / num_line_pairs';
    calib.halfpitch_formula = 'half_pitch = pi*r / num_line_pairs = full_pitch/2';
    calib.display_fullpitch_nm = p.siemens.display_fullpitch_nm;
    calib.ring_fullpitch_nm = p.siemens.display_fullpitch_nm;
    calib.ring_radius_m = (p.siemens.display_fullpitch_nm(:) * 1e-9) * num_line_pairs / (2*pi);

    if p.siemens.add_calib_rings
        ring_amp = 0.10 * phase_step;
        ring_width = max(1.5*p.dx, 35e-9);
        for ii = 1:numel(calib.ring_radius_m)
            rr = calib.ring_radius_m(ii);
            if rr > inner_radius && rr < star_radius
                ring_mask = abs(r - rr) <= ring_width;
                phi_object(ring_mask) = max(phi_object(ring_mask), ring_amp);
            end
        end
    end

    % supersampling 已经提供抗锯齿；默认 edge_sigma_px=0。
    % 若仍需要非常轻微的边缘平滑，可设置 0.1~0.2，不建议再用 0.8~0.9。
    if p.siemens.edge_sigma_px > 0
        phi_object = imgaussfilt(phi_object, p.siemens.edge_sigma_px);
    end

    % 纯相位物体：振幅保持为 1。amp_gt 只用于记录和可视化。
    amp_gt = ones(p.N, p.N);

    % 每个像素对应的局部 full-pitch / half-pitch，便于后续定量标定。
    full_pitch_m = 2 * pi * r / num_line_pairs;
    half_pitch_m = full_pitch_m / 2;
    full_pitch_m(~mask_star) = NaN;
    half_pitch_m(~mask_star) = NaN;

    ground_truth.amp = amp_gt;
    ground_truth.phi = phi_object;
    ground_truth.x = x;
    ground_truth.y = y;
    ground_truth.r = r;
    ground_truth.theta = theta;
    ground_truth.full_pitch_m = full_pitch_m;
    ground_truth.half_pitch_m = half_pitch_m;
    ground_truth.siemens = calib;

    U_obj_sample = amp_gt .* exp(1i * phi_object);

    % -----------------------------
    % 2. 传播到荧光薄膜/近场信息
    % -----------------------------
    fx = (-p.N/2:p.N/2-1) / (p.N * p.dx);
    fy = (-p.N/2:p.N/2-1) / (p.N * p.dy);
    [FX, FY] = meshgrid(fx, fy);

    fx_ref = p.fx_ref;
    alpha = p.alpha;
    U_ref_film = 1.0 * exp(1i*2*pi*(fx_ref*(x*cos(alpha)+y*sin(alpha))));

    lambda = p.lambda;
    z = p.z_sample;
    n_SiN = 2.0;
    lambda_eff = lambda / n_SiN;
    k_eff = 2 * pi / lambda_eff;

    term = 1 - (lambda_eff * FX).^2 - (lambda_eff * FY).^2;
    H_exact = zeros(size(term));
    H_exact(term >= 0) = exp(1i * k_eff * z .* sqrt(term(term >= 0)));
    H_exact(term < 0)  = exp(-k_eff * z .* sqrt(-term(term < 0)));

    U_obj_film = ifft2(fft2(U_obj_sample) .* fftshift(H_exact));
    I_perfect = abs(U_obj_film + U_ref_film).^2;

    I_single = I_perfect + p.noise_level * max(I_perfect(:)) * randn(p.N);
    I_single(I_single < 0) = 0;

    % -----------------------------
    % 3. 传统 QPM 对比组：只保留远场 NA 截止内频率
    % -----------------------------
    f_cutoff_QPM = p.NA_SIM / p.lambda;
    Pupil = double(sqrt(FX.^2 + FY.^2) <= f_cutoff_QPM);
    U_obj_traditional = ifft2(fft2(U_obj_sample) .* fftshift(Pupil));
    I_perfect_QPM = abs(U_obj_traditional + U_ref_film).^2;

    I_traditional_QPM = I_perfect_QPM + p.noise_level * max(I_perfect_QPM(:)) * randn(p.N);
    I_traditional_QPM(I_traditional_QPM < 0) = 0;
end
