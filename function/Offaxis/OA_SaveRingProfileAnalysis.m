function OA_SaveRingProfileAnalysis(save_path, ring_GT, ring_WF, ring_Y, ring_X, ring_avg, ring_fused, target_fp_nm, params)
    [~, idx] = min(abs([ring_GT.target_fullpitch_nm] - target_fp_nm));
    theta = ring_GT(idx).theta_deg(:);
    Y = [ring_GT(idx).profile_centered(:), ring_WF(idx).profile_centered(:), ...
         ring_Y(idx).profile_centered(:), ring_X(idx).profile_centered(:), ...
         ring_avg(idx).profile_centered(:), ring_fused(idx).profile_centered(:)];
    labels = {'GT','WF','alpha0Y','alpha90X','Avg','Fused'};
    csv_path = fullfile(save_path, sprintf('E_angular_profile_fullpitch_%dnm.csv', round(ring_GT(idx).target_fullpitch_nm)));
    T = array2table([theta, Y], 'VariableNames', [{'theta_deg'}, labels]);
    writetable(T, csv_path);

    colors = [0.35 0.35 0.35; 0.90 0.45 0.05; 0.20 0.45 0.85; 0.55 0.25 0.70; 0.30 0.70 0.45; 0.85 0.20 0.10];
    rgb = OA_MakeDirectCurvePlot(theta, Y(:,[1 2 6]), colors([1 2 6],:), [0 360], [], ...
        sprintf('Full-pitch %d nm angular profile', round(ring_GT(idx).target_fullpitch_nm)), params);
    imwrite(rgb, fullfile(save_path, sprintf('E_angular_profile_fullpitch_%dnm.png', round(ring_GT(idx).target_fullpitch_nm))));
    imwrite(rgb, fullfile(save_path, sprintf('E_angular_profile_fullpitch_%dnm.tif', round(ring_GT(idx).target_fullpitch_nm))));
end
