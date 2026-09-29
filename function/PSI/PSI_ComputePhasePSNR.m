function psnr_val = PSI_ComputePhasePSNR(a, b)
    a = a(:);
    b = b(:);
    valid = isfinite(a) & isfinite(b);
    a = a(valid);
    b = b(valid);
    if numel(a) < 3
        psnr_val = NaN;
        return;
    end
    mse = mean((a - b).^2, 'omitnan');
    if ~isfinite(mse) || mse <= eps
        psnr_val = Inf;
        return;
    end
    dyn_range = max(b) - min(b);
    if ~isfinite(dyn_range) || dyn_range <= eps
        dyn_range = max(abs(b));
    end
    if ~isfinite(dyn_range) || dyn_range <= eps
        psnr_val = NaN;
    else
        psnr_val = 10 * log10((dyn_range.^2) / mse);
    end
end
