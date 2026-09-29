function PSI_formatFigure_TP(fig)
    % Nature-style clean formatting with explicit white background.
    axisFontSize = 10;
    labelFontSize = 12;
    titleFontSize = 12;
    legendFontSize = 9;
    colorbarFontSize = 10;

    set(fig, 'Color', 'w', 'InvertHardcopy', 'off');
    set(findall(fig, '-property', 'FontName'), 'FontName', 'Arial');

    ax = findall(fig, 'Type', 'axes');
    for ia = 1:numel(ax)
        set(ax(ia), 'FontName', 'Arial', 'FontSize', axisFontSize, ...
            'LineWidth', 0.90, 'TickDir', 'out', 'TickLength', [0.018 0.018], ...
            'Box', 'off', 'Layer', 'top', 'Color', 'w', ...
            'XColor', 'k', 'YColor', 'k', 'ZColor', 'k', ...
            'GridColor', [0.85 0.85 0.85], 'MinorGridColor', [0.92 0.92 0.92], ...
            'GridAlpha', 0.16, 'MinorGridAlpha', 0.08);
        ax(ia).XLabel.FontName = 'Arial';
        ax(ia).YLabel.FontName = 'Arial';
        ax(ia).Title.FontName = 'Arial';
        ax(ia).XLabel.FontSize = labelFontSize;
        ax(ia).YLabel.FontSize = labelFontSize;
        ax(ia).Title.FontSize = titleFontSize;
        ax(ia).XLabel.Color = 'k';
        ax(ia).YLabel.Color = 'k';
        ax(ia).Title.Color = 'k';
        ax(ia).Title.FontWeight = 'normal';
        ax(ia).XTickLabelRotation = 0;
        ax(ia).YTickLabelRotation = 0;
        try
            ax(ia).Toolbar.Visible = 'off';
        catch
        end
        try
            disableDefaultInteractivity(ax(ia));
        catch
        end
    end

    lgd = findall(fig, 'Type', 'legend');
    for il = 1:numel(lgd)
        set(lgd(il), 'FontName', 'Arial', 'FontSize', legendFontSize, ...
            'Box', 'off', 'Color', 'none', 'TextColor', 'k');
    end

    cb = findall(fig, 'Type', 'colorbar');
    for ic = 1:numel(cb)
        set(cb(ic), 'FontName', 'Arial', 'FontSize', colorbarFontSize, ...
            'Color', 'k', 'LineWidth', 0.75, 'Box', 'off');
        cb(ic).Label.FontName = 'Arial';
        cb(ic).Label.FontSize = labelFontSize;
        cb(ic).Label.Color = 'k';
    end
end
