function q = PSI_localPercentile(v,p)
    v = sort(v(isfinite(v)));
    if isempty(v)
        q = NaN;
        return;
    end

    idx = 1 + (numel(v)-1)*p/100;
    lo = floor(idx);
    hi = ceil(idx);

    if lo == hi
        q = v(lo);
    else
        q = v(lo) + (idx-lo)*(v(hi)-v(lo));
    end
end
