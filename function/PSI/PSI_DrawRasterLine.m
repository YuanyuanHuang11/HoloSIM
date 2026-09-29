function img = PSI_DrawRasterLine(img, x1, y1, x2, y2, color, width_px)
    n = max(2, ceil(max(abs(x2-x1), abs(y2-y1))));
    xs = linspace(x1, x2, n); ys = linspace(y1, y2, n);
    for ii = 1:n, img = PSI_SetRasterPixelDisk(img, xs(ii), ys(ii), width_px, color); end
end
