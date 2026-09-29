function [x_nm, pNorm] = PSI_twoPointNormalizedProfile(phi, x, halfWidth_nm)
    yc = floor(size(phi,1)/2) + 1;
    xFull_nm = x(yc,:) * 1e9;
    p = double(phi(yc,:));

    mask = abs(xFull_nm) <= halfWidth_nm;
    farMask = abs(xFull_nm) > halfWidth_nm * 0.85;
    if nnz(farMask) > 10
        p = p - median(p(farMask), 'omitnan');
    else
        p = p - median(p, 'omitnan');
    end

    pShow = p(mask);
    scaleVal = max(pShow, [], 'omitnan');
    if ~isfinite(scaleVal) || scaleVal <= 0
        scaleVal = max(abs(pShow), [], 'omitnan');
    end
    if ~isfinite(scaleVal) || scaleVal <= 0
        scaleVal = 1;
    end

    x_nm = xFull_nm(mask);
    pNorm = pShow / scaleVal;
end
