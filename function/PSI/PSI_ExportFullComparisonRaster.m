function PSI_ExportFullComparisonRaster(panelData, panelCmaps, panelClims, panelTitles, panelNames, file_base, ps, result)
    if isfield(ps, 'full_comparison_panel_px')
        tile_px = ps.full_comparison_panel_px;
    else
        tile_px = 900;
    end
    pad_px = max(18, round(tile_px * 0.035));

    n_row = size(panelData, 1);
    n_col = size(panelData, 2);
    canvas_h = n_row * tile_px + (n_row + 1) * pad_px;
    canvas_w = n_col * tile_px + (n_col + 1) * pad_px;
    canvas = ones(canvas_h, canvas_w, 3);

    for rr = 1:n_row
        for cc = 1:n_col
            img = panelData{rr,cc};
            rgb = PSI_scalarImageToRGB(img, panelCmaps{rr,cc}, panelClims{rr,cc});
            rgb = imresize(rgb, [tile_px tile_px], 'bicubic');

            if rr == 1 && isfield(result, 'profile_line')
                rgb = PSI_overlayProfileGuideLineRaster(rgb, result.profile_line, size(img));
            end

            y1 = pad_px + 1 + (rr - 1) * (tile_px + pad_px);
            y2 = y1 + tile_px - 1;
            x1 = pad_px + 1 + (cc - 1) * (tile_px + pad_px);
            x2 = x1 + tile_px - 1;
            canvas(y1:y2, x1:x2, :) = rgb;
        end
    end

    [out_dir, ~, ~] = fileparts(file_base);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    imwrite(uint8(255 * canvas), [file_base '.png']);
    imwrite(uint8(255 * canvas), [file_base '.tif'], 'Compression', 'lzw');

    fid = fopen([file_base '_info.txt'], 'w');
    if fid ~= -1
        fprintf(fid, 'Full comparison raster montage exported by direct imwrite.\n');
        fprintf(fid, 'This path avoids MATLAB figure infrastructure, drawnow, print, getframe and exportgraphics.\n\n');
        for rr = 1:n_row
            for cc = 1:n_col
                fprintf(fid, 'Row %d, Col %d: %s / %s, clim = [%.8g, %.8g]\n', ...
                    rr, cc, panelTitles{rr,cc}, panelNames{rr,cc}, panelClims{rr,cc}(1), panelClims{rr,cc}(2));
            end
        end
        fclose(fid);
    end
end
