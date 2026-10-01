function [phase_flat, amplitude] = OA_DemodulatePhase2(hologram_input, params, multi_0, multi)
    hologram = double(hologram_input);
    [Nx, Ny] = size(hologram);
    
    % --- 1. 0-frquency removal ---
    sigma_bg = 50; 
    I_on_axis_sim = imgaussfilt(hologram, sigma_bg); 
    hologram_no_dc = hologram - I_on_axis_sim;
    hologram_ready = hologram_no_dc / std(hologram_no_dc(:));
    % hologram_ready = hologram / std(hologram(:));
    % --- 2. Fourier transform and Peak detection ---
    H = fft2(hologram_ready);
    H_shift = fftshift(H);
    H_mag = abs(H_shift);
    center_x = floor(Nx/2) + 1; 
    center_y = floor(Ny/2) + 1; 
    
    win_row = hanning(Nx); win_col = hanning(Ny);
    window_2d = win_row * win_col';
    holo_for_search = (hologram_ready - mean(hologram_ready(:))) .* window_2d;

    H_mag_search = abs(fftshift(fft2(holo_for_search)));
    
    alpha = params.alpha;
    shift_x = params.fx_ref * cos(alpha) * Nx * params.dx; 
    shift_y = params.fx_ref * sin(alpha) * Ny * params.dy; 
    theory_peak_x_col = round(center_y + shift_x); 
    theory_peak_y_row = round(center_x + shift_y); 
    search_radius = params.recon.carrier_search_radius_px; 
    [xx, yy] = meshgrid(1:Ny, 1:Nx); 
    local_mask = ((xx - theory_peak_x_col).^2 + (yy - theory_peak_y_row).^2) <= search_radius^2;
    H_mag_local = H_mag_search .* local_mask;
    [~, idx] = max(H_mag_local(:));
    
    if H_mag_local(idx) == 0
        peak_x_int = theory_peak_y_row; peak_y_int = theory_peak_x_col; 
    else
        [peak_x_int, peak_y_int] = ind2sub([Nx, Ny], idx);
    end
    
    % sub-pixel peak detection
    if peak_x_int > 3 && peak_x_int < Nx-3 && peak_y_int > 3 && peak_y_int < Ny-3
        win_radius = 3; 
        row_idx = (peak_x_int - win_radius) : (peak_x_int + win_radius);
        col_idx = (peak_y_int - win_radius) : (peak_y_int + win_radius);
        local_amp = H_mag_search(row_idx, col_idx);
        local_energy = local_amp.^2; 
        local_energy = local_energy - min(local_energy(:)); 
        [xx_local, yy_local] = meshgrid(col_idx, row_idx);
        total_energy = sum(local_energy(:));
        if total_energy > 0
            peak_x_final = sum(yy_local(:) .* local_energy(:)) / total_energy; 
            peak_y_final = sum(xx_local(:) .* local_energy(:)) / total_energy; 
        else
            peak_x_final = peak_x_int; peak_y_final = peak_y_int;
        end
    else
        peak_x_final = peak_x_int; peak_y_final = peak_y_int;
    end
    
    % --- 3. Gaussian filtering ---
    dist_to_0_order = sqrt((peak_x_final - center_x)^2 + (peak_y_final - center_y)^2);
    theta = atan2(center_x - peak_x_final, center_y - peak_y_final); 
%     multi = 1.5;
    R_dc = dist_to_0_order * multi_0; 
    R_ortho = R_dc * multi; R_away = R_dc * multi; n_order = 1.5; 
    dx = xx - peak_y_final; dy = yy - peak_x_final; 
    dx_rot = dx * cos(theta) + dy * sin(theta); 
    dy_rot = -dx * sin(theta) + dy * cos(theta);
    R_dynamic = zeros(size(dx_rot));
    R_dynamic(dx_rot >= 0) = R_dc;   
    R_dynamic(dx_rot < 0)  = R_away; 
    D_squared = (dx_rot.^2) ./ (R_dynamic.^2) + (dy_rot.^2) ./ (R_ortho.^2);
    filter_mask = exp(-(D_squared.^n_order)); 
    H_filtered = H_shift .* filter_mask;
    % =========================================================
    % h_diag_fig = figure('Name', '频域滤波效果检查 - 诊断面板', 'Color', 'w', 'Position', [100, 200, 1500, 450]);
    % log_H_shift = log(1 + abs(H_shift));
    % log_H_filtered = log(1 + abs(H_filtered));

    % subplot(1, 3, 1);
    % imagesc(log_H_shift); colormap(jet); colorbar; hold on;
    % plot(peak_y_final, peak_x_final, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    % title('1. 原始频谱 (Log) & 载波定位'); axis image;
    % 
    % subplot(1, 3, 2);
    % imagesc(filter_mask); colormap(jet); colorbar; hold on;
    % plot(peak_y_final, peak_x_final, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
    % title('2. 旋转椭圆滤波器 Mask (透光率 0-1)'); axis image;
    % 
    % subplot(1, 3, 3);
    % imagesc(log_H_filtered); colormap(jet); colorbar;
    % title('3. 切除后的纯净 +1 级物光 (Log)'); axis image;

    % --- 4. Frequency shifiting and demodulation ---
    object_wave_carrier = ifft2(ifftshift(H_filtered));
    fx = (peak_y_final - center_y) / Ny; 
    fy = (peak_x_final - center_x) / Nx; 
    [X_space, Y_space] = meshgrid(0:Ny-1, 0:Nx-1); 
    digital_ref = exp(-1i * 2 * pi * (fx * X_space + fy * Y_space));
    object_wave = object_wave_carrier .* digital_ref;

    % Debug figure export removed to avoid MATLAB graphics backend stalls.
    amplitude = abs(object_wave);
    amplitude = amplitude / max(amplitude(:));
    phase = angle(object_wave);
    
    % --- 5. Background alignment and optional phase unwrapping ---
    amp_norm = amplitude / max(amplitude(:));
    thresh = graythresh(amp_norm);
    cell_mask_hard = amp_norm > thresh;
    
    if isfield(params.recon, 'use_phase_unwrap') && params.recon.use_phase_unwrap
        phase_unwrapped = PSI_unwrap_phase_2D_masked(phase, cell_mask_hard);
    else
        phase_unwrapped = phase;
    end
    bg_mask = ~imdilate(cell_mask_hard, strel('disk', 10)); 
    
    [Ny_dim, Nx_dim] = size(phase_unwrapped);
    [X_grid, Y_grid] = meshgrid(1:Nx_dim, 1:Ny_dim);
    idx_bg = find(bg_mask);
    
%     if length(idx_bg) > 10000 
%         X_fit = X_grid(idx_bg); Y_fit = Y_grid(idx_bg); Z_fit = phase_unwrapped(idx_bg);
%     else
%         edge_band = cell_mask_hard & ~imerode(cell_mask_hard, strel('disk', 5));
%         idx_edge = find(edge_band);
%         X_fit = X_grid(idx_edge); Y_fit = Y_grid(idx_edge); Z_fit = phase_unwrapped(idx_edge);
%     end
    % Use only the image border as a safe background region.
    % Plane fitting is the default: it removes piston/tilt while avoiding
    % quadratic over-subtraction of the Siemens-star low-frequency phase.
    margin = max(10, params.recon.bg_margin_px);
    bg_mask_safe = true(Ny_dim, Nx_dim);
    bg_mask_safe(margin:end-margin, margin:end-margin) = false;
    idx_bg_safe = find(bg_mask_safe & isfinite(phase_unwrapped));

    X_fit = X_grid(idx_bg_safe);
    Y_fit = Y_grid(idx_bg_safe);
    Z_fit = phase_unwrapped(idx_bg_safe);

    if strcmpi(params.recon.bg_fit_order, 'quadratic')
        A_fit = [X_fit.^2, Y_fit.^2, X_fit.*Y_fit, X_fit, Y_fit, ones(length(X_fit), 1)];
        coeffs = A_fit \ Z_fit;
        Phase_background_surf = coeffs(1)*X_grid.^2 + coeffs(2)*Y_grid.^2 + ...
                                coeffs(3)*X_grid.*Y_grid + coeffs(4)*X_grid + ...
                                coeffs(5)*Y_grid + coeffs(6);
    else
        A_fit = [X_fit, Y_fit, ones(length(X_fit), 1)];
        coeffs = A_fit \ Z_fit;
        Phase_background_surf = coeffs(1)*X_grid + coeffs(2)*Y_grid + coeffs(3);
    end

    phase_unwrapped_raw_flat = phase_unwrapped - Phase_background_surf;
    bg_mean_val = mean(phase_unwrapped_raw_flat(idx_bg_safe), 'omitnan');
    phase_unwrapped_flat = phase_unwrapped_raw_flat - bg_mean_val;

    if params.recon.force_positive_core
        core_mask = cell_mask_hard & ~bg_mask_safe;
        if nnz(core_mask) > 200 && mean(phase_unwrapped_flat(core_mask), 'omitnan') < 0
            phase_unwrapped_flat = -phase_unwrapped_flat;
        end
    end
    
%     sigma_soft = 10; 
%     cell_mask_soft = imgaussfilt(double(cell_mask_hard), sigma_soft);
    phase_flat = phase_unwrapped_flat;% .* cell_mask_soft;
    
%     core_mask = imerode(cell_mask_hard, strel('disk', 25));
%     if sum(core_mask(:)) < 100, core_mask = cell_mask_hard; end
%     if mean(phase_final(core_mask)) < 0
%         phase_final = -phase_final;
%     end
%     
%     phase_flat = phase_final; 
end
