function OA_SaveDirectOffaxisAnalysis(save_path, GT_phi, phase_WF, phase_alpha0_Y, phase_alpha90_X, phase_avg, phase_fused, clim_phase, phase_ticks, GT_ref, params, ring_GT, ring_WF, ring_Y, ring_X, ring_avg, ring_fused, fp_axis_nm, vis_GT_s, vis_WF_s, vis_Y_s, vis_X_s, vis_avg_s, vis_fused_s, res_threshold, res_WF_nm, res_fused_nm)
    % Extended analysis export by pure imwrite. No MATLAB figure/export backend is used.
    if isfield(params.plot, 'make_siemens_twotone') && params.plot.make_siemens_twotone
        OA_SaveSiemensTwoToneGT(save_path, GT_phi, GT_ref, params);
    end

    target_fp_nm = params.plot.roi_fullpitch_nm;
    roi_theta_deg = params.plot.roi_theta_deg;
    roi_size_px = params.plot.roi_size_px;
    roi = OA_ComputeSiemensROI(GT_ref, params, target_fp_nm, roi_theta_deg, roi_size_px);

    maps = {GT_phi, phase_WF, phase_alpha0_Y, phase_alpha90_X, phase_avg, phase_fused};
    names = {'GT', 'WF-QPM', 'alpha0-Yfreq', 'alpha90-Xfreq', 'Average fusion', 'Frequency fusion'};
    OA_SaveROIZoomMontage(save_path, maps, names, roi, clim_phase, OA_GetPhaseColormap(params), params);

    OA_SaveRingProfileAnalysis(save_path, ring_GT, ring_WF, ring_Y, ring_X, ring_avg, ring_fused, target_fp_nm, params);
    OA_SaveModulationAnalysis(save_path, fp_axis_nm, vis_GT_s, vis_WF_s, vis_Y_s, vis_X_s, vis_avg_s, vis_fused_s, res_threshold, res_WF_nm, res_fused_nm, params);
    if ~isfield(params.plot, 'make_phase_retention_curve') || params.plot.make_phase_retention_curve
        OA_SavePhaseRetentionResolutionCurve(save_path, fp_axis_nm, vis_GT_s, vis_WF_s, vis_fused_s, params);
    end

    fid = fopen(fullfile(save_path, 'D_offaxis_analysis_summary.txt'), 'w');
    fprintf(fid, 'Additional off-axis Siemens analysis exported by direct imwrite.\n');
    fprintf(fid, 'Siemens two-tone colors: dark teal = [%.3f %.3f %.3f], warm cream = [%.3f %.3f %.3f].\n', ...
        params.plot.siemens_dark_color, params.plot.siemens_bright_color);
    fprintf(fid, 'ROI target full-pitch = %.1f nm, theta = %.1f deg, size = %d px.\n', target_fp_nm, roi_theta_deg, roi_size_px);
    fprintf(fid, 'ROI row range = [%d %d], col range = [%d %d].\n', roi.r1, roi.r2, roi.c1, roi.c2);
    fprintf(fid, 'Interpretation: alpha=0 carrier lies on fx; usable filter extension is mainly along fy, so alpha0 is treated as Y-frequency enhanced.\n');
    fprintf(fid, 'Interpretation: alpha=90 carrier lies on fy; usable filter extension is mainly along fx, so alpha90 is treated as X-frequency enhanced.\n');
    fprintf(fid, 'Frequency fusion uses alpha90/X result near fx axis and alpha0/Y result near fy axis.\n');
    fclose(fid);
end
