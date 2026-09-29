function p0 = PSI_interpCrossing(p1, r1, p2, r2, tau)
    if ~isfinite(r1) || ~isfinite(r2) || abs(r2-r1) < eps
        p0 = p2;
    else
        p0 = p1 + (tau-r1) * (p2-p1) / (r2-r1);
        p0 = max(min(p0, max(p1,p2)), min(p1,p2));
    end
end
