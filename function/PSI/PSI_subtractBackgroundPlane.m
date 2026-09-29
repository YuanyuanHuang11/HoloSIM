function phi = PSI_subtractBackgroundPlane(phi, bgMask)
    % Remove a fitted background plane using only the non-cell background.
    % This is more stable for LESC than subtracting a single corner median.
    phi = double(phi);
    if nargin < 2 || isempty(bgMask) || nnz(bgMask) < 100
        phi = phi - median(phi(:), 'omitnan');
        return;
    end

    [ny, nx] = size(phi);
    [X, Y] = meshgrid(1:nx, 1:ny);
    valid = bgMask & isfinite(phi);
    if nnz(valid) < 100
        phi = phi - median(phi(:), 'omitnan');
        return;
    end

    x = X(valid);
    y = Y(valid);
    z = phi(valid);

    % Robust-lite plane fit: initial fit, reject large residuals, refit.
    A = [ones(numel(x),1), x(:), y(:)];
    coef = A \ z(:);
    res = z(:) - A * coef;
    sigma = 1.4826 * median(abs(res - median(res)), 'omitnan');
    if isfinite(sigma) && sigma > 0
        keep = abs(res) < 3 * sigma;
        if nnz(keep) > 100
            coef = A(keep,:) \ z(keep);
        end
    end

    bg = reshape([ones(numel(X),1), X(:), Y(:)] * coef, ny, nx);
    phi = phi - bg;
end
