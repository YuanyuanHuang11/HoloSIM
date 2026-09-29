function p0 = PSI_thresholdPitchStable(fullPitchNm, R, tau)
    % Smallest pitch where R >= tau and all larger pitches remain >= tau.
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

    above = r >= tau;
    stableAbove = false(size(above));
    for ii = 1:numel(above)
        stableAbove(ii) = all(above(ii:end));
    end

    ii = find(stableAbove, 1, 'first');
    if isempty(ii)
        p0 = PSI_thresholdPitchFirst(p, r, tau);
        return;
    end

    if ii == 1
        p0 = p(1);
    else
        p0 = PSI_interpCrossing(p(ii-1), r(ii-1), p(ii), r(ii), tau);
    end
end
