function p0 = PSI_thresholdPitchFirst(fullPitchNm, R, tau)
    % First upward crossing from the high-frequency/small-pitch side.
    [p, idx] = sort(fullPitchNm(:), 'ascend');
    r = R(:);
    r = r(idx);

    valid = isfinite(p) & isfinite(r);
    p = p(valid);
    r = r(valid);

    if isempty(p) || all(r < tau)
        p0 = NaN;
        return;
    end

    ii = find(r >= tau, 1, 'first');
    if ii == 1
        p0 = p(1);
    else
        p0 = PSI_interpCrossing(p(ii-1), r(ii-1), p(ii), r(ii), tau);
    end
end
