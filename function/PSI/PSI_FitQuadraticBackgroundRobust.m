function bg_surf = PSI_FitQuadraticBackgroundRobust(phase_img, bg_mask, X_grid, Y_grid, params)
    idx = find(bg_mask & isfinite(phase_img));
    if numel(idx) < 100
        bg_surf = zeros(size(phase_img));
        return;
    end

    X_fit = X_grid(idx);
    Y_fit = Y_grid(idx);
    Z_fit = phase_img(idx);

    % LESC occupies a large fraction of the FOV. A quadratic surface fitted only
    % to outer-cell background can extrapolate strongly into the cell and create
    % artificial red/blue ramps. Use a plane by default; keep quadratic only as
    % an explicit option.
    fit_order = 'plane';
    if isfield(params, 'recon') && isfield(params.recon, 'background_fit_order')
        fit_order = lower(params.recon.background_fit_order);
    end

    switch fit_order
        case 'quadratic'
            A_fit = [X_fit.^2, Y_fit.^2, X_fit.*Y_fit, X_fit, Y_fit, ones(length(X_fit), 1)];
        case 'constant'
            A_fit = ones(length(X_fit), 1);
        otherwise
            A_fit = [X_fit, Y_fit, ones(length(X_fit), 1)];
    end

    coeffs = A_fit \ Z_fit;

    if isfield(params, 'recon') && isfield(params.recon, 'robust_background_fit') && params.recon.robust_background_fit
        Z_pred = A_fit * coeffs;
        resid = Z_fit - Z_pred;
        sigma = 1.4826 * median(abs(resid - median(resid)), 'omitnan') + eps;
        keep = abs(resid) < 3.5 * sigma;
        if nnz(keep) > 100
            coeffs = A_fit(keep,:) \ Z_fit(keep);
        end
    end

    switch fit_order
        case 'quadratic'
            bg_surf = coeffs(1)*X_grid.^2 + coeffs(2)*Y_grid.^2 + coeffs(3)*X_grid.*Y_grid + ...
                      coeffs(4)*X_grid + coeffs(5)*Y_grid + coeffs(6);
        case 'constant'
            bg_surf = coeffs(1) * ones(size(phase_img));
        otherwise
            bg_surf = coeffs(1)*X_grid + coeffs(2)*Y_grid + coeffs(3);
    end
end
