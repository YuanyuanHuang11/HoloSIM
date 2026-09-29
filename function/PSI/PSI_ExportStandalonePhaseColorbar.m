function PSI_ExportStandalonePhaseColorbar(base_path, cmin, cmax, params)
    h = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 3.0 8.0], 'InvertHardcopy', 'off');
    ax = axes('Parent', h, 'Position', [0.01 0.01 0.01 0.01], 'Visible', 'off');
    colormap(h, jet(256));
    caxis(ax, [cmin cmax]);
    cb = colorbar(ax, 'eastoutside');
    cb.Position = [0.32 0.10 0.28 0.82];
    ylabel(cb, 'Phase (rad)', 'FontName', params.plot.font_name, 'FontSize', params.plot.font_size_label);
    try
        cb.Ticks = linspace(cmin, cmax, 5);
    catch
    end
    PSI_FormatNatureColorbar(cb, params.plot);
    drawnow;
    if isfield(params.plot, 'individual_export_png') && params.plot.individual_export_png
        try
            exportgraphics(h, [base_path '.png'], 'Resolution', params.plot.export_dpi, 'BackgroundColor', 'white');
        catch
            print(h, [base_path '.png'], '-dpng', sprintf('-r%d', params.plot.export_dpi));
        end
    end
    if isfield(params.plot, 'individual_export_pdf') && params.plot.individual_export_pdf
        try
            exportgraphics(h, [base_path '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
        catch
            set(h, 'PaperPositionMode', 'auto');
            print(h, [base_path '.pdf'], '-dpdf', '-painters');
        end
    end
    PSI_PoreExportEMF(h, base_path);
    close(h);
end
