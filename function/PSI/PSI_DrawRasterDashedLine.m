function img = PSI_DrawRasterDashedLine(img, x1, y1, x2, y2, color_main, color_edge, width_px)
    n = max(2, ceil(max(abs(x2-x1), abs(y2-y1))));
    xs = linspace(x1, x2, n); ys = linspace(y1, y2, n);
    dash_len = max(10, round(n * 0.035)); gap_len = max(6, round(n * 0.020)); period = dash_len + gap_len;
    for ii = 1:n
        if mod(ii-1, period) < dash_len
            img = PSI_SetRasterPixelDisk(img, xs(ii), ys(ii), width_px + 1, color_edge);
            img = PSI_SetRasterPixelDisk(img, xs(ii), ys(ii), width_px, color_main);
        end
    end
end
