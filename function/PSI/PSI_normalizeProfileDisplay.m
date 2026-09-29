function p = PSI_normalizeProfileDisplay(p)
    p = double(p(:)).';
    p = p - mean(p, 'omitnan');
    s = max(abs(p), [], 'omitnan');
    if ~isfinite(s) || s <= 0
        s = 1;
    end
    p = p / s;
end
