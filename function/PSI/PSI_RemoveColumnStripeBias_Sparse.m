function img_corr = PSI_RemoveColumnStripeBias_Sparse(img, bg_mask, smooth_px, strength)
    % Remove vertical striping without smoothing pore structures.
    % The stripe profile is estimated from a background mask as a robust
    % column-wise median. Only the high-frequency column component is removed.

    if nargin < 3 || isempty(smooth_px)
        smooth_px = 61;
    end
    if nargin < 4 || isempty(strength)
        strength = 1.0;
    end

    img_corr = img;
    if isempty(bg_mask) || ~isequal(size(bg_mask), size(img)) || nnz(bg_mask) < 100
        bg_mask = true(size(img));
    end

    [Ny, Nx] = size(img);
    col_profile = nan(1, Nx);
    min_bg_per_col = max(8, round(0.02 * Ny));

    for cc = 1:Nx
        idx = bg_mask(:,cc) & isfinite(img(:,cc));
        if nnz(idx) >= min_bg_per_col
            col_profile(cc) = median(img(idx,cc), 'omitnan');
        end
    end

    valid = isfinite(col_profile);
    if nnz(valid) < 10
        return;
    end

    % Interpolate columns with insufficient background pixels.
    col_profile(~valid) = interp1(find(valid), col_profile(valid), find(~valid), 'linear', 'extrap');

    % Force odd smoothing window.
    smooth_px = max(5, round(smooth_px));
    if mod(smooth_px, 2) == 0
        smooth_px = smooth_px + 1;
    end

    % Low-frequency illumination/background trend is preserved. Only the
    % rapidly varying column bias is removed.
    low_trend = movmedian(col_profile, smooth_px, 'omitnan');
    low_trend = movmean(low_trend, smooth_px, 'omitnan');
    stripe_profile = col_profile - low_trend;
    stripe_profile = stripe_profile - median(stripe_profile, 'omitnan');

    % Avoid over-correction from occasional bad columns.
    sigma = 1.4826 * median(abs(stripe_profile - median(stripe_profile, 'omitnan')), 'omitnan') + eps;
    stripe_profile = max(min(stripe_profile, 4*sigma), -4*sigma);

    img_corr = img - strength * repmat(stripe_profile, Ny, 1);
end
