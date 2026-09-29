function climVals = PSI_robustClim(img, prc)
    v = double(img(:));
    v = v(isfinite(v));
    if isempty(v)
        climVals = [0 1];
        return;
    end
    lo = PSI_localPercentile(v, prc(1));
    hi = PSI_localPercentile(v, prc(2));
    if ~isfinite(lo) || ~isfinite(hi) || hi <= lo
        lo = min(v); hi = max(v);
    end
    if hi <= lo
        hi = lo + 1;
    end
    climVals = [lo hi];
end
