function OA_PlotPhaseRetentionCurveFigure(x, gt, wf, fused, thresholds, res_fused, params, file_base)
    % Nature-style phase-retention curve using MATLAB graphics.
    % Only this curve uses figure/exportgraphics so text is rendered normally.

    if isfield(params.plot, 'font_name')
        font_name = params.plot.font_name;
    else
        font_name = 'Arial';
    end
    if isfield(params.plot, 'export_dpi')
        dpi = params.plot.export_dpi;
    else
        dpi = 600;
    end
    if isfield(params.plot, 'retention_xmax_nm')
        xmax = params.plot.retention_xmax_nm;
    else
        xmax = max(1200, ceil(max(x(isfinite(x)))/100)*100);
    end
    if isfield(params.plot, 'retention_ylim')
        ylim_in = params.plot.retention_ylim;
    else
        ylim_in = [0, 1.05];
    end

    fig = figure('Color','w', ...
        'Units','centimeters', ...
        'Position',[2 2 9.2 6.6], ...
        'Visible','off', ...
        'InvertHardcopy','off');

    ax = axes('Parent', fig, 'Units','normalized', 'Position',[0.16 0.17 0.79 0.72]);
    hold(ax, 'on');

    col_gt = [0.45 0.45 0.45];
    col_wf = [0.48 0.42 0.70];
    col_fused = [0.00 0.45 0.74];
    col_grid = [0.78 0.78 0.78];

    valid = isfinite(x) & isfinite(gt);
    plot(ax, x(valid), gt(valid), '-', 'Color', col_gt, 'LineWidth', 1.35);
    valid = isfinite(x) & isfinite(wf);
    plot(ax, x(valid), wf(valid), '-', 'Color', col_wf, 'LineWidth', 1.35);
    valid = isfinite(x) & isfinite(fused);
    plot(ax, x(valid), fused(valid), '-', 'Color', col_fused, 'LineWidth', 1.75);

    for ii = 1:numel(thresholds)
        th = thresholds(ii);
        yline(ax, th, '--', 'Color', col_grid, 'LineWidth', 0.8, 'HandleVisibility','off');
        if ii <= numel(res_fused) && isfinite(res_fused(ii))
            xline(ax, res_fused(ii), ':', 'Color', [0.62 0.62 0.62], ...
                'LineWidth', 0.8, 'HandleVisibility','off');
            plot(ax, res_fused(ii), th, 'o', ...
                'MarkerSize', 4.2, ...
                'MarkerFaceColor', 'w', ...
                'MarkerEdgeColor', col_fused, ...
                'LineWidth', 1.0, ...
                'HandleVisibility','off');
        end
    end

    xlim(ax, [0 xmax]);
    ylim(ax, ylim_in);
    xticks(ax, 0:200:xmax);
    yticks(ax, 0:0.2:1.0);

    xlabel(ax, 'Spatial period (nm)', 'FontName', font_name, 'FontSize', 9.5);
    ylabel(ax, 'Phase retention', 'FontName', font_name, 'FontSize', 9.5);
    title(ax, 'Resolution criterion', 'FontName', font_name, 'FontSize', 10.5, 'FontWeight', 'normal');

    set(ax, ...
        'FontName', font_name, ...
        'FontSize', 8.5, ...
        'LineWidth', 0.85, ...
        'Box', 'on', ...
        'TickDir', 'in', ...
        'TickLength', [0.018 0.018], ...
        'Layer', 'top', ...
        'XColor', 'k', ...
        'YColor', 'k');

    lgd = legend(ax, {'GT / GT', 'WF-QPM / GT', 'Off-axis fused / GT'}, ...
        'Location', 'southeast');
    set(lgd, ...
        'FontName', font_name, ...
        'FontSize', 7.8, ...
        'Box', 'off', ...
        'TextColor', 'k');

    % Resolution annotation box.
    txt_lines = cell(numel(thresholds), 1);
    for ii = 1:numel(thresholds)
        if ii <= numel(res_fused) && isfinite(res_fused(ii))
            txt_lines{ii} = sprintf('%d%%: %.0f nm', round(100*thresholds(ii)), res_fused(ii));
        else
            txt_lines{ii} = sprintf('%d%%: N/A', round(100*thresholds(ii)));
        end
    end
    text(ax, 0.63*xmax, 0.58, txt_lines, ...
        'FontName', font_name, ...
        'FontSize', 7.8, ...
        'Color', 'k', ...
        'BackgroundColor', 'w', ...
        'EdgeColor', [0.75 0.75 0.75], ...
        'Margin', 5, ...
        'VerticalAlignment', 'bottom');

    % Try exportgraphics first; if MATLAB graphics is unstable, use print fallback.
    try
        exportgraphics(fig, [file_base '.png'], 'Resolution', dpi, 'BackgroundColor', 'white');
        exportgraphics(fig, [file_base '.tif'], 'Resolution', dpi, 'BackgroundColor', 'white');
    catch
        print(fig, [file_base '.png'], '-dpng', sprintf('-r%d', dpi));
        print(fig, [file_base '.tif'], '-dtiff', sprintf('-r%d', dpi));
    end
    close(fig);
end
