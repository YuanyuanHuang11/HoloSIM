function r = PSI_ComputePearsonCorrelation(a, b)
    a = a(:);
    b = b(:);
    valid = isfinite(a) & isfinite(b);
    a = a(valid);
    b = b(valid);
    if numel(a) < 3
        r = NaN;
        return;
    end
    a = a - mean(a);
    b = b - mean(b);
    denom = sqrt(sum(a.^2) * sum(b.^2));
    if denom <= eps
        r = NaN;
    else
        r = sum(a .* b) / denom;
    end
end
