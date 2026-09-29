function PSI_formatFigure(fig)
    % Compact Nature-style formatting.
    % Left/bottom axes keep inward ticks; top/right are frame lines only.
    axisFontSize = 7.0;
    labelFontSize = 8.0;
    titleFontSize = 8.2;
    legendFontSize = 6.2;
    colorbarFontSize = 6.8;
    frameLineWidth = 0.75;

    set(fig, 'Color', 'w', 'InvertHardcopy', 'off');
    set(findall(fig, '-property', 'FontName'), 'FontName', 'Arial');
    delete(findall(fig, 'Tag', 'TopRightFrameLine'));

    ax = findall(fig, 'Type', 'axes');
    for ia = 1:numel(ax)
        thisAx = ax(ia);
        if strcmp(thisAx.Visible, 'off')
            continue;
        end
        set(thisAx, ...
            'FontName','Arial', ...
            'FontSize',axisFontSize, ...
            'LineWidth',frameLineWidth, ...
            'TickDir','in', ...
            'TickLength',[0.016 0.016], ...
            'Box','off', ...
            'Layer','top', ...
            'Color','w', ...
            'XColor','k', ...
            'YColor','k', ...
            'ZColor','k', ...
            'XMinorTick','off', ...
            'YMinorTick','off', ...
            'GridAlpha',0.10, ...
            'MinorGridAlpha',0.05);
        grid(thisAx, 'off');
        thisAx.XLabel.FontName = 'Arial';
        thisAx.YLabel.FontName = 'Arial';
        thisAx.Title.FontName = 'Arial';
        thisAx.XLabel.FontSize = labelFontSize;
        thisAx.YLabel.FontSize = labelFontSize;
        thisAx.Title.FontSize = titleFontSize;
        thisAx.XLabel.FontWeight = 'normal';
        thisAx.YLabel.FontWeight = 'normal';
        thisAx.Title.FontWeight = 'normal';
        thisAx.XLabel.Color = 'k';
        thisAx.YLabel.Color = 'k';
        thisAx.Title.Color = 'k';
        try, thisAx.Toolbar.Visible = 'off'; catch, end
        try, disableDefaultInteractivity(thisAx); catch, end
        PSI_drawTopRightFrame(thisAx, frameLineWidth);
    end

    lgd = findall(fig, 'Type', 'legend');
    for il = 1:numel(lgd)
        set(lgd(il), 'FontName','Arial', 'FontSize',legendFontSize, ...
            'Box','off', 'Color','none', 'TextColor',[0.10 0.10 0.10]);
        try, lgd(il).ItemTokenSize = [8 6]; catch, end
    end

    cb = findall(fig, 'Type', 'colorbar');
    for ic = 1:numel(cb)
        set(cb(ic), 'FontName','Arial', 'FontSize',colorbarFontSize, ...
            'Color','k', 'LineWidth',frameLineWidth, 'TickDirection','in');
        cb(ic).Label.FontName = 'Arial';
        cb(ic).Label.FontSize = labelFontSize;
        cb(ic).Label.Color = 'k';
        cb(ic).Label.FontWeight = 'normal';
    end
end
