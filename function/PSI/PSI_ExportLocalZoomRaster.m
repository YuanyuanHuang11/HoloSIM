function PSI_ExportLocalZoomRaster(panels, titles, ix, iy, clim_phase, cmap_phase, file_base, result, ps)
    tile_px = PSI_GetPlotField(ps, 'local_zoom_tile_px', 850);
    pad_px = max(20, round(tile_px * 0.035));
    n_col = numel(panels);
    canvas_h = tile_px + 2 * pad_px;
    canvas_w = n_col * tile_px + (n_col + 1) * pad_px;
    canvas = ones(canvas_h, canvas_w, 3);
    for k = 1:n_col
        crop = panels{k}(iy, ix);
        rgb = PSI_scalarImageToRGB(crop, cmap_phase, clim_phase);
        rgb = imresize(rgb, [tile_px tile_px], 'bicubic');
        if isfield(result, 'profile_line')
            rgb = PSI_overlayProfileGuideLineRasterOnCrop(rgb, result.profile_line, ix, iy);
        end
        y1 = pad_px + 1; y2 = y1 + tile_px - 1;
        x1 = pad_px + 1 + (k - 1) * (tile_px + pad_px); x2 = x1 + tile_px - 1;
        canvas(y1:y2, x1:x2, :) = rgb;
    end
    [out_dir, ~, ~] = fileparts(file_base); if ~isempty(out_dir) && ~exist(out_dir, 'dir'), mkdir(out_dir); end
    imwrite(uint8(255 * min(max(canvas, 0), 1)), [file_base '.png']);
    imwrite(uint8(255 * min(max(canvas, 0), 1)), [file_base '.tif'], 'Compression', 'lzw');
    fid = fopen([file_base '_info.txt'], 'w');
    if fid ~= -1
        fprintf(fid, 'Direct-raster local zoom montage. No MATLAB figure infrastructure was used.\n');
        fprintf(fid, 'Color limits: [%.8g, %.8g] rad.\n', clim_phase(1), clim_phase(2));
        for k = 1:numel(titles), fprintf(fid, 'Panel %d: %s\n', k, titles{k}); end
        fclose(fid);
    end
end
