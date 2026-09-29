function center_profile = PSI_BuildLESCMaxPhaseProfile(GT_ref, GT_phi, phase_QPM, phase_HoloSIM, params)
    xvec_m = GT_ref.x(1,:);
    yvec_m = GT_ref.y(:,1);

    if isfield(GT_ref, 'mask_tissue')
        search_mask = GT_ref.mask_tissue & isfinite(GT_phi);
    elseif isfield(GT_ref, 'object_mask')
        search_mask = GT_ref.object_mask & isfinite(GT_phi);
    else
        search_mask = isfinite(GT_phi);
    end

    tmp = GT_phi;
    tmp(~search_mask) = -Inf;
    [~, idxMax] = max(tmp(:));
    [iy0, ix0] = ind2sub(size(GT_phi), idxMax);

    % Use a horizontal line through the high-phase center. This is robust for
    % the LESC model and gives an intuitive center-crossing phase profile.
    if isfield(GT_ref, 'mask_tissue')
        row_mask = GT_ref.mask_tissue(iy0,:);
    elseif isfield(GT_ref, 'object_mask')
        row_mask = GT_ref.object_mask(iy0,:);
    else
        row_mask = true(1, numel(xvec_m));
    end

    valid_idx = find(row_mask & isfinite(GT_phi(iy0,:)));
    if isempty(valid_idx)
        half_width_m = 0.55 * (params.N/2) * params.dx;
        idx_prof = xvec_m >= xvec_m(ix0)-half_width_m & xvec_m <= xvec_m(ix0)+half_width_m;
    else
        % Crop to the contiguous tissue segment containing the peak.
        left = ix0;
        right = ix0;
        while left > 1 && row_mask(left-1)
            left = left - 1;
        end
        while right < numel(row_mask) && row_mask(right+1)
            right = right + 1;
        end

        pad_px = round(0.04 * params.N);
        left = max(1, left - pad_px);
        right = min(params.N, right + pad_px);
        idx_prof = false(1, params.N);
        idx_prof(left:right) = true;
    end

    x0 = xvec_m(ix0);
    center_profile.name = 'LESC high-phase center profile';
    center_profile.axis_nm = (xvec_m(idx_prof) - x0) * 1e9;
    center_profile.GT = GT_phi(iy0, idx_prof);
    center_profile.HoloSIM = phase_HoloSIM(iy0, idx_prof);
    center_profile.QPM = phase_QPM(iy0, idx_prof);
    center_profile.peak_xy_m = [xvec_m(ix0), yvec_m(iy0)];
    center_profile.line.orientation = 'horizontal';
    center_profile.line.row_index = iy0;
    center_profile.line.col_index = ix0;
    center_profile.line.x_index_range = find(idx_prof);
    center_profile.line.x_nm = xvec_m(idx_prof) * 1e9;
    center_profile.line.y_nm = yvec_m(iy0) * 1e9;
end
