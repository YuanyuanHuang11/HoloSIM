function img_corr = PSI_RemoveColumnStripeBias(img, bg_mask, smooth_px, strength, periodic_strength, periodic_smooth_px, periodic_lowpass_px)
    % Background-only dual-scale column-bias correction.
    %   slow term:     removes large-scale column bias;
    %   periodic term: removes fine periodic vertical stripes by estimating a
    %                  short-scale column component from background pixels only.
    if nargin < 3 || isempty(smooth_px), smooth_px = 101; end
    if nargin < 4 || isempty(strength),  strength = 0.40; end
    if nargin < 5 || isempty(periodic_strength), periodic_strength = 0.0; end
    if nargin < 6 || isempty(periodic_smooth_px), periodic_smooth_px = 7; end
    if nargin < 7 || isempty(periodic_lowpass_px), periodic_lowpass_px = 121; end

    img = double(img);
    [ny, nx] = size(img);
    if nargin < 2 || isempty(bg_mask) || ~isequal(size(bg_mask), size(img)) || nnz(bg_mask) < 100
        bg_mask = true(size(img));
    end

    raw_col_bias = nan(1, nx);
    for ix = 1:nx
        col_valid = bg_mask(:,ix) & isfinite(img(:,ix));
        vals = img(col_valid, ix);
        if numel(vals) >= 8
            raw_col_bias(ix) = median(vals, 'omitnan');
        end
    end

    good = isfinite(raw_col_bias);
    if nnz(good) < max(10, round(0.05 * nx))
        img_corr = img;
        return;
    end

    xq = 1:nx;
    raw_col_bias = interp1(xq(good), raw_col_bias(good), xq, 'linear', 'extrap');
    raw_col_bias = raw_col_bias - median(raw_col_bias, 'omitnan');

    slow_bias = PSI_smoothColumnVector(raw_col_bias, smooth_px);
    slow_bias = slow_bias - median(slow_bias, 'omitnan');
    total_bias = strength * slow_bias;

    if periodic_strength > 0
        short_bias = PSI_smoothColumnVector(raw_col_bias, periodic_smooth_px);
        long_bias  = PSI_smoothColumnVector(raw_col_bias, periodic_lowpass_px);
        periodic_bias = short_bias - long_bias;
        periodic_bias = periodic_bias - median(periodic_bias, 'omitnan');
        total_bias = total_bias + periodic_strength * periodic_bias;
    end

    img_corr = img - repmat(total_bias, ny, 1);
end
