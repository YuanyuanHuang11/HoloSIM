function PSI_ExportSingleImagePanel(img, cmap_in, clim_in, title_str, file_base, ps)
    if isfield(ps, 'individual_panel_px')
        out_px = ps.individual_panel_px;
    else
        out_px = 1800;
    end

    rgb = PSI_scalarImageToRGB(img, cmap_in, clim_in);
    rgb = imresize(rgb, [out_px out_px], 'bicubic');

    [out_dir, ~, ~] = fileparts(file_base);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    imwrite(uint8(255 * rgb), [file_base '.png']);
    imwrite(uint8(255 * rgb), [file_base '.tif'], 'Compression', 'lzw');

    fid = fopen([file_base '_info.txt'], 'w');
    if fid ~= -1
        fprintf(fid, 'Panel: %s\n', title_str);
        fprintf(fid, 'Color limits: [%.8g, %.8g]\n', clim_in(1), clim_in(2));
        fprintf(fid, 'Export method: direct imwrite raster path.\n');
        fclose(fid);
    end
end
