function OA_SavePhaseRetentionResolutionCurve(save_path, fp_axis_nm, vis_GT_s, vis_WF_s, vis_fused_s, params)
    % Export a Nature-style phase-retention curve for the fused off-axis result.
    % This version uses a standard MATLAB figure only for the curve so the
    % text is rendered with Arial instead of the bitmap font used by direct
    % raster drawing. Image panels/colorbars can still be saved by imwrite.

    thresholds = [0.10, 0.20, 0.50];
    if isfield(params.plot, 'retention_thresholds')
        thresholds = params.plot.retention_thresholds(:).';
    end

    x = fp_axis_nm(:);
    gt = min(max(vis_GT_s(:), 0), 1.10);
    wf = min(max(vis_WF_s(:), 0), 1.10);
    fused = min(max(vis_fused_s(:), 0), 1.10);

    T = table(x, gt, wf, fused, ...
        'VariableNames', {'SpatialPeriod_nm','GT_over_GT','WF_QPM_over_GT','OffaxisFused_over_GT'});
    writetable(T, fullfile(save_path, 'G_phase_retention_resolution_curve.csv'));

    res_fused = nan(size(thresholds));
    res_wf = nan(size(thresholds));
    for ii = 1:numel(thresholds)
        res_fused(ii) = OA_EstimateResolutionAtThreshold(x, fused, thresholds(ii));
        res_wf(ii) = OA_EstimateResolutionAtThreshold(x, wf, thresholds(ii));
    end

    use_fig = true;
    if isfield(params.plot, 'use_figure_for_resolution_curve')
        use_fig = params.plot.use_figure_for_resolution_curve;
    end

    file_base = fullfile(save_path, 'G_phase_retention_resolution_curve');
    if use_fig
        try
            OA_PlotPhaseRetentionCurveFigure(x, gt, wf, fused, thresholds, res_fused, params, file_base);
        catch ME
            warning('Figure-based resolution curve export failed: %s. Falling back to direct raster.', ME.message);
            rgb = OA_MakePhaseRetentionCurveRaster(x, gt, wf, fused, thresholds, res_fused, params);
            imwrite(rgb, [file_base '.png']);
            imwrite(rgb, [file_base '.tif']);
        end
    else
        rgb = OA_MakePhaseRetentionCurveRaster(x, gt, wf, fused, thresholds, res_fused, params);
        imwrite(rgb, [file_base '.png']);
        imwrite(rgb, [file_base '.tif']);
    end

    fid = fopen(fullfile(save_path, 'G_phase_retention_resolution_curve_summary.txt'), 'w');
    fprintf(fid, 'Phase-retention resolution curve for off-axis frequency-domain fused result.\n');
    fprintf(fid, 'Y-axis = annular modulation / GT annular modulation.\n');
    fprintf(fid, 'X-axis = Siemens-star full-pitch spatial period in nm.\n');
    fprintf(fid, 'Curves: GT/GT, WF-QPM/GT, Off-axis fused/GT.\n');
    fprintf(fid, 'Threshold-based full-pitch estimates for fused result:\n');
    for ii = 1:numel(thresholds)
        fprintf(fid, '  %.0f%% retention: %.6g nm\n', thresholds(ii)*100, res_fused(ii));
    end
    fprintf(fid, 'Threshold-based full-pitch estimates for WF-QPM result:\n');
    for ii = 1:numel(thresholds)
        fprintf(fid, '  %.0f%% retention: %.6g nm\n', thresholds(ii)*100, res_wf(ii));
    end
    fclose(fid);
end
