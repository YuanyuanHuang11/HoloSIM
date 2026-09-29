function PSI_ExportStandaloneColorbar_LSEC(cmap_in, clim_in, label_str, file_base, ps, tick_values)
    % Direct-raster standalone colorbar with embedded numeric tick labels.
    % This function intentionally does not use figure, axes, text, print,
    % exportgraphics, getframe, saveas, or drawnow.  It is safe for MATLAB
    % sessions where the graphics backend hangs, while still producing PNG/TIF
    % colorbars with visible tick values.

    if isfield(ps, 'colorbar_px_h')
        cb_h = ps.colorbar_px_h;
    else
        cb_h = 1800;
    end
    if isfield(ps, 'colorbar_px_w')
        cb_w = ps.colorbar_px_w;
    else
        cb_w = 430;
    end

    show_tick_labels = true;
    if isfield(ps, 'colorbar_show_tick_labels')
        show_tick_labels = logical(ps.colorbar_show_tick_labels);
    end
    if isfield(ps, 'colorbar_tick_label_font_scale')
        font_scale = ps.colorbar_tick_label_font_scale;
    else
        font_scale = 5;
    end
    if isfield(ps, 'colorbar_tick_label_gap_px')
        label_gap = ps.colorbar_tick_label_gap_px;
    else
        label_gap = 18;
    end

    strip_w = max(42, round(cb_w * 0.24));
    margin_l = max(18, round(cb_w * 0.10));
    x1 = margin_l + 1;
    x2 = margin_l + strip_w;

    cmap_img = flipud(reshape(cmap_in, [size(cmap_in,1), 1, 3]));
    cmap_img = imresize(cmap_img, [cb_h, strip_w], 'nearest');
    canvas = uint8(255 * ones(cb_h, cb_w, 3));
    canvas(:, x1:x2, :) = uint8(255 * cmap_img);

    % Complete black frame around the color strip.
    frame_w = 3;
    canvas(:, x1:x1+frame_w-1, :) = 0;
    canvas(:, x2-frame_w+1:x2, :) = 0;
    canvas(1:frame_w, x1:x2, :) = 0;
    canvas(cb_h-frame_w+1:cb_h, x1:x2, :) = 0;

    if nargin < 6 || isempty(tick_values)
        tick_values = clim_in;
    end
    tick_values = tick_values(:).';

    % Inward black tick marks and numeric tick labels.
    if ~isempty(tick_values)
        tick_len = max(18, round(strip_w * 0.46));
        tick_w = 3;
        labels = PSI_formatColorbarTickLabels(tick_values);
        for ii = 1:numel(tick_values)
            tv = tick_values(ii);
            tNorm = (tv - clim_in(1)) / (clim_in(2) - clim_in(1));
            tNorm = min(max(tNorm, 0), 1);
            yy = round(cb_h - tNorm * (cb_h - 1));
            yy = min(max(yy, 1), cb_h);

            y1_tick = max(1, yy - floor(tick_w/2));
            y2_tick = min(cb_h, yy + floor(tick_w/2));
            tx1 = max(x1, x2 - tick_len);
            tx2 = x2;
            canvas(y1_tick:y2_tick, tx1:tx2, :) = 0;

            if show_tick_labels
                label_text = labels{ii};
                label_x = x2 + label_gap;
                label_h = 7 * font_scale;
                label_y = yy - round(label_h / 2);
                label_y = min(max(label_y, 4), cb_h - label_h - 3);
                canvas = PSI_drawSimpleBitmapText(canvas, label_text, label_x, label_y, font_scale, [0 0 0]);
            end
        end
    end

    % Draw a compact unit tag at the lower right when possible.  This is not
    % used as the primary label; exact label and limits are also written to
    % the *_info.txt file.  Keeping it compact avoids cluttering the colorbar.
    unit_text = '';
    if contains(lower(label_str), 'rad')
        unit_text = 'rad';
    elseif contains(lower(label_str), 'amp')
        unit_text = 'amp';
    end
    if show_tick_labels && ~isempty(unit_text)
        unit_scale = max(3, round(font_scale * 0.75));
        unit_x = x2 + label_gap;
        unit_y = cb_h - 8 - 7 * unit_scale;
        canvas = PSI_drawSimpleBitmapText(canvas, unit_text, unit_x, unit_y, unit_scale, [0 0 0]);
    end

    [out_dir, ~, ~] = fileparts(file_base);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    imwrite(canvas, [file_base '.png']);
    imwrite(canvas, [file_base '.tif'], 'Compression', 'lzw');

    fid = fopen([file_base '_info.txt'], 'w');
    if fid ~= -1
        fprintf(fid, 'Colorbar: %s', label_str);
        fprintf(fid, 'Color limits: [%.8g, %.8g]', clim_in(1), clim_in(2));
        if ~isempty(tick_values)
            fprintf(fid, 'Ticks: ');
            fprintf(fid, '%.8g ', tick_values);
            fprintf(fid, '');
            fprintf(fid, 'Tick labels: ');
            labels = PSI_formatColorbarTickLabels(tick_values);
            for ii = 1:numel(labels)
                fprintf(fid, '%s ', labels{ii});
            end
            fprintf(fid, '');
        end
        fprintf(fid, 'Standalone colorbar exported by direct imwrite with embedded numeric tick labels.');
        fclose(fid);
    end
end
