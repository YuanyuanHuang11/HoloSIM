function img = PSI_DrawRasterPolyline(img, x, y, color, width_px)
    valid = isfinite(x) & isfinite(y); x = x(valid); y = y(valid);
    if numel(x) < 2, return; end
    for ii = 1:(numel(x)-1), img = PSI_DrawRasterLine(img, x(ii), y(ii), x(ii+1), y(ii+1), color, width_px); end
end
