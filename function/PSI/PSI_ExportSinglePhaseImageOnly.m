function PSI_ExportSinglePhaseImageOnly(img, panel_title, base_path, cmin, cmax, params)
    img = PSI_ClipPhaseForDisplay(img, cmin, cmax, params);
    rgb = ind2rgb(gray2ind(mat2gray(img, [cmin cmax]), 256), jet(256));

    if isfield(params.plot, 'individual_export_png') && params.plot.individual_export_png
        imwrite(rgb, [base_path '.png']);
    end
    if isfield(params.plot, 'individual_export_pdf') && params.plot.individual_export_pdf
        h = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', ...
            'Position', [100 100 size(img,2) size(img,1)]);
        ax = axes('Parent', h, 'Position', [0 0 1 1]);
        image(ax, rgb); axis(ax, 'image'); axis(ax, 'off');
        try
            exportgraphics(h, [base_path '.pdf'], 'ContentType', 'image', 'BackgroundColor', 'white');
        catch
            set(h, 'PaperPositionMode', 'auto');
            print(h, [base_path '.pdf'], '-dpdf', '-opengl');
        end
        close(h);
    end
end
