function sep0 = PSI_twoPointStableResolution(sep_nm, dip, tau)
    % Smallest separation where dip >= tau and all larger separations remain above tau.
    [s,idx] = sort(sep_nm(:), 'ascend');
    d = dip(:);
    d = d(idx);
    valid = isfinite(s) & isfinite(d);
    s = s(valid);
    d = d(valid);

    if isempty(s) || all(d < tau)
        sep0 = NaN;
        return;
    end

    above = d >= tau;
    stableAbove = false(size(above));
    for ii = 1:numel(above)
        stableAbove(ii) = all(above(ii:end));
    end

    ii = find(stableAbove, 1, 'first');
    if isempty(ii)
        ii = find(above, 1, 'first');
    end

    if ii == 1
        sep0 = s(1);
    else
        sep0 = s(ii-1) + (tau - d(ii-1)) * (s(ii)-s(ii-1)) / max(d(ii)-d(ii-1), eps);
        sep0 = max(min(sep0, s(ii)), s(ii-1));
    end
end
