function ring_profiles = OA_ExtractSiemensProfilesAtFullPitch(img, GT, params, target_fp_nm)
    Nlp = GT.siemens.num_line_pairs;
    center_x = params.N/2 + 1;
    center_y = params.N/2 + 1;
    ring_halfwidth_px = 1.5;
    n_r_avg = 5;
    n_theta = 720;

    ring_profiles = struct('target_fullpitch_nm', {}, 'radius_m', {}, ...
                           'theta_deg', {}, 'profile', {}, 'profile_centered', {});
    for ii = 1:numel(target_fp_nm)
        rr_m = (target_fp_nm(ii) * 1e-9) * Nlp / (2*pi);
        [profile, theta_deg] = OA_SampleAnnulusProfile(img, center_x, center_y, rr_m / params.dx, ...
                                                    ring_halfwidth_px, n_r_avg, n_theta);
        profile = profile(:).';
        profile_centered = profile - mean(profile(~isnan(profile)));

        ring_profiles(ii).target_fullpitch_nm = target_fp_nm(ii);
        ring_profiles(ii).radius_m = rr_m;
        ring_profiles(ii).theta_deg = theta_deg(:).';
        ring_profiles(ii).profile = profile;
        ring_profiles(ii).profile_centered = profile_centered;
    end
end
