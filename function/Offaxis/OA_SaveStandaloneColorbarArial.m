function OA_SaveStandaloneColorbarArial(save_path, file_stem, cmap, clim_in, ticks, label_str, params)
    fig = figure('Color','w', 'Units','centimeters', 'Position',[2 2 3.5 8.8], 'Visible','off');
    ax = axes('Parent', fig, 'Units','normalized', 'Position',[0.05 0.04 0.18 0.90], 'Visible','off');
    imagesc(ax, [clim_in(1) clim_in(1); clim_in(2) clim_in(2)]);
    axis(ax, 'off');
    colormap(ax, cmap);
    caxis(ax, clim_in);

    cb = colorbar(ax, 'eastoutside');
    cb.Units = 'normalized';
    cb.Position = [0.34 0.07 0.22 0.86];
    cb.Limits = clim_in;
    cb.Ticks = ticks;
    cb.TickLabels = arrayfun(@OA_FormatTickLabel, ticks, 'UniformOutput', false);
    cb.TickDirection = 'in';
    cb.Color = 'k';
    cb.LineWidth = 0.8;
    cb.FontName = 'Arial';
    cb.FontSize = 9;
    cb.Label.String = label_str;
    cb.Label.FontName = 'Arial';
    cb.Label.FontSize = 10;
    cb.Label.Color = 'k';

    dpi = 600;
    if isfield(params, 'plot') && isfield(params.plot, 'export_dpi')
        dpi = params.plot.export_dpi;
    end
    exportgraphics(fig, fullfile(save_path, [file_stem '.png']), 'Resolution', dpi, 'BackgroundColor','white');
    exportgraphics(fig, fullfile(save_path, [file_stem '.tif']), 'Resolution', dpi, 'BackgroundColor','white');
    close(fig);
end
