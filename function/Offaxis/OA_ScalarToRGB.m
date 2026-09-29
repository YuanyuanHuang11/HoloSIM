function rgb = OA_ScalarToRGB(img, clim_in, cmap)
    img = double(img);
    t = (img - clim_in(1)) / (clim_in(2) - clim_in(1));
    t = min(max(t, 0), 1);
    idx = round(t * (size(cmap,1)-1)) + 1;
    rgb = uint8(255 * ind2rgb(idx, cmap));
end
