function OA_SaveModulationAnalysis(save_path, fp_axis_nm, vis_GT_s, vis_WF_s, vis_Y_s, vis_X_s, vis_avg_s, vis_fused_s, res_threshold, res_WF_nm, res_fused_nm, params)
    labels = {'GT','WF','alpha0Y','alpha90X','Avg','Fused'};
    T = array2table([fp_axis_nm(:), vis_GT_s(:), vis_WF_s(:), vis_Y_s(:), vis_X_s(:), vis_avg_s(:), vis_fused_s(:)], ...
        'VariableNames', [{'FullPitch_nm'}, labels]);
    writetable(T, fullfile(save_path, 'F_annular_modulation_curves.csv'));
    X = fp_axis_nm(:);
    Y = [vis_GT_s(:), vis_WF_s(:), vis_fused_s(:)];
    colors = [0.35 0.35 0.35; 0.90 0.45 0.05; 0.85 0.20 0.10];
    rgb = OA_MakeDirectCurvePlot(X, Y, colors, [], [0 1.25], 'Normalized annular modulation', params);
    imwrite(rgb, fullfile(save_path, 'F_annular_modulation_curves.png'));
    imwrite(rgb, fullfile(save_path, 'F_annular_modulation_curves.tif'));
    fid = fopen(fullfile(save_path, 'F_annular_modulation_summary.txt'), 'w');
    fprintf(fid, 'Resolution criterion = %.6g normalized modulation.\n', res_threshold);
    fprintf(fid, 'WF-QPM estimated full-pitch = %.6g nm.\n', res_WF_nm);
    fprintf(fid, 'Frequency-fused estimated full-pitch = %.6g nm.\n', res_fused_nm);
    fclose(fid);
end
