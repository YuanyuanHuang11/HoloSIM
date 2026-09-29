function PSI_ExportWorkflowImageOnly(img, base_path, cmap_name, prc, fixed_clim)
    img = double(img);
    img(~isfinite(img)) = NaN;

    if strcmpi(cmap_name, 'gray')
        if isempty(fixed_clim)
            [lo, hi] = PSI_RobustImageLimits(img, prc);
            clim = [lo, hi];
        else
            clim = fixed_clim;
        end
        if clim(2) <= clim(1)
            clim(2) = clim(1) + eps;
        end
        rgb = ind2rgb(gray2ind(mat2gray(img, clim), 256), gray(256));
    else
        if isempty(fixed_clim)
            fixed_clim = [-pi pi];
        end
        rgb = ind2rgb(gray2ind(mat2gray(img, fixed_clim), 256), jet(256));
    end

    imwrite(rgb, [base_path '.png']);
end
