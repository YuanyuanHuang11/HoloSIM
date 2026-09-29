function SIM_PlotHoloSIMVsQPMProfilesMetrics(result, params, file_base)
    % LESC center-profile figure for publication.
    % The profile is taken through the highest-phase region of the LESC
    % ground truth and corresponds to the dashed line overlaid on the maps.

    ps = params.plot;

    if PSI_GetPlotField(ps, 'use_safe_raster_profile', true)
        PSI_ExportProfileRaster(result.center_profile, file_base, ps);
        return;
    end

    colGT   = [0.45 0.45 0.45];   % gray GT
    colHolo = [0.00 0.45 0.74];   % Nature-style blue
    colQPM  = [0.85 0.33 0.00];   % Nature-style orange

    fig = figure('Color','w', 'Units','centimeters', 'Position',[2 2 8.8 5.8]);
    ax = axes('Parent', fig, 'Position', [0.18 0.18 0.76 0.70]);
    hold(ax, 'on');

    sp = result.center_profile;
    plot(ax, sp.axis_nm, sp.GT,      '-', 'Color', colGT,   'LineWidth', 1.15);
    plot(ax, sp.axis_nm, sp.HoloSIM, '-', 'Color', colHolo, 'LineWidth', 1.05);
    plot(ax, sp.axis_nm, sp.QPM,     '-', 'Color', colQPM,  'LineWidth', 1.05);

    xlim(ax, [min(sp.axis_nm), max(sp.axis_nm)]);
    allY = [sp.GT(:); sp.HoloSIM(:); sp.QPM(:)];
    allY = allY(isfinite(allY));
    if isempty(allY)
        ylim(ax, [-0.1 1.8]);
    else
        yMin = min(allY);
        yMax = max(allY);
        pad = max(0.04, 0.10 * (yMax - yMin + eps));
        ylim(ax, [yMin - pad, yMax + pad]);
    end

    title(ax, 'LESC high-phase center profile', ...
        'FontName', ps.font_name, 'FontSize', ps.font_size_title, ...
        'FontWeight', 'normal');
    xlabel(ax, 'Lateral position (nm)');
    ylabel(ax, 'Phase (rad)');
    PSI_FormatProfileAxesNature(ax, ps);

    lgd = legend(ax, {'GT','HoloSIM','Conventional QPM'}, 'Location', 'northeast');
    PSI_FormatLegendNature(lgd, ps);
    try
        lgd.ItemTokenSize = [10 7];
    catch
    end

    PSI_ExportPublicationFigureFast_LSEC(fig, file_base, ps);
    if isfield(ps, 'close_fig_after_export') && ps.close_fig_after_export
        close(fig);
    end
end
