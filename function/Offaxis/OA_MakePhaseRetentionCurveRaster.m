function rgb = OA_MakePhaseRetentionCurveRaster(x, gt, wf, fused, thresholds, res_fused, params)
    width = 1450; height = 900;
    left = 170; right = 130; top = 80; bottom = 145;
    rgb = uint8(255 * ones(height, width, 3));

    if isfield(params.plot, 'retention_xmax_nm')
        xmax = params.plot.retention_xmax_nm;
    else
        xmax = max(1200, ceil(max(x(isfinite(x)))/100)*100);
    end
    xlim_in = [0, xmax];
    if isfield(params.plot, 'retention_ylim')
        ylim_in = params.plot.retention_ylim;
    else
        ylim_in = [0, 1.05];
    end

    % Nature-like line colors: GT gray, WF purple, fused blue.
    col_gt = [0.46 0.46 0.46];
    col_wf = [0.47 0.42 0.68];
    col_fused = [0.00 0.45 0.74];
    col_grid = [0.82 0.82 0.82];
    col_black = [0 0 0];

    % Axes box.
    rgb = OA_DrawRasterLine(rgb, left, height-bottom, width-right, height-bottom, col_black, 2);
    rgb = OA_DrawRasterLine(rgb, left, top, left, height-bottom, col_black, 2);
    rgb = OA_DrawRasterLine(rgb, left, top, width-right, top, col_black, 2);
    rgb = OA_DrawRasterLine(rgb, width-right, top, width-right, height-bottom, col_black, 2);

    % Axis ticks.
    xticks = 0:200:xlim_in(2);
    yticks = 0:0.2:1.0;
    for ii = 1:numel(xticks)
        [px, py0] = OA_MapCurveXY(xticks(ii), ylim_in(1), xlim_in, ylim_in, width, height, left, right, top, bottom);
        rgb = OA_DrawRasterLine(rgb, px, py0, px, py0-12, col_black, 2);
        rgb = OA_DrawSimpleText(rgb, round(px)-22, height-bottom+22, OA_FormatTickLabel(xticks(ii)), 3, col_black);
    end
    for ii = 1:numel(yticks)
        [px0, py] = OA_MapCurveXY(xlim_in(1), yticks(ii), xlim_in, ylim_in, width, height, left, right, top, bottom);
        rgb = OA_DrawRasterLine(rgb, px0, py, px0+12, py, col_black, 2);
        rgb = OA_DrawSimpleText(rgb, 75, round(py)-10, OA_FormatTickLabel(yticks(ii)), 3, col_black);
    end

    % Threshold dashed horizontal lines and fused vertical markers.
    for ii = 1:numel(thresholds)
        th = thresholds(ii);
        [~, py] = OA_MapCurveXY(0, th, xlim_in, ylim_in, width, height, left, right, top, bottom);
        rgb = OA_DrawDashedRasterLine(rgb, left, py, width-right, py, col_grid, 2, 14, 12);
        rgb = OA_DrawSimpleText(rgb, 45, round(py)-10, sprintf('%.0f%%', th*100), 3, col_black);
        if ii <= numel(res_fused) && isfinite(res_fused(ii))
            [px, ~] = OA_MapCurveXY(res_fused(ii), th, xlim_in, ylim_in, width, height, left, right, top, bottom);
            rgb = OA_DrawDashedRasterLine(rgb, px, top, px, height-bottom, [0.55 0.55 0.55], 1, 8, 12);
            rgb = OA_DrawCircleMarker(rgb, px, py, 8, col_black, [1 1 1], 2);
        end
    end

    % Curves.
    valid = isfinite(x) & isfinite(gt); [px, py] = OA_MapCurveXY(x(valid), gt(valid), xlim_in, ylim_in, width, height, left, right, top, bottom); rgb = OA_DrawPolyline(rgb, px, py, col_gt, 4);
    valid = isfinite(x) & isfinite(wf); [px, py] = OA_MapCurveXY(x(valid), wf(valid), xlim_in, ylim_in, width, height, left, right, top, bottom); rgb = OA_DrawPolyline(rgb, px, py, col_wf, 4);
    valid = isfinite(x) & isfinite(fused); [px, py] = OA_MapCurveXY(x(valid), fused(valid), xlim_in, ylim_in, width, height, left, right, top, bottom); rgb = OA_DrawPolyline(rgb, px, py, col_fused, 5);

    % Title and labels.
    rgb = OA_DrawSimpleText(rgb, 545, 28, 'Resolution criterion', 4, col_black);
    rgb = OA_DrawSimpleText(rgb, 525, height-58, 'Spatial period (nm)', 3, col_black);
    rgb = OA_DrawSimpleText(rgb, 18, 315, 'Phase retention', 3, col_black);

    % Legend.
    lx = 930; ly = 600;
    rgb = OA_DrawRasterLine(rgb, lx, ly, lx+70, ly, col_gt, 4);
    rgb = OA_DrawSimpleText(rgb, lx+85, ly-10, 'GT / GT', 3, col_black);
    rgb = OA_DrawRasterLine(rgb, lx, ly+38, lx+70, ly+38, col_wf, 4);
    rgb = OA_DrawSimpleText(rgb, lx+85, ly+28, 'WF-QPM / GT', 3, col_black);
    rgb = OA_DrawRasterLine(rgb, lx, ly+76, lx+70, ly+76, col_fused, 5);
    rgb = OA_DrawSimpleText(rgb, lx+85, ly+66, 'Off-axis fused / GT', 3, col_black);

    % Result text box.
    bx = 860; by = 260; bw = 320; bh = 150;
    rgb(by:by+bh, bx:bx+bw, :) = uint8(255);
    rgb = OA_DrawRasterLine(rgb, bx, by, bx+bw, by, [0.75 0.75 0.75], 2);
    rgb = OA_DrawRasterLine(rgb, bx, by+bh, bx+bw, by+bh, [0.75 0.75 0.75], 2);
    rgb = OA_DrawRasterLine(rgb, bx, by, bx, by+bh, [0.75 0.75 0.75], 2);
    rgb = OA_DrawRasterLine(rgb, bx+bw, by, bx+bw, by+bh, [0.75 0.75 0.75], 2);
    for ii = 1:numel(thresholds)
        if ii <= numel(res_fused) && isfinite(res_fused(ii))
            txt = sprintf('%.0f%%: %.0f nm', thresholds(ii)*100, res_fused(ii));
        else
            txt = sprintf('%.0f%%: NaN', thresholds(ii)*100);
        end
        rgb = OA_DrawSimpleText(rgb, bx+35, by+28+(ii-1)*38, txt, 3, col_black);
    end
end
