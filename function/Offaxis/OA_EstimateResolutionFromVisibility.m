function fp_limit_nm = OA_EstimateResolutionFromVisibility(fp_axis_nm, vis_curve, threshold)
    fp_axis_nm = fp_axis_nm(:);
    vis_curve = vis_curve(:);
    idx = find(vis_curve >= threshold, 1, 'first');
    if isempty(idx)
        fp_limit_nm = NaN;
    else
        fp_limit_nm = fp_axis_nm(idx);
    end
end
