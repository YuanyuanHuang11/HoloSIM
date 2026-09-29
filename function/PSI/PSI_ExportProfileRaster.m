function PSI_ExportProfileRaster(sp, file_base, ps)
    out_w = PSI_GetPlotField(ps, 'profile_raster_w_px', 1800);
    out_h = PSI_GetPlotField(ps, 'profile_raster_h_px', 1100);
    margin_l = round(0.12 * out_w);
    margin_r = round(0.05 * out_w);
    margin_t = round(0.08 * out_h);
    margin_b = round(0.16 * out_h);
    plot_x1 = margin_l; plot_x2 = out_w - margin_r;
    plot_y1 = margin_t; plot_y2 = out_h - margin_b;
    canvas = ones(out_h, out_w, 3);
    colGT = [0.45 0.45 0.45]; colHolo = [0.00 0.45 0.74]; colQPM = [0.85 0.33 0.00];
    x = double(sp.axis_nm(:)); yGT = double(sp.GT(:)); yH = double(sp.HoloSIM(:)); yQ = double(sp.QPM(:));
    allY = [yGT; yH; yQ]; allY = allY(isfinite(allY));
    if isempty(x) || isempty(allY), return; end
    xmin = min(x); xmax = max(x); ymin = min(allY); ymax = max(allY);
    ypad = max(0.04, 0.10 * (ymax - ymin + eps)); ymin = ymin - ypad; ymax = ymax + ypad;
    axis_w = max(2, round(out_h * 0.0022));
    canvas = PSI_DrawRasterLine(canvas, plot_x1, plot_y1, plot_x1, plot_y2, [0 0 0], axis_w);
    canvas = PSI_DrawRasterLine(canvas, plot_x1, plot_y2, plot_x2, plot_y2, [0 0 0], axis_w);
    n_tick = 5; tick_len = round(0.015 * out_w);
    for kk = 1:n_tick
        tx = plot_x1 + (kk-1) / (n_tick-1) * (plot_x2 - plot_x1);
        canvas = PSI_DrawRasterLine(canvas, tx, plot_y2, tx, plot_y2 + tick_len, [0 0 0], axis_w);
        ty = plot_y2 - (kk-1) / (n_tick-1) * (plot_y2 - plot_y1);
        canvas = PSI_DrawRasterLine(canvas, plot_x1 - tick_len, ty, plot_x1, ty, [0 0 0], axis_w);
    end
    [px, py] = PSI_MapCurveToRaster(x, yGT, xmin, xmax, ymin, ymax, plot_x1, plot_x2, plot_y1, plot_y2);
    canvas = PSI_DrawRasterPolyline(canvas, px, py, colGT, max(2, round(out_h * 0.0030)));
    [px, py] = PSI_MapCurveToRaster(x, yH, xmin, xmax, ymin, ymax, plot_x1, plot_x2, plot_y1, plot_y2);
    canvas = PSI_DrawRasterPolyline(canvas, px, py, colHolo, max(2, round(out_h * 0.0026)));
    [px, py] = PSI_MapCurveToRaster(x, yQ, xmin, xmax, ymin, ymax, plot_x1, plot_x2, plot_y1, plot_y2);
    canvas = PSI_DrawRasterPolyline(canvas, px, py, colQPM, max(2, round(out_h * 0.0026)));
    lx1 = plot_x2 - round(0.22 * out_w); lx2 = lx1 + round(0.08 * out_w); ly0 = plot_y1 + round(0.04 * out_h); gap = round(0.035 * out_h);
    canvas = PSI_DrawRasterLine(canvas, lx1, ly0, lx2, ly0, colGT, max(3, round(out_h * 0.004)));
    canvas = PSI_DrawRasterLine(canvas, lx1, ly0 + gap, lx2, ly0 + gap, colHolo, max(3, round(out_h * 0.004)));
    canvas = PSI_DrawRasterLine(canvas, lx1, ly0 + 2*gap, lx2, ly0 + 2*gap, colQPM, max(3, round(out_h * 0.004)));
    [out_dir, ~, ~] = fileparts(file_base); if ~isempty(out_dir) && ~exist(out_dir, 'dir'), mkdir(out_dir); end
    imwrite(uint8(255 * min(max(canvas, 0), 1)), [file_base '.png']);
    imwrite(uint8(255 * min(max(canvas, 0), 1)), [file_base '.tif'], 'Compression', 'lzw');
    fid = fopen([file_base '_info.txt'], 'w');
    if fid ~= -1
        fprintf(fid, 'Direct-raster profile export. No MATLAB figure infrastructure was used.\n');
        fprintf(fid, 'Curve order / legend: GT gray, HoloSIM blue, Conventional QPM orange.\n');
        fprintf(fid, 'X axis: lateral position (nm), range [%.8g, %.8g].\n', xmin, xmax);
        fprintf(fid, 'Y axis: phase (rad), range [%.8g, %.8g].\n', ymin, ymax);
        fclose(fid);
    end
end
