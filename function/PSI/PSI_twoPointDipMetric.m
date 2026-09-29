function M = PSI_twoPointDipMetric(phi, x, sep_nm, S)
    % Measure central two-point phase dip from the y=0 line profile.
    yc = floor(S.N/2) + 1;
    x_nm = x(yc,:) * 1e9;
    p = double(phi(yc,:));

    farMask = abs(x_nm) > S.twoPoint.profile_halfwidth_nm * 0.85;
    if nnz(farMask) > 10
        p = p - median(p(farMask), 'omitnan');
    else
        p = p - median(p, 'omitnan');
    end

    peakWin = S.twoPoint.peak_window_nm;
    leftMask = abs(x_nm + sep_nm/2) <= peakWin;
    rightMask = abs(x_nm - sep_nm/2) <= peakWin;

    if ~any(leftMask) || ~any(rightMask)
        M = struct('dipFraction',NaN,'valleyRatio',NaN,'peakMean',NaN, ...
            'detectedPeakSeparation_nm',NaN);
        return;
    end

    xLeft = x_nm(leftMask);
    pLeft = p(leftMask);
    xRight = x_nm(rightMask);
    pRight = p(rightMask);

    [peakL, idxL] = max(pLeft);
    [peakR, idxR] = max(pRight);
    peakX_L = xLeft(idxL);
    peakX_R = xRight(idxR);

    betweenMask = x_nm >= min(peakX_L,peakX_R) & x_nm <= max(peakX_L,peakX_R);
    if nnz(betweenMask) < 2
        valley = min([peakL peakR]);
    else
        valley = min(p(betweenMask), [], 'omitnan');
    end

    pMean = mean([peakL peakR], 'omitnan');
    if ~isfinite(pMean) || pMean <= eps
        dip = NaN;
        vRatio = NaN;
    else
        vRatio = valley / pMean;
        dip = 1 - vRatio;
    end

    M = struct();
    M.dipFraction = dip;
    M.valleyRatio = vRatio;
    M.peakMean = pMean;
    M.detectedPeakSeparation_nm = abs(peakX_R - peakX_L);
end
