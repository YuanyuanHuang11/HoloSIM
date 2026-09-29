function c = PSI_SafeCorr(a, b)
    a = double(a(:));
    b = double(b(:));
    valid = isfinite(a) & isfinite(b);
    a = a(valid);
    b = b(valid);

    if numel(a) < 3
        c = NaN;
        return;
    end

    a = a - mean(a);
    b = b - mean(b);
    denom = sqrt(sum(a.^2) * sum(b.^2));

    if denom < eps
        c = NaN;
    else
        c = sum(a .* b) / denom;
    end
end
