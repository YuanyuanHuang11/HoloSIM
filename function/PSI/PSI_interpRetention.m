function Rq = PSI_interpRetention(fullPitchNm, R, queryPitch)
    [p, idx] = sort(fullPitchNm(:), 'ascend');
    r = R(:);
    r = r(idx);

    valid = isfinite(p) & isfinite(r);
    p = p(valid);
    r = r(valid);

    if isempty(p) || queryPitch < min(p) || queryPitch > max(p)
        Rq = NaN;
    else
        Rq = interp1(p, r, queryPitch, 'linear');
    end
end
