function rgb = PSI_overlayProfileGuideLineRaster(rgb, profile_line, img_size)
    if ~isfield(profile_line, 'row_index') || ~isfield(profile_line, 'x_index_range')
        return;
    end
    xidx = profile_line.x_index_range;
    if isempty(xidx)
        xidx = 1:img_size(2);
    end
    tile_h = size(rgb, 1);
    tile_w = size(rgb, 2);
    yy = round(profile_line.row_index / img_size(1) * tile_h);
    yy = min(max(yy, 1), tile_h);
    x1 = round(min(xidx) / img_size(2) * tile_w);
    x2 = round(max(xidx) / img_size(2) * tile_w);
    x1 = min(max(x1, 1), tile_w);
    x2 = min(max(x2, 1), tile_w);
    if x2 < x1
        tmp = x1; x1 = x2; x2 = tmp;
    end

    line_w = max(2, round(tile_h * 0.0020));
    dash_len = max(12, round(tile_w * 0.018));
    gap_len = max(8, round(tile_w * 0.010));
    period = dash_len + gap_len;
    for xx = x1:x2
        if mod(xx - x1, period) < dash_len
            ylo = max(1, yy - line_w);
            yhi = min(tile_h, yy + line_w);
            rgb(ylo:yhi, xx, :) = 1.0;
            ylo2 = max(1, yy - line_w - 1);
            yhi2 = min(tile_h, yy + line_w + 1);
            if ylo2 < ylo
                rgb(ylo2:ylo-1, xx, :) = 0.0;
            end
            if yhi2 > yhi
                rgb(yhi+1:yhi2, xx, :) = 0.0;
            end
        end
    end
end
