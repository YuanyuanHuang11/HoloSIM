function M = PSI_hincModulationMap(I, GT, S)
    % Background-subtracted and robustly scaled hologram modulation map.
    % This is for visualizing H_inc readout, not for PSI phase display.
    I = double(I);
    [xx, yy] = meshgrid(1:S.N, 1:S.N);
    cx = S.N/2 + 1;
    cy = S.N/2 + 1;
    rr = sqrt((xx-cx).^2 + (yy-cy).^2) * S.dx;
    bg = rr > (GT.star_radius_m + 0.5e-6);
    star = rr <= GT.star_radius_m & rr >= GT.inner_radius_m;
    if nnz(bg) > 100
        M = I - median(I(bg), 'omitnan');
    else
        M = I - median(I(:), 'omitnan');
    end
    vals = abs(M(star & isfinite(M)));
    if isempty(vals)
        scaleVal = max(abs(M(:)), [], 'omitnan');
    else
        scaleVal = PSI_localPercentile(vals, 99);
    end
    if ~isfinite(scaleVal) || scaleVal <= 0
        scaleVal = 1;
    end
    M = M / scaleVal;
    M = max(min(M, 1), -1);
end
