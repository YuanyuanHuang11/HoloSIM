function [lo, hi] = PSI_RobustImageLimits(img, prc)
    vals = img(isfinite(img));
    if isempty(vals)
        lo = 0; hi = 1; return;
    end
    lo = prctile(vals, prc(1));
    hi = prctile(vals, prc(2));
    if ~isfinite(lo) || ~isfinite(hi) || hi <= lo
        lo = min(vals); hi = max(vals);
    end
    if ~isfinite(lo) || ~isfinite(hi) || hi <= lo
        lo = 0; hi = 1;
    end
end
