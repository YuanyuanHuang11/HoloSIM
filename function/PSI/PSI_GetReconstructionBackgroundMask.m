function bg_mask = PSI_GetReconstructionBackgroundMask(params, img_size)
    Ny_dim = img_size(1);
    Nx_dim = img_size(2);
    bg_mask = false(Ny_dim, Nx_dim);

    if isfield(params, 'recon') && isfield(params.recon, 'bg_fit_mask') && isequal(size(params.recon.bg_fit_mask), [Ny_dim, Nx_dim])
        bg_mask = params.recon.bg_fit_mask;
    elseif isfield(params, 'recon') && isfield(params.recon, 'mask_cell') && isequal(size(params.recon.mask_cell), [Ny_dim, Nx_dim])
        if isfield(params.recon, 'bg_dilate_px')
            bg_dilate_px = params.recon.bg_dilate_px;
        else
            bg_dilate_px = 12;
        end
        bg_mask = ~imdilate(params.recon.mask_cell, strel('disk', bg_dilate_px));
    end

    if nnz(bg_mask) < 100
        margin = 20;
        bg_mask = true(Ny_dim, Nx_dim);
        bg_mask(margin:end-margin, margin:end-margin) = false;
    end
end
