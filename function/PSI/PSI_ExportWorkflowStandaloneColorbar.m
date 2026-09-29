function PSI_ExportWorkflowStandaloneColorbar(base_path, cmap_name, clim, cb_label, use_high_low_ticks, params)
    h = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 3.0 8.0], 'InvertHardcopy', 'off');
    ax = axes('Parent', h, 'Position', [0.01 0.01 0.01 0.01], 'Visible', 'off');
    if strcmpi(cmap_name, 'gray')
        colormap(h, gray(256));
    else
        colormap(h, jet(256));
    end
    caxis(ax, clim);
    cb = colorbar(ax, 'eastoutside');
    cb.Position = [0.32 0.10 0.28 0.82];
    ylabel(cb, cb_label, 'FontName', params.plot.font_name, 'FontSize', params.plot.font_size_label);
    if use_high_low_ticks
        cb.Ticks = clim;
        cb.TickLabels = {'Low', 'High'};
    else
        cb.Ticks = [-pi 0 pi];
        cb.TickLabels = {'-\pi', '0', '\pi'};
    end
    PSI_FormatNatureColorbar(cb, params.plot);
    drawnow;
    PSI_ExportWorkflowFigure(h, base_path, params.plot, params.sparse);
    close(h);
end
