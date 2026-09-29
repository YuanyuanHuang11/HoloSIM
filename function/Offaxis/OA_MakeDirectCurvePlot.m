function rgb = OA_MakeDirectCurvePlot(x, Y, colors, xlim_in, ylim_in, title_str, params)
    width = 1400; height = 900;
    left = 150; right = 45; top = 80; bottom = 120;
    rgb = uint8(255 * ones(height, width, 3));
    if isempty(xlim_in)
        xv = x(isfinite(x)); xlim_in = [min(xv), max(xv)];
    end
    if isempty(ylim_in)
        yv = Y(isfinite(Y)); pad = 0.08 * max(eps, max(yv)-min(yv)); ylim_in = [min(yv)-pad, max(yv)+pad];
    end
    % axes
    rgb = OA_DrawRasterLine(rgb, left, height-bottom, width-right, height-bottom, [0 0 0], 2);
    rgb = OA_DrawRasterLine(rgb, left, top, left, height-bottom, [0 0 0], 2);
    % title
    rgb = OA_DrawSimpleText(rgb, left, 30, title_str, 3, [0 0 0]);
    % curves
    for kk = 1:size(Y,2)
        yy = Y(:,kk);
        valid = isfinite(x) & isfinite(yy);
        px = left + (x(valid)-xlim_in(1)) / max(eps, xlim_in(2)-xlim_in(1)) * (width-left-right);
        py = height-bottom - (yy(valid)-ylim_in(1)) / max(eps, ylim_in(2)-ylim_in(1)) * (height-top-bottom);
        rgb = OA_DrawPolyline(rgb, px, py, colors(kk,:), 3);
    end
    % simple numeric axis labels
    rgb = OA_DrawSimpleText(rgb, left-5, height-bottom+20, OA_FormatTickLabel(xlim_in(1)), 3, [0 0 0]);
    rgb = OA_DrawSimpleText(rgb, width-right-70, height-bottom+20, OA_FormatTickLabel(xlim_in(2)), 3, [0 0 0]);
    rgb = OA_DrawSimpleText(rgb, 15, top-10, OA_FormatTickLabel(ylim_in(2)), 3, [0 0 0]);
    rgb = OA_DrawSimpleText(rgb, 15, height-bottom-10, OA_FormatTickLabel(ylim_in(1)), 3, [0 0 0]);
end
