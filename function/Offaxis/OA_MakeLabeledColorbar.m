function cb = OA_MakeLabeledColorbar(cmap, clim_in, ticks, height_px, width_px, label_str)
    bar_w = 90;
    left = 40;
    top = 20;
    bottom = 35;
    cb = uint8(255 * ones(height_px, width_px, 3));
    y1 = top; y2 = height_px - bottom;
    for yy = y1:y2
        t = 1 - (yy - y1) / max(1, (y2 - y1));
        idx = round(t * (size(cmap,1)-1)) + 1;
        color_row = reshape(uint8(255*cmap(idx,:)), 1, 1, 3);
        cb(yy, left:left+bar_w-1, :) = repmat(color_row, 1, bar_w, 1);
    end
    % black frame
    cb(y1:y2, left, :) = 0; cb(y1:y2, left+bar_w-1, :) = 0;
    cb(y1, left:left+bar_w-1, :) = 0; cb(y2, left:left+bar_w-1, :) = 0;
    for ii = 1:numel(ticks)
        val = ticks(ii);
        t = (val - clim_in(1)) / (clim_in(2)-clim_in(1));
        yy = round(y2 - t*(y2-y1));
        yy = min(max(yy, y1), y2);
        cb(max(y1,yy-1):min(y2,yy+1), left+bar_w-35:left+bar_w-1, :) = 0;
        txt = OA_FormatTickLabel(val);
        cb = OA_DrawSimpleText(cb, left+bar_w+18, yy-8, txt, 3, [0 0 0]);
    end
    cb = OA_DrawSimpleText(cb, left, height_px-25, label_str, 2, [0 0 0]);
end
