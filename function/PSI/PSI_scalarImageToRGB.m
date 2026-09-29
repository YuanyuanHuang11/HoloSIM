function rgb = PSI_scalarImageToRGB(img, cmap_in, clim_in)
    img = double(img);
    img(img < clim_in(1)) = clim_in(1);
    img(img > clim_in(2)) = clim_in(2);
    denom = clim_in(2) - clim_in(1);
    if denom <= 0 || ~isfinite(denom)
        denom = 1;
    end
    img_norm = (img - clim_in(1)) / denom;
    idx = round(1 + img_norm * (size(cmap_in,1) - 1));
    idx(idx < 1) = 1;
    idx(idx > size(cmap_in,1)) = size(cmap_in,1);
    rgb = ind2rgb(idx, cmap_in);
end
