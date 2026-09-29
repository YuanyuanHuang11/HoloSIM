function [cmin, cmax, ticks] = OA_ComputeRobustClimTicks(data_stack, p_lo, p_hi)
    vals = data_stack(:);
    vals = vals(isfinite(vals));
    lo = prctile(vals, p_lo);
    hi = prctile(vals, p_hi);
    if lo > -0.05
        lo = 0;
    else
        lo = floor(lo * 10) / 10;
    end
    hi = ceil(hi * 10) / 10;
    if hi <= lo, hi = lo + 1; end
    cmin = lo;
    cmax = hi;
    span = hi - lo;
    if span <= 1.2
        step = 0.25;
    elseif span <= 2.5
        step = 0.5;
    else
        step = 1.0;
    end
    ticks = lo:step:hi;
    if isempty(ticks) || abs(ticks(end)-hi) > 1e-9
        ticks = [ticks, hi];
    end
end
