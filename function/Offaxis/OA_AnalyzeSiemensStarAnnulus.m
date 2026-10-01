function analysis = OA_AnalyzeSiemensStarAnnulus(img, GT, params)
    if ~isfield(params, 'siemens')
        error('params.siemens not defined');
    end

    Nlp = GT.siemens.num_line_pairs;
    center_x = params.N/2 + 1;
    center_y = params.N/2 + 1;

    ring_halfwidth_px = 1.5;    
    n_r_avg = 5;
    n_theta = 720;

    r_min_m = GT.siemens.inner_radius_m + 3 * params.dx;
    r_max_m = GT.siemens.star_radius_m  - 3 * params.dx;
    r_axis_m = linspace(r_min_m, r_max_m, 240);
    fp_axis_nm = 2 * pi * r_axis_m / Nlp * 1e9;

    mod_amp = zeros(size(r_axis_m));
    mod_dc  = zeros(size(r_axis_m));

    for ii = 1:numel(r_axis_m)
        radius_px = r_axis_m(ii) / params.dx;
        [profile, theta_deg] = OA_SampleAnnulusProfile(img, center_x, center_y, radius_px, ring_halfwidth_px, n_r_avg, n_theta);
        profile(isnan(profile)) = [];
        if isempty(profile)
            mod_amp(ii) = NaN;
            mod_dc(ii)  = NaN;
            continue;
        end

        profile_centered = profile - mean(profile);
        F = fft(profile_centered);
        harm_idx = Nlp + 1;   % MATLAB 1-indexed；0阶在 1
        if harm_idx <= numel(F)
            mod_amp(ii) = 2 * abs(F(harm_idx)) / numel(profile_centered);
        else
            mod_amp(ii) = NaN;
        end
        mod_dc(ii) = mean(profile);
    end

    analysis.radius_m = r_axis_m(:);
    analysis.full_pitch_nm = fp_axis_nm(:);
    analysis.half_pitch_nm = fp_axis_nm(:) / 2;  % 兼容保留：half-pitch = full-pitch/2
    analysis.mod_amp = mod_amp(:);
    analysis.mod_dc = mod_dc(:);
    analysis.theta_deg = theta_deg(:);
end
