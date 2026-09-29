function ax = PSI_showTwoPointMapPanel(ax, img, x, y, ttl, climVals, halfWidth_nm, useDiverging)
    % Compact map panel without per-panel colorbar.  A shared colorbar is
    % added by the calling plotting block.
    axes(ax); %#ok<LAXES>
    x_nm = x(1,:) * 1e9;
    y_nm = y(:,1) * 1e9;
    ix = abs(x_nm) <= halfWidth_nm;
    iy = abs(y_nm) <= halfWidth_nm;
    hImg = imagesc(ax, x_nm(ix), y_nm(iy), img(iy,ix));
    try
        set(hImg, 'Interpolation', 'nearest');
    catch
    end
    axis(ax,'image');
    set(ax,'YDir','normal');
    if useDiverging
        colormap(ax, PSI_natureDivergingMap(256));
    else
        colormap(ax, PSI_natureSequentialMap(256));
    end
    caxis(ax,climVals);
    ax.XTick = [-300 0 300];
    ax.YTick = [-300 0 300];
    ax.XTickLabelRotation = 0;
    ax.YTickLabelRotation = 0;
    ax.TickLabelInterpreter = 'tex';
    title(ax, ttl, 'Interpreter','tex');
end
