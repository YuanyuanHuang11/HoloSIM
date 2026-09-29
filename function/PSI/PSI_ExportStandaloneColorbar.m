function PSI_ExportStandaloneColorbar(cmap_in, clim_in, label_str, file_base, ps, tick_values)
    if isfield(ps, 'colorbar_px_h')
        cb_h = ps.colorbar_px_h;
    else
        cb_h = 1800;
    end
    if isfield(ps, 'colorbar_px_w')
        cb_w = ps.colorbar_px_w;
    else
        cb_w = 260;
    end

    strip_w = max(28, round(cb_w * 0.28));
    margin_l = round(cb_w * 0.14);
    x1 = margin_l + 1;
    x2 = margin_l + strip_w;

    cmap_img = flipud(reshape(cmap_in, [size(cmap_in,1), 1, 3]));
    cmap_img = imresize(cmap_img, [cb_h, strip_w], 'nearest');
    canvas = uint8(255 * ones(cb_h, cb_w, 3));
    canvas(:, x1:x2, :) = uint8(255 * cmap_img);

    % Frame and ticks
    canvas(:, x1, :) = 0;
    canvas(:, x2, :) = 0;
    canvas(1, x1:x2, :) = 0;
    canvas(end, x1:x2, :) = 0;

    if nargin >= 6 && ~isempty(tick_values)
        for ii = 1:numel(tick_values)
            tv = tick_values(ii);
            tNorm = (tv - clim_in(1)) / (clim_in(2) - clim_in(1));
            tNorm = min(max(tNorm, 0), 1);
            yy = round(cb_h - tNorm * (cb_h - 1));
            yy = min(max(yy, 1), cb_h);
            tx1 = min(cb_w, x2 + 4);
            tx2 = min(cb_w, x2 + 20);
            canvas(max(1,yy-1):min(cb_h,yy+1), tx1:tx2, :) = 0;
        end
    end

    [out_dir, ~, ~] = fileparts(file_base);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    imwrite(canvas, [file_base '.png']);
    imwrite(canvas, [file_base '.tif'], 'Compression', 'lzw');

    fid = fopen([file_base '_info.txt'], 'w');
    if fid ~= -1
        fprintf(fid, 'Colorbar: %s\n', label_str);
        fprintf(fid, 'Color limits: [%.8g, %.8g]\n', clim_in(1), clim_in(2));
        if nargin >= 6 && ~isempty(tick_values)
            fprintf(fid, 'Ticks: ');
            fprintf(fid, '%.8g ', tick_values);
            fprintf(fid, '\n');
        end
        fprintf(fid, 'Tick labels are stored here; add text labels during layout if desired.\n');
        fclose(fid);
    end
end
